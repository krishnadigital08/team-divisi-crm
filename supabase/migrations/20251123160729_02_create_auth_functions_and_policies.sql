/*
  # Auth Functions and RLS Policies

  1. Helper Functions
    - has_role: Check if user has a specific role
    - get_user_role: Get user's primary role
    - handle_new_user: Auto-create profile on signup
    
  2. RLS Policies
    - Profiles: Users can view their own, admins can view all
    - User Roles: Users can view their own, admins can manage
    - Divisions: All authenticated users can view
    - Sources: All authenticated users can view, admins can manage
    - Products: All authenticated users can view, admins can manage
    - Customers: Role-based access control
    - Interactions: Users can view/edit their own, admins can manage all
    - Settings: Appropriate access per table
*/

-- Helper function to check if user has a specific role
CREATE OR REPLACE FUNCTION public.has_role(user_id uuid, required_role app_role)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_roles.user_id = $1 AND role = $2
  );
$$;

-- Helper function to get user's primary role (highest in hierarchy)
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS app_role
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT role FROM public.user_roles 
  WHERE user_roles.user_id = $1
  ORDER BY 
    CASE role
      WHEN 'superadmin' THEN 1
      WHEN 'owner' THEN 2
      WHEN 'manager' THEN 3
      WHEN 'supervisor' THEN 4
      WHEN 'marketing' THEN 5
    END
  LIMIT 1;
$$;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (user_id, display_name, email, created_at, updated_at)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NEW.email,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create default user preferences
  INSERT INTO public.user_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create default notification settings
  INSERT INTO public.notification_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to create user data for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Profiles policies
CREATE POLICY "profiles_select_policy"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  ))
);

CREATE POLICY "profiles_insert_policy"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_update_policy"
ON public.profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR has_role(auth.uid(), 'superadmin'))
WITH CHECK (user_id = auth.uid() OR has_role(auth.uid(), 'superadmin'));

-- User roles policies
CREATE POLICY "user_roles_select_policy"
ON public.user_roles
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid() OR
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner')
);

CREATE POLICY "user_roles_insert_policy"
ON public.user_roles
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
);

CREATE POLICY "user_roles_update_policy"
ON public.user_roles
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
);

CREATE POLICY "user_roles_delete_policy"
ON public.user_roles
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
);

-- Divisions policies
CREATE POLICY "divisions_select_policy"
ON public.divisions
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "divisions_manage_policy"
ON public.divisions
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
);

-- Sources policies
CREATE POLICY "sources_select_policy"
ON public.sources
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "sources_manage_policy"
ON public.sources
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
);

-- Products policies
CREATE POLICY "products_select_policy"
ON public.products
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "products_manage_policy"
ON public.products
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager')
);

-- Customers policies
CREATE POLICY "customers_select_policy"
ON public.customers
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  )) OR
  (has_role(auth.uid(), 'supervisor') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  )) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

CREATE POLICY "customers_insert_policy"
ON public.customers
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  has_role(auth.uid(), 'manager') OR
  has_role(auth.uid(), 'marketing')
);

CREATE POLICY "customers_update_policy"
ON public.customers
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  )) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  )) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

CREATE POLICY "customers_delete_policy"
ON public.customers
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (
    SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
  ))
);

-- Customer products policies
CREATE POLICY "customer_products_all_policy"
ON public.customer_products
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.customers 
    WHERE customers.id = customer_products.customer_id
    AND (
      has_role(auth.uid(), 'superadmin') OR
      has_role(auth.uid(), 'owner') OR
      customers.assigned_to_user_id = auth.uid() OR
      (has_role(auth.uid(), 'manager') AND customers.division_id IN (
        SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
      ))
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.customers 
    WHERE customers.id = customer_products.customer_id
    AND (
      has_role(auth.uid(), 'superadmin') OR
      has_role(auth.uid(), 'owner') OR
      customers.assigned_to_user_id = auth.uid() OR
      (has_role(auth.uid(), 'manager') AND customers.division_id IN (
        SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
      ))
    )
  )
);

-- Interactions policies
CREATE POLICY "interactions_select_policy"
ON public.interactions
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid() OR
  (has_role(auth.uid(), 'manager') AND customer_id IN (
    SELECT id FROM public.customers WHERE division_id IN (
      SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
    )
  ))
);

CREATE POLICY "interactions_insert_policy"
ON public.interactions
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid()
);

CREATE POLICY "interactions_update_policy"
ON public.interactions
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid() OR
  (has_role(auth.uid(), 'manager') AND customer_id IN (
    SELECT id FROM public.customers WHERE division_id IN (
      SELECT division_id FROM public.profiles WHERE user_id = auth.uid()
    )
  ))
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid()
);

CREATE POLICY "interactions_delete_policy"
ON public.interactions
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid()
);

-- System settings policies
CREATE POLICY "system_settings_select_policy"
ON public.system_settings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "system_settings_manage_policy"
ON public.system_settings
FOR ALL
TO authenticated
USING (has_role(auth.uid(), 'superadmin'))
WITH CHECK (has_role(auth.uid(), 'superadmin'));

-- Company settings policies
CREATE POLICY "company_settings_select_policy"
ON public.company_settings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "company_settings_manage_policy"
ON public.company_settings
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner')
);

-- User preferences policies
CREATE POLICY "user_preferences_all_policy"
ON public.user_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Notification settings policies
CREATE POLICY "notification_settings_all_policy"
ON public.notification_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
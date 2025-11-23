/*
  # Fix Infinite Recursion in RLS Policies - Complete Rewrite

  1. Changes
    - Drop all policies that use has_role
    - Drop and recreate has_role function with CASCADE
    - Recreate all policies properly to avoid recursion
*/

-- Drop has_role function with all dependent policies
DROP FUNCTION IF EXISTS public.has_role(uuid, app_role) CASCADE;

-- Recreate has_role function with STABLE and proper security
CREATE OR REPLACE FUNCTION public.has_role(check_user_id uuid, required_role app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = check_user_id AND role = required_role
  );
$$;

-- Profiles policies (avoiding recursion)
CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "profiles_select_by_admins"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_roles.user_id = auth.uid() 
    AND role IN ('superadmin', 'owner')
  )
);

CREATE POLICY "profiles_insert_own"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_update_own"
ON public.profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "profiles_update_by_admins"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_roles.user_id = auth.uid() 
    AND role = 'superadmin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_roles.user_id = auth.uid() 
    AND role = 'superadmin'
  )
);

-- User roles policies
CREATE POLICY "user_roles_select_own"
ON public.user_roles
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "user_roles_select_by_admins"
ON public.user_roles
FOR SELECT
TO authenticated
USING (has_role(auth.uid(), 'superadmin') OR has_role(auth.uid(), 'owner'));

CREATE POLICY "user_roles_manage_by_admins"
ON public.user_roles
FOR ALL
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
);

-- Divisions policies
CREATE POLICY "divisions_select_all"
ON public.divisions
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "divisions_manage_by_admins"
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
CREATE POLICY "sources_select_all"
ON public.sources
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "sources_manage_by_admins"
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
CREATE POLICY "products_select_all"
ON public.products
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "products_manage_by_admins"
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

-- Customers policies (simplified to avoid recursion)
CREATE POLICY "customers_select_policy"
ON public.customers
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  assigned_to_user_id = auth.uid() OR
  created_by_user_id = auth.uid()
);

CREATE POLICY "customers_insert_policy"
ON public.customers
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "customers_update_policy"
ON public.customers
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  assigned_to_user_id = auth.uid() OR
  created_by_user_id = auth.uid()
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  assigned_to_user_id = auth.uid() OR
  created_by_user_id = auth.uid()
);

CREATE POLICY "customers_delete_by_admins"
ON public.customers
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner')
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
      customers.assigned_to_user_id = auth.uid()
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
      customers.assigned_to_user_id = auth.uid()
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
  user_id = auth.uid()
);

CREATE POLICY "interactions_insert_policy"
ON public.interactions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "interactions_update_policy"
ON public.interactions
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid()
)
WITH CHECK (user_id = auth.uid());

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
CREATE POLICY "system_settings_select_all"
ON public.system_settings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "system_settings_manage_by_superadmin"
ON public.system_settings
FOR ALL
TO authenticated
USING (has_role(auth.uid(), 'superadmin'))
WITH CHECK (has_role(auth.uid(), 'superadmin'));

-- Company settings policies
CREATE POLICY "company_settings_select_all"
ON public.company_settings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "company_settings_manage_by_admins"
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
CREATE POLICY "user_preferences_all_own"
ON public.user_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Notification settings policies
CREATE POLICY "notification_settings_all_own"
ON public.notification_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
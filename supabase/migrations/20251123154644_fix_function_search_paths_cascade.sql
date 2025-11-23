/*
  # Fix Function Search Paths with CASCADE

  1. Security Improvements
    - Set explicit search_path for functions to prevent search path manipulation attacks
    - Recreate functions and their dependent policies
    
  2. Changes
    - Drop and recreate has_role function with explicit search_path using CASCADE
    - Drop and recreate get_user_role function with explicit search_path
*/

-- Drop and recreate has_role function with CASCADE
DROP FUNCTION IF EXISTS public.has_role(uuid, app_role) CASCADE;

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

-- Recreate all policies that depend on has_role

-- Customers policies
CREATE POLICY "customers_select_policy"
ON public.customers
FOR SELECT
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'supervisor') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

CREATE POLICY "customers_insert_policy"
ON public.customers
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

CREATE POLICY "customers_update_policy"
ON public.customers
FOR UPDATE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

CREATE POLICY "customers_delete_policy"
ON public.customers
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())) OR
  (has_role(auth.uid(), 'marketing') AND assigned_to_user_id = auth.uid())
);

-- Divisions policies
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
    SELECT id FROM customers WHERE division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())
  ))
);

CREATE POLICY "interactions_insert_policy"
ON public.interactions
FOR INSERT
TO authenticated
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid() OR
  (has_role(auth.uid(), 'manager') AND customer_id IN (
    SELECT id FROM customers WHERE division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())
  ))
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
    SELECT id FROM customers WHERE division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())
  ))
)
WITH CHECK (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid() OR
  (has_role(auth.uid(), 'manager') AND customer_id IN (
    SELECT id FROM customers WHERE division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())
  ))
);

CREATE POLICY "interactions_delete_policy"
ON public.interactions
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  user_id = auth.uid() OR
  (has_role(auth.uid(), 'manager') AND customer_id IN (
    SELECT id FROM customers WHERE division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid())
  ))
);

-- Products policies
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

-- Profiles policies
CREATE POLICY "profiles_select_policy"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  id = auth.uid() OR
  has_role(auth.uid(), 'superadmin') OR
  has_role(auth.uid(), 'owner') OR
  (has_role(auth.uid(), 'manager') AND division_id IN (SELECT division_id FROM profiles WHERE id = auth.uid()))
);

CREATE POLICY "profiles_update_policy"
ON public.profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid() OR has_role(auth.uid(), 'superadmin'))
WITH CHECK (id = auth.uid() OR has_role(auth.uid(), 'superadmin'));

-- Sources policies
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

CREATE POLICY "user_roles_delete_policy"
ON public.user_roles
FOR DELETE
TO authenticated
USING (
  has_role(auth.uid(), 'superadmin') OR
  (has_role(auth.uid(), 'owner') AND role != 'superadmin')
);

-- Drop and recreate get_user_role function with explicit search_path
DROP FUNCTION IF EXISTS public.get_user_role(uuid);

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
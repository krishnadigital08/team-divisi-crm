/*
  # Re-enable RLS and Fix Multiple Permissive Policies

  1. Security Improvements
    - Re-enable RLS on all tables
    - Consolidate multiple permissive policies into single policies using OR conditions
    - This improves performance and security clarity
    
  2. Changes
    - Enable RLS on all public tables
    - Drop old fragmented policies
    - Create consolidated policies for each action
*/

-- Re-enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on customers table
DROP POLICY IF EXISTS "Manager can manage customers in their division" ON public.customers;
DROP POLICY IF EXISTS "Marketing can manage their assigned customers" ON public.customers;
DROP POLICY IF EXISTS "Owner can manage all customers" ON public.customers;
DROP POLICY IF EXISTS "Superadmin can manage all customers" ON public.customers;
DROP POLICY IF EXISTS "Supervisor can view customers in their division" ON public.customers;

-- Create consolidated policies for customers
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

-- Drop all existing policies on divisions table
DROP POLICY IF EXISTS "Authenticated users can view divisions" ON public.divisions;
DROP POLICY IF EXISTS "Managers can manage divisions" ON public.divisions;

-- Create consolidated policies for divisions
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

-- Drop all existing policies on interactions table
DROP POLICY IF EXISTS "Manager can manage interactions in their division" ON public.interactions;
DROP POLICY IF EXISTS "Owner can manage all interactions" ON public.interactions;
DROP POLICY IF EXISTS "Superadmin can manage all interactions" ON public.interactions;
DROP POLICY IF EXISTS "Users can manage their own interactions" ON public.interactions;

-- Create consolidated policies for interactions
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

-- Drop all existing policies on products table
DROP POLICY IF EXISTS "Authenticated users can view products" ON public.products;
DROP POLICY IF EXISTS "Managers can manage products" ON public.products;

-- Create consolidated policies for products
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

-- Drop all existing policies on profiles table
DROP POLICY IF EXISTS "Manager can view profiles in their division" ON public.profiles;
DROP POLICY IF EXISTS "Owner can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Superadmin can manage all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Superadmin can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- Create consolidated policies for profiles
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

-- Drop all existing policies on sources table
DROP POLICY IF EXISTS "Authenticated users can view sources" ON public.sources;
DROP POLICY IF EXISTS "Managers can manage sources" ON public.sources;

-- Create consolidated policies for sources
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

-- Drop all existing policies on user_roles table
DROP POLICY IF EXISTS "Owner can manage non-superadmin roles" ON public.user_roles;
DROP POLICY IF EXISTS "Superadmin can manage all roles" ON public.user_roles;
DROP POLICY IF EXISTS "Owner can view all roles" ON public.user_roles;
DROP POLICY IF EXISTS "Users can view their own roles" ON public.user_roles;

-- Create consolidated policies for user_roles
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
/*
  # Add Foreign Key Indexes for Performance

  1. Performance Improvements
    - Add indexes on all foreign key columns to improve query performance
    - This prevents suboptimal query performance when joining tables
    
  2. Tables Affected
    - customer_products: product_id
    - customers: assigned_to_user_id, created_by_user_id, division_id, manager_user_id, source_id, supervisor_user_id
    - interactions: customer_id, user_id
    - profiles: division_id
    - user_roles: assigned_by
*/

-- Customer Products
CREATE INDEX IF NOT EXISTS idx_customer_products_product_id ON public.customer_products(product_id);

-- Customers
CREATE INDEX IF NOT EXISTS idx_customers_assigned_to_user_id ON public.customers(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_created_by_user_id ON public.customers(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_division_id ON public.customers(division_id);
CREATE INDEX IF NOT EXISTS idx_customers_manager_user_id ON public.customers(manager_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_source_id ON public.customers(source_id);
CREATE INDEX IF NOT EXISTS idx_customers_supervisor_user_id ON public.customers(supervisor_user_id);

-- Interactions
CREATE INDEX IF NOT EXISTS idx_interactions_customer_id ON public.interactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_interactions_user_id ON public.interactions(user_id);

-- Profiles
CREATE INDEX IF NOT EXISTS idx_profiles_division_id ON public.profiles(division_id);

-- User Roles
CREATE INDEX IF NOT EXISTS idx_user_roles_assigned_by ON public.user_roles(assigned_by);
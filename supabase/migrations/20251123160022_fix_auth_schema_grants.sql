/*
  # Fix Auth Schema Access

  1. Changes
    - Grant necessary permissions to auth schema
    - Ensure authenticator role can access what it needs
*/

-- Grant usage on auth schema to necessary roles
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- Grant select on auth.users to service_role (needed for triggers)
GRANT SELECT ON auth.users TO service_role;

-- Ensure public schema grants are correct
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
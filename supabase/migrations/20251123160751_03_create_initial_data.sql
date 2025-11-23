/*
  # Initial Data Setup

  1. Company Settings
    - Create default company settings
    
  2. Divisions
    - Create sample divisions
    
  3. Sources
    - Create common lead sources
    
  4. Products
    - Create sample products
*/

-- Insert default company settings
INSERT INTO public.company_settings (
  id,
  company_name,
  logo_url,
  primary_color,
  timezone,
  date_format,
  currency
) VALUES (
  gen_random_uuid(),
  'Master Plan CRM',
  '',
  '#3B82F6',
  'Asia/Jakarta',
  'dd/MM/yyyy',
  'IDR'
) ON CONFLICT DO NOTHING;

-- Insert sample divisions
INSERT INTO public.divisions (id, name, description) VALUES
  (gen_random_uuid(), 'Sales', 'Sales and Business Development'),
  (gen_random_uuid(), 'Marketing', 'Marketing and Communications'),
  (gen_random_uuid(), 'Customer Service', 'Customer Support and Relations'),
  (gen_random_uuid(), 'Operations', 'Operations and Logistics')
ON CONFLICT DO NOTHING;

-- Insert common sources
INSERT INTO public.sources (id, name, description, is_active) VALUES
  (gen_random_uuid(), 'Website', 'Leads from company website', true),
  (gen_random_uuid(), 'Referral', 'Customer referrals', true),
  (gen_random_uuid(), 'Social Media', 'Social media channels', true),
  (gen_random_uuid(), 'Cold Call', 'Outbound cold calling', true),
  (gen_random_uuid(), 'Email Campaign', 'Email marketing campaigns', true),
  (gen_random_uuid(), 'Trade Show', 'Industry events and trade shows', true),
  (gen_random_uuid(), 'Partner', 'Business partner referrals', true)
ON CONFLICT DO NOTHING;

-- Insert sample products
INSERT INTO public.products (id, name, description, price, is_active) VALUES
  (gen_random_uuid(), 'CRM Basic', 'Basic CRM package for small businesses', 500000, true),
  (gen_random_uuid(), 'CRM Professional', 'Professional CRM with advanced features', 1500000, true),
  (gen_random_uuid(), 'CRM Enterprise', 'Enterprise-grade CRM solution', 5000000, true),
  (gen_random_uuid(), 'Consulting Service', 'CRM implementation and consulting', 2000000, true),
  (gen_random_uuid(), 'Training Package', 'Staff training and onboarding', 1000000, true),
  (gen_random_uuid(), 'Custom Development', 'Custom feature development', 3000000, true)
ON CONFLICT DO NOTHING;
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://bbertkjreeaybjfdryds.supabase.co";
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJiZXJ0a2pyZWVheWJqZmRyeWRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NjE3MzcsImV4cCI6MjA3OTQzNzczN30.IGjRuzbqH7cqIUvW3sqMin2yPv-Q5CcloKphFcb7JJo";

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});
import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { config, assertConfig } from '../config';

assertConfig();

export const supabase: SupabaseClient = createClient(
  config.supabaseUrl || 'https://placeholder.supabase.co',
  config.supabaseAnonKey || 'placeholder',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      storage: typeof window !== 'undefined' ? window.localStorage : undefined,
    },
  },
);

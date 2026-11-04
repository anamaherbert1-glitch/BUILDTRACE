/**
 * Configuration publique BUILDTRACE.
 * Ne jamais y placer de clé service_role.
 */
export const config = {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL as string,
  supabaseAnonKey: import.meta.env.VITE_SUPABASE_ANON_KEY as string,
  appName: 'BUILDTRACE',
  storageBucket: 'listing-photos',
} as const;

export function assertConfig(): void {
  if (!config.supabaseUrl || !config.supabaseAnonKey) {
    console.error(
      '[BUILDTRACE] Variables VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY requises.',
    );
  }
}

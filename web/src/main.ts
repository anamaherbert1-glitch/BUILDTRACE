import { assertConfig } from './config';
import { AuthBridge } from './auth-bridge';
import { fetchPublishedListings } from './services/listings.service';

assertConfig();

export async function bootstrap(): Promise<void> {
  try {
    const session = await AuthBridge.getSession();
    console.info('[BUILDTRACE] Session:', session?.user?.email ?? 'anonyme');

    AuthBridge.onAuthStateChange((event, next) => {
      console.info('[BUILDTRACE] Auth:', event, next?.user?.id ?? null);
    });

    const listings = await fetchPublishedListings(12).catch(() => []);
    console.info('[BUILDTRACE] Annonces:', listings.length);

    (window as unknown as { BUILDTRACE_TS?: object }).BUILDTRACE_TS = {
      auth: AuthBridge,
      listings,
    };
  } catch (err) {
    console.error('[BUILDTRACE] Bootstrap:', err);
  }
}

if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => void bootstrap());
  } else {
    void bootstrap();
  }
}

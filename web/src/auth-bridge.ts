/**
 * Pont entre l'UI HTML et le service d'auth TypeScript.
 * Compatible chargement via Vite (import) ou build.
 */
import {
  signIn,
  signUp,
  signOut,
  signInWithOAuth,
  resetPassword,
  getSession,
  onAuthStateChange,
  AuthError,
} from './services/auth.service';

export const AuthBridge = {
  signIn,
  signUp,
  signOut,
  signInWithOAuth,
  resetPassword,
  getSession,
  onAuthStateChange,
  AuthError,
};

declare global {
  interface Window {
    BUILDTRACE_AUTH?: typeof AuthBridge;
  }
}

if (typeof window !== 'undefined') {
  window.BUILDTRACE_AUTH = AuthBridge;
}

export default AuthBridge;

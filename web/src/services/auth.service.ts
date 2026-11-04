import type { User, Session, AuthChangeEvent } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { Profile } from '../types/database';

export type AuthMode = 'login' | 'signup';

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

function mapAuthError(err: unknown): Error {
  const msg =
    err && typeof err === 'object' && 'message' in err
      ? String((err as { message: string }).message)
      : 'Erreur d’authentification.';

  const lower = msg.toLowerCase();
  if (lower.includes('invalid login')) {
    return new AuthError('E-mail ou mot de passe incorrect.');
  }
  if (lower.includes('already registered') || lower.includes('already been registered')) {
    return new AuthError('Un compte existe déjà avec cet e-mail.');
  }
  if (lower.includes('password')) {
    return new AuthError('Le mot de passe doit contenir au moins 6 caractères.');
  }
  if (lower.includes('email')) {
    return new AuthError('Adresse e-mail invalide.');
  }
  return new AuthError(msg);
}

export async function getSession(): Promise<Session | null> {
  const { data, error } = await supabase.auth.getSession();
  if (error) throw mapAuthError(error);
  return data.session;
}

export async function getCurrentUser(): Promise<User | null> {
  const { data, error } = await supabase.auth.getUser();
  if (error) throw mapAuthError(error);
  return data.user;
}

export async function signUp(
  email: string,
  password: string,
  fullName: string,
): Promise<{ user: User | null; session: Session | null; needsEmailConfirm: boolean }> {
  const cleanEmail = email.trim().toLowerCase();
  const cleanName = fullName.trim();
  if (!cleanName) throw new AuthError('Saisissez votre nom et prénom.');
  if (!cleanEmail) throw new AuthError('Saisissez votre e-mail.');
  if (password.length < 6) {
    throw new AuthError('Le mot de passe doit contenir au moins 6 caractères.');
  }

  const redirectTo =
    typeof window !== 'undefined'
      ? `${window.location.origin}${window.location.pathname}`
      : undefined;

  const { data, error } = await supabase.auth.signUp({
    email: cleanEmail,
    password,
    options: {
      data: { full_name: cleanName },
      emailRedirectTo: redirectTo,
    },
  });
  if (error) throw mapAuthError(error);

  if (data.user) {
    await ensureProfile(data.user.id, cleanName, cleanEmail);
  }

  return {
    user: data.user,
    session: data.session,
    needsEmailConfirm: !data.session,
  };
}

export async function signIn(
  email: string,
  password: string,
): Promise<{ user: User; session: Session }> {
  const cleanEmail = email.trim().toLowerCase();
  if (!cleanEmail || !password) {
    throw new AuthError('E-mail et mot de passe requis.');
  }

  const { data, error } = await supabase.auth.signInWithPassword({
    email: cleanEmail,
    password,
  });
  if (error) throw mapAuthError(error);
  if (!data.user || !data.session) {
    throw new AuthError('Connexion impossible.');
  }
  return { user: data.user, session: data.session };
}

export async function signOut(): Promise<void> {
  const { error } = await supabase.auth.signOut();
  if (error) throw mapAuthError(error);
}

export async function resetPassword(email: string): Promise<void> {
  const cleanEmail = email.trim().toLowerCase();
  if (!cleanEmail) throw new AuthError('Saisissez votre e-mail.');

  const redirectTo =
    typeof window !== 'undefined'
      ? `${window.location.origin}${window.location.pathname}`
      : undefined;

  const { error } = await supabase.auth.resetPasswordForEmail(cleanEmail, {
    redirectTo,
  });
  if (error) throw mapAuthError(error);
}

export async function signInWithOAuth(
  provider: 'google' | 'apple',
): Promise<void> {
  const redirectTo =
    typeof window !== 'undefined'
      ? `${window.location.origin}${window.location.pathname}`
      : undefined;

  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo,
      queryParams: provider === 'google' ? { prompt: 'select_account' } : undefined,
    },
  });
  if (error) throw mapAuthError(error);
}

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle();
  if (error) throw mapAuthError(error);
  return data as Profile | null;
}

export async function ensureProfile(
  userId: string,
  fullName: string,
  email?: string,
): Promise<void> {
  const { error } = await supabase.from('profiles').upsert(
    {
      id: userId,
      full_name: fullName,
      ...(email ? { email } : {}),
    },
    { onConflict: 'id' },
  );
  // Ne pas bloquer l'auth si la colonne email n'existe pas encore
  if (error && !String(error.message).toLowerCase().includes('email')) {
    console.warn('[BUILDTRACE] ensureProfile:', error.message);
  }
}

export function onAuthStateChange(
  callback: (event: AuthChangeEvent, session: Session | null) => void,
) {
  return supabase.auth.onAuthStateChange((event, session) => {
    callback(event, session);
  });
}

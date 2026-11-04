import { supabase } from '../lib/supabase';
import type { CreateListingInput, Listing } from '../types/database';

export async function fetchPublishedListings(limit = 40): Promise<Listing[]> {
  const { data, error } = await supabase
    .from('listings')
    .select('*')
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return (data ?? []) as Listing[];
}

export async function fetchMyListings(ownerId: string): Promise<Listing[]> {
  const { data, error } = await supabase
    .from('listings')
    .select('*')
    .eq('owner_id', ownerId)
    .order('updated_at', { ascending: false });
  if (error) throw error;
  return (data ?? []) as Listing[];
}

export async function fetchListingById(id: string): Promise<Listing | null> {
  const { data, error } = await supabase
    .from('listings')
    .select('*')
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  return data as Listing | null;
}

export async function createListing(
  ownerId: string,
  input: CreateListingInput,
): Promise<Listing> {
  const payload = {
    ...input,
    owner_id: ownerId,
    status: input.status ?? 'published',
    published_at:
      (input.status ?? 'published') === 'published'
        ? new Date().toISOString()
        : null,
    photo_urls: input.photo_urls ?? [],
  };
  const { data, error } = await supabase
    .from('listings')
    .insert(payload)
    .select('*')
    .single();
  if (error) throw error;
  return data as Listing;
}

export async function searchListings(params: {
  query?: string;
  category?: string;
  location?: string;
}): Promise<Listing[]> {
  let q = supabase
    .from('listings')
    .select('*')
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .limit(50);

  if (params.category) q = q.eq('category', params.category);
  if (params.location) q = q.ilike('location', `%${params.location}%`);
  if (params.query) q = q.ilike('title', `%${params.query}%`);

  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as Listing[];
}

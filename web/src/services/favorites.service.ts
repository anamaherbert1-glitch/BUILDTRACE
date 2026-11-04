import { supabase } from '../lib/supabase';
import type { Favorite, Listing } from '../types/database';

export async function listFavorites(userId: string): Promise<Favorite[]> {
  const { data, error } = await supabase
    .from('favorites')
    .select('*')
    .eq('user_id', userId);
  if (error) throw error;
  return (data ?? []) as Favorite[];
}

export async function listFavoriteListings(userId: string): Promise<Listing[]> {
  const { data, error } = await supabase
    .from('favorites')
    .select('listing_id, listings(*)')
    .eq('user_id', userId);
  if (error) throw error;
  return (data ?? [])
    .map((row: { listings: Listing | Listing[] | null }) => {
      const l = row.listings;
      return Array.isArray(l) ? l[0] : l;
    })
    .filter(Boolean) as Listing[];
}

export async function addFavorite(
  userId: string,
  listingId: string,
): Promise<void> {
  const { error } = await supabase
    .from('favorites')
    .insert({ user_id: userId, listing_id: listingId });
  if (error) throw error;
}

export async function removeFavorite(
  userId: string,
  listingId: string,
): Promise<void> {
  const { error } = await supabase
    .from('favorites')
    .delete()
    .eq('user_id', userId)
    .eq('listing_id', listingId);
  if (error) throw error;
}

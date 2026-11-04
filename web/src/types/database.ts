/** Types alignés sur le schéma Supabase BUILDTRACE */

export type ListingType = 'sale' | 'rent' | 'both';
export type ListingStatus = 'draft' | 'published' | 'archived' | 'rejected';
export type ListingCondition = 'excellent' | 'good' | 'fair' | 'poor';
export type AccountType = 'individual' | 'pro' | 'business' | 'admin';

export interface Profile {
  id: string;
  full_name: string | null;
  company_name: string | null;
  phone: string | null;
  city: string | null;
  account_type: AccountType;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Listing {
  id: string;
  owner_id: string;
  title: string;
  description: string | null;
  category: string;
  quantity: number;
  unit: string;
  dimensions: string | null;
  condition: ListingCondition;
  listing_type: ListingType;
  sale_price_xof: number | null;
  rental_price_xof: number | null;
  rental_period: string | null;
  location: string;
  photo_urls: string[];
  status: ListingStatus;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface Conversation {
  id: string;
  listing_id: string | null;
  buyer_id: string;
  seller_id: string;
  created_at: string;
  updated_at: string;
}

export interface Message {
  id: string;
  conversation_id: string;
  sender_id: string;
  content: string;
  created_at: string;
}

export interface Favorite {
  user_id: string;
  listing_id: string;
  created_at: string;
}

export interface SupportRequest {
  id: string;
  user_id: string | null;
  kind: string;
  subject: string;
  body: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface CreateListingInput {
  title: string;
  description?: string;
  category: string;
  quantity: number;
  unit: string;
  dimensions?: string;
  condition: ListingCondition;
  listing_type: ListingType;
  sale_price_xof?: number | null;
  rental_price_xof?: number | null;
  rental_period?: string | null;
  location: string;
  photo_urls?: string[];
  status?: ListingStatus;
}

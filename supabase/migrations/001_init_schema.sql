-- ============================================================
-- BUILDTRACE — schéma initial (PLpgSQL / PostgreSQL / Supabase)
-- Tables alignées sur l'application web existante
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------- ENUMS ----------
DO $$ BEGIN
  CREATE TYPE public.listing_type AS ENUM ('sale', 'rent', 'both');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.listing_status AS ENUM ('draft', 'published', 'archived', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.listing_condition AS ENUM ('excellent', 'good', 'fair', 'poor');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.account_type AS ENUM ('individual', 'pro', 'business', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------- PROFILES ----------
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT,
  company_name  TEXT,
  phone         TEXT,
  city          TEXT,
  account_type  public.account_type NOT NULL DEFAULT 'individual',
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_city ON public.profiles (city);

-- ---------- LISTINGS (annonces) ----------
CREATE TABLE IF NOT EXISTS public.listings (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  description       TEXT,
  category          TEXT NOT NULL DEFAULT 'autre',
  quantity          NUMERIC(12, 2) NOT NULL DEFAULT 1,
  unit              TEXT NOT NULL DEFAULT 'unité',
  dimensions        TEXT,
  condition         public.listing_condition NOT NULL DEFAULT 'good',
  listing_type      public.listing_type NOT NULL DEFAULT 'sale',
  sale_price_xof    NUMERIC(14, 2),
  rental_price_xof  NUMERIC(14, 2),
  rental_period     TEXT,
  location          TEXT NOT NULL DEFAULT '',
  photo_urls        TEXT[] NOT NULL DEFAULT '{}',
  status            public.listing_status NOT NULL DEFAULT 'draft',
  published_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT listings_price_check CHECK (
    listing_type = 'rent'
      OR sale_price_xof IS NOT NULL
      OR listing_type = 'both'
  )
);

CREATE INDEX IF NOT EXISTS idx_listings_status ON public.listings (status);
CREATE INDEX IF NOT EXISTS idx_listings_owner ON public.listings (owner_id);
CREATE INDEX IF NOT EXISTS idx_listings_category ON public.listings (category);
CREATE INDEX IF NOT EXISTS idx_listings_published ON public.listings (published_at DESC NULLS LAST);

-- ---------- CONVERSATIONS ----------
CREATE TABLE IF NOT EXISTS public.conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id  UUID REFERENCES public.listings(id) ON DELETE SET NULL,
  buyer_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seller_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT conversations_parties_distinct CHECK (buyer_id <> seller_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_conversation_listing_buyer_seller
  ON public.conversations (listing_id, buyer_id, seller_id);

CREATE INDEX IF NOT EXISTS idx_conversations_buyer ON public.conversations (buyer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_seller ON public.conversations (seller_id);

-- ---------- MESSAGES ----------
CREATE TABLE IF NOT EXISTS public.messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content          TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT messages_content_not_empty CHECK (length(trim(content)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages (conversation_id, created_at);

-- ---------- FAVORITES ----------
CREATE TABLE IF NOT EXISTS public.favorites (
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  listing_id  UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, listing_id)
);

-- ---------- SUPPORT / FEEDBACK ----------
CREATE TABLE IF NOT EXISTS public.support_requests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  kind        TEXT NOT NULL DEFAULT 'feedback',
  subject     TEXT NOT NULL,
  body        TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'open',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------- updated_at trigger ----------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_updated ON public.profiles;
CREATE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_listings_updated ON public.listings;
CREATE TRIGGER trg_listings_updated
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_conversations_updated ON public.conversations;
CREATE TRIGGER trg_conversations_updated
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------- Auto profile on signup ----------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

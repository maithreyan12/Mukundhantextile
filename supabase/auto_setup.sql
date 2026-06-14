-- ============================================================
-- E-Commerce App - Automatic Supabase Setup
-- Tables, RLS policies, triggers, and demo data
-- Run this in the Supabase SQL Editor
-- ============================================================

-- ========================
-- 1. EXTENSIONS
-- ========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- 2. CUSTOM TYPES
-- ========================
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('customer', 'admin');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ========================
-- 3. HELPERS
-- ========================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  );
$$;

-- ========================
-- 4. TABLES
-- ========================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'customer',
  phone TEXT,
  is_banned BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_price NUMERIC(10,2),
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  stock INT NOT NULL DEFAULT 0,
  images TEXT[] NOT NULL DEFAULT '{}',
  rating NUMERIC(2,1) NOT NULL DEFAULT 0,
  review_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  variants JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  image_url TEXT NOT NULL,
  title TEXT,
  target_type TEXT,
  target_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.wishlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);

CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  variant JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id, variant)
);

-- ========================
-- 5. INDEXES
-- ========================
CREATE INDEX IF NOT EXISTS idx_categories_active ON public.categories(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_created ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_banners_active ON public.banners(is_active, sort_order);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON public.wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_product ON public.wishlist(product_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_user ON public.cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_product ON public.cart_items(product_id);

-- ========================
-- 6. TRIGGERS
-- ========================
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_categories_updated_at ON public.categories;
CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON public.categories
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_banners_updated_at ON public.banners;
CREATE TRIGGER trg_banners_updated_at
BEFORE UPDATE ON public.banners
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture')
  )
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        email = EXCLUDED.email,
        avatar_url = EXCLUDED.avatar_url,
        updated_at = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================
-- 7. RLS
-- ========================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_admin_all ON public.profiles;

CREATE POLICY profiles_insert_own
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_select_own
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_update_own
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id OR public.is_admin())
  WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_admin_all
  ON public.profiles
  FOR DELETE
  USING (public.is_admin());

-- Categories
DROP POLICY IF EXISTS categories_public_select ON public.categories;
DROP POLICY IF EXISTS categories_admin_insert ON public.categories;
DROP POLICY IF EXISTS categories_admin_update ON public.categories;
DROP POLICY IF EXISTS categories_admin_delete ON public.categories;

CREATE POLICY categories_public_select
  ON public.categories
  FOR SELECT
  USING (true);

CREATE POLICY categories_admin_insert
  ON public.categories
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY categories_admin_update
  ON public.categories
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY categories_admin_delete
  ON public.categories
  FOR DELETE
  USING (public.is_admin());

-- Products
DROP POLICY IF EXISTS products_public_select ON public.products;
DROP POLICY IF EXISTS products_admin_insert ON public.products;
DROP POLICY IF EXISTS products_admin_update ON public.products;
DROP POLICY IF EXISTS products_admin_delete ON public.products;

CREATE POLICY products_public_select
  ON public.products
  FOR SELECT
  USING (true);

CREATE POLICY products_admin_insert
  ON public.products
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY products_admin_update
  ON public.products
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY products_admin_delete
  ON public.products
  FOR DELETE
  USING (public.is_admin());

-- Banners
DROP POLICY IF EXISTS banners_public_select ON public.banners;
DROP POLICY IF EXISTS banners_admin_insert ON public.banners;
DROP POLICY IF EXISTS banners_admin_update ON public.banners;
DROP POLICY IF EXISTS banners_admin_delete ON public.banners;

CREATE POLICY banners_public_select
  ON public.banners
  FOR SELECT
  USING (true);

CREATE POLICY banners_admin_insert
  ON public.banners
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY banners_admin_update
  ON public.banners
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY banners_admin_delete
  ON public.banners
  FOR DELETE
  USING (public.is_admin());

-- Wishlist
DROP POLICY IF EXISTS wishlist_select_own ON public.wishlist;
DROP POLICY IF EXISTS wishlist_insert_own ON public.wishlist;
DROP POLICY IF EXISTS wishlist_update_own ON public.wishlist;
DROP POLICY IF EXISTS wishlist_delete_own ON public.wishlist;

CREATE POLICY wishlist_select_own
  ON public.wishlist
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY wishlist_insert_own
  ON public.wishlist
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY wishlist_update_own
  ON public.wishlist
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY wishlist_delete_own
  ON public.wishlist
  FOR DELETE
  USING (auth.uid() = user_id);

-- Cart Items
DROP POLICY IF EXISTS cart_select_own ON public.cart_items;
DROP POLICY IF EXISTS cart_insert_own ON public.cart_items;
DROP POLICY IF EXISTS cart_update_own ON public.cart_items;
DROP POLICY IF EXISTS cart_delete_own ON public.cart_items;

CREATE POLICY cart_select_own
  ON public.cart_items
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY cart_insert_own
  ON public.cart_items
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY cart_update_own
  ON public.cart_items
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY cart_delete_own
  ON public.cart_items
  FOR DELETE
  USING (auth.uid() = user_id);

-- ========================
-- 8. DEMO DATA
-- ========================
INSERT INTO public.categories (id, name, image_url, sort_order, is_active)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Electronics', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=1200&q=80', 1, true),
  ('22222222-2222-2222-2222-222222222222', 'Fashion', 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=1200&q=80', 2, true),
  ('33333333-3333-3333-3333-333333333333', 'Home', 'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80', 3, true),
  ('44444444-4444-4444-4444-444444444444', 'Sports', 'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1200&q=80', 4, true)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    image_url = EXCLUDED.image_url,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO public.banners (id, image_url, title, target_type, target_id, sort_order, is_active)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1600&q=80', 'Summer Deals', 'category', '11111111-1111-1111-1111-111111111111', 1, true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1600&q=80', 'New Arrivals', 'product', '55555555-5555-5555-5555-555555555551', 2, true)
ON CONFLICT (id) DO UPDATE
SET image_url = EXCLUDED.image_url,
    title = EXCLUDED.title,
    target_type = EXCLUDED.target_type,
    target_id = EXCLUDED.target_id,
    sort_order = EXCLUDED.sort_order,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO public.products (
  id, name, description, price, discount_price, category_id,
  stock, images, rating, review_count, is_active, variants
)
VALUES
  (
    '55555555-5555-5555-5555-555555555551',
    'Wireless Headphones',
    'Premium noise-cancelling wireless headphones with long battery life.',
    129.99,
    99.99,
    '11111111-1111-1111-1111-111111111111',
    25,
    ARRAY['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=1200&q=80'],
    4.8,
    124,
    true,
    '[{"color":"Black"},{"color":"White"}]'::jsonb
  ),
  (
    '55555555-5555-5555-5555-555555555552',
    'Smart Watch',
    'Track health, workouts, and notifications from your wrist.',
    89.99,
    74.99,
    '11111111-1111-1111-1111-111111111111',
    18,
    ARRAY['https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1200&q=80'],
    4.6,
    88,
    true,
    '[{"size":"42mm"},{"size":"44mm"}]'::jsonb
  ),
  (
    '55555555-5555-5555-5555-555555555553',
    'Casual Jacket',
    'Lightweight jacket for everyday wear.',
    59.99,
    49.99,
    '22222222-2222-2222-2222-222222222222',
    40,
    ARRAY['https://images.unsplash.com/photo-1523398002811-999ca8dec234?auto=format&fit=crop&w=1200&q=80'],
    4.4,
    56,
    true,
    '[{"size":"M"},{"size":"L"},{"size":"XL"}]'::jsonb
  ),
  (
    '55555555-5555-5555-5555-555555555554',
    'Modern Sofa',
    'Minimal sofa for a clean living room setup.',
    399.99,
    349.99,
    '33333333-3333-3333-3333-333333333333',
    8,
    ARRAY['https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1200&q=80'],
    4.7,
    41,
    true,
    '[{"color":"Beige"},{"color":"Gray"}]'::jsonb
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    'Running Shoes',
    'Comfortable sneakers built for daily training.',
    79.99,
    NULL,
    '44444444-4444-4444-4444-444444444444',
    30,
    ARRAY['https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=1200&q=80'],
    4.9,
    202,
    true,
    '[{"size":"8"},{"size":"9"},{"size":"10"}]'::jsonb
  )
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    price = EXCLUDED.price,
    discount_price = EXCLUDED.discount_price,
    category_id = EXCLUDED.category_id,
    stock = EXCLUDED.stock,
    images = EXCLUDED.images,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    is_active = EXCLUDED.is_active,
    variants = EXCLUDED.variants,
    updated_at = now();

-- Optional examples for authenticated-user data:
-- INSERT INTO public.wishlist (user_id, product_id)
-- VALUES ('<auth-user-id>', '55555555-5555-5555-5555-555555555551');
-- INSERT INTO public.cart_items (user_id, product_id, quantity, variant)
-- VALUES ('<auth-user-id>', '55555555-5555-5555-5555-555555555551', 1, '{"color":"Black"}'::jsonb);

-- ============================================================
-- DONE
-- ============================================================

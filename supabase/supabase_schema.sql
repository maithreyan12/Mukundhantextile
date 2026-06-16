-- ============================================================
-- E-Commerce App — Supabase Schema Migration (FIXED)
-- Run this ENTIRE script in the Supabase SQL Editor
-- ============================================================

-- ========================
-- 1. EXTENSIONS
-- ========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- 2. CUSTOM TYPES
-- ========================
DO $$ BEGIN
  CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE discount_type AS ENUM ('percentage', 'flat');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('customer', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ========================
-- 3. TABLES
-- ========================

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
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

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_price NUMERIC(10,2),
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  stock INT NOT NULL DEFAULT 0,
  images TEXT[] NOT NULL DEFAULT '{}',
  rating NUMERIC(2,1) NOT NULL DEFAULT 0,
  review_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  variants JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Cart Items
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  variant JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id, variant)
);

-- Wishlist
CREATE TABLE IF NOT EXISTS wishlist (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- Addresses
CREATE TABLE IF NOT EXISTS addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  street TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  coupon_code TEXT,
  status order_status NOT NULL DEFAULT 'pending',
  payment_method TEXT NOT NULL DEFAULT 'cod',
  shipping_address JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  product_image TEXT,
  quantity INT NOT NULL DEFAULT 1,
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  variant JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- Coupons
CREATE TABLE IF NOT EXISTS coupons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  discount_type discount_type NOT NULL DEFAULT 'percentage',
  value NUMERIC(10,2) NOT NULL DEFAULT 0,
  min_order_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  expiry_date TIMESTAMPTZ,
  usage_limit INT NOT NULL DEFAULT 0,
  used_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Banners
CREATE TABLE IF NOT EXISTS banners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  image_url TEXT NOT NULL,
  title TEXT,
  target_type TEXT, -- 'product', 'category', 'url'
  target_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'general',
  data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Browse Settings
CREATE TABLE IF NOT EXISTS browse_settings (
  id TEXT PRIMARY KEY,
  live_now_label TEXT NOT NULL DEFAULT 'Live now',
  live_now_sort TEXT NOT NULL DEFAULT 'popular',
  live_now_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  deals_label TEXT NOT NULL DEFAULT 'Deals at 99',
  deals_price NUMERIC(10,2) NOT NULL DEFAULT 99.0,
  deals_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sale_coming_label TEXT NOT NULL DEFAULT 'Sale coming!',
  sale_coming_sort TEXT NOT NULL DEFAULT 'new',
  sale_coming_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ========================

-- 4. INDEXES
-- ========================
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_created ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cart_items_user ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_user ON wishlist(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_user ON addresses(user_id);

-- ========================
-- 5. FUNCTIONS & TRIGGERS (BEFORE RLS!)
-- ========================

-- Auto-create profile on user signup
-- SECURITY DEFINER means this runs with the function owner's privileges,
-- bypassing RLS entirely — this is critical for new user signup!
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', COALESCE(NEW.raw_user_meta_data->>'full_name', '')),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
  );
  RETURN NEW;
EXCEPTION WHEN unique_violation THEN
  -- Profile already exists, just return
  RETURN NEW;
WHEN OTHERS THEN
  -- Log but don't block signup
  RAISE LOG 'handle_new_user error for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Update product rating when a review is added/updated/deleted
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
DECLARE
  _product_id UUID;
BEGIN
  _product_id := COALESCE(NEW.product_id, OLD.product_id);

  UPDATE products
  SET
    rating = COALESCE((
      SELECT ROUND(AVG(rating)::numeric, 1)
      FROM reviews
      WHERE product_id = _product_id
    ), 0),
    review_count = (
      SELECT COUNT(*)
      FROM reviews
      WHERE product_id = _product_id
    ),
    updated_at = now()
  WHERE id = _product_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_change ON reviews;
CREATE TRIGGER on_review_change
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_product_rating();

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS set_products_updated_at ON products;
CREATE TRIGGER set_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS set_orders_updated_at ON orders;
CREATE TRIGGER set_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ========================
-- 6. ROW LEVEL SECURITY
-- ========================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE browse_settings ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies first to avoid conflicts on re-run

DO $$ 
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- CRITICAL: Create a SECURITY DEFINER function to check admin role
-- This bypasses RLS, preventing infinite recursion on the profiles table
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- ---- Profiles ----
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id OR is_admin());

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id OR is_admin())
  WITH CHECK (auth.uid() = id OR is_admin());

-- ---- Categories ----
CREATE POLICY "categories_public_read"
  ON categories FOR SELECT USING (true);

CREATE POLICY "categories_admin_insert"
  ON categories FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "categories_admin_update"
  ON categories FOR UPDATE USING (is_admin());
CREATE POLICY "categories_admin_delete"
  ON categories FOR DELETE USING (is_admin());

-- ---- Products ----
CREATE POLICY "products_public_read"
  ON products FOR SELECT USING (true);

CREATE POLICY "products_admin_insert"
  ON products FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "products_admin_update"
  ON products FOR UPDATE USING (is_admin());
CREATE POLICY "products_admin_delete"
  ON products FOR DELETE USING (is_admin());

-- ---- Cart Items ----
CREATE POLICY "cart_select_own"
  ON cart_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "cart_insert_own"
  ON cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cart_update_own"
  ON cart_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "cart_delete_own"
  ON cart_items FOR DELETE USING (auth.uid() = user_id);

-- ---- Wishlist ----
CREATE POLICY "wishlist_select_own"
  ON wishlist FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "wishlist_insert_own"
  ON wishlist FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "wishlist_delete_own"
  ON wishlist FOR DELETE USING (auth.uid() = user_id);

-- ---- Addresses ----
CREATE POLICY "addresses_select_own"
  ON addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "addresses_insert_own"
  ON addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "addresses_update_own"
  ON addresses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "addresses_delete_own"
  ON addresses FOR DELETE USING (auth.uid() = user_id);

-- ---- Orders ----
CREATE POLICY "orders_select_own"
  ON orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "orders_insert_own"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "orders_admin_select"
  ON orders FOR SELECT USING (is_admin());
CREATE POLICY "orders_admin_update"
  ON orders FOR UPDATE USING (is_admin());

-- ---- Order Items ----
CREATE POLICY "order_items_select_own"
  ON order_items FOR SELECT
  USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));
CREATE POLICY "order_items_insert_own"
  ON order_items FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()));
CREATE POLICY "order_items_admin_select"
  ON order_items FOR SELECT USING (is_admin());

-- ---- Reviews ----
CREATE POLICY "reviews_public_read"
  ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert_own"
  ON reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews_update_own"
  ON reviews FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews_delete_own"
  ON reviews FOR DELETE USING (auth.uid() = user_id);

-- ---- Coupons ----
CREATE POLICY "coupons_read_authenticated"
  ON coupons FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "coupons_admin_insert"
  ON coupons FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "coupons_admin_update"
  ON coupons FOR UPDATE USING (is_admin());
CREATE POLICY "coupons_admin_delete"
  ON coupons FOR DELETE USING (is_admin());

-- ---- Banners ----
CREATE POLICY "banners_public_read"
  ON banners FOR SELECT USING (true);
CREATE POLICY "banners_admin_insert"
  ON banners FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "banners_admin_update"
  ON banners FOR UPDATE USING (is_admin());
CREATE POLICY "banners_admin_delete"
  ON banners FOR DELETE USING (is_admin());

-- ---- Notifications ----
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "notifications_admin_insert"
  ON notifications FOR INSERT WITH CHECK (is_admin());

-- ---- Browse Settings ----
CREATE POLICY "browse_settings_public_read"
  ON browse_settings FOR SELECT USING (true);
CREATE POLICY "browse_settings_admin_insert"
  ON browse_settings FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "browse_settings_admin_update"
  ON browse_settings FOR UPDATE USING (is_admin());
CREATE POLICY "browse_settings_admin_delete"
  ON browse_settings FOR DELETE USING (is_admin());

-- ========================

-- 7. STORAGE BUCKETS
-- ========================
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('category-images', 'category-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('banner-images', 'banner-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies (drop first to avoid duplicate errors)
DROP POLICY IF EXISTS "public_read_product_images" ON storage.objects;
DROP POLICY IF EXISTS "public_read_category_images" ON storage.objects;
DROP POLICY IF EXISTS "public_read_banner_images" ON storage.objects;
DROP POLICY IF EXISTS "auth_upload_images" ON storage.objects;
DROP POLICY IF EXISTS "auth_update_images" ON storage.objects;
DROP POLICY IF EXISTS "auth_delete_images" ON storage.objects;
DROP POLICY IF EXISTS "avatar_owner_select" ON storage.objects;
DROP POLICY IF EXISTS "avatar_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatar_owner_update" ON storage.objects;

CREATE POLICY "public_read_product_images" ON storage.objects 
  FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "public_read_category_images" ON storage.objects 
  FOR SELECT USING (bucket_id = 'category-images');

CREATE POLICY "public_read_banner_images" ON storage.objects 
  FOR SELECT USING (bucket_id = 'banner-images');

CREATE POLICY "auth_upload_images" ON storage.objects 
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "auth_update_images" ON storage.objects 
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "auth_delete_images" ON storage.objects 
  FOR DELETE USING (auth.role() = 'authenticated');

CREATE POLICY "avatar_owner_select" ON storage.objects 
  FOR SELECT USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatar_owner_insert" ON storage.objects 
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatar_owner_update" ON storage.objects 
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ========================
-- 8. ENABLE REALTIME
-- ========================
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ========================
-- 9. CREATE PROFILES FOR EXISTING USERS
-- (if users signed up before this migration)
-- ========================
INSERT INTO public.profiles (id, name, email)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'name', raw_user_meta_data->>'full_name', ''),
  COALESCE(email, '')
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT (id) DO NOTHING;

-- ========================
-- DONE! Your schema is ready.
-- ========================

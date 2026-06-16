-- Migration: Create browse_settings table
-- Created at: 2026-06-16

CREATE TABLE IF NOT EXISTS public.browse_settings (
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

-- Enable RLS
ALTER TABLE public.browse_settings ENABLE ROW LEVEL SECURITY;

-- Drop Policies if exist
DROP POLICY IF EXISTS browse_settings_public_select ON public.browse_settings;
DROP POLICY IF EXISTS browse_settings_admin_insert ON public.browse_settings;
DROP POLICY IF EXISTS browse_settings_admin_update ON public.browse_settings;
DROP POLICY IF EXISTS browse_settings_admin_delete ON public.browse_settings;

-- Create Policies
CREATE POLICY browse_settings_public_select
  ON public.browse_settings
  FOR SELECT
  USING (true);

CREATE POLICY browse_settings_admin_insert
  ON public.browse_settings
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY browse_settings_admin_update
  ON public.browse_settings
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY browse_settings_admin_delete
  ON public.browse_settings
  FOR DELETE
  USING (public.is_admin());

-- Insert Default Row
INSERT INTO public.browse_settings (id, live_now_label, live_now_sort, live_now_enabled, deals_label, deals_price, deals_enabled, sale_coming_label, sale_coming_sort, sale_coming_enabled)
VALUES ('popular_store_settings', 'Live now', 'popular', true, 'Deals at 99', 99.0, true, 'Sale coming!', 'new', true)
ON CONFLICT (id) DO NOTHING;

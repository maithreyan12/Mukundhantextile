-- ============================================================
-- SQL Script: Reset Orders for mukundhantextile@gmail.com
-- Run this script in your Supabase SQL Editor to clear
-- mock orders and reset the admin dashboard revenue analysis.
-- ============================================================

-- 1. Create a policy to allow admins to delete orders if needed in future
CREATE POLICY "orders_admin_delete" 
  ON public.orders FOR DELETE 
  USING (is_admin());

-- 2. Delete all orders (and cascade delete order items) for mukundhantextile@gmail.com
DELETE FROM public.orders 
WHERE user_id IN (
  SELECT id FROM public.profiles WHERE email = 'mukundhantextile@gmail.com'
);

-- Remove Prostitution category and its subcategories from Supabase
-- Run this in your Supabase SQL Editor

-- First, delete all subcategories for Prostitution
DELETE FROM public.subcategories
WHERE category_id IN (
  SELECT id FROM public.categories WHERE name = 'Prostitution'
);

-- Then, delete the Prostitution category itself
DELETE FROM public.categories
WHERE name = 'Prostitution';

-- Verify deletion (optional - run this to check)
-- SELECT * FROM public.categories WHERE name = 'Prostitution';
-- SELECT * FROM public.subcategories WHERE category_id IN (SELECT id FROM public.categories WHERE name = 'Prostitution');


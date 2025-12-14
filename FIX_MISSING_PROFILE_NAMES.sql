-- Fix Missing Profile Names
-- This script helps identify and fix profiles with NULL or empty names

-- 1. Check profiles with missing names
SELECT 
  id,
  name,
  created_at,
  CASE 
    WHEN name IS NULL OR name = '' THEN 'Missing Name'
    ELSE 'Has Name'
  END as status
FROM public.profiles
WHERE name IS NULL OR name = '';

-- 2. Update profiles with empty names to use a default based on user ID
-- This is a temporary fix - users should update their profiles in the app
UPDATE public.profiles
SET name = 'User ' || SUBSTRING(id::text, 1, 8)
WHERE name IS NULL OR name = '';

-- 3. Verify the update
SELECT 
  id,
  name,
  created_at
FROM public.profiles
WHERE name LIKE 'User %'
ORDER BY created_at DESC;

-- Note: Users should go to Settings in the app and update their profile name
-- This script just ensures they have a readable name instead of NULL


-- Fix RLS policy for profiles to allow group members to see each other's names
-- This allows users to see profiles of other users who are in the same groups

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;

-- Create a new policy that allows:
-- 1. Users to see their own profile
-- 2. Users to see profiles of other users who are in the same groups
CREATE POLICY "profiles_select_own_or_group_member"
ON public.profiles FOR SELECT
USING (
  id = public.uid() -- Can see own profile
  OR EXISTS (
    -- Can see profiles of users who are in at least one group with the current user
    SELECT 1 FROM public.group_members gm1
    INNER JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = public.uid()  -- Current user is in this group
    AND gm2.user_id = profiles.id      -- The profile owner is also in this group
  )
);


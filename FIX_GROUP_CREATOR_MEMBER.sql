-- Fix RLS policy to ensure group creators can add themselves as members
-- This ensures that when a user creates a group, they can immediately add themselves

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "members_insert_admin_or_self" ON public.group_members;
DROP POLICY IF EXISTS "members_insert_creator" ON public.group_members;

-- Create policy that allows:
-- 1. Users to add themselves (when creating a group)
-- 2. Group creators to add themselves even if not yet a member
-- 3. Admins to add other members
CREATE POLICY "members_insert_admin_or_self"
ON public.group_members FOR INSERT
WITH CHECK (
  -- User can always add themselves
  user_id = public.uid()
  -- OR user is the creator of the group (allows adding self when creating group)
  OR EXISTS (
    SELECT 1 FROM public.groups g
    WHERE g.id = group_members.group_id 
    AND g.created_by = public.uid()
  )
  -- OR user is an admin of the group
  OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_members.group_id 
    AND gm.user_id = public.uid() 
    AND gm.role = 'admin'
  )
);


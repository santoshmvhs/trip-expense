-- Allow non-admin members to leave groups
-- This updates the RLS policy to allow users to delete themselves from group_members
-- Only if they are NOT an admin

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "members_delete_admin_only" ON public.group_members;

-- Create new policy that allows:
-- 1. Admins can delete any member (existing behavior)
-- 2. Non-admin members can delete themselves (new behavior)
CREATE POLICY "members_delete_admin_or_self"
ON public.group_members FOR DELETE
USING (
  -- Admin can delete any member
  EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_members.group_id 
    AND gm.user_id = public.uid() 
    AND gm.role = 'admin'
  )
  OR
  -- Non-admin can delete themselves (but not others)
  (
    user_id = public.uid()
    AND NOT EXISTS (
      -- Make sure they're not an admin trying to leave
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_members.group_id
      AND gm.user_id = public.uid()
      AND gm.role = 'admin'
    )
  )
);

-- Add comment for documentation
COMMENT ON POLICY "members_delete_admin_or_self" ON public.group_members IS 
'Allows admins to delete any member, and non-admin members to delete themselves. Prevents admins from leaving groups.';


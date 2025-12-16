-- Fix Expense Edit Permissions
-- Allow any group member to edit expenses (not just creator/admin)
-- Run this in Supabase SQL Editor

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "expenses_update_if_creator_or_admin" ON public.expenses;
DROP POLICY IF EXISTS "expenses_delete_if_creator_or_admin" ON public.expenses;
DROP POLICY IF EXISTS "splits_insert_if_expense_creator_or_admin" ON public.expense_splits;
DROP POLICY IF EXISTS "splits_update_if_expense_creator_or_admin" ON public.expense_splits;
DROP POLICY IF EXISTS "splits_delete_if_expense_creator_or_admin" ON public.expense_splits;

-- Create new policies that allow any group member to edit/delete expenses
CREATE POLICY "expenses_update_if_group_member"
ON public.expenses FOR UPDATE
USING (public.is_group_member(group_id, public.uid()))
WITH CHECK (public.is_group_member(group_id, public.uid()));

CREATE POLICY "expenses_delete_if_group_member"
ON public.expenses FOR DELETE
USING (public.is_group_member(group_id, public.uid()));

-- Allow any group member to manage expense splits
CREATE POLICY "splits_insert_if_group_member"
ON public.expense_splits FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
  )
);

CREATE POLICY "splits_update_if_group_member"
ON public.expense_splits FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
  )
);

CREATE POLICY "splits_delete_if_group_member"
ON public.expense_splits FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
  )
);



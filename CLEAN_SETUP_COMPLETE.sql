-- COMPLETE CLEAN SETUP FOR TRIP EXPENSE APP
-- This script drops all existing tables and recreates them in the correct order
-- Run this ENTIRE script in Supabase SQL Editor

-- ============================================================================
-- STEP 1: DROP ALL EXISTING OBJECTS (in reverse dependency order)
-- ============================================================================

-- Drop triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.is_group_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.uid() CASCADE;

-- Drop tables (in reverse dependency order to avoid foreign key issues)
DROP TABLE IF EXISTS public.user_budgets CASCADE;
DROP TABLE IF EXISTS public.group_budgets CASCADE;
DROP TABLE IF EXISTS public.settlements CASCADE;
DROP TABLE IF EXISTS public.expense_splits CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.groups CASCADE;
DROP TABLE IF EXISTS public.group_invitations CASCADE;
DROP TABLE IF EXISTS public.group_activities CASCADE;
DROP TABLE IF EXISTS public.subcategories CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ============================================================================
-- STEP 2: CREATE EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- STEP 3: CREATE TABLES (in dependency order)
-- ============================================================================

-- PROFILES (1:1 with auth.users) - MUST BE FIRST
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  photo_url TEXT,
  default_currency TEXT NOT NULL DEFAULT 'INR',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- GROUPS
CREATE TABLE public.groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- GROUP MEMBERS
CREATE TABLE public.group_members (
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- admin | member
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

-- EXPENSES
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  paid_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  expense_date DATE NOT NULL DEFAULT (NOW()::DATE),
  category TEXT,
  subcategory TEXT,
  notes TEXT,
  receipt_path TEXT, -- supabase storage path
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- EXPENSE SPLITS (who owes how much for an expense)
CREATE TABLE public.expense_splits (
  expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  share NUMERIC(12,2) NOT NULL CHECK (share >= 0),
  PRIMARY KEY (expense_id, user_id)
);

-- SETTLEMENTS (optional: record payments)
CREATE TABLE public.settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  from_user UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  to_user UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  method TEXT, -- cash, bank, upi, etc
  notes TEXT,
  settled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- GROUP INVITATIONS
CREATE TABLE public.group_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, accepted, declined
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, email)
);

-- GROUP ACTIVITIES (timeline)
CREATE TABLE public.group_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL, -- expense_added, expense_updated, member_added, etc.
  description TEXT NOT NULL,
  related_id UUID, -- ID of related expense, member, etc.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- CATEGORIES (shared across all users)
CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- SUBCATEGORIES
CREATE TABLE public.subcategories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(category_id, name)
);

-- GROUP BUDGETS (trip-level budgets)
CREATE TABLE public.group_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  category TEXT, -- Optional: budget for specific category
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- USER BUDGETS (individual private budgets per group)
CREATE TABLE public.user_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  category TEXT, -- Optional: budget for specific category
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, user_id, category) -- One budget per user per group per category
);

-- ============================================================================
-- STEP 4: CREATE INDEXES
-- ============================================================================

CREATE INDEX idx_group_members_user ON public.group_members(user_id);
CREATE INDEX idx_expenses_group_date ON public.expenses(group_id, expense_date DESC);
CREATE INDEX idx_splits_user ON public.expense_splits(user_id);
CREATE INDEX idx_settlements_group ON public.settlements(group_id, settled_at DESC);
CREATE INDEX idx_invitations_email ON public.group_invitations(email);
CREATE INDEX idx_invitations_token ON public.group_invitations(token);
CREATE INDEX idx_activities_group ON public.group_activities(group_id, created_at DESC);
CREATE INDEX idx_group_budgets_group ON public.group_budgets(group_id);
CREATE INDEX idx_user_budgets_group_user ON public.user_budgets(group_id, user_id);
CREATE INDEX idx_subcategories_category ON public.subcategories(category_id);

-- ============================================================================
-- STEP 5: CREATE HELPER FUNCTIONS
-- ============================================================================

-- RLS-friendly membership check
CREATE OR REPLACE FUNCTION public.is_group_member(gid UUID, uid UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = gid AND gm.user_id = uid
  );
$$;

-- Helper function for RLS
CREATE OR REPLACE FUNCTION public.uid()
RETURNS UUID
LANGUAGE SQL
STABLE
AS $$
  SELECT auth.uid();
$$;

-- ============================================================================
-- STEP 6: ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 7: CREATE RLS POLICIES
-- ============================================================================

-- PROFILES
-- Allow users to see their own profile AND profiles of users in the same groups
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

CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
WITH CHECK (id = public.uid());

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
USING (id = public.uid())
WITH CHECK (id = public.uid());

-- GROUPS
CREATE POLICY "groups_select_if_member"
ON public.groups FOR SELECT
USING (public.is_group_member(id, public.uid()) OR created_by = public.uid());

CREATE POLICY "groups_insert_authenticated"
ON public.groups FOR INSERT
WITH CHECK (created_by = public.uid());

CREATE POLICY "groups_update_if_creator_or_admin"
ON public.groups FOR UPDATE
USING (
  created_by = public.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

CREATE POLICY "groups_delete_if_creator_or_admin"
ON public.groups FOR DELETE
USING (
  created_by = public.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

-- GROUP MEMBERS
CREATE POLICY "members_select_if_member"
ON public.group_members FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

-- Allow admin to add members, or allow user to add themselves when creating group
CREATE POLICY "members_insert_admin_or_self"
ON public.group_members FOR INSERT
WITH CHECK (
  user_id = public.uid() -- User can add themselves
  OR EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_members.group_id 
    AND gm.user_id = public.uid() 
    AND gm.role = 'admin'
  )
);

CREATE POLICY "members_update_admin_only"
ON public.group_members FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_members.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

CREATE POLICY "members_delete_admin_only"
ON public.group_members FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_members.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

-- EXPENSES
CREATE POLICY "expenses_select_if_member"
ON public.expenses FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "expenses_insert_if_member"
ON public.expenses FOR INSERT
WITH CHECK (
  public.is_group_member(group_id, public.uid())
  AND created_by = public.uid()
);

CREATE POLICY "expenses_update_if_creator_or_admin"
ON public.expenses FOR UPDATE
USING (
  public.is_group_member(group_id, public.uid())
  AND (
    created_by = public.uid()
    OR EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
    )
  )
);

CREATE POLICY "expenses_delete_if_creator_or_admin"
ON public.expenses FOR DELETE
USING (
  public.is_group_member(group_id, public.uid())
  AND (
    created_by = public.uid()
    OR EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
    )
  )
);

-- EXPENSE SPLITS
CREATE POLICY "splits_select_if_group_member"
ON public.expense_splits FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id AND public.is_group_member(e.group_id, public.uid())
  )
);

CREATE POLICY "splits_insert_if_expense_creator_or_admin"
ON public.expense_splits FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
      AND (
        e.created_by = public.uid()
        OR EXISTS (
          SELECT 1 FROM public.group_members gm
          WHERE gm.group_id = e.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
        )
      )
  )
);

CREATE POLICY "splits_update_if_expense_creator_or_admin"
ON public.expense_splits FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
      AND (
        e.created_by = public.uid()
        OR EXISTS (
          SELECT 1 FROM public.group_members gm
          WHERE gm.group_id = e.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
        )
      )
  )
);

CREATE POLICY "splits_delete_if_expense_creator_or_admin"
ON public.expense_splits FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.expenses e
    WHERE e.id = expense_id
      AND public.is_group_member(e.group_id, public.uid())
      AND (
        e.created_by = public.uid()
        OR EXISTS (
          SELECT 1 FROM public.group_members gm
          WHERE gm.group_id = e.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
        )
      )
  )
);

-- SETTLEMENTS
CREATE POLICY "settlements_select_if_member"
ON public.settlements FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "settlements_insert_if_member"
ON public.settlements FOR INSERT
WITH CHECK (public.is_group_member(group_id, public.uid()));

CREATE POLICY "settlements_delete_admin_only"
ON public.settlements FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

-- GROUP INVITATIONS
CREATE POLICY "invitations_select_if_group_member"
ON public.group_invitations FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "invitations_insert_if_admin"
ON public.group_invitations FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
  )
);

-- GROUP ACTIVITIES
CREATE POLICY "activities_select_if_member"
ON public.group_activities FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "activities_insert_if_member"
ON public.group_activities FOR INSERT
WITH CHECK (public.is_group_member(group_id, public.uid()));

-- CATEGORIES (public read access for all authenticated users)
CREATE POLICY "categories_select_all"
ON public.categories FOR SELECT
TO authenticated
USING (true);

-- SUBCATEGORIES (public read access for all authenticated users)
CREATE POLICY "subcategories_select_all"
ON public.subcategories FOR SELECT
TO authenticated
USING (true);

-- GROUP BUDGETS (trip-level budgets - visible to all group members)
CREATE POLICY "group_budgets_select_if_member"
ON public.group_budgets FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "group_budgets_insert_if_admin"
ON public.group_budgets FOR INSERT
WITH CHECK (
  public.is_group_member(group_id, public.uid())
  AND (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
    )
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = public.uid()
    )
  )
);

CREATE POLICY "group_budgets_update_if_admin"
ON public.group_budgets FOR UPDATE
USING (
  public.is_group_member(group_id, public.uid())
  AND (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
    )
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = public.uid()
    )
  )
);

CREATE POLICY "group_budgets_delete_if_admin"
ON public.group_budgets FOR DELETE
USING (
  public.is_group_member(group_id, public.uid())
  AND (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
    )
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_id AND g.created_by = public.uid()
    )
  )
);

-- USER BUDGETS (individual private budgets - only visible to the user)
CREATE POLICY "user_budgets_select_own"
ON public.user_budgets FOR SELECT
USING (user_id = public.uid());

CREATE POLICY "user_budgets_insert_own"
ON public.user_budgets FOR INSERT
WITH CHECK (
  user_id = public.uid()
  AND public.is_group_member(group_id, public.uid())
);

CREATE POLICY "user_budgets_update_own"
ON public.user_budgets FOR UPDATE
USING (user_id = public.uid())
WITH CHECK (user_id = public.uid());

CREATE POLICY "user_budgets_delete_own"
ON public.user_budgets FOR DELETE
USING (user_id = public.uid());

-- ============================================================================
-- STEP 8: CREATE SIGNUP TRIGGER (BULLETPROOF VERSION)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_name TEXT;
BEGIN
  -- Extract name from metadata (try both 'full_name' and 'name')
  user_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  );
  
  -- Insert profile - this will NEVER fail and block signup
  BEGIN
    INSERT INTO public.profiles (id, name, default_currency)
    VALUES (NEW.id, user_name, 'INR')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    -- Even if insert fails, don't block signup
    -- The client-side fallback will handle profile creation
    NULL;
  END;
  
  -- ALWAYS return NEW to allow signup to succeed
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- STEP 9: GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.groups TO authenticated;
GRANT ALL ON public.group_members TO authenticated;
GRANT ALL ON public.expenses TO authenticated;
GRANT ALL ON public.expense_splits TO authenticated;
GRANT ALL ON public.settlements TO authenticated;
GRANT ALL ON public.group_invitations TO authenticated;
GRANT ALL ON public.group_activities TO authenticated;
GRANT ALL ON public.group_budgets TO authenticated;
GRANT ALL ON public.user_budgets TO authenticated;
GRANT SELECT ON public.categories TO authenticated;
GRANT SELECT ON public.subcategories TO authenticated;


-- Add Moments Feature to Trip App
-- This adds moment-centric financial orchestration alongside existing groups/expenses

-- ============================================================================
-- MOMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE, -- NULLABLE: moments can be standalone or group-linked
  type TEXT NOT NULL CHECK (type IN ('trip', 'gift', 'goal', 'wishlist')),
  title TEXT NOT NULL,
  description TEXT,
  target_amount NUMERIC(12,2) NOT NULL CHECK (target_amount > 0),
  current_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ NOT NULL,
  lifecycle_state TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (lifecycle_state IN ('DRAFT', 'ACTIVE', 'COMPLETED')),
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  funded BOOLEAN NOT NULL DEFAULT FALSE,
  overdue BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MOMENT PARTICIPANTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moment_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULLABLE: can invite by email
  email TEXT NOT NULL, -- Required for non-users
  display_name TEXT,
  role TEXT NOT NULL DEFAULT 'contributor' CHECK (role IN ('creator', 'contributor', 'observer')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create unique index using COALESCE (PostgreSQL allows functions in indexes)
CREATE UNIQUE INDEX IF NOT EXISTS idx_moment_participants_unique 
ON public.moment_participants(moment_id, COALESCE(user_id::text, email));

-- ============================================================================
-- MOMENT CONTRIBUTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moment_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL, -- user_id UUID as text OR email
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  note TEXT,
  expense_id UUID REFERENCES public.expenses(id) ON DELETE SET NULL, -- NULLABLE: link to expense if applicable
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MOMENT ACTIVITY LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moment_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL CHECK (activity_type IN ('contribution_added', 'participant_added', 'moment_closed', 'moment_updated')),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata JSONB, -- Flexible metadata storage
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MOMENT WISHLIST ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.moment_wishlist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2) CHECK (price >= 0),
  link TEXT, -- URL to the item
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'wanted' CHECK (status IN ('wanted', 'purchased', 'fulfilled')),
  image_url TEXT, -- URL to item image
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  purchased_by UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Who purchased/fulfilled it
  purchased_at TIMESTAMPTZ, -- When it was purchased
  contribution_id UUID REFERENCES public.moment_contributions(id) ON DELETE SET NULL, -- Link to contribution if applicable
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- ADD MOMENT_ID TO EXPENSES (optional link)
-- ============================================================================
ALTER TABLE public.expenses 
ADD COLUMN IF NOT EXISTS moment_id UUID REFERENCES public.moments(id) ON DELETE SET NULL;

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_moments_group ON public.moments(group_id);
CREATE INDEX IF NOT EXISTS idx_moments_created_by ON public.moments(created_by);
CREATE INDEX IF NOT EXISTS idx_moments_lifecycle ON public.moments(lifecycle_state);
CREATE INDEX IF NOT EXISTS idx_moment_participants_moment ON public.moment_participants(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_participants_user ON public.moment_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_moment_contributions_moment ON public.moment_contributions(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_contributions_participant ON public.moment_contributions(participant_id);
CREATE INDEX IF NOT EXISTS idx_moment_contributions_expense ON public.moment_contributions(expense_id);
CREATE INDEX IF NOT EXISTS idx_expenses_moment ON public.expenses(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_activities_moment ON public.moment_activities(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_wishlist_items_moment ON public.moment_wishlist_items(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_wishlist_items_status ON public.moment_wishlist_items(status);
CREATE INDEX IF NOT EXISTS idx_moment_wishlist_items_created_by ON public.moment_wishlist_items(created_by);

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.moments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_wishlist_items ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DROP POLICIES THAT DEPEND ON FUNCTIONS FIRST
-- ============================================================================
-- Drop policies that depend on is_moment_participant before dropping the function
DROP POLICY IF EXISTS "moments_select_if_creator_or_participant" ON public.moments;
DROP POLICY IF EXISTS "moments_insert_if_authenticated" ON public.moments;
DROP POLICY IF EXISTS "moments_update_if_creator" ON public.moments;
DROP POLICY IF EXISTS "moments_delete_if_creator" ON public.moments;

-- Drop policies that depend on get_user_email BEFORE dropping the function
DROP POLICY IF EXISTS "moment_participants_select_if_moment_access" ON public.moment_participants;
DROP POLICY IF EXISTS "moment_participants_insert_if_creator" ON public.moment_participants;
DROP POLICY IF EXISTS "moment_contributions_select_if_moment_access" ON public.moment_contributions;
DROP POLICY IF EXISTS "moment_contributions_insert_if_participant" ON public.moment_contributions;
DROP POLICY IF EXISTS "moment_activities_select_if_moment_access" ON public.moment_activities;
DROP POLICY IF EXISTS "moment_activities_insert_if_authenticated" ON public.moment_activities;
DROP POLICY IF EXISTS "moment_wishlist_items_select_if_moment_access" ON public.moment_wishlist_items;
DROP POLICY IF EXISTS "moment_wishlist_items_insert_if_participant" ON public.moment_wishlist_items;
DROP POLICY IF EXISTS "moment_wishlist_items_update_if_participant" ON public.moment_wishlist_items;
DROP POLICY IF EXISTS "moment_wishlist_items_delete_if_creator" ON public.moment_wishlist_items;

-- ============================================================================
-- HELPER FUNCTIONS: Drop in correct order (is_moment_participant depends on get_user_email)
-- ============================================================================
-- Drop is_moment_participant first (it depends on get_user_email)
DROP FUNCTION IF EXISTS public.is_moment_participant(UUID, UUID) CASCADE;

-- Then drop get_user_email (after all dependent functions are dropped)
DROP FUNCTION IF EXISTS public.get_user_email(UUID) CASCADE;

-- ============================================================================
-- HELPER FUNCTION: Get user email (bypasses RLS)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_email(user_uuid UUID)
RETURNS TEXT AS $$
BEGIN
  RETURN (SELECT email FROM auth.users WHERE id = user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- HELPER FUNCTION: Check if user is a moment participant (bypasses RLS)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_moment_participant(moment_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.moment_participants
    WHERE moment_id = moment_uuid
    AND (user_id = user_uuid OR email = public.get_user_email(user_uuid))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- RLS POLICIES FOR MOMENTS
-- ============================================================================

-- Moments: Users can see moments they created or are participants in
-- Use helper function to avoid infinite recursion
CREATE POLICY "moments_select_if_creator_or_participant"
ON public.moments FOR SELECT
USING (
  -- User created the moment
  created_by = public.uid() OR
  -- User is a participant (using helper function that bypasses RLS)
  public.is_moment_participant(id, public.uid()) OR
  -- Moment is in a group the user is a member of
  (group_id IS NOT NULL AND public.is_group_member(group_id, public.uid()))
);

-- Moments: Users can create moments
CREATE POLICY "moments_insert_if_authenticated"
ON public.moments FOR INSERT
WITH CHECK (created_by = public.uid());

-- Moments: Creators can update their moments
CREATE POLICY "moments_update_if_creator"
ON public.moments FOR UPDATE
USING (created_by = public.uid())
WITH CHECK (created_by = public.uid());

-- Moments: Creators can delete their moments
CREATE POLICY "moments_delete_if_creator"
ON public.moments FOR DELETE
USING (created_by = public.uid());

-- ============================================================================
-- RLS POLICIES FOR MOMENT PARTICIPANTS
-- ============================================================================

-- Policies already dropped above (before function drop)

-- Participants: Can see participants of moments they have access to
-- Avoid recursion: Only check direct row access, not through moments policy
CREATE POLICY "moment_participants_select_if_moment_access"
ON public.moment_participants FOR SELECT
USING (
  -- User is a participant themselves (direct row check - no recursion)
  user_id = public.uid() OR 
  email = public.get_user_email(public.uid())
);

-- Participants: Moment creators can add participants
CREATE POLICY "moment_participants_insert_if_creator"
ON public.moment_participants FOR INSERT
WITH CHECK (
  moment_id IN (SELECT id FROM public.moments WHERE created_by = public.uid())
);

-- ============================================================================
-- RLS POLICIES FOR MOMENT CONTRIBUTIONS
-- ============================================================================

-- Policies already dropped above (before function drop)

-- Contributions: Can see contributions of moments they have access to
-- Avoid recursion: Only check moment_participants directly, not moments
CREATE POLICY "moment_contributions_select_if_moment_access"
ON public.moment_contributions FOR SELECT
USING (
  -- User is the contributor (direct check - no recursion)
  participant_id = public.uid()::text OR
  participant_id = public.get_user_email(public.uid()) OR
  -- User is a participant (direct check on moment_participants - no recursion)
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
);

-- Contributions: Participants can add contributions
CREATE POLICY "moment_contributions_insert_if_participant"
ON public.moment_contributions FOR INSERT
WITH CHECK (
  participant_id = public.uid()::text OR
  participant_id = public.get_user_email(public.uid()) OR
  moment_id IN (
    SELECT id FROM public.moments WHERE created_by = public.uid()
  )
);

-- ============================================================================
-- RLS POLICIES FOR MOMENT ACTIVITIES
-- ============================================================================

-- Policies already dropped above (before function drop)

-- Activities: Can see activities of moments they have access to
-- Avoid recursion: Only check direct access, not through moments policy
CREATE POLICY "moment_activities_select_if_moment_access"
ON public.moment_activities FOR SELECT
USING (
  -- User is a participant (direct check on moment_participants - no recursion)
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
);

-- Activities: System can create activities (via service role or triggers)
CREATE POLICY "moment_activities_insert_if_authenticated"
ON public.moment_activities FOR INSERT
WITH CHECK (user_id = public.uid());

-- ============================================================================
-- RLS POLICIES FOR MOMENT WISHLIST ITEMS
-- ============================================================================

-- Policies already dropped above (before function drop)

-- Wishlist items: Can see items of moments they have access to
CREATE POLICY "moment_wishlist_items_select_if_moment_access"
ON public.moment_wishlist_items FOR SELECT
USING (
  -- User is a participant (direct check on moment_participants - no recursion)
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
);

-- Wishlist items: Participants can add items
CREATE POLICY "moment_wishlist_items_insert_if_participant"
ON public.moment_wishlist_items FOR INSERT
WITH CHECK (
  created_by = public.uid() AND
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
);

-- Wishlist items: Participants can update items (mark as purchased, etc.)
CREATE POLICY "moment_wishlist_items_update_if_participant"
ON public.moment_wishlist_items FOR UPDATE
USING (
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
)
WITH CHECK (
  moment_id IN (
    SELECT moment_id FROM public.moment_participants 
    WHERE user_id = public.uid() OR email = public.get_user_email(public.uid())
  )
);

-- Wishlist items: Creator can delete items
CREATE POLICY "moment_wishlist_items_delete_if_creator"
ON public.moment_wishlist_items FOR DELETE
USING (created_by = public.uid());

-- ============================================================================
-- FUNCTION: Update moment current_amount when contribution is added
-- ============================================================================
-- Drop existing trigger first
DROP TRIGGER IF EXISTS trigger_update_moment_amount ON public.moment_contributions;

CREATE OR REPLACE FUNCTION public.update_moment_amount()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.moments
  SET 
    current_amount = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.moment_contributions
      WHERE moment_id = NEW.moment_id
    ),
    updated_at = NOW()
  WHERE id = NEW.moment_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_moment_amount
AFTER INSERT OR UPDATE OR DELETE ON public.moment_contributions
FOR EACH ROW
EXECUTE FUNCTION public.update_moment_amount();

-- ============================================================================
-- FUNCTION: Auto-create activity log when contribution is added
-- ============================================================================
-- Drop existing trigger first
DROP TRIGGER IF EXISTS trigger_log_moment_contribution ON public.moment_contributions;

CREATE OR REPLACE FUNCTION public.log_moment_contribution()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.moment_activities (moment_id, activity_type, user_id, metadata)
  VALUES (
    NEW.moment_id,
    'contribution_added',
    CASE 
      WHEN NEW.participant_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' 
      THEN NEW.participant_id::UUID
      ELSE NULL
    END,
    jsonb_build_object(
      'contribution_id', NEW.id,
      'amount', NEW.amount,
      'participant_id', NEW.participant_id,
      'expense_id', NEW.expense_id
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_log_moment_contribution
AFTER INSERT ON public.moment_contributions
FOR EACH ROW
EXECUTE FUNCTION public.log_moment_contribution();

-- ============================================================================
-- FUNCTION: Auto-create activity log when participant is added
-- ============================================================================
-- Drop existing trigger first
DROP TRIGGER IF EXISTS trigger_log_moment_participant ON public.moment_participants;

CREATE OR REPLACE FUNCTION public.log_moment_participant()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.moment_activities (moment_id, activity_type, user_id, metadata)
  VALUES (
    NEW.moment_id,
    'participant_added',
    NEW.user_id,
    jsonb_build_object(
      'participant_id', NEW.id,
      'email', NEW.email,
      'role', NEW.role
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_log_moment_participant
AFTER INSERT ON public.moment_participants
FOR EACH ROW
EXECUTE FUNCTION public.log_moment_participant();

-- ============================================================================
-- FUNCTION: Update updated_at timestamp for wishlist items
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_wishlist_item_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists (for idempotency)
DROP TRIGGER IF EXISTS trigger_update_wishlist_item_timestamp ON public.moment_wishlist_items;

CREATE TRIGGER trigger_update_wishlist_item_timestamp
BEFORE UPDATE ON public.moment_wishlist_items
FOR EACH ROW
EXECUTE FUNCTION public.update_wishlist_item_timestamp();

-- ============================================================================
-- UPDATE EXISTING CONSTRAINT (if table already exists)
-- ============================================================================
-- Drop the old constraint if it exists (without 'wishlist')
DO $$
BEGIN
  -- Check if the constraint exists and drop it
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'moments_type_check' 
    AND conrelid = 'public.moments'::regclass
  ) THEN
    ALTER TABLE public.moments DROP CONSTRAINT moments_type_check;
  END IF;
END $$;

-- Add the new constraint with 'wishlist' included
ALTER TABLE public.moments 
ADD CONSTRAINT moments_type_check CHECK (type IN ('trip', 'gift', 'goal', 'wishlist'));


-- Add Trip Budget Planner Tables
-- This allows setting a total budget and distributing it across categories/subcategories

-- Trip Budgets (main budget with total amount)
CREATE TABLE IF NOT EXISTS public.trip_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  description TEXT,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(group_id) -- One trip budget per group
);

-- Trip Budget Allocations (how the total is distributed)
CREATE TABLE IF NOT EXISTS public.trip_budget_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_budget_id UUID NOT NULL REFERENCES public.trip_budgets(id) ON DELETE CASCADE,
  category TEXT, -- e.g., "Transportation", "Accommodation"
  subcategory TEXT, -- e.g., "Flights", "Hotels", "Local Transport"
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trip_budgets_group ON public.trip_budgets(group_id);
CREATE INDEX IF NOT EXISTS idx_trip_budget_allocations_budget ON public.trip_budget_allocations(trip_budget_id);
CREATE INDEX IF NOT EXISTS idx_trip_budget_allocations_category ON public.trip_budget_allocations(category, subcategory);

-- Enable RLS
ALTER TABLE public.trip_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_budget_allocations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for trip_budgets
CREATE POLICY "trip_budgets_select_if_member"
ON public.trip_budgets FOR SELECT
USING (public.is_group_member(group_id, public.uid()));

CREATE POLICY "trip_budgets_insert_if_admin"
ON public.trip_budgets FOR INSERT
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

CREATE POLICY "trip_budgets_update_if_admin"
ON public.trip_budgets FOR UPDATE
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
)
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

CREATE POLICY "trip_budgets_delete_if_admin"
ON public.trip_budgets FOR DELETE
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

-- RLS Policies for trip_budget_allocations
CREATE POLICY "trip_budget_allocations_select_if_member"
ON public.trip_budget_allocations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.trip_budgets tb
    WHERE tb.id = trip_budget_id
    AND public.is_group_member(tb.group_id, public.uid())
  )
);

CREATE POLICY "trip_budget_allocations_insert_if_admin"
ON public.trip_budget_allocations FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trip_budgets tb
    WHERE tb.id = trip_budget_id
    AND public.is_group_member(tb.group_id, public.uid())
    AND (
      EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = tb.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
      )
      OR EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = tb.group_id AND g.created_by = public.uid()
      )
    )
  )
);

CREATE POLICY "trip_budget_allocations_update_if_admin"
ON public.trip_budget_allocations FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.trip_budgets tb
    WHERE tb.id = trip_budget_id
    AND public.is_group_member(tb.group_id, public.uid())
    AND (
      EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = tb.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
      )
      OR EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = tb.group_id AND g.created_by = public.uid()
      )
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.trip_budgets tb
    WHERE tb.id = trip_budget_id
    AND public.is_group_member(tb.group_id, public.uid())
    AND (
      EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = tb.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
      )
      OR EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = tb.group_id AND g.created_by = public.uid()
      )
    )
  )
);

CREATE POLICY "trip_budget_allocations_delete_if_admin"
ON public.trip_budget_allocations FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.trip_budgets tb
    WHERE tb.id = trip_budget_id
    AND public.is_group_member(tb.group_id, public.uid())
    AND (
      EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = tb.group_id AND gm.user_id = public.uid() AND gm.role = 'admin'
      )
      OR EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = tb.group_id AND g.created_by = public.uid()
      )
    )
  )
);

-- Grant permissions
GRANT ALL ON public.trip_budgets TO authenticated;
GRANT ALL ON public.trip_budget_allocations TO authenticated;


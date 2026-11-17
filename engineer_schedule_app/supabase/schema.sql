-- ============================================================================
-- Engineer Schedule App – Supabase Database Schema & Row Level Security (RLS)
-- ============================================================================

-- ─── Private Schema for Security-Definer Helpers ────────────────────────────
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

-- ─── Profiles Table ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID        PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email      TEXT,
  full_name  TEXT,
  role       TEXT        NOT NULL DEFAULT 'user'
                         CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profiles linked 1-to-1 with auth.users.';

-- ─── Schedules Table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.schedules (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  engineer_name TEXT        NOT NULL,
  schedule_date DATE        NOT NULL,
  site_name     TEXT        NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.schedules IS 'Work schedule entries for engineers.';

-- ─── Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_schedules_user_id
  ON public.schedules (user_id);

CREATE INDEX IF NOT EXISTS idx_schedules_schedule_date
  ON public.schedules (schedule_date);

-- ─── Auto-Create Profile on Sign-Up ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION private.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    'user'
  );
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.handle_new_user() FROM PUBLIC;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_new_user();

-- ─── RLS Helper Functions (non-exposed private schema) ──────────────────────
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid()) AND role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated;

CREATE OR REPLACE FUNCTION private.get_my_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role
  FROM public.profiles
  WHERE id = (SELECT auth.uid());
$$;

REVOKE ALL ON FUNCTION private.get_my_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.get_my_role() TO authenticated;

-- ─── Table Privileges & Row Level Security ──────────────────────────────────
REVOKE ALL ON public.profiles  FROM anon;
REVOKE ALL ON public.schedules FROM anon;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.schedules TO authenticated;

ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies so script is idempotent on re-run.
DROP POLICY IF EXISTS profiles_select_own    ON public.profiles;
DROP POLICY IF EXISTS profiles_select_admin  ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own    ON public.profiles;
DROP POLICY IF EXISTS profiles_update_admin  ON public.profiles;
DROP POLICY IF EXISTS profiles_select_policy ON public.profiles;
DROP POLICY IF EXISTS profiles_update_policy ON public.profiles;

DROP POLICY IF EXISTS schedules_select_own    ON public.schedules;
DROP POLICY IF EXISTS schedules_select_admin  ON public.schedules;
DROP POLICY IF EXISTS schedules_insert_admin  ON public.schedules;
DROP POLICY IF EXISTS schedules_update_admin  ON public.schedules;
DROP POLICY IF EXISTS schedules_delete_admin  ON public.schedules;
DROP POLICY IF EXISTS schedules_select_policy ON public.schedules;
DROP POLICY IF EXISTS schedules_insert_policy ON public.schedules;
DROP POLICY IF EXISTS schedules_update_policy ON public.schedules;
DROP POLICY IF EXISTS schedules_delete_policy ON public.schedules;

-- ── Profiles Policies ───────────────────────────────────────────────────────

-- Users can read their own profile; admins can read all profiles.
CREATE POLICY profiles_select_policy ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = id
    OR (SELECT private.is_admin())
  );

-- Users can update their own profile (without changing role); admins can update any.
CREATE POLICY profiles_update_policy ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) = id
    OR (SELECT private.is_admin())
  )
  WITH CHECK (
    (SELECT private.is_admin())
    OR (
      (SELECT auth.uid()) = id
      AND role = (SELECT private.get_my_role())
    )
  );

-- ── Schedules Policies ──────────────────────────────────────────────────────
-- Standard users have READ-ONLY access to their own schedules.
-- Only admins can insert, update, or delete schedules.

CREATE POLICY schedules_select_policy ON public.schedules
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    OR (SELECT private.is_admin())
  );

CREATE POLICY schedules_insert_policy ON public.schedules
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT private.is_admin()));

CREATE POLICY schedules_update_policy ON public.schedules
  FOR UPDATE
  TO authenticated
  USING ((SELECT private.is_admin()))
  WITH CHECK ((SELECT private.is_admin()));

CREATE POLICY schedules_delete_policy ON public.schedules
  FOR DELETE
  TO authenticated
  USING ((SELECT private.is_admin()));

-- ============================================================
-- GURU DARSHAN Event & Media App — Supabase Database Schema
-- ============================================================
-- Run this entire file in your Supabase SQL Editor.
-- It creates all tables, RLS policies, triggers, and indexes.
-- ============================================================

-- ============================================================
-- 1. HELPER FUNCTIONS
-- ============================================================

-- Role-checking function (SECURITY DEFINER for performance)
CREATE OR REPLACE FUNCTION public.has_role(role_name text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
    AND role = role_name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'user',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. TABLES
-- ============================================================

-- Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Home Banners
CREATE TABLE IF NOT EXISTS public.home_banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL DEFAULT '',
  subtitle TEXT DEFAULT '',
  image_url TEXT NOT NULL,
  action_url TEXT DEFAULT '',
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Events
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  event_date DATE NOT NULL,
  banner_url TEXT DEFAULT '',
  thumbnail_url TEXT DEFAULT '',
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Event Photos
CREATE TABLE IF NOT EXISTS public.event_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  caption TEXT DEFAULT '',
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Event Videos
CREATE TABLE IF NOT EXISTS public.event_videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  description TEXT DEFAULT '',
  video_url TEXT NOT NULL,
  video_type TEXT NOT NULL DEFAULT 'youtube' CHECK (video_type IN ('youtube', 'youtube_unlisted', 'public_video')),
  thumbnail_url TEXT DEFAULT '',
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notification Reads
CREATE TABLE IF NOT EXISTS public.notification_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  UNIQUE(notification_id, user_id)
);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_home_banners_active ON public.home_banners(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_events_active ON public.events(is_active, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_events_featured ON public.events(is_featured, is_active);
CREATE INDEX IF NOT EXISTS idx_event_photos_event ON public.event_photos(event_id, display_order);
CREATE INDEX IF NOT EXISTS idx_event_videos_event ON public.event_videos(event_id, display_order);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notification_reads_user ON public.notification_reads(user_id, notification_id);

-- ============================================================
-- 4. TRIGGERS
-- ============================================================

-- Auto-create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_banners_updated_at
  BEFORE UPDATE ON public.home_banners
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.home_banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------
-- PROFILES POLICIES
-- --------------------------------------------------------

-- Users can read their own profile
CREATE POLICY "users_read_own_profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Admin can read all profiles
CREATE POLICY "admin_read_all_profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING ((SELECT has_role('admin')));

-- Users can update their own profile (but NOT role)
CREATE POLICY "users_update_own_profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid() AND role = 'user');

-- Admin can update any profile
CREATE POLICY "admin_update_profiles"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ((SELECT has_role('admin')))
  WITH CHECK ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- HOME BANNERS POLICIES
-- --------------------------------------------------------

-- All users (including unregistered visitors) can read active banners
CREATE POLICY "users_read_active_banners"
  ON public.home_banners FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Admin can read all banners (including inactive)
CREATE POLICY "admin_read_all_banners"
  ON public.home_banners FOR SELECT
  TO authenticated
  USING ((SELECT has_role('admin')));

-- Admin full CRUD on banners
CREATE POLICY "admin_insert_banners"
  ON public.home_banners FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_update_banners"
  ON public.home_banners FOR UPDATE
  TO authenticated
  USING ((SELECT has_role('admin')))
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_delete_banners"
  ON public.home_banners FOR DELETE
  TO authenticated
  USING ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- EVENTS POLICIES
-- --------------------------------------------------------

-- All users (including unregistered visitors) can read active events
CREATE POLICY "users_read_active_events"
  ON public.events FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

-- Admin can read all events
CREATE POLICY "admin_read_all_events"
  ON public.events FOR SELECT
  TO authenticated
  USING ((SELECT has_role('admin')));

-- Admin full CRUD on events
CREATE POLICY "admin_insert_events"
  ON public.events FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_update_events"
  ON public.events FOR UPDATE
  TO authenticated
  USING ((SELECT has_role('admin')))
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_delete_events"
  ON public.events FOR DELETE
  TO authenticated
  USING ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- EVENT PHOTOS POLICIES
-- --------------------------------------------------------

-- All users can read all photos
CREATE POLICY "users_read_photos"
  ON public.event_photos FOR SELECT
  TO anon, authenticated
  USING (true);

-- Admin full CRUD on photos
CREATE POLICY "admin_insert_photos"
  ON public.event_photos FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_update_photos"
  ON public.event_photos FOR UPDATE
  TO authenticated
  USING ((SELECT has_role('admin')))
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_delete_photos"
  ON public.event_photos FOR DELETE
  TO authenticated
  USING ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- EVENT VIDEOS POLICIES
-- --------------------------------------------------------

-- All users can read all videos
CREATE POLICY "users_read_videos"
  ON public.event_videos FOR SELECT
  TO anon, authenticated
  USING (true);

-- Admin full CRUD on videos
CREATE POLICY "admin_insert_videos"
  ON public.event_videos FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_update_videos"
  ON public.event_videos FOR UPDATE
  TO authenticated
  USING ((SELECT has_role('admin')))
  WITH CHECK ((SELECT has_role('admin')));

CREATE POLICY "admin_delete_videos"
  ON public.event_videos FOR DELETE
  TO authenticated
  USING ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- NOTIFICATIONS POLICIES
-- --------------------------------------------------------

-- All users can read notifications
CREATE POLICY "users_read_notifications"
  ON public.notifications FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only admin can create notifications
CREATE POLICY "admin_insert_notifications"
  ON public.notifications FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT has_role('admin')));

-- Admin can delete notifications
CREATE POLICY "admin_delete_notifications"
  ON public.notifications FOR DELETE
  TO authenticated
  USING ((SELECT has_role('admin')));

-- --------------------------------------------------------
-- NOTIFICATION READS POLICIES
-- --------------------------------------------------------

-- Users can read their own notification read status
CREATE POLICY "users_read_own_notification_reads"
  ON public.notification_reads FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can insert their own read status
CREATE POLICY "users_insert_own_notification_reads"
  ON public.notification_reads FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can update their own read status
CREATE POLICY "users_update_own_notification_reads"
  ON public.notification_reads FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admin can read all notification reads
CREATE POLICY "admin_read_notification_reads"
  ON public.notification_reads FOR SELECT
  TO authenticated
  USING ((SELECT has_role('admin')));

-- ============================================================
-- 6. ADMIN ACCOUNT SETUP
-- ============================================================
-- After signing up your admin account, run this:
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'your-admin@email.com';
-- ============================================================

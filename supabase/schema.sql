-- HabitTracker Supabase Schema
-- Run this in your Supabase SQL Editor
-- Privacy: NO habit names are ever stored. Only anonymized daily aggregate counts.

-- ============================================================
-- 1. PROFILES
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Habit Tracker',
    friend_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can look up profiles (needed for friend code lookup)
CREATE POLICY "profiles_select" ON profiles
    FOR SELECT USING (true);

-- Users can only insert their own profile
CREATE POLICY "profiles_insert" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "profiles_update" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE INDEX IF NOT EXISTS idx_profiles_friend_code ON profiles(friend_code);

-- ============================================================
-- 2. FRIEND CONNECTIONS (bidirectional, canonical ordering)
-- ============================================================

CREATE TABLE IF NOT EXISTS friend_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_a UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_id_b UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id_a, user_id_b),
    CHECK (user_id_a < user_id_b)  -- enforce canonical ordering: smaller UUID first
);

ALTER TABLE friend_connections ENABLE ROW LEVEL SECURITY;

-- Users can see their own connections
CREATE POLICY "friends_select" ON friend_connections
    FOR SELECT USING (
        auth.uid() = user_id_a OR auth.uid() = user_id_b
    );

-- Users can create connections they are part of
CREATE POLICY "friends_insert" ON friend_connections
    FOR INSERT WITH CHECK (
        auth.uid() = user_id_a OR auth.uid() = user_id_b
    );

-- Users can delete connections they are part of
CREATE POLICY "friends_delete" ON friend_connections
    FOR DELETE USING (
        auth.uid() = user_id_a OR auth.uid() = user_id_b
    );

CREATE INDEX IF NOT EXISTS idx_friend_connections_a ON friend_connections(user_id_a);
CREATE INDEX IF NOT EXISTS idx_friend_connections_b ON friend_connections(user_id_b);

-- ============================================================
-- 3. DAILY STATS (anonymized — NO habit names, only counts)
-- ============================================================

CREATE TABLE IF NOT EXISTS daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    completed_count INT NOT NULL DEFAULT 0,
    scheduled_count INT NOT NULL DEFAULT 0,
    completion_rate REAL NOT NULL DEFAULT 0,
    active_streak INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;

-- Users can insert their own stats
CREATE POLICY "daily_stats_insert" ON daily_stats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own stats
CREATE POLICY "daily_stats_update" ON daily_stats
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can read their own stats OR stats of connected friends
CREATE POLICY "daily_stats_select" ON daily_stats
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM friend_connections
            WHERE (user_id_a = auth.uid() AND user_id_b = daily_stats.user_id)
               OR (user_id_b = auth.uid() AND user_id_a = daily_stats.user_id)
        )
    );

CREATE INDEX IF NOT EXISTS idx_daily_stats_user_date ON daily_stats(user_id, date);

-- ============================================================
-- 4. HABITS (Automatic Cloud Storage for Habits)
-- ============================================================

CREATE TABLE IF NOT EXISTS habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'build',
    schedule_days TEXT NOT NULL DEFAULT '0,1,2,3,4,5,6',
    sort_order INT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habits_select" ON habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "habits_insert" ON habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "habits_update" ON habits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "habits_delete" ON habits
    FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);

-- ============================================================
-- 5. HABIT LOGS (Automatic Cloud Storage for Habit Completions)
-- ============================================================

CREATE TABLE IF NOT EXISTS habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT TRUE,
    is_slip BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(habit_id, date)
);

ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habit_logs_select" ON habit_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "habit_logs_insert" ON habit_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "habit_logs_update" ON habit_logs
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "habit_logs_delete" ON habit_logs
    FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_habit_logs_user_date ON habit_logs(user_id, date);

-- ============================================================
-- ENABLE ANONYMOUS AUTH
-- ============================================================
-- NOTE: You must also enable "Anonymous Sign-ins" in the
-- Supabase Dashboard → Authentication → Providers → Anonymous.

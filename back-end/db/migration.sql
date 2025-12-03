-- Migration Script: Apply New Database Schema
-- Run this after stopping the application and backing up data

-- Connect to your PostgreSQL database first
-- psql -h localhost -p 5432 -U timebeam -d timebeam -f back-end/db/migration.sql

-- Enable extensions (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PHASE 1: Add New Tables (Safe - no data conflicts)
-- ============================================================================

-- Enhanced users table (add missing columns)
ALTER TABLE users ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) DEFAULT 'UTC';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    work_duration_minutes INTEGER DEFAULT 25 CHECK (work_duration_minutes > 0),
    short_break_minutes INTEGER DEFAULT 5 CHECK (short_break_minutes > 0),
    long_break_minutes INTEGER DEFAULT 15 CHECK (long_break_minutes > 0),
    sessions_before_long_break INTEGER DEFAULT 4 CHECK (sessions_before_long_break > 0),
    auto_start_breaks BOOLEAN DEFAULT true,
    auto_start_work BOOLEAN DEFAULT false,
    daily_goal_minutes INTEGER DEFAULT 120 CHECK (daily_goal_minutes > 0),
    theme VARCHAR(20) DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
    sound_enabled BOOLEAN DEFAULT true,
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create user_devices table
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    device_type VARCHAR(20) CHECK (device_type IN ('ios', 'macos', 'watchos')),
    platform_version VARCHAR(50),
    app_version VARCHAR(20),
    fcm_token TEXT,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, device_id)
);

-- Create timer_states table
CREATE TABLE IF NOT EXISTS timer_states (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    phase VARCHAR(20) NOT NULL CHECK (phase IN ('work', 'short_break', 'long_break')),
    remaining_seconds INTEGER NOT NULL CHECK (remaining_seconds >= 0),
    is_running BOOLEAN NOT NULL DEFAULT false,
    work_duration_minutes INTEGER NOT NULL,
    break_duration_minutes INTEGER NOT NULL,
    long_break_duration_minutes INTEGER NOT NULL,
    auto_start_next BOOLEAN NOT NULL DEFAULT false,
    short_breaks_completed INTEGER NOT NULL DEFAULT 0,
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by_device_id UUID REFERENCES user_devices(id),
    version BIGINT NOT NULL DEFAULT 1
);

-- Enhance session_records table
ALTER TABLE session_records ADD COLUMN IF NOT EXISTS device_id UUID REFERENCES user_devices(id);
ALTER TABLE session_records ADD COLUMN IF NOT EXISTS was_completed BOOLEAN DEFAULT true;
ALTER TABLE session_records ADD COLUMN IF NOT EXISTS was_interrupted BOOLEAN DEFAULT false;
ALTER TABLE session_records ADD COLUMN IF NOT EXISTS interruption_reason VARCHAR(100);
ALTER TABLE session_records ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Create daily_analytics table
CREATE TABLE IF NOT EXISTS daily_analytics (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_work_minutes INTEGER NOT NULL DEFAULT 0,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    productive_streak_days INTEGER,
    longest_streak_days INTEGER,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, date)
);

-- Create user_streaks table
CREATE TABLE IF NOT EXISTS user_streaks (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_productive_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create productive_windows table
CREATE TABLE IF NOT EXISTS productive_windows (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    window_start_hour INTEGER NOT NULL CHECK (window_start_hour >= 0 AND window_start_hour <= 23),
    window_end_hour INTEGER NOT NULL CHECK (window_end_hour >= 0 AND window_end_hour <= 23),
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_minutes INTEGER NOT NULL DEFAULT 0,
    date_computed DATE NOT NULL,

    PRIMARY KEY (user_id, window_start_hour, window_end_hour, date_computed)
);

-- Create push_subscriptions table
CREATE TABLE IF NOT EXISTS push_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES user_devices(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('ios', 'macos', 'web')),
    is_active BOOLEAN DEFAULT true,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, device_id)
);

-- Create notifications_sent table
CREATE TABLE IF NOT EXISTS notifications_sent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES user_devices(id),
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    body TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================================
-- PHASE 2: Create Indexes (Performance Optimization)
-- ============================================================================

-- Essential indexes for timer sync
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_timer_states_updated ON timer_states(last_updated_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_devices_user_active ON user_devices(user_id, is_active, last_seen_at DESC);

-- Analytics query optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_started ON session_records(user_id, started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_kind_started ON session_records(user_id, kind, started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_started_at ON session_records(started_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_date ON session_records(user_id, DATE(started_at));

-- Daily analytics optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_analytics_user_date ON daily_analytics(user_id, date DESC);

-- Notification optimization
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_sent ON notifications_sent(user_id, sent_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_push_subscriptions_user_active ON push_subscriptions(user_id, is_active);

-- ============================================================================
-- PHASE 3: Create Triggers (Automatic Updates)
-- ============================================================================

-- Update timestamps automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PHASE 4: Create Views (Simplified Access)
-- ============================================================================

-- User with preferences view
CREATE OR REPLACE VIEW user_with_preferences AS
SELECT
    u.id, u.email, u.display_name, u.timezone, u.is_admin, u.created_at, u.updated_at,
    p.work_duration_minutes, p.short_break_minutes, p.long_break_minutes,
    p.sessions_before_long_break, p.auto_start_breaks, p.auto_start_work,
    p.daily_goal_minutes, p.theme, p.sound_enabled, p.notifications_enabled
FROM users u
LEFT JOIN user_preferences p ON u.id = p.user_id;

-- Active devices view
CREATE OR REPLACE VIEW active_user_devices AS
SELECT * FROM user_devices WHERE is_active = true;

-- ============================================================================
-- PHASE 5: Migrate Existing Data (if any)
-- ============================================================================

-- Create default preferences for existing users
INSERT INTO user_preferences (user_id)
SELECT id FROM users
WHERE id NOT IN (SELECT user_id FROM user_preferences)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- PHASE 6: Validation Queries
-- ============================================================================

-- Check table creation
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN (
        'users', 'user_preferences', 'user_devices', 'timer_states',
        'session_records', 'daily_analytics', 'user_streaks',
        'productive_windows', 'push_subscriptions', 'notifications_sent'
    )
ORDER BY tablename;

-- Check indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename IN (
        'timer_states', 'user_devices', 'session_records',
        'daily_analytics', 'push_subscriptions', 'notifications_sent'
    )
ORDER BY tablename, indexname;

-- ============================================================================
-- PHASE 7: Grant Permissions (Production)
-- ============================================================================

-- Example grants (customize for your environment)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO timebeam_app;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO timebeam_app;

-- ============================================================================
-- PHASE 8: Post-Migration Steps
-- ============================================================================

-- After running this migration:

-- 1. Restart the backend application
-- 2. The TimerSyncService will now use the database instead of in-memory storage
-- 3. Test timer sync between devices
-- 4. Monitor performance and adjust indexes if needed

-- ============================================================================
-- ROLLBACK (If needed - drop new tables in reverse order)
-- ============================================================================

-- WARNING: This will delete all data in new tables!
-- Only run if you need to rollback the migration

/*
DROP VIEW IF EXISTS active_user_devices;
DROP VIEW IF EXISTS user_with_preferences;

DROP TABLE IF EXISTS notifications_sent;
DROP TABLE IF EXISTS push_subscriptions;
DROP TABLE IF EXISTS productive_windows;
DROP TABLE IF EXISTS user_streaks;
DROP TABLE IF EXISTS daily_analytics;

-- Note: timer_states, user_devices, user_preferences tables contain new data
-- Decide whether to keep or drop based on your needs

-- Remove added columns from existing tables
ALTER TABLE session_records DROP COLUMN IF EXISTS device_id;
ALTER TABLE session_records DROP COLUMN IF EXISTS was_completed;
ALTER TABLE session_records DROP COLUMN IF EXISTS was_interrupted;
ALTER TABLE session_records DROP COLUMN IF EXISTS interruption_reason;
ALTER TABLE session_records DROP COLUMN IF EXISTS created_at;

ALTER TABLE users DROP COLUMN IF EXISTS timezone;
ALTER TABLE users DROP COLUMN IF EXISTS created_at;
ALTER TABLE users DROP COLUMN IF EXISTS updated_at;
*/

-- End of migration script

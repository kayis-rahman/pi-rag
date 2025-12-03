-- TimeBeam Database Schema - Complete Redesign
-- Optimized for performance, scalability, and multi-device sync

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CORE USER MANAGEMENT
-- ============================================================================

-- Enhanced users table with timezone and metadata
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    timezone VARCHAR(50) DEFAULT 'UTC',
    is_admin BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User preferences (separate table for flexibility)
CREATE TABLE user_preferences (
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

-- ============================================================================
-- DEVICE MANAGEMENT (Critical for Sync)
-- ============================================================================

-- Track all user devices for sync
CREATE TABLE user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL, -- Unique device identifier
    device_name VARCHAR(255), -- User-friendly name
    device_type VARCHAR(20) CHECK (device_type IN ('ios', 'macos', 'watchos')),
    platform_version VARCHAR(50),
    app_version VARCHAR(20),
    fcm_token TEXT, -- For push notifications
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, device_id)
);

-- ============================================================================
-- TIMER STATE MANAGEMENT (Replaces In-Memory Storage)
-- ============================================================================

-- Persistent timer states (replaces in-memory storage)
CREATE TABLE timer_states (
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
    version BIGINT NOT NULL DEFAULT 1 -- For optimistic locking
);

-- ============================================================================
-- SESSION RECORDS (Enhanced for Analytics)
-- ============================================================================

-- Partitioned session records for performance
CREATE TABLE session_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES user_devices(id),
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('work', 'short_break', 'long_break')),
    was_completed BOOLEAN DEFAULT true,
    was_interrupted BOOLEAN DEFAULT false,
    interruption_reason VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (started_at);

-- Create initial partitions (can be automated for production)
CREATE TABLE session_records_2025_01 PARTITION OF session_records
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE session_records_2025_02 PARTITION OF session_records
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE session_records_2025_03 PARTITION OF session_records
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
-- Add more partitions as needed

-- ============================================================================
-- ANALYTICS OPTIMIZATION
-- ============================================================================

-- Pre-computed daily analytics for performance
CREATE TABLE daily_analytics (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_work_minutes INTEGER NOT NULL DEFAULT 0,
    total_sessions INTEGER NOT NULL DEFAULT 0,
    productive_streak_days INTEGER,
    longest_streak_days INTEGER,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, date)
) PARTITION BY RANGE (date);

-- User streaks tracking
CREATE TABLE user_streaks (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_productive_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Productive time windows
CREATE TABLE productive_windows (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    window_start_hour INTEGER NOT NULL CHECK (window_start_hour >= 0 AND window_start_hour <= 23),
    window_end_hour INTEGER NOT NULL CHECK (window_end_hour >= 0 AND window_end_hour <= 23),
    total_sessions INTEGER NOT NULL DEFAULT 0,
    total_minutes INTEGER NOT NULL DEFAULT 0,
    date_computed DATE NOT NULL,

    PRIMARY KEY (user_id, window_start_hour, window_end_hour, date_computed)
);

-- ============================================================================
-- NOTIFICATIONS & COMMUNICATION
-- ============================================================================

-- Push notification tokens and preferences
CREATE TABLE push_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES user_devices(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) CHECK (platform IN ('ios', 'macos', 'web')),
    is_active BOOLEAN DEFAULT true,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, device_id)
);

-- Notification history (optional - can be archived)
CREATE TABLE notifications_sent (
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
-- LEGACY TABLES (Keep for Migration)
-- ============================================================================

-- Keep refresh tokens for backward compatibility
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES (Performance Optimization)
-- ============================================================================

-- Essential indexes for timer sync
CREATE INDEX CONCURRENTLY idx_timer_states_updated ON timer_states(last_updated_at);
CREATE INDEX CONCURRENTLY idx_user_devices_user_active ON user_devices(user_id, is_active, last_seen_at DESC);

-- Analytics query optimization
CREATE INDEX CONCURRENTLY idx_session_records_user_started ON session_records(user_id, started_at DESC);
CREATE INDEX CONCURRENTLY idx_session_records_user_kind_started ON session_records(user_id, kind, started_at DESC);
CREATE INDEX CONCURRENTLY idx_session_records_started_at ON session_records(started_at);
CREATE INDEX CONCURRENTLY idx_session_records_user_date ON session_records(user_id, DATE(started_at));

-- Daily analytics optimization
CREATE INDEX CONCURRENTLY idx_daily_analytics_user_date ON daily_analytics(user_id, date DESC);

-- Notification optimization
CREATE INDEX CONCURRENTLY idx_notifications_user_sent ON notifications_sent(user_id, sent_at DESC);
CREATE INDEX CONCURRENTLY idx_push_subscriptions_user_active ON push_subscriptions(user_id, is_active);

-- Refresh token optimization
CREATE INDEX CONCURRENTLY idx_refresh_tokens_user_expires ON refresh_tokens(user_id, expires_at);

-- ============================================================================
-- TRIGGERS (Automatic Updates)
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
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update user_streaks automatically
CREATE OR REPLACE FUNCTION update_user_streaks()
RETURNS TRIGGER AS $$
BEGIN
    -- This would be implemented with a more complex function
    -- For now, just update the timestamp
    UPDATE user_streaks SET updated_at = CURRENT_TIMESTAMP WHERE user_id = NEW.user_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- VIEWS (Simplified Access)
-- ============================================================================

-- User with preferences view
CREATE VIEW user_with_preferences AS
SELECT
    u.id, u.email, u.display_name, u.timezone, u.is_admin, u.created_at, u.updated_at,
    p.work_duration_minutes, p.short_break_minutes, p.long_break_minutes,
    p.sessions_before_long_break, p.auto_start_breaks, p.auto_start_work,
    p.daily_goal_minutes, p.theme, p.sound_enabled, p.notifications_enabled
FROM users u
LEFT JOIN user_preferences p ON u.id = p.user_id;

-- Active devices view
CREATE VIEW active_user_devices AS
SELECT * FROM user_devices WHERE is_active = true;

-- ============================================================================
-- INITIAL DATA (Optional)
-- ============================================================================

-- Insert default admin user (change credentials in production)
-- INSERT INTO users (email, display_name, is_admin) VALUES ('admin@timebeam.com', 'Admin User', true);

-- Note: Password hashing would be handled by the application layer
-- Default preferences will be created when users register

-- ============================================================================
-- PARTITION MANAGEMENT (For Production)
-- ============================================================================

-- Function to create monthly partitions automatically
CREATE OR REPLACE FUNCTION create_session_partition(target_month DATE)
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    start_date := date_trunc('month', target_month);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'session_records_' || to_char(start_date, 'YYYY_MM');

    -- Check if partition already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relname = partition_name AND n.nspname = current_schema()
    ) THEN
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF session_records FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CLEANUP & MAINTENANCE
-- ============================================================================

-- Function to clean up old data (customize retention policy)
CREATE OR REPLACE FUNCTION cleanup_old_data(retention_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    -- Delete old notifications (keep last 90 days)
    DELETE FROM notifications_sent
    WHERE sent_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    -- Archive old sessions if needed (customize based on requirements)
    -- This would move data to archive tables

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE users IS 'Core user accounts with timezone support';
COMMENT ON TABLE user_preferences IS 'User-specific Pomodoro timer preferences and settings';
COMMENT ON TABLE user_devices IS 'Registered devices for cross-device synchronization';
COMMENT ON TABLE timer_states IS 'Persistent timer state storage (replaces in-memory)';
COMMENT ON TABLE session_records IS 'Historical Pomodoro sessions with device tracking';
COMMENT ON TABLE daily_analytics IS 'Pre-computed daily analytics for performance';
COMMENT ON TABLE user_streaks IS 'Current and longest productivity streaks';
COMMENT ON TABLE productive_windows IS 'Most productive time windows analysis';
COMMENT ON TABLE push_subscriptions IS 'Push notification tokens and preferences';
COMMENT ON TABLE notifications_sent IS 'Notification delivery history';

-- ============================================================================
-- GRANTS (For Production)
-- ============================================================================

-- Example grants (customize for your environment)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO timebeam_app;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO timebeam_app;

-- End of schema

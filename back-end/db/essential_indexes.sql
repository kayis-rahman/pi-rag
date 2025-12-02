-- Essential Database Indexes for TimeBeam Analytics Performance
-- Run this script to create indexes that will significantly improve query performance

-- Essential indexes for analytics queries
-- These indexes support the optimized queries in AnalyticsService.java

-- Index for user-based queries (most common filter)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_started
ON session_records(user_id, started_at);

-- Index for session type filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_kind
ON session_records(user_id, kind);

-- Index for date range queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_started_at
ON session_records(started_at);

-- Composite index for user + kind + started_at (covers most analytics queries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_kind_started
ON session_records(user_id, kind, started_at);

-- Index for duration-based analytics (if needed for future features)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_session_records_user_duration
ON session_records(user_id, duration_seconds)
WHERE kind = 'WORK';

-- Verify indexes were created
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'session_records'
ORDER BY indexname;

-- V1: Create initial schema tables
-- Uses IF NOT EXISTS for ddl-auto compatibility (V2/V3 add columns on top)

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    display_name VARCHAR(255) NOT NULL,
    admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    started_at TIMESTAMPTZ NOT NULL,
    duration_seconds BIGINT NOT NULL,
    kind VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS timer_states (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    phase VARCHAR(20) NOT NULL DEFAULT 'work',
    remaining_seconds INTEGER NOT NULL DEFAULT 1500,
    is_running BOOLEAN NOT NULL DEFAULT FALSE,
    work_duration INTEGER NOT NULL DEFAULT 1500,
    break_duration INTEGER NOT NULL DEFAULT 300,
    long_break_duration INTEGER NOT NULL DEFAULT 900,
    auto_start_next_session BOOLEAN NOT NULL DEFAULT FALSE,
    short_breaks_completed INTEGER NOT NULL DEFAULT 0,
    start_timestamp TIMESTAMPTZ,
    pause_timestamp TIMESTAMPTZ,
    last_modified_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_devices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    device_id VARCHAR(255) NOT NULL UNIQUE,
    device_name VARCHAR(255),
    device_type VARCHAR(50) NOT NULL,
    platform_version VARCHAR(100),
    app_version VARCHAR(50),
    fcm_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tasks (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'TODO',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at);
CREATE INDEX IF NOT EXISTS idx_timer_states_user_id ON timer_states(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_device_id ON user_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

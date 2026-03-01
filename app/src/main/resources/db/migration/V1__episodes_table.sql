--liquibase formatted sql

--changeset synapse:episodes-table
CREATE TABLE IF NOT EXISTS episodes (
    id VARCHAR(36) PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--rollback DROP TABLE episodes;

--changeset synapse:episodes-index
CREATE INDEX IF NOT EXISTS idx_episodes_session_id ON episodes(session_id);
CREATE INDEX IF NOT EXISTS idx_episodes_timestamp ON episodes(timestamp);
--rollback DROP INDEX idx_episodes_session_id;
--rollback DROP INDEX idx_episodes_timestamp;
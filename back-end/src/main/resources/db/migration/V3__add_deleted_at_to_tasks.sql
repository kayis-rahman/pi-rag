ALTER TABLE tasks ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_tasks_user_deleted ON tasks(user_id, deleted_at);

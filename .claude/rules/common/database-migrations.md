# Common Database Migration Patterns

> Shared database migration patterns for TimeBeam project.

## Migration Tool

- Flyway for schema migrations
- Location: `back-end/src/main/resources/db/migration/`
- Naming: `V{version}__{description}.sql` (e.g., `V1__init_schema.sql`)

## Migration Rules

- NEVER modify existing migrations (always add new ones)
- Always backward compatible (no breaking changes)
- Test migrations on fresh database before applying
- Include rollback script for each migration
- Use transactions for atomic migrations

## Schema Design

- Use `BIGSERIAL` for auto-increment IDs
- Use `TIMESTAMPTZ` for timestamps (with timezone)
- Use `JSONB` for flexible data (with GIN index)
- Add `created_at` and `updated_at` to all tables
- Soft delete: `deleted_at TIMESTAMPTZ` instead of `DELETE`

## Indexing

- Index foreign keys
- Index columns used in WHERE/JOIN clauses
- GIN index for JSONB columns
- Avoid over-indexing (slows writes)

## Data Migration

- Use `DO` blocks for data-only migrations
- Never drop columns with data — deprecate first
- Batch large data migrations (avoid locking)
- Test with production-like data volume

## Common Patterns

```sql
-- Add column (non-breaking)
ALTER TABLE timers ADD COLUMN sync_version INTEGER DEFAULT 0;

-- Add index
CREATE INDEX idx_timers_device_id ON timers(device_id);

-- Soft delete column
ALTER TABLE sessions ADD COLUMN deleted_at TIMESTAMPTZ;

-- GIN index for JSONB
CREATE INDEX idx_timers_metadata ON timers USING GIN (metadata);
```

## Rollback Safety

- Always test `flyway undo` before deploying
- Keep migration history for 10+ versions
- Document breaking changes in migration comments

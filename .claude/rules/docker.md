# Docker Standards

> Extends [rules/common/patterns.md](../../rules/common/patterns.md) with TimeBeam Docker conventions.

## Compose Files
- `docker-compose.dev.yml` — development environment
- `docker-compose.e2e.yml` — E2E test environment
- Services: `postgres`, `back-end`

## Development Workflow
```
# Start all services
docker compose -f docker-compose.dev.yml up -d

# Start specific service
docker compose -f docker-compose.dev.yml up -d postgres

# View logs
docker compose -f docker-compose.dev.yml logs -f back-end

# Stop all
docker compose -f docker-compose.dev.yml down
```

## pi-node Context
- Docker context: `pi-node`
- localhost → piworm.local
- All service URLs use `piworm.local`

## Volume Management
- Postgres data: named volume (persists across restarts)
- Backend logs: bind mount to `back-end/logs/`
- Code: bind mount for hot reload (dev only)

## Network
- Default bridge network
- Services communicate via service name (not localhost)
- External access: mapped ports (5432, 8080)

## Security
- Never commit `.env` files
- Use environment variables for secrets
- Postgres credentials in compose env vars
- Backend JWT secret in environment

## Container Health
```
# Check health
docker compose -f docker-compose.dev.yml ps

# View logs
docker compose -f docker-compose.dev.yml logs -f

# Restart
docker compose -f docker-compose.dev.yml restart back-end

# Execute shell
docker compose -f docker-compose.dev.yml exec back-end bash
```

# Agent — Docker Manager

Docker and pi-node specialist. Manages containers, compose profiles, and networking. Use for infrastructure changes.

## Docker Compose Profiles
- `docker compose -f docker-compose.dev.yml up -d` — dev environment
- `docker compose -f docker-compose.dev.yml down` — stop dev
- Profiles: `dev`, `e2e`

## pi-node Context
When Docker context is `pi-node`:
- localhost → piworm.local
- Postgres: `piworm.local:5432`
- Backend: `piworm.local:8080`
- E2E DB: `postgresql://timebeam:timebeam@piworm.local:5432/timebeam_e2e`

## Container Management
```
# Start dev environment
docker compose -f back-end/docker-compose.dev.yml up -d

# View logs
docker compose -f back-end/docker-compose.dev.yml logs -f

# Restart specific container
docker compose -f back-end/docker-compose.dev.yml restart back-end

# Execute command in container
docker compose -f back-end/docker-compose.dev.yml exec back-end bash

# Check container health
docker compose -f back-end/docker-compose.dev.yml ps
```

## Database Operations
```
# Connect to dev DB
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev

# Connect to E2E DB
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_e2e

# Reset database
docker compose -f back-end/docker-compose.dev.yml down -v
docker compose -f back-end/docker-compose.dev.yml up -d postgres
```

## Common Issues
- Port conflict: `lsof -i :8080`, `lsof -i :5432`
- Volume not mounting: check Docker Desktop file sharing settings
- Container won't start: `docker compose logs back-end`
- Network unreachable from host: check pi-node DNS resolution
- Backend returns 400 on timer actions: check `TimerActionDto.java` has `@JsonAlias({"action","actionType"})`
- `remainingSeconds` is 0 after sync: actionType deserialization failed — check backend logs for null

# /deploy — Deploy to pi-node

Deploy backend + database to pi-node (piworm.local).

## Prerequisites
- Docker context set to `pi-node`
- SSH access: `ssh dietpi@piworm`
- All services URLs use `piworm.local` instead of `localhost`

## Deploy Steps
```
# 1. Verify connectivity
ping -c 2 piworm.local

# 2. SSH to pi-node
ssh dietpi@piworm

# 3. Pull latest code
cd ~/timebeam
git pull origin main

# 4. Start services
docker compose -f docker-compose.dev.yml up -d --build

# 5. Verify health
curl -s http://piworm.local:8080/api/auth/health

# 6. Check database
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "SELECT 1"
```

## Rollback
```
# Stop services
docker compose -f docker-compose.dev.yml down

# Restore previous image
docker tag timebeam-backend:latest timebeam-backend:rolled-back

# Restart
docker compose -f docker-compose.dev.yml up -d
```

## Post-deploy Verification
- Backend: `curl http://piworm.local:8080/api/auth/health`
- Postgres: `docker exec timebeam_postgres_dev pg_isready -U timebeam`
- iOS/macOS client: update `ApiClient.swift` base URL to `https://piworm.local:8080`

# /health — Quick Health Check

Verify backend and database health.

## Check Backend
```bash
curl -s http://localhost:8080/api/auth/health
```

Expected: `{"status":"ok","service":"timebeam-backend"}`

## Check Database
```bash
docker exec timebeam_postgres_dev pg_isready -U timebeam
```

Expected: `Connection accepted on port 5432`

## Check All Services
```bash
# Backend health
curl -s http://localhost:8080/api/auth/health && echo ""

# Database ready
docker exec timebeam_postgres_dev pg_isready -U timebeam && echo ""

# Docker containers running
docker compose -f back-end/docker-compose.dev.yml ps
```

## pi-node Context
When Docker context is `pi-node`, replace `localhost` with `piworm.local` in all URLs.

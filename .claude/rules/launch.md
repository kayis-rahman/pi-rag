# Launch Rules

> Quick commands for starting backend and macOS app. Copy-paste ready.

## Prerequisites
- Docker context is `pi-node` — postgres is at `piworm.local:5432`
- Ensure `docker compose -f back-end/docker-compose.dev.yml up -d` is running

## Start Backend
```bash
cd back-end && lsof -ti:8080 | xargs kill -9 2>/dev/null
nohup mvn spring-boot:run -Dspring-boot.run.profiles=piworm > /tmp/backend.log 2>&1 &
sleep 20 && tail -30 /tmp/backend.log
```

**Key points:**
- Use `piworm` profile, NOT `dev` — `dev` uses `localhost:5432` which fails on `pi-node` context
- Kill port 8080 first — stale processes block startup
- Run from `back-end/` directory explicitly (not project root)
- Use `nohup` + log file — background tasks don't capture maven output
- Health check: `curl http://localhost:8080/api/auth/health`

## Launch macOS App
```bash
cd apple/TimeBeam && xcodebuild -scheme "TimeBeam" -destination 'platform=macOS' run 2>&1 | tail -5
```

**Key points:**
- Scheme is "TimeBeam" (NOT "TimeBeam macOS") — verified via `xcodebuild -list`
- Scheme "TimeBeam iOS" is for iOS simulator
- Scheme "TimeBeamWatch Watch App" is for watch

## New Config Profile
- `application-piworm.yml` — uses `jdbc:postgresql://piworm.local:5432/timebeam_e2e`
- Activated with `-Dspring-boot.run.profiles=piworm`

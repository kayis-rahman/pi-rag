# /ship — Build, test, verify

Build iOS/macOS app, run backend tests, verify health check.

## Steps
1. `cd back-end && mvn test`
2. `cd back-end && docker compose -f docker-compose.dev.yml up -d`
3. `curl http://localhost:8080/api/auth/health`
4. `xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam" -configuration Debug build`

## pi-node context
When Docker context is `pi-node`, replace `localhost` with `piworm.local` in all URLs.

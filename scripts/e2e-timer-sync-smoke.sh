#!/bin/bash
# E2E Timer Sync Smoke Test
# Tests cross-device timer synchronization via APNs
# Uses physical iPhone + macOS backend
#
# Prerequisites:
#   - iPhone 15 Pro connected via USB and paired in Xcode
#   - Backend APNs credentials configured
#   - PostgreSQL running on piworm.local:5432

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

BACKEND_PORT=8081
BACKEND_URL="http://localhost:${BACKEND_PORT}"
TEST_USER_EMAIL="test@example.com"
API_BASE_URL="http://192.168.0.202:${BACKEND_PORT}"
LOG_DIR="/tmp/e2e-timer-sync-$(date +%Y%m%d-%H%M%S)"
POLL_INTERVAL=2
MAX_POLL=60

# Device entity UUIDs (from seeded data in timebeamtest schema)
MACOS_DEVICE_UUID="550e8400-e29b-41d4-a716-446655440031"
IOS_DEVICE_UUID="550e8400-e29b-41d4-a716-446655440030"

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
}

cleanup() {
    log "Cleaning up..."
    if [[ -n "${BACKEND_PID:-}" ]]; then
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
    fi
    log "Cleanup complete."
}

trap cleanup EXIT

mkdir -p "$LOG_DIR"

# =============================================================================
# Step 1: Find connected iPhone
# =============================================================================

log "=== Step 1: Discovering connected iPhone ==="

DEVICE_IDENTIFIER=""
DEVICE_NAME=""

while IFS= read -r line; do
    if echo "$line" | grep -q "iPhone"; then
        DEVICE_NAME=$(echo "$line" | awk '{print $1}')
        DEVICE_IDENTIFIER=$(echo "$line" | awk '{print $3}')
        break
    fi
done < <(xcrun devicectl list devices 2>/dev/null | tail -n +3)

if [[ -z "$DEVICE_IDENTIFIER" ]]; then
    error "No iPhone found. Connect via USB and pair in Xcode first."
    exit 1
fi

log "Found iPhone: $DEVICE_NAME ($DEVICE_IDENTIFIER)"

# =============================================================================
# Step 2: Start backend in E2E mode
# =============================================================================

log "=== Step 2: Starting backend in E2E mode ==="

cd /Users/kayisrahman/Documents/workspace/ideas/time-beam/back-end

# Kill any existing backend on port 8081
lsof -ti:8081 | xargs kill -9 2>/dev/null || true
sleep 2

# Start backend with E2E profile
nohup mvn spring-boot:run \
    -Dspring-boot.run.profiles=e2e \
    -Dspring-boot.run.arguments="--server.port=8081" \
    > /tmp/e2e-backend.log 2>&1 &
BACKEND_PID=$!

log "Backend started (PID: $BACKEND_PID)"

# Wait for backend to be ready
log "Waiting for backend to start..."
for i in $(seq 1 30); do
    if curl -s "${BACKEND_URL}/api/auth/health" > /dev/null 2>&1; then
        log "Backend is ready!"
        break
    fi
    if [[ $i -eq 30 ]]; then
        error "Backend failed to start. Check /tmp/e2e-backend.log"
        cat /tmp/e2e-backend.log | tail -30
        exit 1
    fi
    sleep 2
done

# =============================================================================
# Step 3: Get JWT tokens
# =============================================================================

log "=== Step 3: Authenticating ==="

LOGIN_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"'"${TEST_USER_EMAIL}"'"}')

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('accessToken', ''))" 2>/dev/null || echo "")

if [[ -z "$ACCESS_TOKEN" ]]; then
    error "Login failed. Response: $LOGIN_RESPONSE"
    exit 1
fi

log "Got access token (length: ${#ACCESS_TOKEN})"

# =============================================================================
# Step 4: Build and install app on iPhone
# =============================================================================

log "=== Step 4: Building and installing app on iPhone ==="

cd /Users/kayisrahman/Documents/workspace/ideas/time-beam/apple/TimeBeam

# Patch API_BASE_URL in project
sed -i '' "s|API_BASE_URL = \".*\";|API_BASE_URL = \"${API_BASE_URL}\";|" TimeBeam.xcodeproj/project.pbxproj

# Build for device
log "Building for iPhone..."
xcodebuild -scheme "TimeBeam iOS" \
    -destination "generic/platform=iOS" \
    -configuration Debug \
    -quiet \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED="NO" \
    CODE_SIGNING_ALLOWED="YES" \
    2>&1 | tail -5 || {
        error "Build failed"
        exit 1
    }

# Find the built app
APP_BUNDLE=$(find ~/Library/Developer/Xcode/DerivedData/ -name "TimeBeam*.app" -type d 2>/dev/null | grep -i "Debug-iphoneos" | head -1)

if [[ -z "$APP_BUNDLE" ]]; then
    error "App bundle not found. Build may have failed."
    exit 1
fi

log "App bundle: $APP_BUNDLE"

# Install on device
log "Installing on iPhone..."
xcrun devicectl device install app --device "$DEVICE_IDENTIFIER" "$APP_BUNDLE" 2>&1 || {
    error "Failed to install app"
    exit 1
}

# =============================================================================
# Step 5: Launch app and wait for APNs registration
# =============================================================================

log "=== Step 5: Launching app on iPhone ==="

# Launch the app
log "Launching TimeBeam iOS..."
APP_BUNDLE_ID="com.sparkage.time-beam.ios"
xcrun devicectl device process launch "$DEVICE_IDENTIFIER" "$APP_BUNDLE_ID" 2>&1 || {
    log "Launch via devicectl failed, trying alternative..."
    # Fallback: use the installed app ID directly
    xcrun devicectl device process launch "$DEVICE_IDENTIFIER" "$APP_BUNDLE_ID" 2>&1 || true
}

# Wait for app to start
log "Waiting for app to start..."
sleep 10

# =============================================================================
# Step 6: Wait for APNs token registration
# =============================================================================

log "=== Step 6: Waiting for APNs token registration ==="

# Check device stats periodically
APNS_REGISTERED=false
for i in $(seq 1 15); do
    DEVICE_STATS=$(curl -s "${BACKEND_URL}/api/devices/stats" \
        -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo "")

    # Check if devices have APNs tokens
    if echo "$DEVICE_STATS" | grep -q "apnsToken\|apns_token\|apnsToken"; then
        APNS_REGISTERED=true
        log "APNs tokens registered on devices!"
        break
    fi

    log "Waiting for APNs registration... ($i/15)"
    sleep 4
done

if [[ "$APNS_REGISTERED" != "true" ]]; then
    log "WARNING: APNs tokens not registered via API. Will proceed anyway."
    log "The app may need to be manually launched on the device to register APNs tokens."
fi

# =============================================================================
# Step 7: Test 1 — Start timer via macOS, verify iOS receives via APNs
# =============================================================================

log "=== Test 1: Start Timer — macOS -> iOS via APNs ==="

# Start timer via backend API (simulating macOS action)
# NOTE: deviceId must be the entity UUID, NOT the device_id string
log "Sending START timer action..."
START_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"START\",
        \"phase\": \"work\",
        \"isRunning\": true,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

START_HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"START\",
        \"phase\": \"work\",
        \"isRunning\": true,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

log "Backend response: START HTTP ${START_HTTP}"

# Check backend logs for APNs push
sleep 5
APNS_PUSH_LOG=$(grep -i "timer sync push\|apns\|sendNotification" /tmp/e2e-backend.log 2>/dev/null | tail -5 || echo "No APNs logs found")
log "APNs push logs: $APNS_PUSH_LOG"

# Verify backend timer state
BACKEND_STATE=$(curl -s "${BACKEND_URL}/api/sessions/timer/state" \
    -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo "")
log "Backend timer state after START:"
echo "$BACKEND_STATE" | python3 -m json.tool 2>/dev/null || echo "  $BACKEND_STATE"

# Check iOS app logs for push receipt
IOS_LOG_FILE="${LOG_DIR}/ios_test1.log"
xcrun devicectl device process log stream "$DEVICE_IDENTIFIER" \
    --filter "process == 'TimeBeam iOS'" \
    --output "$IOS_LOG_FILE" 2>&1 &
IOS_LOG_PID=$!
sleep 5
kill "$IOS_LOG_PID" 2>/dev/null || true

log "iOS logs after START action:"
grep -i "timer_sync\|timer sync\|push\|applyState\|applyEventState" "$IOS_LOG_FILE" 2>/dev/null | tail -10 || log "  No timer sync logs found"

# =============================================================================
# Step 8: Test 2 — Pause timer, verify iOS reflects pause
# =============================================================================

log "=== Test 2: Pause Timer — macOS -> iOS via APNs ==="

# Pause timer via backend API
log "Sending PAUSE timer action..."
PAUSE_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"PAUSE\",
        \"phase\": \"work\",
        \"isRunning\": false,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

PAUSE_HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"PAUSE\",
        \"phase\": \"work\",
        \"isRunning\": false,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

log "Backend response: PAUSE HTTP ${PAUSE_HTTP}"

# Check backend logs for APNs push
sleep 5
log "APNs push logs after PAUSE:"
grep -i "timer sync push\|apns\|sendNotification" /tmp/e2e-backend.log 2>/dev/null | tail -5 || log "  No new APNs logs"

# Verify backend timer state
BACKEND_STATE=$(curl -s "${BACKEND_URL}/api/sessions/timer/state" \
    -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo "")
log "Backend timer state after PAUSE:"
echo "$BACKEND_STATE" | python3 -m json.tool 2>/dev/null || echo "  $BACKEND_STATE"

# Check iOS app logs
IOS_LOG_FILE="${LOG_DIR}/ios_test2.log"
xcrun devicectl device process log stream "$DEVICE_IDENTIFIER" \
    --filter "process == 'TimeBeam iOS'" \
    --output "$IOS_LOG_FILE" 2>&1 &
IOS_LOG_PID=$!
sleep 5
kill "$IOS_LOG_PID" 2>/dev/null || true

log "iOS logs after PAUSE action:"
grep -i "timer_sync\|timer sync\|push\|applyState\|applyEventState" "$IOS_LOG_FILE" 2>/dev/null | tail -10 || log "  No timer sync logs found"

# =============================================================================
# Step 9: Test 3 — Reset timer, verify iOS reflects reset
# =============================================================================

log "=== Test 3: Reset Timer — macOS -> iOS via APNs ==="

# Reset timer via backend API
log "Sending RESET timer action..."
RESET_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"RESET\",
        \"phase\": \"work\",
        \"isRunning\": false,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

RESET_HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BACKEND_URL}/api/sessions/timer/action" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "{
        \"actionType\": \"RESET\",
        \"phase\": \"work\",
        \"isRunning\": false,
        \"workDuration\": 1500,
        \"breakDuration\": 300,
        \"longBreakDuration\": 900,
        \"autoStartNextSession\": true,
        \"shortBreaksCompleted\": 0,
        \"deviceId\": \"${MACOS_DEVICE_UUID}\",
        \"timestamp\": $(date +%s)
    }")

log "Backend response: RESET HTTP ${RESET_HTTP}"

# Check backend logs for APNs push
sleep 5
log "APNs push logs after RESET:"
grep -i "timer sync push\|apns\|sendNotification" /tmp/e2e-backend.log 2>/dev/null | tail -5 || log "  No new APNs logs"

# Verify backend timer state
BACKEND_STATE=$(curl -s "${BACKEND_URL}/api/sessions/timer/state" \
    -H "Authorization: Bearer $ACCESS_TOKEN" 2>/dev/null || echo "")
log "Backend timer state after RESET:"
echo "$BACKEND_STATE" | python3 -m json.tool 2>/dev/null || echo "  $BACKEND_STATE"

# Check iOS app logs
IOS_LOG_FILE="${LOG_DIR}/ios_test3.log"
xcrun devicectl device process log stream "$DEVICE_IDENTIFIER" \
    --filter "process == 'TimeBeam iOS'" \
    --output "$IOS_LOG_FILE" 2>&1 &
IOS_LOG_PID=$!
sleep 5
kill "$IOS_LOG_PID" 2>/dev/null || true

log "iOS logs after RESET action:"
grep -i "timer_sync\|timer sync\|push\|applyState\|applyEventState" "$IOS_LOG_FILE" 2>/dev/null | tail -10 || log "  No timer sync logs found"

# =============================================================================
# Summary
# =============================================================================

log "=== E2E Timer Sync Smoke Test Complete ==="
log "Backend logs: /tmp/e2e-backend.log"
log "iOS logs: $LOG_DIR/"

echo ""
echo "=== Test Results Summary ==="
echo ""
echo "Test 1 - Start Timer:"
echo "  HTTP Status: ${START_HTTP}"
echo "  Backend state: $(echo $BACKEND_STATE | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"phase={d.get(\"phase\")}, running={d.get(\"isRunning\")}, remaining={d.get(\"remainingSeconds\")}")' 2>/dev/null || echo "unavailable")"
echo "  iOS logs: $(grep -c 'timer_sync\|applyState\|applyEventState' "$LOG_DIR/ios_test1.log" 2>/dev/null || echo 0) events"
echo ""
echo "Test 2 - Pause Timer:"
echo "  HTTP Status: ${PAUSE_HTTP}"
echo "  Backend state: $(echo $BACKEND_STATE | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"phase={d.get(\"phase\")}, running={d.get(\"isRunning\")}, remaining={d.get(\"remainingSeconds\")}")' 2>/dev/null || echo "unavailable")"
echo "  iOS logs: $(grep -c 'timer_sync\|applyState\|applyEventState' "$LOG_DIR/ios_test2.log" 2>/dev/null || echo 0) events"
echo ""
echo "Test 3 - Reset Timer:"
echo "  HTTP Status: ${RESET_HTTP}"
echo "  Backend state: $(echo $BACKEND_STATE | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"phase={d.get(\"phase\")}, running={d.get(\"isRunning\")}, remaining={d.get(\"remainingSeconds\")}")' 2>/dev/null || echo "unavailable")"
echo "  iOS logs: $(grep -c 'timer_sync\|applyState\|applyEventState' "$LOG_DIR/ios_test3.log" 2>/dev/null || echo 0) events"
echo ""
echo "To review logs, run:"
echo "  cat $LOG_DIR/*.log"
echo "  cat /tmp/e2e-backend.log"

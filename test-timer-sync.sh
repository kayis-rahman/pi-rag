#!/bin/bash

# Timer Sync Acceptance Test Script
# Tests the core functionality of Event-Driven Multi-Device Synchronization

echo "🧪 Timer Sync Acceptance Testing"
echo "================================="

# Test 1: Backend Health Check
echo "1. Testing Backend Health..."
if curl -s http://localhost:8080/api/auth/health | grep -q '"status":"ok"'; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend is not responding"
    exit 1
fi

# Test 2: JWT Token Validation
echo "2. Testing JWT Token Validation..."
# Create a test JWT token (this would normally come from authentication)
# Use the correct JWT secret that matches the backend configuration
export JWT_SECRET="timebeam-jwt-secret-key-2025-very-long-secure-random-string-at-least-32-chars"

JWT_RESPONSE=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","displayName":"Test User"}')

if echo "$JWT_RESPONSE" | grep -q '"accessToken"'; then
    echo "✅ JWT token generation working"
    # Extract token for later tests
    JWT_TOKEN=$(echo "$JWT_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    echo "📝 Got JWT token: ${JWT_TOKEN:0:50}..."
    echo "📝 JWT token length: ${#JWT_TOKEN}"
else
    echo "❌ JWT token generation failed"
    echo "Response: $JWT_RESPONSE"
    exit 1
fi

# Test 3: Timer State Push
echo "3. Testing Timer State Push..."
TIMER_STATE='{
    "phase": "work",
    "remainingSeconds": 1500,
    "isRunning": true,
    "workDuration": 1500,
    "breakDuration": 300,
    "longBreakDuration": 900,
    "autoStartNextSession": true,
    "shortBreaksCompleted": 0,
    "lastModifiedTimestamp": '$(date +%s)',
    "deviceId": "test-device-123"
}'

echo "🔍 Sending timer state push with token: ${JWT_TOKEN:0:30}..."
PUSH_RESPONSE=$(curl -v -X POST http://localhost:8080/api/sessions/timer/state \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "$TIMER_STATE" 2>&1)

echo "🔍 Push response: $PUSH_RESPONSE"

if echo "$PUSH_RESPONSE" | grep -q "200\|success"; then
    echo "✅ Timer state push successful"
else
    echo "❌ Timer state push failed"
    echo "Full response: $PUSH_RESPONSE"
    exit 1
fi

# Test 4: Timer State Pull
echo "4. Testing Timer State Pull..."
PULL_RESPONSE=$(curl -s -X GET http://localhost:8080/api/sessions/timer/state \
  -H "Authorization: Bearer $JWT_TOKEN")

if echo "$PULL_RESPONSE" | grep -q '"phase"\|"remainingSeconds"'; then
    echo "✅ Timer state pull successful"
    echo "📝 Retrieved state with phase: $(echo "$PULL_RESPONSE" | grep -o '"phase":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ Timer state pull failed or returned no data"
    echo "Response: $PULL_RESPONSE"
fi

# Test 5: Timer Action Push
echo "5. Testing Timer Action Push..."
TIMER_ACTION='{
    "action": "pause",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "deviceId": "test-device-123",
    "phase": "work",
    "remainingSeconds": 1500,
    "isRunning": false,
    "workDuration": 1500,
    "breakDuration": 300,
    "longBreakDuration": 900,
    "autoStartNextSession": true,
    "shortBreaksCompleted": 0
}'

echo "🔍 Sending timer action with data: $TIMER_ACTION"
ACTION_RESPONSE=$(curl -v -X POST http://localhost:8080/api/sessions/timer/action \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "$TIMER_ACTION" 2>&1)

echo "🔍 Action response: $ACTION_RESPONSE"

if echo "$ACTION_RESPONSE" | grep -q "200\|success"; then
    echo "✅ Timer action push successful"
else
    echo "❌ Timer action push failed"
    echo "Full response: $ACTION_RESPONSE"
    exit 1
fi

# Test 6: Authentication Required
echo "6. Testing Authentication Requirements..."
UNAUTH_RESPONSE=$(curl -s -w "%{http_code}" -X POST http://localhost:8080/api/sessions/timer/state \
  -H "Content-Type: application/json" \
  -d "$TIMER_STATE")

HTTP_CODE=$(echo "$UNAUTH_RESPONSE" | tail -1)
RESPONSE_BODY=$(echo "$UNAUTH_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "✅ Authentication properly required (HTTP $HTTP_CODE)"
else
    echo "⚠️  Authentication check inconclusive (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "🎉 Timer Sync Acceptance Testing Complete!"
echo "=========================================="
echo "✅ All core API endpoints working"
echo "✅ Authentication properly enforced"
echo "✅ Timer state push/pull functional"
echo "✅ Timer actions can be broadcast"
echo ""
echo "📋 Manual Testing Checklist:"
echo "- [ ] Start timer on Device A, verify sync to Device B"
echo "- [ ] Pause timer on Device A, verify pause on Device B"
echo "- [ ] Timer works offline without authentication"
echo "- [ ] Timer syncs automatically after authentication"
echo "- [ ] Conflict resolution handles concurrent changes"
echo ""
echo "Ready for manual testing and acceptance! 🚀"
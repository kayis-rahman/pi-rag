#!/bin/bash
# Final iOS Timer Sync Implementation Verification
# Run this AFTER implementing all client-side fixes

echo "🎯 Final iOS Timer Sync Implementation Verification"
echo "=================================================="

SERVER_URL="http://localhost:8080"
TEST_EMAIL="test@example.com"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get JWT token
echo -e "\n🔐 Getting authentication token..."
JWT_TOKEN=$(curl -s -X POST "$SERVER_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$TEST_EMAIL\"}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$JWT_TOKEN" ]; then
    echo -e "${RED}❌ Failed to get JWT token${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Authentication successful${NC}"

# Test device registration
echo -e "\n📱 Testing device registration..."
REGISTER_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" \
    -X POST "$SERVER_URL/api/devices/register" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "deviceId": "ios-final-test-device",
        "deviceType": "iOS",
        "deviceName": "iPhone Final Test",
        "platformVersion": "17.0",
        "appVersion": "1.0.0"
    }')

REGISTER_STATUS=$(echo "$REGISTER_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
if [ "$REGISTER_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Device registration successful${NC}"
else
    echo -e "${RED}❌ Device registration failed (HTTP $REGISTER_STATUS)${NC}"
    echo "Response: $REGISTER_RESPONSE"
fi

# Test APNs token registration
echo -e "\n🔔 Testing APNs token registration..."
APNS_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" \
    -X POST "$SERVER_URL/api/sessions/devices/apns-token" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "deviceId": "ios-final-test-device",
        "apnsToken": "final-test-apns-token-12345"
    }')

APNS_STATUS=$(echo "$APNS_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
if [ "$APNS_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ APNs token registration successful${NC}"
else
    echo -e "${RED}❌ APNs token registration failed (HTTP $APNS_STATUS)${NC}"
fi

# Test timer sync with CORRECT field name
echo -e "\n⏰ Testing timer sync (with lastModifiedTimestamp)..."
TIMESTAMP=$(date +%s).123

TIMER_RESPONSE=$(curl -s -w "\nHTTPSTATUS:%{http_code}" \
    -X POST "$SERVER_URL/api/sessions/timer/state" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"deviceId\": \"ios-final-test-device\",
        \"phase\": \"work\",
        \"remainingSeconds\": 1500,
        \"isRunning\": true,
        \"workDuration\": 25,
        \"breakDuration\": 5,
        \"longBreakDuration\": 15,
        \"autoStartNextSession\": false,
        \"shortBreaksCompleted\": 0,
        \"lastModifiedTimestamp\": $TIMESTAMP
    }")

TIMER_STATUS=$(echo "$TIMER_RESPONSE" | grep "HTTPSTATUS:" | cut -d: -f2)
if [ "$TIMER_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Timer sync successful (using lastModifiedTimestamp)${NC}"
else
    echo -e "${RED}❌ Timer sync failed (HTTP $TIMER_STATUS)${NC}"
    echo "Response: $TIMER_RESPONSE"
fi

# Check server logs for diagnostic output
echo -e "\n📊 Checking server diagnostic logs..."
sleep 2

TIMER_LOGS=$(grep "ios-final-test-device" back-end/logs/timebeam.log | tail -3)
if echo "$TIMER_LOGS" | grep -q "TIMER_PUSH_SUCCESS"; then
    echo -e "${GREEN}✅ Server logs show successful timer sync${NC}"
else
    echo -e "${YELLOW}⚠️  Server logs may not show success yet${NC}"
    echo "Recent logs:"
    echo "$TIMER_LOGS"
fi

# Check database
echo -e "\n💾 Checking database registration..."
DEVICE_COUNT=$(docker exec timebeam_postgres psql -U timebeam -d timebeam -c "
SELECT COUNT(*) FROM user_devices
WHERE user_id = (SELECT id FROM users WHERE email = '$TEST_EMAIL' LIMIT 1)
AND device_id = 'ios-final-test-device';" 2>/dev/null | grep -E '^[0-9]+$' | head -1)

if [ "$DEVICE_COUNT" = "1" ]; then
    echo -e "${GREEN}✅ Device properly registered in database${NC}"
else
    echo -e "${RED}❌ Device not found in database${NC}"
fi

echo -e "\n🎯 IMPLEMENTATION VERIFICATION COMPLETE"
echo "========================================"
echo ""
echo "If all tests show ✅, the iOS timer sync implementation is successful!"
echo ""
echo "📋 Next Steps:"
echo "1. Test with actual iOS device"
echo "2. Verify cross-device sync with macOS"
echo "3. Test push notifications"
echo "4. Monitor server logs for any issues"
echo ""
echo "🔍 For ongoing monitoring:"
echo "tail -f back-end/logs/timebeam.log | grep TIMER_PUSH"
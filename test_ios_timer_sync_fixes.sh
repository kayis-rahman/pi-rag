#!/bin/bash
# iOS Timer Sync Fix Verification Script
# Run this after implementing the client-side fixes

set -e

echo "🔍 iOS Timer Sync Fix Verification"
echo "==================================="

# Configuration
SERVER_URL="http://localhost:8080"
TEST_USER_EMAIL="test@example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "success" ]; then
        echo -e "${GREEN}✅ $message${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️  $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Function to make API call and check response
check_api_call() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=${4:-200}
    local description=$5

    echo "Testing: $description"

    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X POST "$url" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" 2>/dev/null)
    elif [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" -X GET "$url" \
            -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null)
    fi

    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')

    if [ "$http_code" = "$expected_status" ]; then
        print_status "success" "$description - HTTP $http_code"
        return 0
    else
        print_status "error" "$description - HTTP $http_code (expected $expected_status)"
        echo "Response: $response_body"
        return 1
    fi
}

# 1. Test Authentication
echo -e "\n📋 Phase 1: Authentication"
echo "============================"

if ! JWT_TOKEN=$(curl -s -X POST "$SERVER_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$TEST_USER_EMAIL\"}" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4); then
    print_status "error" "Authentication failed"
    exit 1
fi

if [ -z "$JWT_TOKEN" ]; then
    print_status "error" "No JWT token received"
    exit 1
fi

print_status "success" "Authentication successful - JWT token obtained"

# 2. Test Device Registration
echo -e "\n📱 Phase 2: Device Registration"
echo "==============================="

# Register iOS device
check_api_call "POST" "$SERVER_URL/api/devices/register" '{
    "deviceId": "ios-test-device-verification",
    "deviceType": "iOS",
    "deviceName": "iPhone Verification Test",
    "platformVersion": "17.0",
    "appVersion": "1.0.0"
}' 200 "iOS Device Registration"

# Register macOS device
check_api_call "POST" "$SERVER_URL/api/devices/register" '{
    "deviceId": "macos-test-device-verification",
    "deviceType": "macOS",
    "deviceName": "MacBook Verification Test",
    "platformVersion": "14.0",
    "appVersion": "1.0.0"
}' 200 "macOS Device Registration"

# 3. Test APNs Token Registration
echo -e "\n🔔 Phase 3: APNs Token Registration"
echo "==================================="

# Register APNs token for iOS
check_api_call "POST" "$SERVER_URL/api/sessions/devices/apns-token" '{
    "deviceId": "ios-test-device-verification",
    "apnsToken": "test-ios-verification-token-12345"
}' 200 "iOS APNs Token Registration"

# Register APNs token for macOS
check_api_call "POST" "$SERVER_URL/api/sessions/devices/apns-token" '{
    "deviceId": "macos-test-device-verification",
    "apnsToken": "test-macos-verification-token-67890"
}' 200 "macOS APNs Token Registration"

# 4. Test Timer Sync with Correct Payload
echo -e "\n⏰ Phase 4: Timer Sync Testing"
echo "=============================="

TIMESTAMP=$(date +%s).123

# Test iOS timer sync with CORRECT field name
check_api_call "POST" "$SERVER_URL/api/sessions/timer/state" "{
    \"deviceId\": \"ios-test-device-verification\",
    \"phase\": \"work\",
    \"remainingSeconds\": 1500,
    \"isRunning\": true,
    \"workDuration\": 25,
    \"breakDuration\": 5,
    \"longBreakDuration\": 15,
    \"autoStartNextSession\": false,
    \"shortBreaksCompleted\": 0,
    \"lastModifiedTimestamp\": $TIMESTAMP
}" 200 "iOS Timer Sync (Correct Payload)"

# Test macOS timer sync
check_api_call "POST" "$SERVER_URL/api/sessions/timer/state" "{
    \"deviceId\": \"macos-test-device-verification\",
    \"phase\": \"work\",
    \"remainingSeconds\": 1500,
    \"isRunning\": true,
    \"workDuration\": 25,
    \"breakDuration\": 5,
    \"longBreakDuration\": 15,
    \"autoStartNextSession\": false,
    \"shortBreaksCompleted\": 0,
    \"lastModifiedTimestamp\": $TIMESTAMP
}" 200 "macOS Timer Sync"

# 5. Verify Server Logs
echo -e "\n📊 Phase 5: Server Log Verification"
echo "==================================="

echo "Recent timer sync logs:"
tail -20 back-end/logs/timebeam.log | grep -E "(TIMER_PUSH|Device registered|APNs token)" || echo "No recent timer sync logs found"

# 6. Check Database State
echo -e "\n💾 Phase 6: Database Verification"
echo "================================="

echo "Registered devices:"
docker exec timebeam_postgres psql -U timebeam -d timebeam -c "
SELECT device_id, device_type, active
FROM user_devices
WHERE user_id = (SELECT id FROM users WHERE email = '$TEST_USER_EMAIL' LIMIT 1)
ORDER BY created_at DESC
LIMIT 5;" 2>/dev/null || echo "Database query failed"

echo -e "\n🎯 Verification Complete!"
echo "========================="
echo "If all tests passed, the iOS timer sync fixes are working correctly."
echo "The server-side diagnostic logging will continue monitoring for any issues."
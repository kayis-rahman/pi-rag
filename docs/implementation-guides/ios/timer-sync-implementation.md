# iOS Timer Sync Implementation Guide

## 🎯 Issue Summary

iOS timer sync requests were failing silently while macOS requests succeeded. Server-side diagnostic logging revealed the root causes and solutions.

## 🔍 Root Causes Identified

### 1. **Missing/incorrect timestamp field**
- **Problem**: iOS app sending `"timestamp"` instead of `"lastModifiedTimestamp"`
- **Impact**: NullPointerException in TimerSyncService
- **Status**: ✅ **REQUIRES CLIENT FIX**

### 2. **Device registration not happening**
- **Problem**: iOS devices not registered before attempting timer sync
- **Impact**: APNs token updates and device-specific operations fail
- **Status**: ✅ **REQUIRES CLIENT FIX**

### 3. **Server-side logic works correctly**
- **Finding**: Once proper payload and registration complete, iOS/macOS processing identical
- **Status**: ✅ **SERVER-SIDE WORKING**

## 📋 Required Client-Side Implementation

### **Phase 1: Device Registration (iOS App)**

**File**: `apple/TimeBeam/TimeBeamApp.swift` or device management class

**Required Code**:
```swift
// Register device on app launch/first use
func registerDevice() {
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    let registrationData = DeviceRegistrationDto(
        deviceId: deviceId,
        deviceType: "iOS",
        deviceName: UIDevice.current.name,
        platformVersion: UIDevice.current.systemVersion,
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    )

    // POST to /api/devices/register
    // Handle success/failure appropriately
}
```

### **Phase 2: Timer Sync Payload Fix**

**File**: iOS TimerEventManager or equivalent

**Current (Broken)**:
```swift
let timerState = TimerStateDto(
    deviceId: deviceId,
    phase: phase,
    remainingSeconds: remainingSeconds,
    // ... other fields
    timestamp: Date().timeIntervalSince1970 // ❌ Wrong field name
)
```

**Fixed**:
```swift
let timerState = TimerStateDto(
    deviceId: deviceId,
    phase: phase,
    remainingSeconds: remainingSeconds,
    workDuration: workDuration,
    breakDuration: breakDuration,
    longBreakDuration: longBreakDuration,
    autoStartNextSession: autoStartNextSession,
    shortBreaksCompleted: shortBreaksCompleted,
    lastModifiedTimestamp: Date().timeIntervalSince1970 // ✅ Correct field name
)
```

### **Phase 3: APNs Token Registration**

**File**: iOS PushNotificationManager or equivalent

**Required Code**:
```swift
func registerAPNsToken(_ token: Data) {
    let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
    let deviceId = getDeviceId()

    let apnsData = APNsTokenDto(
        deviceId: deviceId,
        apnsToken: tokenString
    )

    // POST to /api/sessions/devices/apns-token
    // This should happen AFTER device registration
}
```

## 🧪 Testing Scripts

### **Test Device Registration**
```bash
#!/bin/bash
# test_device_registration.sh

TOKEN="your-jwt-token-here"

# Register iOS device
curl -X POST http://localhost:8080/api/devices/register \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ios-test-device-001",
    "deviceType": "iOS",
    "deviceName": "iPhone Test",
    "platformVersion": "17.0",
    "appVersion": "1.0.0"
  }'

# Register macOS device
curl -X POST http://localhost:8080/api/devices/register \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "macos-test-device-001",
    "deviceType": "macOS",
    "deviceName": "MacBook Test",
    "platformVersion": "14.0",
    "appVersion": "1.0.0"
  }'
```

### **Test Timer Sync**
```bash
#!/bin/bash
# test_timer_sync.sh

TOKEN="your-jwt-token-here"

echo "Testing iOS Timer Sync:"
curl -X POST http://localhost:8080/api/sessions/timer/state \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ios-test-device-001",
    "phase": "work",
    "remainingSeconds": 1500,
    "isRunning": true,
    "workDuration": 25,
    "breakDuration": 5,
    "longBreakDuration": 15,
    "autoStartNextSession": false,
    "shortBreaksCompleted": 0,
    "lastModifiedTimestamp": '$(date +%s).123'
  }'

echo -e "\n\nTesting macOS Timer Sync:"
curl -X POST http://localhost:8080/api/sessions/timer/state \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "macos-test-device-001",
    "phase": "work",
    "remainingSeconds": 1500,
    "isRunning": true,
    "workDuration": 25,
    "breakDuration": 5,
    "longBreakDuration": 15,
    "autoStartNextSession": false,
    "shortBreaksCompleted": 0,
    "lastModifiedTimestamp": '$(date +%s).123'
  }'
```

### **Test APNs Token Registration**
```bash
#!/bin/bash
# test_apns_registration.sh

TOKEN="your-jwt-token-here"

# Register APNs token for iOS
curl -X POST http://localhost:8080/api/sessions/devices/apns-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ios-test-device-001",
    "apnsToken": "test-ios-apns-token-12345"
  }'

# Register APNs token for macOS
curl -X POST http://localhost:8080/api/sessions/devices/apns-token \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "macos-test-device-001",
    "apnsToken": "test-macos-apns-token-67890"
  }'
```

## 📊 Verification Checklist

### **Pre-Implementation**
- [ ] Server running with PostgreSQL database
- [ ] Diagnostic logging enabled and working
- [ ] JWT authentication working

### **Device Registration**
- [ ] iOS app registers device on first launch
- [ ] macOS app registers device on first launch
- [ ] Device registration API calls succeed (200 status)
- [ ] Devices appear in database `user_devices` table

### **Timer Sync**
- [ ] iOS timer sync uses `lastModifiedTimestamp` field
- [ ] macOS timer sync uses `lastModifiedTimestamp` field
- [ ] Timer sync API calls succeed (200 status)
- [ ] Server logs show `TIMER_PUSH_SUCCESS` for both platforms
- [ ] Timer states persist in database

### **APNs Token Registration**
- [ ] iOS APNs token registration happens after device registration
- [ ] macOS APNs token registration happens after device registration
- [ ] APNs token API calls succeed (200 status)
- [ ] Server logs show successful token updates

### **Cross-Device Sync**
- [ ] Timer state changes sync between iOS and macOS devices
- [ ] Push notifications work for timer updates
- [ ] Real-time sync works in both directions

## 🔍 Monitoring & Debugging

### **Server Log Monitoring**
```bash
# Monitor timer sync logs
tail -f back-end/logs/timebeam.log | grep TIMER_PUSH

# Monitor device registration logs
tail -f back-end/logs/timebeam.log | grep "Device registered"

# Monitor APNs token logs
tail -f back-end/logs/timebeam.log | grep "APNs token"
```

### **Common Issues & Solutions**

1. **500 Error on Timer Sync**
   - Check payload uses `lastModifiedTimestamp` not `timestamp`
   - Ensure device is registered first

2. **APNs Token Registration Fails**
   - Ensure device registration completed first
   - Check device ID matches registered device

3. **Timer Sync Succeeds but No Cross-Device Updates**
   - Verify both devices are registered
   - Check APNs tokens are registered
   - Monitor push notification service logs

## 🎯 Implementation Priority

1. **High Priority**: Device registration flow
2. **High Priority**: Timer sync payload field fix
3. **Medium Priority**: APNs token registration
4. **Low Priority**: Push notification testing

## ✅ Success Criteria

- [ ] iOS timer sync requests succeed (200 status)
- [ ] macOS timer sync requests succeed (200 status)
- [ ] Server logs show identical processing for both platforms
- [ ] Cross-device timer synchronization works
- [ ] Push notifications work for timer updates

---

**Implementation Status**: Server-side ✅ Complete | Client-side 🔄 Ready for Implementation</content>
<parameter name="filePath">IOS_TIMER_SYNC_IMPLEMENTATION_GUIDE.md
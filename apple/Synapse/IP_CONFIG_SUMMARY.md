# IP Address Configuration - Summary

## Changes Made

### 1. Info.plist Configuration
**File:** `apple/Synapse/Synapse/Info.plist`
- Changed: `http://localhost:8080` → `$(API_BASE_URL)`
- Build variable substitution now resolves to actual IP at build time

### 2. Xcode Project Build Settings
**File:** `apple/Synapse/Synapse.xcodeproj/project.pbxproj`
Added `API_BASE_URL` build setting to four configurations:

| Configuration | Line | Value |
|-------------|-------|--------|
| iOS Debug | 693 | http://192.168.0.173:8080 |
| iOS Release | 790 | http://192.168.0.173:8080 |
| macOS Debug | 747 | http://192.168.0.173:8080 |
| macOS Release | 844 | http://192.168.0.173:8080 |

### 3. Swift Code Updates (Environment Variable Support)
Updated fallback URLs to use `ProcessInfo.processInfo.environment["API_BASE_URL"]`:

**Files Updated:**
- `Synapse/SynapseApp.swift:47` - AnalyticsApiClient fallback
- `Synapse/Application/Services/TaskService.swift:19` - ApiClient fallback
- `Synapse/Presentation/Views/iOS/AnalyticsView.swift` - Multiple instances (223, 256, 283)

All now fallback to: `http://192.168.0.173:8080` if environment variable not set

### 4. Documentation
**New File:** `apple/Synapse/API_CONFIG.md`
- Comprehensive guide for changing API URLs
- Instructions for development, testing, and team scenarios
- Troubleshooting section

## Verification

✅ **Build Status:** BUILD SUCCEEDED
✅ **Compiled Info.plist:** Shows `API_BASE_URL => "http://192.168.0.173:8080"`
✅ **Backend Connectivity:** Backend running on port 8080, bound to 0.0.0.0
✅ **IP Address:** Host machine IP confirmed as 192.168.0.173

## How It Works

1. **Build Time:** Xcode reads `API_BASE_URL` from project.pbxproj build settings
2. **Substitution:** Info.plist `$(API_BASE_URL)` is replaced with actual value
3. **Runtime:** Swift code reads from compiled Info.plist via `Configuration.fromInfoPlist()`
4. **Fallback:** If Info.plist fails, Swift code checks environment variable or uses hardcoded IP

## Testing the Connection

To verify iOS Simulator can now connect:

1. Run backend:
   ```bash
   cd back-end
   mvn spring-boot:run -Dspring-boot.run.profiles=dev
   ```

2. Run iOS app:
   - In Xcode, select "Synapse iOS" scheme
   - Choose iPhone 17 simulator
   - Run app (⌘R)

3. Check console logs:
   ```
   [DEBUG] API Base URL: http://192.168.0.173:8080
   ✅ ApiClient: Creating request to URL: http://192.168.0.173:8080/...
   ```

4. Should NOT see:
   ```
   ❌ Connection refused
   ❌ Could not connect to the server
   ```

## Changing the IP Address

### Quick Change (Same Network, New IP)

1. Get new IP:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. Update build settings (4 locations):
   ```bash
   cd apple/Synapse
   sed -i '' 's|API_BASE_URL = ".*|API_BASE_URL = "http://NEW_IP:8080"|' \
     Synapse.xcodeproj/project.pbxproj
   ```

3. Rebuild:
   ```bash
   xcodebuild clean build -scheme "Synapse iOS" \
     -destination "platform=iOS Simulator,name=iPhone 17"
   ```

### Or Use Xcode UI (Easier)

1. Open Xcode project
2. Select target (Synapse iOS or Synapse)
3. Build Settings tab
4. Search for "API_BASE_URL"
5. Update value
6. Build and run

## Benefits of This Approach

✅ **Flexible:** Easy to change IP without code edits
✅ **Development-Friendly:** Each developer can use their own IP
✅ **Team-Ready:** Environment variable support for different environments
✅ **Documented:** Clear instructions in API_CONFIG.md
✅ **Backward Compatible:** Fallback URLs still work if Info.plist fails
✅ **Build-Time Resolution:** Fast, no runtime overhead

## Next Steps

1. **Test the app** - Run iOS Simulator and verify backend connectivity
2. **Update documentation** - Add to main README if needed
3. **Consider automation** - Could use shell script to auto-detect IP
4. **Team setup** - Document for future team members

## Files Modified

| File | Change |
|------|---------|
| `Synapse/Info.plist` | Added $(API_BASE_URL) placeholder |
| `Synapse.xcodeproj/project.pbxproj` | Added API_BASE_URL to 4 build configs |
| `Synapse/SynapseApp.swift` | Updated fallback URL |
| `Synapse/Application/Services/TaskService.swift` | Updated fallback URL |
| `Synapse/Presentation/Views/iOS/AnalyticsView.swift` | Updated 3 instances |
| `API_CONFIG.md` | New configuration guide |

## Git Status

```
M Synapse.xcodeproj/project.pbxproj
M Synapse/Info.plist
M Synapse/SynapseApp.swift
M Synapse/Application/Services/TaskService.swift
M Synapse/Presentation/Views/iOS/AnalyticsView.swift
?? API_CONFIG.md
```

Ready to commit these changes!

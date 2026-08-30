# API Configuration

Synapse iOS/macOS apps connect to the backend using an environment variable configuration.

## Current Configuration

**Backend URL:** `http://192.168.0.173:8080`

This is configured in four places:
1. **Xcode Project Build Settings** - Primary configuration
   - iOS Debug: project.pbxproj:693
   - iOS Release: project.pbxproj:790
   - macOS Debug: project.pbxproj:747
   - macOS Release: project.pbxproj:844

2. **Info.plist** - Build variable substitution
   - Synapse/Info.plist:6 uses `$(API_BASE_URL)` placeholder

3. **Swift Fallback Code** - Environment variable support
   - SynapseApp.swift:47
   - TaskService.swift:19
   - AnalyticsView.swift:223, 256, 283

## How to Change the API URL

### Option 1: Update Build Settings (Recommended for Development)

Edit the `API_BASE_URL` value in Xcode:
1. Open Xcode project
2. Select "Synapse iOS" or "Synapse" (macOS) target
3. Go to "Build Settings" tab
4. Search for "API_BASE_URL"
5. Change the value to your new URL

Or edit project.pbxproj directly:
```bash
# Replace all instances (iOS + macOS, Debug + Release)
sed -i '' 's|API_BASE_URL = ".*|API_BASE_URL = "http://YOUR_NEW_IP:8080"|' \
  Synapse.xcodeproj/project.pbxproj
```

### Option 2: Use Environment Variable (For Testing)

Set environment variable when running from Xcode:
1. Edit Scheme → Run → Arguments → Environment Variables
2. Add: `API_BASE_URL` = `http://YOUR_IP:8080`

Or when running from command line:
```bash
API_BASE_URL=http://192.168.0.173:8080 xcodebuild \
  -scheme "Synapse iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Get Your Current IP Address

On macOS:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Example output:
```
	inet 192.168.0.173 netmask 0xffffff00 broadcast 192.168.0.255
```

The IP address is `192.168.0.173`

## Common Scenarios

### Different Network
If you switch networks (home, work, coffee shop), your IP may change:
```bash
# Check new IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Update project if needed
```

### Testing with Real Device
For real device testing, ensure:
1. Device and Mac are on same network
2. Mac firewall allows port 8080 access
3. Use Mac's actual IP (not localhost)

### Team Development
For team members with different IPs:
1. Each developer should configure their own local IP
2. Don't commit personal IP changes to git
3. Use environment variables for flexibility

## Verification

To verify the configuration is working:
1. Build and run the app
2. Check Xcode console for:
   ```
   [DEBUG] API Base URL: http://192.168.0.173:8080
   ```
3. Make API calls (login, timer sync, etc.)
4. Confirm no connection errors

## Troubleshooting

**Error:** "Could not connect to the server"
- Check backend is running: `lsof -i :8080`
- Verify IP address is correct
- Ensure Mac firewall allows connections
- Confirm device and Mac are on same network

**Error:** Build still uses localhost
- Clean build folder: `⌘⇧K` or `xcodebuild clean`
- Rebuild project
- Verify project.pbxproj has API_BASE_URL entries

## Backend Network Binding

The backend is configured to bind to all interfaces:
```yaml
# back-end/src/main/resources/application.yml
server:
  address: 0.0.0.0  # Accepts connections from any IP
```

This allows iOS Simulator and external devices to connect via the Mac's IP address.

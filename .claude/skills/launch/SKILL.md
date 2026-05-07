# SKILL.md — Launch TimeBeam

> Start backend and launch macOS/iOS app on physical device. Copy-paste ready commands.

## Prerequisites
- Docker context is `pi-node` — postgres is at `piworm.local:5432`
- Ensure `docker compose -f back-end/docker-compose.dev.yml up -d` is running
- For physical device: iPhone must be connected via USB and trusted

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
- Scheme "TimeBeam iOS" is for iOS physical device
- Scheme "TimeBeamWatch Watch App" is for watch

## Launch iOS App — Physical Device

### 1. Pre-flight Checks
```bash
# Check device connected
xcrun devicectl list devices 2>&1 | grep -E "iPhone|State"

# Check backend health
curl -s http://192.168.0.202:8080/api/auth/health && echo ""

# Check app installed
xcrun devicectl device info apps --device <UDID> 2>&1 | grep -i sparkage
```

**Expected output:**
- Device shows `connected` state
- Backend: `{"status":"ok","service":"timebeam-backend"}`
- App: `Time Beam   com.sparkage.time-beam.ios   1.0   <build>`

### 2. Build & Install
```bash
cd apple/TimeBeam && xcodebuild \
  -project TimeBeam.xcodeproj \
  -scheme "TimeBeam iOS" \
  -destination "id=<UDID>" \
  -configuration Debug \
  clean build install
```

Replace `<UDID>` with device UDID from `xcrun devicectl list devices`.

### 3. Launch with Debugger
In Xcode:
1. Open `apple/TimeBeam/TimeBeam.xcodeproj`
2. Select scheme **TimeBeam iOS**
3. Select connected iPhone as destination
4. Press **⌘R** (or click Run button)

Xcode will:
- Attach `lldb` debugger
- Show console output in real time
- Allow breakpoints and stepping

**Expected startup sequence in Xcode console:**

1. `setupApp()` starts (LoadingView visible on device)
2. `restoreSession()` — pulls auth token from Keychain
   - If signed in: continues to step 3
   - If not signed in: shows Google Sign-In screen
3. `pullTimerState` → 200 response — syncs timer from backend
   - `applySyncedState()` — timer updates to server state
4. `TimerSyncManager.configure(with:)` — sync manager wired up
   - `startPeriodicPolling()` — 30-second polling loop starts
5. `isAppReady = true` — LoadingView dismissed
   - Timer view appears on device
6. Console logs `syncTimerState()` every 30 seconds

**If signed out on first launch:**
- Google Sign-In screen appears → tap sign-in with Google account
- After auth: goes through steps 3-6 above
- Device syncs timer automatically after successful auth

**Troubleshooting:**
| Issue | Fix |
|---|---|
| Device not showing as connected | Tap **Trust This Computer** on iPhone. Reconnect USB. |
| Backend unreachable (192.168.0.202) | Check Mac LAN IP: `ipconfig getifaddr en0`. Update `API_BASE_URL` in `project.pbxproj` if different. |
| App not installed | Run build step first: `xcodebuild ... clean build install` |
| Debugger won't attach | Close/reopen Xcode. Confirm scheme and device selected. |

## Config Profiles
- `application-piworm.yml` — uses `jdbc:postgresql://piworm.local:5432/timebeam_e2e`
- Activated with `-Dspring-boot.run.profiles=piworm`

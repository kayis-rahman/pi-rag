# Phase 4: Cross Sync - Pattern Map

**Mapped:** 2026-05-10
**Files analyzed:** 10 (3 new, 7 modified)
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `SyncFailureAlertManager.swift` | service | event-driven | `TimerSyncManager.swift` | exact |
| `QueuedTimerAction.swift` | model | transform | `TimerActionDto.swift` | exact |
| `SyncStatusBanner.swift` | component | request-response | `PrimaryButton.swift` | role-match |
| `TimerSyncManager.swift` | service | event-driven | `TimerSyncManager.swift` | exact (self) |
| `PushNotificationService.java` | service | event-driven | `PushNotificationService.java` | exact (self) |
| `KeychainStore.swift` | utility | file-I/O | `KeychainStore.swift` | exact (self) |
| `ApiClient.swift` | utility | request-response | `ApiClient.swift` | exact (self) |
| `MacAppDelegate.swift` | service | event-driven | `MacAppDelegate.swift` | exact (self) |
| `iOSAppDelegate.swift` | service | event-driven | `iOSAppDelegate.swift` | exact (self) |
| `TimeBeamApp.swift` | component | request-response | `TimeBeamApp.swift` | role-match |

## Pattern Assignments

### `SyncFailureAlertManager.swift` (service, event-driven) — NEW

**Analog:** `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift`

This file is a singleton service that coordinates user-facing alerts after 3+ consecutive sync failures. It follows the same singleton + @Observable + @MainActor pattern as `TimerSyncManager` and `AuthManager`.

**Imports pattern** (from `TimerSyncManager.swift` lines 1-5):
```swift
import os
import Observation
import Foundation
import _Concurrency
```

**Singleton + @Observable pattern** (from `TimerSyncManager.swift` lines 13-16):
```swift
@MainActor
@Observable
final class TimerSyncManager {
    static let shared = TimerSyncManager()
```

**Apply to SyncFailureAlertManager:**
```swift
import os
import Observation
import Foundation
import _Concurrency

@MainActor
@Observable
final class SyncFailureAlertManager {
    static let shared = SyncFailureAlertManager()

    var showAlert: Bool = false
    var consecutiveFailures: Int = 0
    private var retryAction: (() async -> Void)?

    private init() {}
```

**Alert presentation pattern** (from `AuthManager.swift` lines 40-46):
```swift
@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()

    var isSignedIn: Bool = false
    var displayName: String? = nil
    var email: String? = nil
```

**Logging pattern** (from `TimerSyncManager.swift` lines 507-513):
```swift
if let error = error {
    print("💥 TIMER_SYNC_ERROR: \(syncType) failed with error: \(error.localizedDescription)")
    LoggerStore.timer.error("Timer sync failed - \(syncType): \(error.localizedDescription)")
```

**SyncFailureAlertManager public API (derived from RESEARCH.md Pattern 3):**
- `showAlert(consecutiveFailures: Int, retryAction: @escaping () async -> Void)` — set `showAlert = true`, store retry closure
- `dismissAlert()` — set `showAlert = false`, reset `consecutiveFailures = 0`
- `manualRetry()` — invoke stored `retryAction`

---

### `QueuedTimerAction.swift` (model, transform) — NEW

**Analog:** `apple/TimeBeam/TimeBeam/Infrastructure/Networking/DTOs/TimerActionDto.swift`

This file is a lightweight Codable struct — the queue entry data model. It mirrors `TimerActionDto` but captures a full snapshot of timer state at action time for offline replay.

**Imports pattern** (from `TimerActionDto.swift` line 1):
```swift
import Foundation
```

**Struct Codable pattern** (from `TimerActionDto.swift` lines 3-4):
```swift
struct TimerActionDto: Codable {
    let action: String
```

**Enum reference pattern** (from `TimerAction.swift` lines 3-9):
```swift
public enum TimerAction: String, Codable {
    case start = "START"
    case pause = "PAUSE"
    case reset = "RESET"
    case stop = "STOP"
    case advance = "ADVANCE"
}
```

**Apply to QueuedTimerAction** (derived from RESEARCH.md Pattern 1):
```swift
import Foundation

struct QueuedTimerAction: Codable, Sendable {
    let action: TimerAction              // enum: start, pause, reset, stop, advance
    let timestamp: Double                // Date().timeIntervalSince1970
    let phase: String                    // snapshot of phase at action time
    let remainingSeconds: Int
    let isRunning: Bool
    let workDuration: Int
    let breakDuration: Int
    let longBreakDuration: Int
    let autoStartNextSession: Bool
    let shortBreaksCompleted: Int
}
```

**Key design notes:**
- `Sendable` conformance allows cross-actor usage (NWPathMonitor background queue -> MainActor)
- `Codable` enables JSON encoding/decoding for Keychain persistence
- Uses existing `TimerAction` enum (no new enum needed)

---

### `SyncStatusBanner.swift` (component, request-response) — NEW

**Analog:** `apple/TimeBeam/TimeBeam/Presentation/Views/Components/PrimaryButton.swift`

This file is a SwiftUI View component — a dismissible banner shown when sync is degraded. It follows the same structural pattern as `PrimaryButton` and `SecondaryButton`.

**Imports pattern** (from `PrimaryButton.swift` line 1):
```swift
import SwiftUI
```

**View struct pattern** (from `PrimaryButton.swift` lines 3-44):
```swift
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                // ... content
            }
        }
        .buttonStyle(.plain)
    }
}
```

**Preview pattern** (from `PrimaryButton.swift` lines 47-54):
```swift
#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Start Timer", icon: "play.fill") {}
    }
    .padding()
}
```

**Apply to SyncStatusBanner:**
```swift
import SwiftUI

struct SyncStatusBanner: View {
    @Bindable var alertManager: SyncFailureAlertManager
    let onRetry: () async -> Void
    let onDismiss: () -> Void

    var body: some View {
        if alertManager.showAlert {
            // HStack with warning icon, message, retry button, dismiss
        }
    }
}

#Preview {
    SyncStatusBanner(
        alertManager: .shared,
        onRetry: {},
        onDismiss: {}
    )
}
```

**Glass effect pattern** (from `PrimaryButton.swift` line 41):
```swift
.glassEffectInteractiveConditional(tint: .themePrimary, in: .rect(cornerRadius: 12))
```

**Secondary button styling** (from `SecondaryButton.swift` lines 34-41):
```swift
.background(
    RoundedRectangle(cornerRadius: 10)
        .fill(Color.themeCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDestructive ? Color.themeError : Color.themeBorder, lineWidth: 1.5)
        )
)
```

---

### `TimerSyncManager.swift` (service, event-driven) — MODIFY

**Analog:** Self — `apple/TimeBeam/TimeBeam/Application/Services/TimerSyncManager.swift`

This is the primary extension target. The existing file already has: polling (line 83-97), action sync (line 156-215), push event apply (line 224-263), retry logic (line 266-339), error handling (line 501-520), and validation (line 431-485).

**Properties to ADD:**
```swift
// Action queue
private var actionQueue: [QueuedTimerAction] = []
private let maxQueueSize = 50

// Network monitoring (from RESEARCH.md Pattern 2)
private var networkMonitor: NWPathMonitor?
private var networkQueue: DispatchQueue?

// Exponential backoff tracker (from RESEARCH.md Pattern 3)
private var consecutiveFailures: Int = 0
private let backoffIntervals: [Int: TimeInterval] = [
    1: 30,   // First failure: 30s
    2: 60,   // Second failure: 60s
    3: 120,  // Third failure: 120s
]
private let maxBackoff: TimeInterval = 300  // Cap
```

**Import to ADD** (from RESEARCH.md Pattern 2):
```swift
import Network
```

**Existing configure() pattern** (lines 64-79):
```swift
func configure(with timer: PomodoroTimer) {
    self.timer = timer
    // ...
    startPeriodicPolling()
}
```

**Modify to add:** Load action queue from Keychain, start network monitoring:
```swift
func configure(with timer: PomodoroTimer) {
    self.timer = timer
    // Load persisted action queue
    actionQueue = loadActionQueue()
    if !actionQueue.isEmpty {
        print("🔄 TIMER_SYNC_QUEUE: Loaded \(actionQueue.count) queued actions from Keychain")
    }
    startNetworkMonitoring()
    startPeriodicPolling()
}
```

**Existing polling pattern** (lines 83-97) — MODIFY interval:
```swift
// Current: 5_000_000_000 nanoseconds (5s)
// Change to: 30_000_000_000 nanoseconds (30s per D-12)
```

**Existing applyEventState pattern** (lines 224-263) — MODIFY to add timestamp check:
```swift
// Current: applies unconditionally
// Add timestamp guard (from RESEARCH.md Pitfall 2):
guard let pushTimestamp = userInfo["lastModifiedTimestamp"] as? Double else { return }
guard pushTimestamp > timer.lastModifiedTimestamp else {
    print("⏭️ TIMER_SYNC_EVENT: Push timestamp \(pushTimestamp) <= local \(timer.lastModifiedTimestamp), skipping")
    return
}
```

**Existing handleSyncFailure pattern** (lines 501-520):
```swift
private func handleSyncFailure(_ syncType: String, error: Error?) {
    syncRetryCount += 1
    syncRetryDelay = min(syncRetryDelay * 2, 30.0)
    // ...
    if syncRetryCount >= 3 {
        print("⚠️ TIMER_SYNC_FALLBACK: Triggering fallback mechanisms")
    }
}
```

**Modify to integrate backoff + alert** (from RESEARCH.md Pattern 3):
```swift
private func handleSyncFailure(_ syncType: String, error: Error?) {
    syncRetryCount += 1
    consecutiveFailures += 1
    syncRetryDelay = min(syncRetryDelay * 2, 30.0)

    if consecutiveFailures >= 3 {
        Task { @MainActor in
            SyncFailureAlertManager.shared.showAlert(
                consecutiveFailures: consecutiveFailures,
                retryAction: { [weak self] in await self?.manualRetry() }
            )
        }
    }
}

private func handleSyncSuccess() {
    syncRetryCount = 0
    consecutiveFailures = 0
    SyncFailureAlertManager.shared.dismissAlert()
}
```

**New methods to ADD:**
- `startNetworkMonitoring()` — RESEARCH.md Pattern 2, lines 260-286
- `stopNetworkMonitoring()` — RESEARCH.md Pattern 2, lines 282-286
- `drainActionQueue() async` — RESEARCH.md Pattern 1, lines 288-313
- `enqueueAction(_ action: QueuedTimerAction)` — RESEARCH.md Pattern 1, lines 209-217
- `persistActionQueue()` — RESEARCH.md Pattern 1, lines 219-227
- `loadActionQueue() -> [QueuedTimerAction]` — RESEARCH.md Pattern 1, lines 229-239
- `syncQueuedAction(_ action: QueuedTimerAction) async -> Bool` — new, maps queued action to existing `syncTimerAction`

**resetForTesting method** (from RESEARCH.md Pitfall 7):
```swift
func resetForTesting() {
    actionQueue.removeAll()
    stopNetworkMonitoring()
    consecutiveFailures = 0
    syncRetryCount = 0
    syncRetryDelay = 1.0
    isNetworkConnected = true
}
```

---

### `PushNotificationService.java` (service, event-driven) — MODIFY

**Analog:** Self — `back-end/src/main/java/com/sparkage/timebeam/infrastructure/external/PushNotificationService.java`

**Payload template to FIX** (lines 151-164):
```java
// Current (missing autoStartNextSession, shortBreaksCompleted):
String payload = String.format(
    Locale.ROOT,
    "{\"aps\":{\"content-available\":1,\"sound\":\"\"},\"type\":\"timer_sync\",\"phase\":\"%s\",\"remainingSeconds\":%d,\"isRunning\":%s,\"startTimestamp\":%f,\"pauseTimestamp\":%s,\"workDuration\":%d,\"breakDuration\":%d,\"longBreakDuration\":%d,\"deviceId\":\"%s\",\"lastModifiedTimestamp\":%f}",
    state.getPhase(),
    liveRemaining,
    isRunning,
    state.getStartTimestamp() != null ? state.getStartTimestamp() : 0.0,
    pauseTs,
    state.getWorkDuration() != null ? state.getWorkDuration() : 1500,
    state.getBreakDuration() != null ? state.getBreakDuration() : 300,
    state.getLongBreakDuration() != null ? state.getLongBreakDuration() : 900,
    state.getDeviceId(),
    lastModifiedSec
);
```

**Fix:** Add `autoStartNextSession` and `shortBreaksCompleted` fields per RESEARCH.md Pattern 4, lines 376-390.

**Logging pattern** (lines 31):
```java
private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
```

**Spring service pattern** (lines 29-30):
```java
@Service
public class PushNotificationService {
```

**Constructor injection pattern** (lines 78-80):
```java
public PushNotificationService(UserDeviceRepository userDeviceRepository) {
    this.userDeviceRepository = userDeviceRepository;
}
```

**Null-safe field access pattern** (lines 158-163):
```java
state.getWorkDuration() != null ? state.getWorkDuration() : 1500,
state.getBreakDuration() != null ? state.getBreakDuration() : 300,
state.getLongBreakDuration() != null ? state.getLongBreakDuration() : 900,
```

---

### `KeychainStore.swift` (utility, file-I/O) — MODIFY

**Analog:** Self — `apple/TimeBeam/TimeBeam/Helper/KeychainStore.swift`

**Current Item enum** (lines 5-13):
```swift
enum Item: String {
    case idToken = "com.timebeam.auth.idToken"
    case accessToken = "com.timebeam.auth.accessToken"
    case refreshToken = "com.timebeam.auth.refreshToken"
    case userDisplayName = "com.timebeam.auth.displayName"
    case userEmail = "com.timebeam.auth.email"
    case apnsToken = "com.timebeam.apns.token"
    case deviceId = "com.timebeam.app.deviceId"
}
```

**ADD:** `case actionQueue = "com.timebeam.sync.actionQueue"` for offline action persistence.

**Existing save pattern** (lines 17-40):
```swift
static func save(_ value: Data, for item: Item) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: item.rawValue
    ]
    SecItemDelete(query as CFDictionary)
    // ...
}
```

**Existing load pattern** (lines 42-65):
```swift
static func load(_ item: Item) throws -> Data? {
    // ... kSecReturnData: true ...
    if status == errSecItemNotFound { return nil }
    // ...
}
```

**Existing clear pattern** (lines 67-82):
```swift
static func clear(_ item: Item) throws {
    // ...
    guard status == errSecSuccess || status == errSecItemNotFound else {
    // ...
}
```

These static methods (save/load/clear) are already generic by `Item` type — adding a new case requires no additional method changes.

**Access group pattern** (lines 32-34):
```swift
#if os(iOS) || os(macOS)
attributes[kSecAttrAccessGroup as String] = "425MSY8FLG.com.sparkage.time-beam"
#endif
```

This pattern is already present — the new `actionQueue` item will automatically get the shared access group.

---

### `ApiClient.swift` (utility, request-response) — MODIFY

**Analog:** Self — `apple/TimeBeam/TimeBeam/Infrastructure/Networking/ApiClient.swift`

The existing file already has `pushTimerAction` (lines 321-333) and `pullTimerState` (lines 284-319). No new methods needed. The modification is minor: ensure the existing methods handle the offline queue integration.

**Existing pushTimerAction pattern** (lines 321-333):
```swift
func pushTimerAction(_ action: TimerActionDto, accessToken: String) async throws {
    guard let request = createBaseRequest(path: "api/sessions/timer/action", method: "POST", body: action, accessToken: accessToken) else {
        throw ApiError.networkError("Failed to create request")
    }
    let (_, response) = try await urlSession.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw ApiError.networkError("Invalid response type")
    }
    guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
        throw ApiError.networkError("Push timer action failed with status: \(httpResponse.statusCode)")
    }
}
```

**Existing error types** (lines 504-531):
```swift
enum ApiError: Error, LocalizedError {
    case invalidURL
    case encodingFailed(Error)
    case networkError(String)
    case authenticationFailure
    case timeoutError(String)
    case retryExceeded(String)
    case serverError(Int, String)
```

**No new methods needed.** The `TimerSyncManager` handles the network-aware routing (enqueue vs send) at a higher level. `ApiClient` remains a thin HTTP wrapper.

---

### `MacAppDelegate.swift` (service, event-driven) — MODIFY

**Analog:** Self — `apple/TimeBeam/TimeBeam/Infrastructure/External/MacAppDelegate.swift`

**Current push handler** (lines 76-85):
```swift
func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
    if let type = userInfo["type"] as? String, type == "timer_sync" {
        print("Received silent timer_sync push on macOS")
        Task { [weak self] in
            await MainActor.run {
                self?.applyStateFromPush(userInfo as [AnyHashable: Any])
            }
        }
    }
}
```

**Current applyStateFromPush** (lines 138-141):
```swift
@MainActor
private func applyStateFromPush(_ userInfo: [AnyHashable: Any]) {
    TimerSyncManager.shared.applyEventState(from: userInfo)
}
```

**WillPresent handler** (lines 98-119):
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    if let type = userInfo["type"] as? String, type == "timer_sync" {
        Task { [weak self] in
            await MainActor.run {
                self?.applyStateFromPush(userInfo)
            }
        }
        completionHandler([])
        return
    }
    completionHandler([.banner, .sound])
}
```

**Modification needed:** The existing handlers already call `applyEventState` which will have the timestamp check added. No structural changes needed in the delegate — the fix is in `TimerSyncManager.applyEventState`.

**APNs registration pattern** (lines 56-68):
```swift
@MainActor
private func registerApnsTokenWhenReady(token: String, retries: Int = 6) async {
    for attempt in 0..<retries {
        if let accessToken = AuthManager.shared.getValidAccessToken() {
            let deviceId = TimerSyncManager.shared.deviceId
            try? await ApiClient.shared.updateApnsToken(deviceId: deviceId, apnsToken: token, accessToken: accessToken)
            pendingApnsToken = nil
            return
        }
        if attempt < retries - 1 {
            try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
        }
    }
}
```

This pattern is consistent between Mac and iOS delegates — no changes needed.

---

### `iOSAppDelegate.swift` (service, event-driven) — MODIFY

**Analog:** Self — `apple/TimeBeam/TimeBeam/Infrastructure/External/iOSAppDelegate.swift`

**Current push handlers** (lines 34-77):
```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    if let type = userInfo["type"] as? String, type == "timer_sync" {
        _Concurrency.Task { [weak self] in
            await MainActor.run {
                self?.applyStateFromPush(userInfo)
            }
        }
        completionHandler([])
        return
    }
    completionHandler([.banner, .sound, .badge])
}
```

**Silent push handler** (lines 111-127):
```swift
func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if let type = userInfo["type"] as? String, type == "timer_sync" {
        _Concurrency.Task { [weak self] in
            await MainActor.run {
                self?.applyStateFromPush(userInfo)
            }
            completionHandler(.newData)
        }
        return
    }
    completionHandler(.noData)
}
```

**Modification needed:** Same as macOS — the existing handlers already route to `TimerSyncManager.applyEventState`. The fix is in the sync manager, not the delegate.

**Logging pattern** (iOS-specific, lines 39, 46, 61, 117):
```swift
AppLogger.info("Received timer sync notification on iOS (willPresent)", category: .sync)
```

Note: iOS uses `AppLogger` while macOS uses `print()`. This is an established pattern difference between platforms.

---

## Shared Patterns

### Authentication Token Access
**Source:** `apple/TimeBeam/TimeBeam/Infrastructure/External/AuthManager.swift` lines 91-117 and 144-166
**Apply to:** `TimerSyncManager.swift` (action sync, state pull), `SyncFailureAlertManager.swift` (retry)

**Pattern:** Get valid token, attempt refresh if expired:
```swift
var accessToken = AuthManager.shared.getValidAccessToken()
if accessToken == nil {
    let refreshed = await AuthManager.shared.refreshAccessToken()
    if refreshed { accessToken = AuthManager.shared.getValidAccessToken() }
}
guard let accessToken = accessToken else { return }
```

This exact pattern appears in `TimerSyncManager.swift` lines 102-107, 280-287, and 367.

---

### @MainActor for UI State Access
**Source:** `TimerSyncManager.swift` line 13, `AuthManager.swift` line 38
**Apply to:** All new service files, all component files

**Pattern:**
```swift
@MainActor
@Observable
final class TimerSyncManager {
```

And for background-to-main dispatch:
```swift
Task { @MainActor in
    SyncFailureAlertManager.shared.showAlert(...)
}
```

---

### Error Handling with LoggerStore
**Source:** `TimerSyncManager.swift` lines 501-520
**Apply to:** `TimerSyncManager.swift` modifications, `SyncFailureAlertManager.swift`

**Dual logging pattern:**
```swift
print("💥 TIMER_SYNC_ERROR: \(syncType) failed with error: \(error.localizedDescription)")
LoggerStore.timer.error("Timer sync failed - \(syncType): \(error.localizedDescription)")
```

---

### JSON Encoding/Decoding for Codable Models
**Source:** `TimerSyncManager.swift` (implicit via TimerActionDto), `SessionLogger.swift` lines 42-56
**Apply to:** `QueuedTimerAction.swift` persistence, `TimerSyncManager.swift` action queue

**Pattern from SessionLogger:**
```swift
// Save (encode)
let data = try JSONEncoder().encode(records)
try KeychainStore.save(data, for: .actionQueue)

// Load (decode)
if let data = try KeychainStore.load(.actionQueue),
   let queue = try JSONDecoder().decode([QueuedTimerAction].self, from: data) {
    return queue
}
```

---

### Swift Concurrency — async/await with Task
**Source:** Throughout `TimerSyncManager.swift`
**Apply to:** `SyncFailureAlertManager.swift`, `TimerSyncManager.swift` modifications

**Pattern — background delay:**
```swift
Task {
    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    await retrySync()
}
```

**Pattern — MainActor dispatch:**
```swift
Task { @MainActor in
    SyncFailureAlertManager.shared.showAlert(...)
}
```

---

### NWPathMonitor Network Detection
**Source:** RESEARCH.md Pattern 2 (no existing codebase analog — new capability)
**Apply to:** `TimerSyncManager.swift` modifications

This is a new import and pattern. The implementation follows Apple's Network.framework API. No existing codebase analog — the planner should use the RESEARCH.md pattern directly.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| NWPathMonitor integration | utility | event-driven | No network monitoring code exists in the codebase yet — new capability |

## Metadata

**Analog search scope:** `apple/TimeBeam/TimeBeam/Application/Services/`, `apple/TimeBeam/TimeBeam/Domain/Models/`, `apple/TimeBeam/TimeBeam/Infrastructure/`, `apple/TimeBeam/TimeBeam/Presentation/Views/Components/`, `apple/TimeBeam/TimeBeam/Helper/`, `back-end/src/main/java/com/sparkage/timebeam/infrastructure/external/`, `back-end/src/main/java/com/sparkage/timebeam/application/service/`
**Files scanned:** 15
**Pattern extraction date:** 2026-05-10

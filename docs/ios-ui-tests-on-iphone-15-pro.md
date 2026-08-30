# Run Synapse UI Tests on a Physical iPhone 15 Pro

This guide runs the Synapse iOS UI tests on the connected iPhone 15 Pro. The
test runner uses the device currently configured in
`scripts/run-on-iphone15pro.sh`.

## Prerequisites

- macOS with Xcode installed.
- The iPhone connected by USB or available over the configured network link.
- The iPhone unlocked during build, installation, and test execution.
- Developer Mode enabled on the iPhone: **Settings → Privacy & Security →
  Developer Mode**.
- The iPhone trusted by this Mac.
- A valid Apple development team selected for the `Synapse iOS` target.
- The iPhone’s iOS version supported by the installed Xcode version.

Check that Xcode can see the device:

```sh
xcrun devicectl list devices
```

If this command fails, stop here and use the **CoreDeviceService recovery**
procedure below. Running `xcodebuild test` while `devicectl` cannot enumerate
the phone will not repair the connection and can leave a misleading test
result.

Resolve the connected physical iPhone 15 Pro identifier at the start of each
test session. Do not copy or retain a stale UUID:

```sh
DEVICE_ID="$({ xcrun devicectl list devices 2>/dev/null || true; } \
  | grep -E 'available \(paired\).*iPhone 15 Pro' \
  | grep -Eo '[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}' \
  | head -n 1)"
test -n "$DEVICE_ID" || {
  echo "No available paired physical iPhone 15 Pro found; stopping."
  exit 1
}
echo "Using physical iPhone 15 Pro: $DEVICE_ID"
```

## Build, install, and launch the app

From the repository root:

```sh
./scripts/run-on-iphone15pro.sh
```

The script checks the iPhone lock state before building. If it reports that
the device is locked or CoreDevice cannot be reached, fix that connection first
and rerun the script.

The script builds the `Synapse iOS` scheme, installs the resulting app, and
launches bundle identifier `com.sparkage.synapse.ios` on the iPhone.

The build output is placed in:

```text
/tmp/synapse-iphone15pro-derived/Build/Products/Debug-iphoneos/Synapse iOS.app
```

If signing or provisioning is requested, accept the Xcode prompts and rerun
the script with the phone unlocked.

## Run all UI tests on the iPhone

```sh
xcodebuild test \
  -project apple/Synapse/Synapse.xcodeproj \
  -scheme "Synapse iOS" \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath /tmp/synapse-iphone15pro-ui-tests \
  -only-testing:SynapseUITests/GTDWorkspaceUITests \
  -allowProvisioningUpdates
```

The UI test launch configuration adds `-ui-testing`. This bypasses normal
backend/auth startup and uses a unique local SwiftData test store with CloudKit
disabled, so each fresh test-app process starts with isolated local data.

## Run one focused UI test

For example, to verify capture → Home → task details → save:

```sh
xcodebuild test \
  -project apple/Synapse/Synapse.xcodeproj \
  -scheme "Synapse iOS" \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath /tmp/synapse-iphone15pro-ui-tests-focused \
  -only-testing:SynapseUITests/GTDWorkspaceUITests/testHomeTaskOpensDetailsAndSaves \
  -allowProvisioningUpdates
```

The physical test validates capture → Home → task details → save. Swift-level
behavior tests cover editing the title and preserving the task identity.

Other useful test names are visible in:

```text
apple/Synapse/SynapseUITests/iOS/GTDWorkspaceUITests.swift
```

Use the same command and replace the value passed to `-only-testing` with the
test method you want to run.

### Physical-device text-entry note

The current connected phone reports iOS 27 build `24A5418b`, while this Mac is
running Xcode 26.5.2. On this pairing, XCTest can launch the app and drive the
UI, but `typeText` may not update a SwiftUI `TextField` binding. The capture
navigation/detail tests therefore use the explicit
`SYNAPSE_UI_TEST_CAPTURE_TITLE` fixture set by the test itself. This keeps the
physical UI test deterministic; capture classification, persistence, and
editor mutation are verified independently by `CaptureServiceTests` and
`CaptureIntentBehaviorTests`.

For full physical keyboard-entry coverage, run the same tests after updating
Xcode to the iOS 27-compatible release, or after the phone is restored to an
iOS version supported by the installed Xcode.

For the live Siri/Shortcuts and two-device CloudKit checks, follow
[Siri and CloudKit verification](siri-cloudkit-verification.md).

## Inspect failures

Test results are stored below the derived-data directory, for example:

```text
/tmp/synapse-iphone15pro-ui-tests/Logs/Test/*.xcresult
```

Print a concise summary:

```sh
xcrun xcresulttool get test-results summary \
  --path /tmp/synapse-iphone15pro-ui-tests/Logs/Test/<result>.xcresult
```

Print test-level failures:

```sh
xcrun xcresulttool get test-results tests \
  --path /tmp/synapse-iphone15pro-ui-tests/Logs/Test/<result>.xcresult
```

For screenshots and action attachments, open the `.xcresult` bundle in Xcode:

```sh
open /tmp/synapse-iphone15pro-ui-tests/Logs/Test/<result>.xcresult
```

## Common issues

### Device is locked

Unlock the iPhone and rerun the command. Keep it unlocked for the full test
run; long UI tests can fail if the device auto-locks. The corresponding
`devicectl` error is:

```text
Unable to launch com.sparkage.synapse.ios because the device was not, or could not, be unlocked.
```

Installation may succeed while launch and XCTest execution are still denied;
unlocking the phone is required for both steps.

### Device is not available

Reconnect the phone, unlock it, and check:

```sh
xcrun devicectl list devices
```

If it appears as unavailable, restart the device connection and ensure
Developer Mode remains enabled.

### `CoreDeviceService` timed out or the connection was invalidated

If `xcrun devicectl list devices` reports an XPC connection error, a
`CoreDeviceService` timeout, or says that the provisioning parameter list could
not be loaded, XCTest has not started yet. Do not diagnose this as a Synapse
test failure.

Recover in this order:

1. Stop any active Xcode test/build and close any open Simulator windows.
2. Disconnect and reconnect the iPhone directly to the Mac.
3. Unlock the iPhone, keep it awake, and accept **Trust This Computer** if it
   appears.
4. Confirm Developer Mode is still enabled.
5. Wait a few seconds, then retry:

   ```sh
   xcrun devicectl list devices
   ```

6. If the same timeout occurs, quit Xcode completely and retry the command
   from a fresh Terminal window. Xcode owns part of the device-services
   lifecycle, so closing its windows is not sufficient.
7. If the timeout still occurs, restart the iPhone, reconnect it after it has
   fully booted, unlock it, and repeat the check.
8. Once the phone is listed as `available (paired)`, rerun the build script and
   the UI-test command.

If CoreDevice still times out after the iPhone restart, restart the Mac and
reconnect the phone before trying again. Do not use the
`devicectl manage create` suggestion printed by this error: it creates a
device-management record and does not restore the unavailable CoreDevice
service. A successful `devicectl list devices` check is required before the
physical UI-test command can run.

For the exact error below, the short recovery sequence is therefore:

```text
Failed to load provisioning parameter list …
ERROR: Timed out waiting for CoreDeviceService to fully initialize
```

```sh
# Quit Xcode first, then reconnect and unlock the iPhone.
xcrun devicectl list devices

# Only after the iPhone appears as available (paired):
./scripts/run-on-iphone15pro.sh
```

### `DeviceSupport` or debugger-version warnings

These can occur when the iPhone is running a newer beta iOS build than the
installed Xcode supports. Update Xcode to the matching release/beta, then
rerun the test. A normal app build/install may still work while XCTest device
execution fails.

### Signing or provisioning errors

Open `apple/Synapse/Synapse.xcodeproj` in Xcode, select the `Synapse iOS`
target, choose the correct **Team**, and confirm the bundle identifier is
registered. Then rerun:

```sh
./scripts/run-on-iphone15pro.sh
```

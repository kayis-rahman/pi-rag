#!/bin/zsh
set -euo pipefail

PROJECT="apple/Synapse/Synapse.xcodeproj"
SCHEME="Synapse iOS"
APP_BUNDLE_ID="com.sparkage.synapse.ios"
BUILD_DERIVED_DATA="/private/tmp/synapse-iphone15pro-derived"
TEST_DERIVED_DATA="/private/tmp/synapse-iphone15pro-ui-tests"
SCRIPT_NAME="${0:t}"

usage() {
  print "Usage: ./$SCRIPT_NAME [--test [TEST_IDENTIFIER]]"
  print ""
  print "Without arguments, builds, installs, and launches Synapse."
  print "With --test, runs physical-device UI tests. TEST_IDENTIFIER defaults to:"
  print "  SynapseUITests/GTDWorkspaceUITests"
}

MODE="run"
TEST_IDENTIFIER="SynapseUITests/GTDWorkspaceUITests"
case "${1:-}" in
  "") ;;
  --test)
    MODE="test"
    TEST_IDENTIFIER="${2:-$TEST_IDENTIFIER}"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

# Resolve the currently available physical iPhone 15 Pro. Never retain a stale
# identifier and never fall back to a simulator.
DEVICE_LIST_OUTPUT="$(xcrun devicectl list devices 2>&1)" || {
  print -u2 "devicectl could not enumerate devices."
  print -u2 -- "$DEVICE_LIST_OUTPUT"
  print -u2 "Reconnect and unlock the iPhone, then rerun this command."
  exit 2
}

DEVICE_ID="$(print -r -- "$DEVICE_LIST_OUTPUT" \
  | grep -F 'available (paired)' \
  | grep -F 'iPhone 15 Pro' \
  | grep -Eo '([0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12})' \
  | head -n 1 || true)"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No available paired physical iPhone 15 Pro found; stopping." >&2
  print -u2 -- "$DEVICE_LIST_OUTPUT"
  print -u2 "The phone must show: available (paired) ... iPhone 15 Pro ... physical"
  exit 2
fi
echo "Using physical iPhone 15 Pro: $DEVICE_ID"

# devicectl and xcodebuild maintain separate device-service state. Require both
# tools to recognize the same physical destination before building or testing.
DESTINATIONS_OUTPUT="$(xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -showdestinations 2>&1)" || {
  print -u2 "xcodebuild could not enumerate destinations."
  print -u2 -- "$DESTINATIONS_OUTPUT"
  exit 2
}

if ! print -r -- "$DESTINATIONS_OUTPUT" | grep -F "platform:iOS" | grep -Fq "id:$DEVICE_ID"; then
  print -u2 "devicectl sees the iPhone, but xcodebuild does not list it as an iOS destination."
  print -u2 "Reconnect and unlock the phone, run xcodebuild -runFirstLaunch, then retry."
  print -u2 "If automation reports 'Operation not permitted' under ~/Library, grant it access"
  print -u2 "to Xcode/CoreDevice services or run this script from an unrestricted Terminal."
  exit 2
fi

echo "Checking iPhone 15 Pro lock state..."
LOCK_STATE_OUTPUT=$(xcrun devicectl device info lockState --device "$DEVICE_ID" 2>&1) || {
  echo "Unable to query the iPhone through CoreDevice. Reconnect and unlock the device, then retry." >&2
  echo "$LOCK_STATE_OUTPUT" >&2
  exit 2
}

if ! print -r -- "$LOCK_STATE_OUTPUT" | rg -q 'passcodeRequired: false'; then
  echo "iPhone 15 Pro is locked. Unlock it and keep it awake before running this script." >&2
  exit 2
fi

if [[ "$MODE" == "test" ]]; then
  echo "Running $TEST_IDENTIFIER on the physical iPhone 15 Pro..."
  echo "Result bundles will be under $TEST_DERIVED_DATA/Logs/Test"
  xcodebuild -quiet test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS,id=$DEVICE_ID" \
    -derivedDataPath "$TEST_DERIVED_DATA" \
    -allowProvisioningUpdates \
    -enableCodeCoverage NO \
    -only-testing:"$TEST_IDENTIFIER" || {
      test_exit_code=$?
      print -u2 "Physical-device test failed. This is not a simulator result."
      print -u2 "Inspect $TEST_DERIVED_DATA/Logs/Test/*.xcresult with xcresulttool."
      print -u2 "If output contains 'Operation not permitted' for ~/Library or CoreSimulator,"
      print -u2 "the runner is sandboxed; allow Xcode/CoreDevice access and rerun."
      exit "$test_exit_code"
    }
  exit 0
fi

APP_PATH="$BUILD_DERIVED_DATA/Build/Products/Debug-iphoneos/Synapse iOS.app"

xcodebuild -quiet build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$BUILD_DERIVED_DATA" \
  -allowProvisioningUpdates

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
xcrun devicectl device process launch --device "$DEVICE_ID" \
  --terminate-existing "$APP_BUNDLE_ID"

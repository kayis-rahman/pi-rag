#!/bin/zsh
set -euo pipefail

# Resolve the connected physical iPhone 15 Pro; never fall back to a simulator.
DEVICE_ID="$({ xcrun devicectl list devices 2>/dev/null || true; } \
  | grep -E 'available \(paired\).*iPhone 15 Pro' \
  | grep -Eo '[0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}' \
  | head -n 1 || true)"
if [[ -z "$DEVICE_ID" ]]; then
  echo "No available paired physical iPhone 15 Pro found; stopping." >&2
  exit 2
fi
echo "Using physical iPhone 15 Pro: $DEVICE_ID"
PROJECT="apple/Synapse/Synapse.xcodeproj"
SCHEME="Synapse iOS"
DERIVED_DATA="/tmp/synapse-iphone15pro-derived"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/Synapse iOS.app"

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

xcodebuild -quiet \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -allowProvisioningUpdates \
  build

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
xcrun devicectl device process launch --device "$DEVICE_ID" \
  --terminate-existing com.sparkage.synapse.ios

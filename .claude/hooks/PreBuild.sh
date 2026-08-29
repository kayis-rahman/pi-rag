#!/usr/bin/env bash
# Pre-build checks
# Clean derived data, verify signing, check dependencies

# Clean old build artifacts
rm -f /tmp/build.log /tmp/ios-build.log /tmp/mac-build.log

# Verify entitlements file exists
if [ ! -f "apple/TimeBeam/TimeBeam macOS.entitlements" ]; then
  echo '{"systemMessage": "Warning: TimeBeam macOS.entitlements not found"}'
fi

# Verify Xcode command line tools
if ! xcode-select -p > /dev/null 2>&1; then
  echo '{"systemMessage": "Error: Xcode command line tools not installed. Run: xcode-select --install"}'
fi

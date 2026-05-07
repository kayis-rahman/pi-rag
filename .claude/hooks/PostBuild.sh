#!/usr/bin/env bash
# Post-build verification
# Check for build artifacts, run smoke test

# Verify build log exists
if [ -f "/tmp/build.log" ]; then
  BUILD_STATUS=$(grep -c "BUILD SUCCEEDED" /tmp/build.log 2>/dev/null || echo "0")
  if [ "$BUILD_STATUS" -eq "0" ]; then
    echo '{"systemMessage": "Build may have failed. Check /tmp/build.log for details."}'
  fi
fi

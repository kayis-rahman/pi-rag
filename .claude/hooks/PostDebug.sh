#!/usr/bin/env bash
# Post-debug summary
# Extract key findings from logs

# Backend log summary
if [ -f "back-end/logs/timebeam.log" ]; then
  ERROR_COUNT=$(grep -c "ERROR" back-end/logs/timebeam.log 2>/dev/null || echo "0")
  WARN_COUNT=$(grep -c "WARN" back-end/logs/timebeam.log 2>/dev/null || echo "0")
  echo '{"systemMessage": "Backend logs: $ERROR_COUNT errors, $WARN_COUNT warnings"}'
fi

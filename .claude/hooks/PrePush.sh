#!/usr/bin/env bash
# Pre-push hook
# Verify build before push

echo "Running pre-push checks..."

# Check for hardcoded secrets
if git diff HEAD~1..HEAD | grep -iE "(password|secret|api.key|token)\s*=\s*['\"][^'\"]+['\"]" > /dev/null 2>&1; then
  echo "ERROR: Hardcoded secrets detected. Aborting push."
  exit 1
fi

# Run tests if back-end exists
if [ -d "back-end" ]; then
  echo "Running backend tests..."
  cd back-end && mvn test -q
  if [ $? -ne 0 ]; then
    echo "ERROR: Backend tests failed. Aborting push."
    exit 1
  fi
  cd ..
fi

echo "Pre-push checks passed."
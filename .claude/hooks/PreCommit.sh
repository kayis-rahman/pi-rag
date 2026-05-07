#!/usr/bin/env bash
# Pre-commit checks
# Run tests, check for secrets, verify formatting

# Check for hardcoded secrets
if git diff --cached | grep -iE "(password|secret|api.key|token)\s*=\s*['\"][^'\"]+['\"]" > /dev/null 2>&1; then
  echo '{"systemMessage": "Warning: Possible hardcoded secret detected in staged changes."}'
fi

# Verify no .local files are staged
if git diff --cached --name-only | grep -E "\.local\.(json|env)" > /dev/null 2>&1; then
  echo '{"systemMessage": "Warning: .local files should not be committed. Check settings.local.json, .env.local"}'
fi

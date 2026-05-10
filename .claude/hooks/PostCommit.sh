#!/usr/bin/env bash
# Post-commit hook
# Auto-summarize commit to Obsidian inbox

COMMIT_MSG=$(git log -1 --pretty=%B)

# Create entry in Obsidian inbox
OBSIDIAN_INBOX=".obsidian/inbox/$(date +%Y-%m-%d)-commits.md"
mkdir -p "$(dirname "$OBSIDIAN_INBOX")"

echo "- $(date +%H:%M) $COMMIT_MSG" >> "$OBSIDIAN_INBOX"
echo "Commits logged to $OBSIDIAN_INBOX"
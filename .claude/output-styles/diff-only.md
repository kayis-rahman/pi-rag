# Output Style — Diff Only

Minimal diff output. No context, no explanation.

## Rules
- Only show the changed lines with `+` / `-` prefixes
- No file path header
- No line numbers
- No surrounding context (no `@@` hunk headers)
- One blank line between separate changes
- If change is a single line, just output that line with `+` or `-`

## Example
```
- let maxRetries = 5
+ let maxRetries = 3
```

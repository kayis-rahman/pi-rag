# Synapse Development Instructions

## Physical-device-only iOS rule

All iOS builds, installs, launches, and UI-test runs must target the configured
physical iPhone 15 Pro (`00008130-000629D90A13803A`). Do not use an
iOS Simulator destination or create simulator devices. Before running, verify
that `xcrun devicectl list devices` reports the phone as available and paired.
If the physical device is unavailable, stop and fix the connection; do not
fall back to a simulator or report a simulator result as validation. Use
`scripts/run-on-iphone15pro.sh` for the standard build/install/launch flow and
the physical-device UI-test commands documented in
`docs/ios-ui-tests-on-iphone-15-pro.md`.

## UI changes

For every user-interface change—including SwiftUI layout, styling, interaction,
motion, navigation, accessibility, and UI tests—use the `emilkowalski/skills`
guidance before implementation. In this workspace, the installed Emil
Kowalski skill is `emil-design-eng` at:

`/Users/kayisrahman/.agents/skills/anthropic-skills/skills/emil-design-eng/SKILL.md`

Read the skill instructions before making the UI change, apply its principles
to the implementation, and mention any material design decisions in the final
handoff. This requirement applies to iOS, macOS, watchOS, and shared UI code.

Continue to use the Swift-specific `write-swift` skill for Swift implementation
and concurrency work when the task involves Swift code.

## Capture test requirements

Changes to Quick Capture, Inbox persistence, triage, or capture intents must
include all three test layers:

1. Unit/service tests for classification, validation, normalization, and edge
   cases.
2. SwiftData/integration tests for local persistence, duplicates, offline
   behavior, and CloudKit synchronization where applicable.
3. Physical-device UI tests for the user-visible capture flow on the configured
   iPhone 15 Pro.

Use deterministic fixtures and unique UUID markers for persisted test data.
Keep manual-only conditions such as low storage and account sign-out explicitly
documented rather than making nondeterministic tests.

# Synapse UI Guidance

## Strict physical-device-only iOS rule

All iOS builds, installs, launches, and UI-test runs must target the configured
physical iPhone 15 Pro (`EF10AF50-5F03-56B0-A662-5DFE185E0B23`). Simulator
destinations and simulator-based validation are prohibited. Before running,
verify that `xcrun devicectl list devices` reports the phone as available and
paired. If the phone is unavailable, stop and fix the connection rather than
falling back to a simulator. Use `scripts/run-on-iphone15pro.sh` and the
physical-device UI-test commands documented in
`docs/ios-ui-tests-on-iphone-15-pro.md`.

For every UI change—SwiftUI layout, styling, interaction, motion, navigation,
accessibility, or UI tests—read and apply the installed `emil-design-eng`
skill from `emilkowalski/skills` before implementation:

`/Users/kayisrahman/.agents/skills/anthropic-skills/skills/emil-design-eng/SKILL.md`

This applies to iOS, macOS, watchOS, and shared UI code. Use `write-swift` as
well for Swift implementation or concurrency work.

For Quick Capture, Inbox persistence, triage, or App Intent changes, require
three test layers: unit/service tests, SwiftData/integration tests, and
physical-device UI tests on the configured iPhone 15 Pro. Use unique UUID
fixtures for persisted data and document manual-only cases such as low storage
or account sign-out.

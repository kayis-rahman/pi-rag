# Xcode Cloud Setup

Xcode Cloud workflows are configured in Xcode/App Store Connect, not as a
YAML file in the repo. This doc records the one-time setup and what's
already committed to support it.

## What's in the repo

`apple/Synapse/ci_scripts/ci_post_clone.sh` — runs after Xcode Cloud clones
the repo, before build. Currently runs `swiftlint --strict`. Add
`ci_pre_xcodebuild.sh` / `ci_post_xcodebuild.sh` in the same directory if you
need steps before/after the build (e.g. notarization, notifications).

## One-time setup (do this in Xcode)

1. Open `apple/Synapse/Synapse.xcodeproj` in Xcode.
2. Product → Xcode Cloud → Create Workflow. Sign in with the Apple ID that
   has App Store Connect access, select the team, and let Xcode create the
   `SYNAPSE_...` Xcode Cloud App Store Connect API integration.
3. Create these workflows:

   **"iOS Unit Tests"**
   - Scheme: `Synapse iOS Unit Tests`
   - Start condition: branch changes on `main` and `develop`
   - Action: Test (iOS Simulator only — physical-device UI tests are
     excluded, see note below)
   - Post-action: none required; Xcode Cloud reports pass/fail on the PR
     automatically if you enable "Xcode Cloud" as a required check in
     GitHub branch protection.

   **"TestFlight Release"**
   - Scheme: `Synapse iOS`
   - Start condition: new tag matching `v*.*.*`
   - Action: Archive → Release (TestFlight, internal testers)
   - Post-action: TestFlight external testing group, if/when you want
     phased external rollout per `docs/RELEASING.md`.

   Optionally add a **"macOS Build"** workflow (scheme `Synapse macOS`,
   Archive action) if you want Xcode Cloud to sanity-build macOS too — it
   won't upload anywhere unless you configure a Mac distribution method.

4. Confirm signing: Xcode Cloud manages certificates/profiles automatically
   once you grant it access in the Certificates, Identifiers & Profiles
   section during workflow creation. No manual `.p12`/profile management
   needed.

## Why physical-device UI tests are NOT in Xcode Cloud

Per `CLAUDE.md`, all UI-test runs must target the paired physical iPhone
(currently `EF10AF50-5F03-56B0-A662-5DFE185E0B23` — verify this matches
`xcrun devicectl list devices` before trusting it, see note in
`docs/RELEASING.md`). Xcode Cloud only provisions simulators/cloud Macs, it
cannot attach to a specific paired physical device. So:

- Xcode Cloud runs `Synapse iOS Unit Tests` (unit/service/SwiftData tests)
  on every push — these don't need the physical device.
- `SynapseUITests` against the physical iPhone stay a **manual pre-release
  gate**: run `scripts/run-on-iphone15pro.sh` yourself locally before
  tagging a release. This can't be automated away without either relaxing
  the physical-device-only rule or adding a self-hosted Mac runner
  permanently tethered to that phone.

## Triggering a release

1. Run the physical-device UI test suite locally, confirm green.
2. Bump marketing version / build number, update `CHANGELOG.md` per
   `docs/RELEASING.md`.
3. Tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
4. Xcode Cloud's "TestFlight Release" workflow picks up the tag, archives,
   and uploads to TestFlight automatically. Check progress in the Xcode
   Cloud report tab in Xcode, or App Store Connect.

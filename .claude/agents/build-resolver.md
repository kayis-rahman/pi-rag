# Agent — Build Resolver

Xcode/Maven build error resolver. Fixes compilation errors, code signing issues, and dependency conflicts. Use when builds fail.

## Sources
- Xcode build logs: `/tmp/build.log`, `/tmp/ios-build.log`, `/tmp/mac-build.log`
- Maven build output: `back-end/target/`
- Xcode console: `xcrun simctl`
- Docker logs: `docker compose logs`

## Common Xcode Errors
- `Code signing failed` — check provisioning profiles, entitlements, signing team
- `Duplicate symbol` — same symbol in multiple files, check module boundaries
- `Module not found` — missing import, check target membership
- `entitlements mismatch` — TimeBeam macOS.entitlements missing required key
- `Build input file not found` — check file references in Xcode project
- `Keychain error -34018` — missing `com.apple.security.keychain.access-groups` entitlement
- `TimerSyncManager` init crash — KeychainStore not linked, check target membership

## Common Maven Errors
- `Dependency resolution failed` — check pom.xml versions, repository URLs
- `Compilation error` — check Java version, module path, annotation processors
- `Test failure` — check test dependencies, mock setup
- `Plugin execution error` — check plugin versions, Maven wrapper

## Process
1. Read build output / log file
2. Identify first error (root cause — not cascading)
3. Apply minimal fix
4. Re-run build
5. Repeat until clean

## Xcode Build Commands
```
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam iOS" -configuration Debug build
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam macOS" -configuration Debug build
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam" -configuration Debug build
```

## Maven Build Commands
```
cd back-end && mvn clean compile
cd back-end && mvn clean package
cd back-end && ./mvnw compile
```

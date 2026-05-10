# /clean — Clean Build Artifacts

Clean Xcode derived data and Maven build artifacts.

## Clean Xcode
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/TimeBeam-*

# Clean build folder
cd apple/TimeBeam && xcodebuild clean -project TimeBeam.xcodeproj -scheme "TimeBeam" -configuration Debug

# Or use xcodebuild -alltargets clean
cd apple/TimeBeam && xcodebuild -project TimeBeam.xcodeproj -alltargets clean
```

## Clean Maven
```bash
cd back-end && mvn clean
```

## Full Clean
```bash
# Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/TimeBeam-*

# Maven
cd back-end && mvn clean

# Remove build artifacts
rm -rf back-end/target
rm -rf apple/TimeBeam/build
```

## When to Clean

- Build errors persist after code changes
- Xcode shows stale symbols or modules
- Maven dependency resolution fails
- Pre-commit checks fail inexplicably

# /build — Build iOS/macOS app

Build iOS and macOS targets with code signing verification.

## iOS Build
```
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam iOS" -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tee /tmp/ios-build.log
```

## macOS Build
```
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam macOS" -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tee /tmp/mac-build.log
```

## Universal Build
```
xcodebuild -project apple/TimeBeam/TimeBeam.xcodeproj -scheme "TimeBeam" -configuration Debug build 2>&1 | tee /tmp/build.log
```

## Pre-build Checks
1. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/TimeBeam-*`
2. Verify signing: check `apple/TimeBeam/TimeBeam macOS.entitlements`
3. Verify Keychain entitlements: `com.apple.security.keychain.access-groups` with `425MSY8FLG.com.sparkage.time-beam`
4. Verify build settings: check `project.pbxproj` for correct bundle IDs
5. Verify API_BASE_URL in `project.pbxproj` points to correct host (localhost or piworm.local)

## Post-build
- iOS app: `~/Library/Developer/Xcode/DerivedData/TimeBeam-*/Build/Products/Debug-iphoneos/`
- macOS app: `~/Library/Developer/Xcode/DerivedData/TimeBeam-*/Build/Products/Debug/`

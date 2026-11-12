# Sending a build to TestFlight

## Once, in App Store Connect (Tom)

1. Go to appstoreconnect.apple.com, then Apps, then the + button, then New App.
2. Platform iOS. Name: Puggle (or another name if it's taken). Language: English (Australia).
3. Bundle ID: com.tomgarton.puggle. SKU: anything, for example puggle-ios.
4. In TestFlight, add yourself under Internal Testing.
5. In the CloudKit Console (icloud.developer.apple.com), open iCloud.com.tomgarton.puggle
   and choose Deploy Schema Changes, to Production. TestFlight builds sync through
   Production, so without this, nothing syncs. Repeat after adding new fields.

The app already answers the encryption question (it uses none beyond Apple's own)
and includes a privacy manifest, so uploads go straight through.

## Each build (from app/)

```
xcodebuild -project Puggle.xcodeproj -scheme Puggle -configuration Release \
  -destination generic/platform=iOS -archivePath build/Puggle.xcarchive \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/Puggle.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
```

The second command uploads to App Store Connect using the Apple ID signed in to
Xcode, and raises the build number by itself. Processing takes 5 to 30 minutes,
then the build shows in TestFlight on the phone.

## Before inviting people outside the family

- Fill in Support.email in Puggle/Features/Family/YourDataView.swift.
- Before external testers, Apple reviews the first build. It needs a privacy
  policy link.

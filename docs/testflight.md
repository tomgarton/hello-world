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

One step: `zsh tools/testflight.sh` (add `--archive-only` to stop before the upload). The note for testers is in `docs/testflight-notes.md`. The two commands it runs:

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

- Before external testers, Apple reviews the first build. It needs a privacy
  policy link.

## Checked on 14 November 2026

- The release archive builds and signs (version 0.1.0, build 1, 9.3 MB). It had stopped building: a
  debug-only mock-up file (`RefinementSheets.swift`) was being compiled into release. It is now
  left out of release builds.
- Nothing has been uploaded from this check. Whether an earlier build reached App Store Connect is
  not something the project can show: look under TestFlight in App Store Connect.

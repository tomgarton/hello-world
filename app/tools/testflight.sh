#!/bin/zsh
# Sends a build to TestFlight. Run from app/:  zsh tools/testflight.sh
# It archives a release build, then uploads it to App Store Connect with the Apple ID signed in to Xcode.
# The build number goes up by itself. `--archive-only` stops before the upload.
set -e
cd "$(dirname "$0")/.."
rm -rf build/Puggle.xcarchive build/export
echo "Archiving…"
xcodebuild -project Puggle.xcodeproj -scheme Puggle -configuration Release \
  -destination generic/platform=iOS -archivePath build/Puggle.xcarchive \
  -allowProvisioningUpdates archive | grep -E "error|ARCHIVE" || true
[[ -d build/Puggle.xcarchive/Products/Applications/Puggle.app ]] || { echo "The archive failed."; exit 1 }
if [[ "$1" == "--archive-only" ]]; then echo "Archived to build/Puggle.xcarchive. Nothing uploaded."; exit 0; fi
echo "Uploading to App Store Connect…"
xcodebuild -exportArchive -archivePath build/Puggle.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates | grep -E "error|EXPORT|Upload" || true
echo "Done. The build shows in TestFlight after Apple has processed it, usually within half an hour."

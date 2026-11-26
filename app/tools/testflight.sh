#!/bin/zsh
# Sends a build to TestFlight. Run from app/:  zsh tools/testflight.sh
# It archives a release build, then uploads it to App Store Connect. `--archive-only` stops before the upload.
#
# Signs in with an App Store Connect API key when there is one (20 November 2026), since the command line
# cannot always use the Apple Account signed in to Xcode. The key stays outside the repository:
#   ~/.appstoreconnect/private_keys/AuthKey_<KEY ID>.p8
#   ~/.appstoreconnect/puggle.env, with ASC_KEY_ID=… and ASC_ISSUER_ID=…
# Without them it falls back to the Apple Account signed in to Xcode.
set -e
cd "$(dirname "$0")/.."

auth=()
if [[ -f ~/.appstoreconnect/puggle.env ]]; then
  source ~/.appstoreconnect/puggle.env
  key=~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
  if [[ -n "$ASC_KEY_ID" && -n "$ASC_ISSUER_ID" && -f $key ]]; then
    auth=(-authenticationKeyPath $key -authenticationKeyID $ASC_KEY_ID -authenticationKeyIssuerID $ASC_ISSUER_ID)
    echo "Signing in with the App Store Connect key $ASC_KEY_ID."
  else
    echo "~/.appstoreconnect/puggle.env needs ASC_KEY_ID and ASC_ISSUER_ID, and the key file beside it. Using Xcode's account."
  fi
fi

rm -rf build/Puggle.xcarchive build/export
echo "Archiving…"
xcodebuild -project Puggle.xcodeproj -scheme Puggle -configuration Release \
  -destination generic/platform=iOS -archivePath build/Puggle.xcarchive \
  -allowProvisioningUpdates $auth archive | grep -E "error|ARCHIVE" || true
[[ -d build/Puggle.xcarchive/Products/Applications/Puggle.app ]] || { echo "The archive failed."; exit 1 }
if [[ "$1" == "--archive-only" ]]; then echo "Archived to build/Puggle.xcarchive. Nothing uploaded."; exit 0; fi
echo "Uploading to App Store Connect…"
xcodebuild -exportArchive -archivePath build/Puggle.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates $auth | grep -E "error|EXPORT|Upload" || true
echo "Done. The build shows in TestFlight after Apple has processed it, usually within half an hour."

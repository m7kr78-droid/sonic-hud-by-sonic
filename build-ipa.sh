#!/bin/sh
set -e
cd "$(dirname "$0")"
rm -rf build Payload sonic-hud.ipa
xcodebuild -project SonicHUD.xcodeproj -scheme SonicHUD -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build
APP=$(find build/Build/Products/Release-iphoneos -name "SonicHUD.app" | head -1)
test -n "$APP"
mkdir -p Payload
cp -R "$APP" Payload/
zip -yr sonic-hud.ipa Payload
ls -lh sonic-hud.ipa

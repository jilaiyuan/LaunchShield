#!/usr/bin/env bash
set -euo pipefail

# LaunchShield release packager for macOS Monterey 12.7.5+
# Requires: xcodebuild, pkgbuild, productsign, xcrun notarytool, xcrun stapler

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/LaunchShield.xcodeproj"
SCHEME_APP="LaunchShieldApp"
CONFIGURATION="Release"
VERSION="${VERSION:-1.0.0}"
BUILD_DIR="$ROOT_DIR/build/release"
ARCHIVE_PATH="$BUILD_DIR/LaunchShield.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
PAYLOAD_ROOT="$BUILD_DIR/payload"
UNSIGNED_PKG="$BUILD_DIR/LaunchShield-${VERSION}-unsigned.pkg"
SIGNED_PKG="$BUILD_DIR/LaunchShield-${VERSION}.pkg"

: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM, e.g. ABCD123456}"
: "${APPLICATION_SIGNING_IDENTITY:?Set APPLICATION_SIGNING_IDENTITY, e.g. Developer ID Application: Your Name (TEAMID)}"
: "${INSTALLER_SIGNING_IDENTITY:?Set INSTALLER_SIGNING_IDENTITY, e.g. Developer ID Installer: Your Name (TEAMID)}"
: "${NOTARY_PROFILE:?Set NOTARY_PROFILE (xcrun notarytool keychain profile)}"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Missing project: $PROJECT_PATH"
  echo "Generate it first: ./Tools/bootstrap_xcode_project.sh"
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$EXPORT_DIR" "$PAYLOAD_ROOT/Applications"

EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>teamID</key>
  <string>${DEVELOPMENT_TEAM}</string>
</dict>
</plist>
PLIST

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_APP" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$APPLICATION_SIGNING_IDENTITY" \
  MACOSX_DEPLOYMENT_TARGET=12.0

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -exportPath "$EXPORT_DIR"

APP_PATH="$(find "$EXPORT_DIR" -maxdepth 2 -name "LaunchShield.app" -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "LaunchShield.app not found in export dir"
  exit 1
fi

cp -R "$APP_PATH" "$PAYLOAD_ROOT/Applications/"

pkgbuild \
  --root "$PAYLOAD_ROOT" \
  --identifier "com.launchshield.app" \
  --version "$VERSION" \
  --install-location "/" \
  "$UNSIGNED_PKG"

productsign \
  --sign "$INSTALLER_SIGNING_IDENTITY" \
  "$UNSIGNED_PKG" \
  "$SIGNED_PKG"

xcrun notarytool submit "$SIGNED_PKG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$SIGNED_PKG"

spctl --assess --type install -vv "$SIGNED_PKG"

echo "Created notarized installer: $SIGNED_PKG"

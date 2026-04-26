#!/usr/bin/env bash
# Build, sign, notarize, and package Nomen for direct download.
#
# Required env vars (or set in ./.env at repo root):
#   DEVELOPER_ID_IDENTITY  Full identity string, e.g.
#                          "Developer ID Application: Your Name (ABC123XYZ4)"
#   DEVELOPMENT_TEAM       10-char Team ID, e.g. ABC123XYZ4
#
# Optional:
#   VERSION                Marketing version (default: today's date YYYY.MM.DD)
#   NOTARY_PROFILE         notarytool keychain profile (default: nomen-notary)
#                          See: xcrun notarytool store-credentials --help

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Source .env if present (gitignored)
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a
  source .env
  set +a
fi

: "${DEVELOPER_ID_IDENTITY:?Set DEVELOPER_ID_IDENTITY (e.g. \"Developer ID Application: Name (TEAMID)\") in .env or env}"
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM (10-char Team ID) in .env or env}"
: "${NOTARY_PROFILE:=nomen-notary}"
: "${VERSION:=$(date +%Y.%m.%d)}"

PROJECT="Nomen.xcodeproj"
SCHEME="Nomen"
BUILD_DIR="$REPO_ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Nomen.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
APP_PATH="$EXPORT_PATH/Nomen.app"
DMG_STAGE="$BUILD_DIR/dmg-source"
DMG_PATH="$BUILD_DIR/Nomen-$VERSION.dmg"

cyan() { printf "\033[36m▶ %s\033[0m\n" "$1"; }

cyan "Preflight: notary profile, codesigning identity, xcodegen"
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
  || { echo "Notary profile '$NOTARY_PROFILE' not found. Run: xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id <email> --team-id $DEVELOPMENT_TEAM --password <app-specific>"; exit 1; }
security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID_IDENTITY" \
  || { echo "Identity not found in keychain: $DEVELOPER_ID_IDENTITY"; exit 1; }
command -v xcodegen >/dev/null || { echo "xcodegen not installed (brew install xcodegen)"; exit 1; }

cyan "Regenerating Xcode project"
xcodegen generate

cyan "Archiving Release ($VERSION)"
rm -rf "$ARCHIVE_PATH"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=macOS' \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$DEVELOPER_ID_IDENTITY" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$(date +%s)" \
  | xcbeautify 2>/dev/null || true

cyan "Exporting signed .app"
mkdir -p "$BUILD_DIR"
cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$DEVELOPMENT_TEAM</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Developer ID Application</string>
</dict>
</plist>
PLIST
rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

[[ -d "$APP_PATH" ]] || { echo "Export missing: $APP_PATH"; exit 1; }

cyan "Verifying app signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

cyan "Building DMG"
rm -rf "$DMG_STAGE" "$DMG_PATH"
mkdir -p "$DMG_STAGE"
cp -R "$APP_PATH" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create \
  -volname "Nomen" \
  -srcfolder "$DMG_STAGE" \
  -ov -format UDZO \
  "$DMG_PATH"

cyan "Signing DMG"
codesign --sign "$DEVELOPER_ID_IDENTITY" --timestamp "$DMG_PATH"

cyan "Submitting to Apple notary service (this can take 1–10 min)"
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

cyan "Stapling notarization ticket"
xcrun stapler staple "$DMG_PATH"

cyan "Final Gatekeeper assessment"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG_PATH" || true
xcrun stapler validate "$DMG_PATH"

echo ""
echo "✓ Released: $DMG_PATH"
ls -lh "$DMG_PATH"
echo ""
echo "Upload this DMG to your hosting (S3, GitHub Releases, your website),"
echo "publish a download link, and you're done."

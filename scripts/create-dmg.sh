#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_ROOT/dist/qevorn.app"
VERSION="1.0.0"
DMG_PATH="$PROJECT_ROOT/dist/qevorn-v$VERSION.dmg"
STAGING_DIRECTORY="$(mktemp -d "$PROJECT_ROOT/dist/qevorn-dmg-staging.XXXXXX")"
SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -n 1)}"

if [[ -z "$SIGNING_IDENTITY" ]]; then
    print -u2 "A Developer ID Application certificate is required. Set CODE_SIGN_IDENTITY to select one."
    exit 1
fi

cleanup() {
    rm -rf "$STAGING_DIRECTORY"
}
trap cleanup EXIT

CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" "$PROJECT_ROOT/scripts/build-app.sh"
cp -R "$APP_BUNDLE" "$STAGING_DIRECTORY/qevorn.app"
ln -s /Applications "$STAGING_DIRECTORY/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "qevorn $VERSION" \
    -srcfolder "$STAGING_DIRECTORY" \
    -format UDZO \
    -ov \
    "$DMG_PATH"
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
hdiutil verify "$DMG_PATH"
print "Built $DMG_PATH"

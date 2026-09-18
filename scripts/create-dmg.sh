#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$PROJECT_ROOT/dist/qevorn.app"
VERSION="1.0.1"
DMG_PATH="$PROJECT_ROOT/dist/qevorn-v$VERSION.dmg"
STAGING_DIRECTORY="$(mktemp -d "$PROJECT_ROOT/dist/qevorn-dmg-staging.XXXXXX")"
SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' | head -n 1)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
DMG_SOURCE="$STAGING_DIRECTORY/image-root"

if [[ -z "$SIGNING_IDENTITY" ]]; then
    print -u2 "A Developer ID Application certificate is required. Set CODE_SIGN_IDENTITY to select one."
    exit 1
fi

cleanup() {
    rm -rf "$STAGING_DIRECTORY"
}
trap cleanup EXIT

CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" "$PROJECT_ROOT/scripts/build-app.sh"

if [[ -n "$NOTARY_PROFILE" ]]; then
    APP_ARCHIVE="$STAGING_DIRECTORY/qevorn-app.zip"
    ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$APP_ARCHIVE"
    xcrun notarytool submit "$APP_ARCHIVE" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait \
        --no-progress
    xcrun stapler staple "$APP_BUNDLE"
    xcrun stapler validate "$APP_BUNDLE"
    spctl --assess --type execute --verbose=4 "$APP_BUNDLE"
fi

mkdir -p "$DMG_SOURCE"
cp -R "$APP_BUNDLE" "$DMG_SOURCE/qevorn.app"
ln -s /Applications "$DMG_SOURCE/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "qevorn $VERSION" \
    -srcfolder "$DMG_SOURCE" \
    -format UDZO \
    -ov \
    "$DMG_PATH"
codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

if [[ -n "$NOTARY_PROFILE" ]]; then
    xcrun notarytool submit "$DMG_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait \
        --no-progress
    xcrun stapler staple "$DMG_PATH"
    xcrun stapler validate "$DMG_PATH"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
fi

hdiutil verify "$DMG_PATH"
print "Built $DMG_PATH"

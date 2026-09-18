#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:--}"

swift build -c release --product qevorn
BUILD_BIN_DIR="$(swift build -c release --show-bin-path)"
APP_BUNDLE="$PROJECT_ROOT/dist/qevorn.app"
CONTENTS="$APP_BUNDLE/Contents"

rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
cp "$BUILD_BIN_DIR/qevorn" "$CONTENTS/MacOS/qevorn"
RESOURCES="$CONTENTS/Resources"
BRANDING="$PROJECT_ROOT/Resources/Branding"
TEMPLATES="$PROJECT_ROOT/Resources/Templates"
ICONSET="$RESOURCES/qevorn.iconset"
RAW_ICONS="$RESOURCES/.icon-source"
ICON_PADDER="$PROJECT_ROOT/.build/qevorn-icon-pad"
mkdir -p "$RESOURCES/Branding" "$RESOURCES/Templates" "$ICONSET" "$RAW_ICONS"
swiftc "$PROJECT_ROOT/scripts/pad-icon.swift" -o "$ICON_PADDER"

# Keep both supplied logo variants available to the app for appearance changes.
# A 10% transparent safety area aligns the visual size with standard macOS Dock icons.
for appearance in light dark; do
    raw_icon="$RAW_ICONS/qevorn-$appearance.png"
    sips -s format png "$BRANDING/qevorn-$appearance.svg" --out "$raw_icon" >/dev/null
    "$ICON_PADDER" "$raw_icon" "$RESOURCES/Branding/qevorn-$appearance.png"
done
rm -rf "$RAW_ICONS"

# Rasterize the bundled Scan me SVG templates for fast native preview and export.
for template in "$TEMPLATES"/*.svg; do
    template_name="${template:t:r}"
    sips -s format png "$template" --out "$RESOURCES/Templates/$template_name.png" >/dev/null
done

# Finder and the Dock use a multi-resolution ICNS as the backward-compatible icon.
for entry in \
    '16 icon_16x16.png' \
    '32 icon_16x16@2x.png' \
    '32 icon_32x32.png' \
    '64 icon_32x32@2x.png' \
    '128 icon_128x128.png' \
    '256 icon_128x128@2x.png' \
    '256 icon_256x256.png' \
    '512 icon_256x256@2x.png' \
    '512 icon_512x512.png' \
    '1024 icon_512x512@2x.png'; do
    size="${entry%% *}"
    filename="${entry#* }"
    sips -z "$size" "$size" "$RESOURCES/Branding/qevorn-light.png" \
        --out "$ICONSET/$filename" >/dev/null
done
iconutil --convert icns --output "$RESOURCES/qevorn.icns" "$ICONSET"
rm -rf "$ICONSET"
cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>qevorn</string>
    <key>CFBundleIdentifier</key><string>com.qevorn.studio</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>qevorn</string>
    <key>CFBundleDisplayName</key><string>qevorn</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>qevorn</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    codesign --force --deep --sign - "$APP_BUNDLE"
else
    codesign --force --deep --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_BUNDLE"
fi
print "Built $APP_BUNDLE"

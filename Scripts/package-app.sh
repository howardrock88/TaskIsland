#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_VERSION="${TASKISLAND_APP_VERSION:-$VERSION}"
APP_BUILD="${TASKISLAND_APP_BUILD:-$APP_VERSION}"
APP_DISPLAY_NAME="${TASKISLAND_APP_DISPLAY_NAME:-任务岛}"
APP_DIR="$ROOT_DIR/.build/package/$APP_DISPLAY_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_SOURCE="$ROOT_DIR/Resources/AppIcon.png"
ICONSET_DIR="$ROOT_DIR/.build/package/AppIcon.iconset"
MIN_MACOS="${TASKISLAND_MIN_MACOS:-15.0}"
BUNDLE_ID="${TASKISLAND_BUNDLE_ID:-local.taskisland.app}"
DEVELOPMENT_REGION="${TASKISLAND_DEVELOPMENT_REGION:-zh_CN}"
DEFAULT_LANGUAGE="${TASKISLAND_DEFAULT_LANGUAGE:-zh-Hans}"
URL_NAME="${TASKISLAND_URL_NAME:-任务岛快捷指令}"
REMINDERS_USAGE_DESCRIPTION="${TASKISLAND_REMINDERS_USAGE_DESCRIPTION:-任务岛需要访问提醒事项，用于把本地任务导入或导出到系统提醒事项。}"
REMINDERS_FULL_ACCESS_USAGE_DESCRIPTION="${TASKISLAND_REMINDERS_FULL_ACCESS_USAGE_DESCRIPTION:-任务岛需要完整提醒事项访问权限，用于读取未完成提醒事项并把任务导出为系统提醒。}"

cd "$ROOT_DIR"
read -r -a BUILD_ARCHS <<< "${TASKISLAND_ARCHS:-$(uname -m)}"
BUILT_BINARIES=()

for ARCH in "${BUILD_ARCHS[@]}"; do
    swift build -c release --product TaskIsland --triple "$ARCH-apple-macosx$MIN_MACOS"
    ARCH_BINARY="$ROOT_DIR/.build/$ARCH-apple-macosx/release/TaskIsland"
    if [[ ! -x "$ARCH_BINARY" ]]; then
        echo "Missing release binary for $ARCH: $ARCH_BINARY" >&2
        exit 1
    fi
    BUILT_BINARIES+=("$ARCH_BINARY")
done

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

if [[ "${#BUILT_BINARIES[@]}" -gt 1 ]]; then
    lipo -create "${BUILT_BINARIES[@]}" -output "$MACOS_DIR/TaskIsland"
else
    cp "${BUILT_BINARIES[0]}" "$MACOS_DIR/TaskIsland"
fi
chmod +x "$MACOS_DIR/TaskIsland"
lipo -info "$MACOS_DIR/TaskIsland"

if [[ -f "$ICON_SOURCE" ]]; then
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"

    sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$DEVELOPMENT_REGION</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>zh-Hans</string>
        <string>en</string>
    </array>
    <key>TaskIslandDefaultLanguage</key>
    <string>$DEFAULT_LANGUAGE</string>
    <key>CFBundleExecutable</key>
    <string>TaskIsland</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_DISPLAY_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>$URL_NAME</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>taskisland</string>
            </array>
        </dict>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRemindersUsageDescription</key>
    <string>$REMINDERS_USAGE_DESCRIPTION</string>
    <key>NSRemindersFullAccessUsageDescription</key>
    <string>$REMINDERS_FULL_ACCESS_USAGE_DESCRIPTION</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if [[ "${TASKISLAND_SKIP_SIGN:-0}" == "1" ]]; then
    echo "Warning: skipped code signing. Downloaded copies will not pass Gatekeeper."
else
    SIGN_IDENTITY="${TASKISLAND_APP_SIGN_IDENTITY:--}"
    CODESIGN_ARGS=(--force --deep --sign "$SIGN_IDENTITY")

    if [[ "$SIGN_IDENTITY" != "-" ]]; then
        CODESIGN_ARGS+=(--options runtime --timestamp)
    fi

    codesign "${CODESIGN_ARGS[@]}" "$APP_DIR"
    codesign --verify --deep --strict --verbose=2 "$APP_DIR"

    if [[ "$SIGN_IDENTITY" == "-" ]]; then
        echo "Warning: app is ad-hoc signed. Set TASKISLAND_APP_SIGN_IDENTITY for distributable builds."
    fi
fi

echo "Built $APP_DIR"

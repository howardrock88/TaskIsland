#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="任务岛"
DMG_BASENAME="TaskIsland"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_DIR="$ROOT_DIR/.build/package/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
DMG_PATH="$DIST_DIR/$DMG_BASENAME-$VERSION.dmg"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/taskisland-dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

bash "$ROOT_DIR/Scripts/package-app.sh"

codesign --force --deep --sign - "$APP_DIR"

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

ditto --norsrc --noextattr --noacl "$APP_DIR" "$STAGE_DIR/$APP_NAME.app"
xattr -cr "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

echo "Built $DMG_PATH"

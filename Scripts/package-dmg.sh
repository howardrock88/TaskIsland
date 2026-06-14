#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=1

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="任务岛"
DMG_BASENAME="TaskIsland"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_DIR="$ROOT_DIR/.build/package/$APP_NAME.app"
DIST_DIR="${TASKISLAND_GITHUB_DIST_DIR:-$ROOT_DIR/dist/github}"
PACKAGE_SUFFIX="${TASKISLAND_PACKAGE_SUFFIX:-}"
DMG_PATH="$DIST_DIR/$DMG_BASENAME-$VERSION$PACKAGE_SUFFIX.dmg"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/taskisland-dmg.XXXXXX")"

cleanup() {
    rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

bash "$ROOT_DIR/Scripts/package-app.sh"

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

DMG_SIGN_IDENTITY="${TASKISLAND_DMG_SIGN_IDENTITY:-${TASKISLAND_APP_SIGN_IDENTITY:-}}"
if [[ -n "$DMG_SIGN_IDENTITY" && "$DMG_SIGN_IDENTITY" != "-" ]]; then
    codesign --force --sign "$DMG_SIGN_IDENTITY" "$DMG_PATH"
    codesign --verify --verbose=2 "$DMG_PATH"
fi

if [[ -n "${TASKISLAND_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$TASKISLAND_NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
else
    echo "Warning: DMG was not notarized. Set TASKISLAND_NOTARY_PROFILE for public distribution."
fi

echo "Built $DMG_PATH"

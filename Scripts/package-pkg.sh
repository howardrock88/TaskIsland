#!/usr/bin/env bash
set -euo pipefail
export COPYFILE_DISABLE=true
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="任务岛"
PKG_BASENAME="TaskIsland"
VERSION="0.1.0"
IDENTIFIER="local.taskisland"
APP_DIR="$ROOT_DIR/.build/package/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/taskisland-pkg.XXXXXX")"
ROOT_STAGE="$WORK_DIR/root"
SCRIPTS_DIR="$WORK_DIR/scripts"
COMPONENT_PKG="$WORK_DIR/$PKG_BASENAME-component.pkg"
PKG_PATH="$DIST_DIR/$PKG_BASENAME-$VERSION.pkg"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"

bash "$ROOT_DIR/Scripts/package-app.sh"
codesign --force --deep --sign - "$APP_DIR"
xattr -cr "$APP_DIR"

mkdir -p "$DIST_DIR" "$ROOT_STAGE/Applications" "$ROOT_STAGE/Library/LaunchAgents" "$SCRIPTS_DIR"
rm -f "$PKG_PATH"

ditto --norsrc --noextattr --noacl "$APP_DIR" "$ROOT_STAGE/Applications/$APP_NAME.app"
cat > "$ROOT_STAGE/Library/LaunchAgents/$IDENTIFIER.agent.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$IDENTIFIER.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>/Applications/$APP_NAME.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
xattr -cr "$ROOT_STAGE"
dot_clean -m "$ROOT_STAGE" >/dev/null 2>&1 || true
find "$ROOT_STAGE" -name ".DS_Store" -delete
find "$ROOT_STAGE" -name "._*" -delete

cat > "$SCRIPTS_DIR/postinstall" <<'SCRIPT'
#!/bin/sh
APP_PATH="/Applications/任务岛.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f "$APP_PATH" >/dev/null 2>&1 || true
fi
/usr/bin/mdimport "$APP_PATH" >/dev/null 2>&1 || true

CONSOLE_USER="$(/usr/bin/stat -f '%Su' /dev/console)"
if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ]; then
    USER_ID="$(/usr/bin/id -u "$CONSOLE_USER" 2>/dev/null)"
    if [ -n "$USER_ID" ]; then
        if [ -x "$LSREGISTER" ]; then
            /bin/launchctl asuser "$USER_ID" "$LSREGISTER" -f "$APP_PATH" >/dev/null 2>&1 || true
        fi
        /bin/launchctl asuser "$USER_ID" /usr/bin/mdimport "$APP_PATH" >/dev/null 2>&1 || true
        /bin/launchctl asuser "$USER_ID" /usr/bin/open -a "/Applications/任务岛.app" >/dev/null 2>&1 || true
    fi
fi
exit 0
SCRIPT
chmod +x "$SCRIPTS_DIR/postinstall"

pkgbuild \
    --root "$ROOT_STAGE" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "$IDENTIFIER.pkg" \
    --version "$VERSION" \
    --install-location "/" \
    --filter '(^|/)\._.*' \
    --filter '(^|/)\.DS_Store$' \
    "$COMPONENT_PKG"

productbuild \
    --package "$COMPONENT_PKG" \
    "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH" >/dev/null || true

echo "Built $PKG_PATH"

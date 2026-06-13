#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${TASKISLAND_APPSTORE_ASSETS_DIR:-$ROOT_DIR/dist/appstore/assets}"
SCREENSHOT_DIR="$OUTPUT_DIR/screenshots/zh-Hans"
ICON_DIR="$OUTPUT_DIR/icon"
ICON_SOURCE="$ROOT_DIR/Resources/AppIcon.png"

SCREENSHOT_WIDTH="${TASKISLAND_APPSTORE_SCREENSHOT_WIDTH:-1440}"
SCREENSHOT_HEIGHT="${TASKISLAND_APPSTORE_SCREENSHOT_HEIGHT:-900}"

SCREENSHOTS=(
    "assets/screenshots/01-floating-island.png"
    "assets/screenshots/02-task-panel.png"
    "assets/screenshots/03-quick-add.png"
    "assets/screenshots/04-task-detail.png"
    "assets/screenshots/05-task-views.png"
    "assets/screenshots/06-settings-display-capsule.png"
    "assets/screenshots/07-settings-focus-priority.png"
    "assets/screenshots/08-settings-shortcuts-data.png"
)

cd "$ROOT_DIR"

rm -rf "$OUTPUT_DIR"
mkdir -p "$SCREENSHOT_DIR" "$ICON_DIR"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "Missing app icon source: $ICON_SOURCE" >&2
    exit 1
fi

sips -z 1024 1024 "$ICON_SOURCE" --out "$ICON_DIR/AppIcon-1024.png" >/dev/null

index=1
for screenshot in "${SCREENSHOTS[@]}"; do
    if [[ ! -f "$screenshot" ]]; then
        echo "Missing screenshot source: $screenshot" >&2
        exit 1
    fi

    width="$(sips -g pixelWidth "$screenshot" 2>/dev/null | awk '/pixelWidth/{print $2}')"
    height="$(sips -g pixelHeight "$screenshot" 2>/dev/null | awk '/pixelHeight/{print $2}')"
    if [[ "$((width * 10))" -ne "$((height * 16))" ]]; then
        echo "Screenshot is not 16:10: $screenshot (${width}x${height})" >&2
        exit 1
    fi

    base_name="$(basename "$screenshot" .png)"
    clean_name="$(printf '%s' "$base_name" | sed -E 's/^[0-9]+-//')"
    output="$SCREENSHOT_DIR/$(printf '%02d' "$index")-$clean_name-${SCREENSHOT_WIDTH}x${SCREENSHOT_HEIGHT}.jpg"
    sips -z "$SCREENSHOT_HEIGHT" "$SCREENSHOT_WIDTH" -s format jpeg "$screenshot" --out "$output" >/dev/null
    index=$((index + 1))
done

cat > "$OUTPUT_DIR/README.txt" <<EOF
TaskIsland App Store assets

Generated from real UI screenshots in assets/screenshots.

Screenshots:
- ${SCREENSHOT_WIDTH}x${SCREENSHOT_HEIGHT}
- 16:10 Mac App Store screenshot ratio
- zh-Hans locale

Icon:
- icon/AppIcon-1024.png

Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

PROMO_SCRIPT="$ROOT_DIR/Scripts/prepare-appstore-promo-assets.sh"
if [[ -x "$PROMO_SCRIPT" && -d "$ROOT_DIR/dist/app-store-promo-assets" ]]; then
    "$PROMO_SCRIPT"
    cat > "$OUTPUT_DIR/README.txt" <<EOF
TaskIsland App Store assets

Assets prepared for App Store Connect.

Screenshots:
- screenshots/zh-Hans: 8 real UI screenshots, ${SCREENSHOT_WIDTH}x${SCREENSHOT_HEIGHT}
- screenshots/zh-Hans-promo: 5 Chinese promo screenshots, 2880x1800
- screenshots/en-promo: 5 English promo screenshots, 2880x1800
- all screenshot upload copies are 16:10

Icon:
- icon/AppIcon-1024.png

Videos:
- videos/zh-Hans/taskisland-app-preview-zh-Hans-1920x1080.mp4
- videos/en/taskisland-app-preview-en-1920x1080.mp4

Original promo assets:
- dist/app-store-promo-assets/

Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
fi

echo "Prepared App Store assets:"
echo "$OUTPUT_DIR"

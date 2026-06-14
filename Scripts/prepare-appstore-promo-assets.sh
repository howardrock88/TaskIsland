#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROMO_DIR="${TASKISLAND_PROMO_ASSETS_DIR:-$ROOT_DIR/dist/app-store-promo-assets}"
OUTPUT_DIR="${TASKISLAND_APPSTORE_ASSETS_DIR:-$ROOT_DIR/dist/appstore/assets}"
SCREENSHOT_WIDTH="${TASKISLAND_APPSTORE_PROMO_SCREENSHOT_WIDTH:-2880}"
SCREENSHOT_HEIGHT="${TASKISLAND_APPSTORE_PROMO_SCREENSHOT_HEIGHT:-1800}"

cd "$ROOT_DIR"

if [[ ! -d "$PROMO_DIR" ]]; then
    echo "Promo assets directory not found: $PROMO_DIR" >&2
    exit 1
fi

prepare_locale_images() {
    local locale="$1"
    local output_locale="$2"
    local image_dir="$PROMO_DIR/images/$locale"
    local output_dir="$OUTPUT_DIR/screenshots/$output_locale"

    if [[ ! -d "$image_dir" ]]; then
        echo "Promo image directory not found: $image_dir" >&2
        exit 1
    fi

    mkdir -p "$output_dir"
    rm -f "$output_dir"/*.jpg

    local image
    for image in "$image_dir"/*.png; do
        if [[ ! -f "$image" ]]; then
            echo "No promo images found in: $image_dir" >&2
            exit 1
        fi

        local width height crop_width crop_height base_name tmp_file output_file
        width="$(sips -g pixelWidth "$image" 2>/dev/null | awk '/pixelWidth/{print $2}')"
        height="$(sips -g pixelHeight "$image" 2>/dev/null | awk '/pixelHeight/{print $2}')"
        if [[ -z "$width" || -z "$height" ]]; then
            echo "Cannot read promo image dimensions: $image" >&2
            exit 1
        fi

        crop_height="$height"
        crop_width="$((height * 16 / 10))"
        if [[ "$crop_width" -gt "$width" ]]; then
            crop_width="$width"
            crop_height="$((width * 10 / 16))"
        fi

        base_name="$(basename "$image" .png)"
        tmp_file="$(mktemp "${TMPDIR:-/tmp}/taskisland-promo-${locale}-${base_name}.XXXXXX.png")"
        output_file="$output_dir/${base_name}-${SCREENSHOT_WIDTH}x${SCREENSHOT_HEIGHT}.jpg"

        sips --cropToHeightWidth "$crop_height" "$crop_width" "$image" --out "$tmp_file" >/dev/null
        sips -z "$SCREENSHOT_HEIGHT" "$SCREENSHOT_WIDTH" -s format jpeg "$tmp_file" --out "$output_file" >/dev/null
        rm -f "$tmp_file"

        local output_width output_height
        output_width="$(sips -g pixelWidth "$output_file" 2>/dev/null | awk '/pixelWidth/{print $2}')"
        output_height="$(sips -g pixelHeight "$output_file" 2>/dev/null | awk '/pixelHeight/{print $2}')"
        if [[ "$output_width" != "$SCREENSHOT_WIDTH" || "$output_height" != "$SCREENSHOT_HEIGHT" ]]; then
            echo "Unexpected output screenshot size: $output_file (${output_width}x${output_height})" >&2
            exit 1
        fi
    done
}

copy_video() {
    local locale="$1"
    local source_file="$2"
    local output_file="$3"

    if [[ ! -f "$source_file" ]]; then
        echo "Promo video not found: $source_file" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$output_file")"
    cp "$source_file" "$output_file"

    if command -v ffprobe >/dev/null 2>&1; then
        local width height duration
        width="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$output_file")"
        height="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$output_file")"
        duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$output_file")"

        if [[ "$width" != "1920" || "$height" != "1080" ]]; then
            echo "Unexpected $locale App Preview size: ${width}x${height}" >&2
            exit 1
        fi

        awk -v duration="$duration" 'BEGIN { exit !(duration >= 15 && duration <= 30) }' || {
            echo "Unexpected $locale App Preview duration: ${duration}s" >&2
            exit 1
        }
    fi
}

prepare_locale_images "zh-Hans" "zh-Hans-promo"
prepare_locale_images "en" "en-promo"

copy_video \
    "zh-Hans" \
    "$PROMO_DIR/videos/taskisland-promo-zh-Hans.mp4" \
    "$OUTPUT_DIR/videos/zh-Hans/taskisland-app-preview-zh-Hans-1920x1080.mp4"

copy_video \
    "en" \
    "$PROMO_DIR/videos/taskisland-promo-en.mp4" \
    "$OUTPUT_DIR/videos/en/taskisland-app-preview-en-1920x1080.mp4"

echo "Prepared App Store promo assets:"
echo "$OUTPUT_DIR"

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${TASKISLAND_APPSTORE_ENV:-$ROOT_DIR/AppStore/submission.env}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APPSTORE_VERSION="${TASKISLAND_APPSTORE_VERSION:-$VERSION}"
APPSTORE_BUILD="${TASKISLAND_APPSTORE_BUILD:-1}"
KIT_ROOT="${TASKISLAND_APPSTORE_UPLOAD_KIT_DIR:-$ROOT_DIR/dist/appstore/upload-kit}"
KIT_NAME="TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD-upload-kit"
KIT_DIR="$KIT_ROOT/$KIT_NAME"
ZIP_PATH="$KIT_ROOT/$KIT_NAME.zip"
PKG_PATH="$ROOT_DIR/dist/appstore/TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD.pkg"
ASSETS_DIR="$ROOT_DIR/dist/appstore/assets"

copy_if_exists() {
    local source="$1"
    local destination="$2"
    if [[ -e "$source" ]]; then
        mkdir -p "$(dirname "$destination")"
        cp -R "$source" "$destination"
    fi
}

image_dimensions() {
    local file="$1"
    local width height
    width="$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth/{print $2}')"
    height="$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight/{print $2}')"
    if [[ -n "$width" && -n "$height" ]]; then
        printf '%sx%s' "$width" "$height"
    else
        printf 'unknown'
    fi
}

video_summary() {
    local file="$1"
    local width="" height="" duration="" seconds=""
    if command -v ffprobe >/dev/null 2>&1; then
        width="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$file" 2>/dev/null || true)"
        height="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file" 2>/dev/null || true)"
        duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null || true)"
    fi
    if [[ -n "$duration" ]]; then
        seconds="$(awk -v duration="$duration" 'BEGIN { printf "%.1f", duration }')"
    fi
    if [[ -n "$width" && -n "$height" && -n "$seconds" ]]; then
        printf '%sx%s, %ss' "$width" "$height" "$seconds"
    elif [[ -n "$width" && -n "$height" ]]; then
        printf '%sx%s' "$width" "$height"
    else
        printf 'unknown'
    fi
}

cd "$ROOT_DIR"

mkdir -p "$KIT_ROOT"
rm -rf "$KIT_DIR" "$ZIP_PATH"
mkdir -p "$KIT_DIR"

copy_if_exists "$ASSETS_DIR" "$KIT_DIR/assets"

mkdir -p "$KIT_DIR/metadata"
for file in \
    AppStore/appstore-connect-copy-paste.zh-Hans.md \
    AppStore/submission-status.zh-Hans.md \
    AppStore/appstore-connect-checklist.zh-Hans.md \
    AppStore/appstore-connect-fill-guide.zh-Hans.md \
    AppStore/appstore-assets-upload-guide.zh-Hans.md \
    AppStore/appstore-upload-selection.zh-Hans.md \
    AppStore/github-publish-plan.zh-Hans.md \
    AppStore/user-only-next-actions.zh-Hans.md \
    AppStore/age-rating-answers.zh-Hans.md \
    AppStore/agreements-tax-banking-guide.zh-Hans.md \
    AppStore/finalize-after-profile.zh-Hans.md \
    AppStore/transporter-upload-guide.zh-Hans.md \
    AppStore/provisioning-profile-guide.zh-Hans.md \
    AppStore/privacy-evidence.zh-Hans.md \
    AppStore/app-review-risk-audit.zh-Hans.md \
    AppStore/export-compliance.zh-Hans.md \
    AppStore/metadata.zh-Hans.md \
    AppStore/metadata.en-US.md \
    AppStore/privacy.zh-Hans.md \
    AppStore/privacy.en-US.md \
    AppStore/review-notes.zh-Hans.md \
    AppStore/review-notes.en-US.md; do
    copy_if_exists "$ROOT_DIR/$file" "$KIT_DIR/metadata/$(basename "$file")"
done

MANIFEST_FILE="$KIT_DIR/metadata/asset-manifest.md"
cat > "$MANIFEST_FILE" <<EOF
# App Store 素材清单

生成时间：$(date '+%Y-%m-%d %H:%M:%S %Z')

## 图标

EOF

if [[ -f "$ASSETS_DIR/icon/AppIcon-1024.png" ]]; then
    icon_path="assets/icon/AppIcon-1024.png"
    icon_dimensions="$(image_dimensions "$ASSETS_DIR/icon/AppIcon-1024.png")"
    printf -- '- `%s`：%s\n' "$icon_path" "$icon_dimensions" >> "$MANIFEST_FILE"
else
    printf -- '- 未找到图标。\n' >> "$MANIFEST_FILE"
fi

cat >> "$MANIFEST_FILE" <<EOF

## 截图

EOF

if [[ -d "$ASSETS_DIR/screenshots" ]]; then
    while IFS= read -r screenshot; do
        relative_path="${screenshot#$ASSETS_DIR/}"
        dimensions="$(image_dimensions "$screenshot")"
        printf -- '- `assets/%s`：%s\n' "$relative_path" "$dimensions" >> "$MANIFEST_FILE"
    done < <(find "$ASSETS_DIR/screenshots" -type f -name '*.jpg' | sort)
else
    printf -- '- 未找到截图目录。\n' >> "$MANIFEST_FILE"
fi

cat >> "$MANIFEST_FILE" <<EOF

## App Preview 视频

EOF

if [[ -d "$ASSETS_DIR/videos" ]]; then
    while IFS= read -r video; do
        relative_path="${video#$ASSETS_DIR/}"
        summary="$(video_summary "$video")"
        printf -- '- `assets/%s`：%s\n' "$relative_path" "$summary" >> "$MANIFEST_FILE"
    done < <(find "$ASSETS_DIR/videos" -type f -name '*.mp4' | sort)
else
    printf -- '- 未找到视频目录。\n' >> "$MANIFEST_FILE"
fi

mkdir -p "$KIT_DIR/public-pages"
copy_if_exists "$ROOT_DIR/docs/index.html" "$KIT_DIR/public-pages/index.html"
copy_if_exists "$ROOT_DIR/docs/privacy.html" "$KIT_DIR/public-pages/privacy.html"
copy_if_exists "$ROOT_DIR/docs/support.html" "$KIT_DIR/public-pages/support.html"
copy_if_exists "$ROOT_DIR/docs/en" "$KIT_DIR/public-pages/en"

PACKAGE_STATUS="not included"
if [[ -n "${TASKISLAND_APPSTORE_PROVISIONING_PROFILE:-}" && -f "$PKG_PATH" ]]; then
    mkdir -p "$KIT_DIR/package"
    cp "$PKG_PATH" "$KIT_DIR/package/"
    PACKAGE_STATUS="included"
fi

cat > "$KIT_DIR/README.zh-Hans.md" <<EOF
# 任务岛 App Store 上传资料包

版本：$APPSTORE_VERSION
构建号：$APPSTORE_BUILD

## 目录

- \`assets/\`：App Store Connect 截图、图标、App Preview 视频
- \`metadata/\`：商品页文案、审核备注、隐私填写依据、操作指南
- \`public-pages/\`：当前 GitHub Pages 使用的隐私政策和支持页备份
- \`package/\`：正式上传包，仅在 provisioning profile 已配置并重新打包后才会出现

## 当前包状态

Package: $PACKAGE_STATUS

如果 \`package/\` 不存在，说明还没补齐 App Store provisioning profile。请先按：

\`metadata/provisioning-profile-guide.zh-Hans.md\`

创建并下载 \`.provisionprofile\`，再运行：

\`\`\`sh
Scripts/check-appstore-readiness.sh
Scripts/package-appstore.sh
Scripts/prepare-appstore-upload-kit.sh
\`\`\`

## App Store Connect 链接

- 首发英文隐私政策 URL：https://howardrock88.github.io/TaskIsland/en/privacy.html
- 首发英文技术支持 URL：https://howardrock88.github.io/TaskIsland/en/support.html
- 简体中文隐私政策 URL：https://howardrock88.github.io/TaskIsland/privacy.html
- 简体中文技术支持 URL：https://howardrock88.github.io/TaskIsland/support.html

## 上传顺序

1. 在 App Store Connect 创建 macOS App 记录。
2. 按 \`metadata/appstore-connect-fill-guide.zh-Hans.md\` 填 App 信息。
3. 按 \`metadata/appstore-assets-upload-guide.zh-Hans.md\` 上传视频、截图和图标。
4. 按 \`metadata/privacy-evidence.zh-Hans.md\` 填 App Privacy。
5. provisioning profile 补齐后，重新生成正式 \`.pkg\` 并上传 Transporter。
EOF

(
    cd "$KIT_DIR"
    find . -type f ! -name 'SHA256SUMS.txt' -print0 | sort -z | xargs -0 shasum -a 256 > SHA256SUMS.txt
)

(
    cd "$KIT_ROOT"
    zip -q -r -X "$ZIP_PATH" "$KIT_NAME"
)

echo "Prepared App Store upload kit:"
echo "$KIT_DIR"
echo "$ZIP_PATH"

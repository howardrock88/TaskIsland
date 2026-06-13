#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${TASKISLAND_APPSTORE_ENV:-$ROOT_DIR/AppStore/submission.env}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

VERSION_FILE="$ROOT_DIR/VERSION"
APP_SCRIPT="$ROOT_DIR/Scripts/package-app.sh"
APPSTORE_SCRIPT="$ROOT_DIR/Scripts/package-appstore.sh"
APPSTORE_ASSETS_SCRIPT="$ROOT_DIR/Scripts/prepare-appstore-assets.sh"
APPSTORE_PROMO_ASSETS_SCRIPT="$ROOT_DIR/Scripts/prepare-appstore-promo-assets.sh"
APPSTORE_UPLOAD_KIT_SCRIPT="$ROOT_DIR/Scripts/prepare-appstore-upload-kit.sh"
APPSTORE_FINALIZE_SCRIPT="$ROOT_DIR/Scripts/finalize-appstore-profile.sh"
APPSTORE_VERIFY_SCRIPT="$ROOT_DIR/Scripts/verify-appstore-package.sh"
SENSITIVE_FILES_SCRIPT="$ROOT_DIR/Scripts/check-sensitive-files.sh"
METADATA_LIMITS_SCRIPT="$ROOT_DIR/Scripts/check-appstore-metadata-limits.sh"
GITHUB_PUBLISH_SCOPE_SCRIPT="$ROOT_DIR/Scripts/preview-github-publish-scope.sh"
ASSET_SELECTION_FILE="$ROOT_DIR/AppStore/appstore-upload-selection.zh-Hans.md"
ENTITLEMENTS="$ROOT_DIR/AppStore/TaskIsland-AppStore.entitlements"
REQUIRED_METADATA_FILES=(
    "$ROOT_DIR/AppStore/metadata.zh-Hans.md"
    "$ROOT_DIR/AppStore/metadata.en-US.md"
    "$ROOT_DIR/AppStore/appstore-connect-copy-paste.zh-Hans.md"
    "$ROOT_DIR/AppStore/submission-status.zh-Hans.md"
    "$ROOT_DIR/AppStore/privacy.zh-Hans.md"
    "$ROOT_DIR/AppStore/privacy.en-US.md"
    "$ROOT_DIR/AppStore/review-notes.zh-Hans.md"
    "$ROOT_DIR/AppStore/review-notes.en-US.md"
    "$ROOT_DIR/AppStore/appstore-connect-checklist.zh-Hans.md"
    "$ROOT_DIR/AppStore/appstore-connect-fill-guide.zh-Hans.md"
    "$ROOT_DIR/AppStore/appstore-assets-upload-guide.zh-Hans.md"
    "$ROOT_DIR/AppStore/appstore-upload-selection.zh-Hans.md"
    "$ROOT_DIR/AppStore/github-publish-plan.zh-Hans.md"
    "$ROOT_DIR/AppStore/privacy-evidence.zh-Hans.md"
    "$ROOT_DIR/AppStore/app-review-risk-audit.zh-Hans.md"
    "$ROOT_DIR/AppStore/export-compliance.zh-Hans.md"
    "$ROOT_DIR/AppStore/age-rating-answers.zh-Hans.md"
    "$ROOT_DIR/AppStore/agreements-tax-banking-guide.zh-Hans.md"
    "$ROOT_DIR/AppStore/finalize-after-profile.zh-Hans.md"
    "$ROOT_DIR/AppStore/provisioning-profile-guide.zh-Hans.md"
    "$ROOT_DIR/AppStore/transporter-upload-guide.zh-Hans.md"
    "$ROOT_DIR/AppStore/user-only-next-actions.zh-Hans.md"
)
APP_NAME="${TASKISLAND_APPSTORE_BUNDLE_DISPLAY_NAME:-${TASKISLAND_APPSTORE_APP_NAME:-TaskIsland}}"
APP_DIR="$ROOT_DIR/.build/package/$APP_NAME.app"
GITHUB_DIST_DIR="$ROOT_DIR/dist/github"
APPSTORE_DIST_DIR="$ROOT_DIR/dist/appstore"
APPSTORE_ASSETS_DIR="$APPSTORE_DIST_DIR/assets"

errors=0
warnings=0

ok() {
    printf 'OK   %s\n' "$1"
}

warn() {
    warnings=$((warnings + 1))
    printf 'WARN %s\n' "$1"
}

fail() {
    errors=$((errors + 1))
    printf 'FAIL %s\n' "$1"
}

has_certificate_named() {
    local name="$1"
    local cert_output
    cert_output="$(security find-certificate -a -c "$name" -Z 2>/dev/null || true)"
    [[ -n "$cert_output" ]]
}

has_codesign_identity_named() {
    local name="$1"
    security find-identity -v -p codesigning 2>/dev/null | grep -F -- "$name" >/dev/null
}

check_url_reachable() {
    local url="$1"
    if ! command -v curl >/dev/null 2>&1; then
        return 2
    fi
    curl -fsSL --max-time 20 "$url" -o /dev/null
}

plist_print() {
    local plist="$1"
    local key="$2"
    /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

cd "$ROOT_DIR"

if [[ -f "$ENV_FILE" ]]; then
    ok "已读取 App Store 本地配置：${ENV_FILE#$ROOT_DIR/}"
else
    warn "还没有 App Store 本地配置文件，可从 AppStore/submission.env.example 复制"
fi

VERSION=""
if [[ -f "$VERSION_FILE" ]]; then
    VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
    if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ok "GitHub / 功能版本号格式正确：$VERSION"
    else
        fail "VERSION 不是 x.y.z 格式：$VERSION"
    fi
else
    fail "缺少 VERSION 文件"
fi

APPSTORE_VERSION="${TASKISLAND_APPSTORE_VERSION:-$VERSION}"
APPSTORE_BUILD="${TASKISLAND_APPSTORE_BUILD:-1}"
MIN_MACOS="${TASKISLAND_MIN_MACOS:-15.0}"
APPSTORE_ARCHS="${TASKISLAND_APPSTORE_ARCHS:-${TASKISLAND_ARCHS:-arm64 x86_64}}"
APPSTORE_PRIMARY_LOCALE="${TASKISLAND_APPSTORE_PRIMARY_LOCALE:-en-US}"
APPSTORE_DEVELOPMENT_REGION="${TASKISLAND_APPSTORE_DEVELOPMENT_REGION:-en}"
APPSTORE_DEFAULT_LANGUAGE="${TASKISLAND_APPSTORE_DEFAULT_LANGUAGE:-en}"
if [[ "$APPSTORE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ok "App Store 版本号格式正确：$APPSTORE_VERSION"
else
    fail "App Store 版本号不是 x.y.z 格式：$APPSTORE_VERSION"
fi

if [[ "$APPSTORE_BUILD" =~ ^[0-9]+([.][0-9]+){0,2}$ ]]; then
    ok "App Store 构建号格式正确：$APPSTORE_BUILD"
else
    fail "App Store 构建号格式不适合提交：$APPSTORE_BUILD"
fi

if [[ "$APPSTORE_PRIMARY_LOCALE" == "en-US" ]]; then
    ok "App Store Connect 主语言配置为 English (U.S.)"
else
    warn "App Store Connect 主语言当前不是 English (U.S.)：$APPSTORE_PRIMARY_LOCALE"
fi

if [[ "$APPSTORE_DEFAULT_LANGUAGE" == "en" ]]; then
    ok "App Store 安装包默认界面语言配置为英文"
else
    warn "App Store 安装包默认界面语言当前不是英文：$APPSTORE_DEFAULT_LANGUAGE"
fi

for script in "$APP_SCRIPT" "$APPSTORE_SCRIPT" "$APPSTORE_ASSETS_SCRIPT" "$APPSTORE_PROMO_ASSETS_SCRIPT" "$APPSTORE_UPLOAD_KIT_SCRIPT" "$APPSTORE_FINALIZE_SCRIPT" "$APPSTORE_VERIFY_SCRIPT" "$SENSITIVE_FILES_SCRIPT" "$METADATA_LIMITS_SCRIPT" "$GITHUB_PUBLISH_SCOPE_SCRIPT"; do
    if [[ -f "$script" ]]; then
        if bash -n "$script"; then
            ok "脚本语法正确：${script#$ROOT_DIR/}"
        else
            fail "脚本语法错误：${script#$ROOT_DIR/}"
        fi
        if [[ -x "$script" ]]; then
            ok "脚本可执行：${script#$ROOT_DIR/}"
        else
            warn "脚本还不是可执行文件：${script#$ROOT_DIR/}"
        fi
    else
        fail "缺少脚本：${script#$ROOT_DIR/}"
    fi
done

if [[ -x "$SENSITIVE_FILES_SCRIPT" ]]; then
    if "$SENSITIVE_FILES_SCRIPT" >/dev/null; then
        ok "敏感文件提交检查通过"
    else
        fail "敏感文件提交检查失败，请运行 Scripts/check-sensitive-files.sh 查看详情"
    fi
fi

if [[ -x "$METADATA_LIMITS_SCRIPT" ]]; then
    if "$METADATA_LIMITS_SCRIPT" >/dev/null; then
        ok "App Store 文案长度检查通过"
    else
        fail "App Store 文案长度检查失败，请运行 Scripts/check-appstore-metadata-limits.sh 查看详情"
    fi
fi

if [[ -d "$GITHUB_DIST_DIR" ]]; then
    ok "GitHub / 直接分发输出目录存在：dist/github"
else
    fail "缺少 GitHub / 直接分发输出目录：dist/github"
fi

if [[ -d "$APPSTORE_DIST_DIR" ]]; then
    ok "App Store 上传包输出目录存在：dist/appstore"
else
    fail "缺少 App Store 上传包输出目录：dist/appstore"
fi

if [[ -d "$APPSTORE_ASSETS_DIR" ]]; then
    ok "App Store 素材输出目录存在：dist/appstore/assets"
    SCREENSHOT_COUNT="$(find "$APPSTORE_ASSETS_DIR/screenshots" -type f -name '*.jpg' 2>/dev/null | wc -l | tr -d '[:space:]')"
    if [[ "$SCREENSHOT_COUNT" -gt 0 ]]; then
        ok "App Store 截图素材已生成：$SCREENSHOT_COUNT 张"
        BAD_SCREENSHOT_COUNT=0
        while IFS= read -r screenshot_file; do
            screenshot_width="$(sips -g pixelWidth "$screenshot_file" 2>/dev/null | awk '/pixelWidth/{print $2}')"
            screenshot_height="$(sips -g pixelHeight "$screenshot_file" 2>/dev/null | awk '/pixelHeight/{print $2}')"
            if [[ -z "$screenshot_width" || -z "$screenshot_height" || "$((screenshot_width * 10))" -ne "$((screenshot_height * 16))" ]]; then
                BAD_SCREENSHOT_COUNT=$((BAD_SCREENSHOT_COUNT + 1))
            fi
        done < <(find "$APPSTORE_ASSETS_DIR/screenshots" -type f -name '*.jpg' 2>/dev/null)
        if [[ "$BAD_SCREENSHOT_COUNT" -eq 0 ]]; then
            ok "App Store 截图比例均为 16:10"
        else
            fail "有 $BAD_SCREENSHOT_COUNT 张 App Store 截图不是 16:10"
        fi
    else
        warn "App Store 素材目录存在，但还没有截图；可运行 Scripts/prepare-appstore-assets.sh"
    fi

    VIDEO_COUNT="$(find "$APPSTORE_ASSETS_DIR/videos" -type f -name '*.mp4' 2>/dev/null | wc -l | tr -d '[:space:]')"
    if [[ "$VIDEO_COUNT" -gt 0 ]]; then
        ok "App Store App Preview 视频素材已生成：$VIDEO_COUNT 条"
        if command -v ffprobe >/dev/null 2>&1; then
            BAD_VIDEO_COUNT=0
            while IFS= read -r video_file; do
                video_width="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$video_file" 2>/dev/null || true)"
                video_height="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$video_file" 2>/dev/null || true)"
                video_duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video_file" 2>/dev/null || true)"
                if [[ "$video_width" != "1920" || "$video_height" != "1080" ]]; then
                    BAD_VIDEO_COUNT=$((BAD_VIDEO_COUNT + 1))
                    continue
                fi
                if ! awk -v duration="$video_duration" 'BEGIN { exit !(duration >= 15 && duration <= 30) }'; then
                    BAD_VIDEO_COUNT=$((BAD_VIDEO_COUNT + 1))
                fi
            done < <(find "$APPSTORE_ASSETS_DIR/videos" -type f -name '*.mp4' 2>/dev/null)
            if [[ "$BAD_VIDEO_COUNT" -eq 0 ]]; then
                ok "App Store App Preview 视频规格看起来可用"
            else
                fail "有 $BAD_VIDEO_COUNT 条 App Preview 视频不是 1920x1080 或时长不在 15-30 秒"
            fi
        else
            warn "未安装 ffprobe，无法自动检查 App Preview 视频时长和尺寸"
        fi
    else
        warn "还没有 App Preview 视频素材；如果要上传视频，可运行 Scripts/prepare-appstore-promo-assets.sh"
    fi
else
    warn "还没有生成 App Store 素材；可运行 Scripts/prepare-appstore-assets.sh"
fi

if [[ -f "$ASSET_SELECTION_FILE" ]]; then
    SELECTED_ZH_SCREENSHOTS="$(rg -c 'dist/appstore/assets/screenshots/(zh-Hans-promo|zh-Hans)/' "$ASSET_SELECTION_FILE" || true)"
    SELECTED_EN_SCREENSHOTS="$(rg -c 'dist/appstore/assets/screenshots/en-promo/' "$ASSET_SELECTION_FILE" || true)"
    SELECTED_ZH_VIDEOS="$(rg -c 'dist/appstore/assets/videos/zh-Hans/' "$ASSET_SELECTION_FILE" || true)"
    SELECTED_EN_VIDEOS="$(rg -c 'dist/appstore/assets/videos/en/' "$ASSET_SELECTION_FILE" || true)"

    if [[ "$SELECTED_ZH_SCREENSHOTS" -ge 1 && "$SELECTED_ZH_SCREENSHOTS" -le 10 ]]; then
        ok "简体中文最终上传截图数量符合 Apple 限制：$SELECTED_ZH_SCREENSHOTS/10"
    else
        fail "简体中文最终上传截图数量不符合 1-10 张限制：$SELECTED_ZH_SCREENSHOTS"
    fi

    if [[ "$SELECTED_EN_SCREENSHOTS" -ge 1 && "$SELECTED_EN_SCREENSHOTS" -le 10 ]]; then
        ok "英文最终上传截图数量符合 Apple 限制：$SELECTED_EN_SCREENSHOTS/10"
    else
        fail "英文最终上传截图数量不符合 1-10 张限制：$SELECTED_EN_SCREENSHOTS"
    fi

    if [[ "$SELECTED_ZH_VIDEOS" -le 3 ]]; then
        ok "简体中文 App Preview 数量符合 Apple 限制：$SELECTED_ZH_VIDEOS/3"
    else
        fail "简体中文 App Preview 数量超过 3 条：$SELECTED_ZH_VIDEOS"
    fi

    if [[ "$SELECTED_EN_VIDEOS" -le 3 ]]; then
        ok "英文 App Preview 数量符合 Apple 限制：$SELECTED_EN_VIDEOS/3"
    else
        fail "英文 App Preview 数量超过 3 条：$SELECTED_EN_VIDEOS"
    fi

    MISSING_SELECTED_ASSETS=0
    while IFS= read -r selected_asset; do
        if [[ ! -f "$ROOT_DIR/$selected_asset" ]]; then
            MISSING_SELECTED_ASSETS=$((MISSING_SELECTED_ASSETS + 1))
            fail "最终上传清单里的素材不存在：$selected_asset"
        fi
    done < <(rg -o 'dist/appstore/assets/[^` ]+' "$ASSET_SELECTION_FILE" | sort -u)
    if [[ "$MISSING_SELECTED_ASSETS" -eq 0 ]]; then
        ok "最终上传清单里的素材文件均存在"
    fi
else
    fail "缺少最终上传素材选择清单：${ASSET_SELECTION_FILE#$ROOT_DIR/}"
fi

if [[ -f "$ENTITLEMENTS" ]]; then
    if plutil -lint "$ENTITLEMENTS" >/dev/null; then
        ok "App Store 沙盒权限文件可解析"
    else
        fail "App Store 沙盒权限文件格式错误"
    fi

    if grep -q "com.apple.security.app-sandbox" "$ENTITLEMENTS"; then
        ok "已开启 App Sandbox 权限"
    else
        fail "缺少 App Sandbox 权限"
    fi

    if [[ "$(plist_print "$ENTITLEMENTS" "com.apple.security.files.user-selected.read-write")" == "true" ]]; then
        ok "已开启用户选择文件读写权限"
    else
        fail "缺少用户选择文件读写权限"
    fi

    if [[ "$(plist_print "$ENTITLEMENTS" "com.apple.security.personal-information.calendars")" == "true" ]]; then
        ok "已开启 EventKit 日历/提醒事项沙盒权限"
    else
        fail "缺少 EventKit 日历/提醒事项沙盒权限"
    fi
else
    fail "缺少 App Store 沙盒权限文件：${ENTITLEMENTS#$ROOT_DIR/}"
fi

NETWORK_OR_TRACKING_REFERENCES="$(rg -n "URLSession|NWConnection|CloudKit|Firebase|Sentry|Crashlytics|Amplitude|Mixpanel|AdMob|NSUserTrackingUsageDescription" Sources Package.swift 2>/dev/null || true)"
if [[ -z "$NETWORK_OR_TRACKING_REFERENCES" ]]; then
    ok "源码未发现网络、云同步、广告或第三方统计关键词"
else
    warn "源码出现网络/统计/广告相关关键词，请提交前复核 App Privacy"
    printf '%s\n' "$NETWORK_OR_TRACKING_REFERENCES"
fi

if rg -n "LaunchAgent|/Library/LaunchAgents" Scripts/package-appstore.sh AppStore/TaskIsland-AppStore.entitlements >/dev/null 2>&1; then
    fail "App Store 渠道脚本或权限文件不应包含 LaunchAgent 安装逻辑"
else
    ok "App Store 渠道未包含 LaunchAgent 安装逻辑"
fi

for required_file in "${REQUIRED_METADATA_FILES[@]}"; do
    if [[ -f "$required_file" ]]; then
        ok "App Store 提交文案草稿存在：${required_file#$ROOT_DIR/}"
    else
        fail "缺少 App Store 提交文案草稿：${required_file#$ROOT_DIR/}"
    fi
done

BUNDLE_ID="${TASKISLAND_BUNDLE_ID:-}"
if [[ -z "$BUNDLE_ID" ]]; then
    warn "还没有设置 TASKISLAND_BUNDLE_ID"
elif [[ "$BUNDLE_ID" == "local.taskisland.app" ]]; then
    fail "TASKISLAND_BUNDLE_ID 仍是本地占位值"
elif [[ "$BUNDLE_ID" =~ ^[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9][A-Za-z0-9-]*)+$ ]]; then
    ok "Bundle ID 格式看起来可用：$BUNDLE_ID"
else
    fail "Bundle ID 格式看起来不对：$BUNDLE_ID"
fi

APP_SIGN_IDENTITY="${TASKISLAND_APPSTORE_APP_SIGN_IDENTITY:-${TASKISLAND_APP_SIGN_IDENTITY:-}}"
if [[ -z "$APP_SIGN_IDENTITY" ]]; then
    warn "还没有设置 TASKISLAND_APPSTORE_APP_SIGN_IDENTITY"
elif has_codesign_identity_named "$APP_SIGN_IDENTITY"; then
    ok "找到 App Store 应用签名证书：$APP_SIGN_IDENTITY"
else
    fail "钥匙串里没有找到 App Store 应用签名证书：$APP_SIGN_IDENTITY"
fi

INSTALLER_SIGN_IDENTITY="${TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY:-${TASKISLAND_INSTALLER_SIGN_IDENTITY:-}}"
if [[ -z "$INSTALLER_SIGN_IDENTITY" ]]; then
    warn "还没有设置 TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY"
elif has_certificate_named "$INSTALLER_SIGN_IDENTITY"; then
    ok "找到 App Store 安装包签名证书：$INSTALLER_SIGN_IDENTITY"
else
    fail "钥匙串里没有找到 App Store 安装包签名证书：$INSTALLER_SIGN_IDENTITY"
fi

PROVISIONING_PROFILE="${TASKISLAND_APPSTORE_PROVISIONING_PROFILE:-}"
if [[ -z "$PROVISIONING_PROFILE" ]]; then
    warn "还没有设置 TASKISLAND_APPSTORE_PROVISIONING_PROFILE；正式 App Store 上传包会等 profile 配好后再生成"
elif [[ -f "$PROVISIONING_PROFILE" ]]; then
    ok "找到 App Store provisioning profile：$PROVISIONING_PROFILE"
    PROFILE_PLIST="$(mktemp "${TMPDIR:-/tmp}/taskisland-profile.XXXXXX")"
    if security cms -D -i "$PROVISIONING_PROFILE" > "$PROFILE_PLIST" 2>/dev/null; then
        ok "App Store provisioning profile 可解析"
        PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PROFILE_PLIST" 2>/dev/null || true)"
        if [[ -n "$BUNDLE_ID" && -n "$PROFILE_APP_ID" ]]; then
            if [[ "$PROFILE_APP_ID" == *".$BUNDLE_ID" ]]; then
                ok "provisioning profile 与 Bundle ID 匹配"
            else
                fail "provisioning profile 的 App ID 不匹配：$PROFILE_APP_ID"
            fi
        fi
    else
        fail "App Store provisioning profile 无法解析"
    fi
    rm -f "$PROFILE_PLIST"
else
    fail "找不到 App Store provisioning profile：$PROVISIONING_PROFILE"
fi

if [[ -z "${TASKISLAND_PRIVACY_URL:-}" ]]; then
    warn "还没有设置隐私政策 URL，对应 App Store Connect 的 App Privacy / Privacy Policy"
elif [[ "$TASKISLAND_PRIVACY_URL" == *"example.com"* ]]; then
    warn "隐私政策 URL 仍是模板占位值：$TASKISLAND_PRIVACY_URL"
else
    ok "已提供隐私政策 URL"
    if check_url_reachable "$TASKISLAND_PRIVACY_URL"; then
        ok "隐私政策 URL 可以访问"
    else
        warn "隐私政策 URL 当前无法访问，请提交前手动确认：$TASKISLAND_PRIVACY_URL"
    fi
fi

if [[ -z "${TASKISLAND_SUPPORT_URL:-}" ]]; then
    warn "还没有设置技术支持 URL，对应 App Store Connect 的 Support URL"
elif [[ "$TASKISLAND_SUPPORT_URL" == *"example.com"* ]]; then
    warn "技术支持 URL 仍是模板占位值：$TASKISLAND_SUPPORT_URL"
else
    ok "已提供技术支持 URL"
    if check_url_reachable "$TASKISLAND_SUPPORT_URL"; then
        ok "技术支持 URL 可以访问"
    else
        warn "技术支持 URL 当前无法访问，请提交前手动确认：$TASKISLAND_SUPPORT_URL"
    fi
fi

if [[ "${1:-}" == "--build-app" ]]; then
    if [[ -z "$BUNDLE_ID" || "$BUNDLE_ID" == "local.taskisland.app" ]]; then
        fail "--build-app 需要先设置正式 TASKISLAND_BUNDLE_ID"
    else
        if TASKISLAND_BUNDLE_ID="$BUNDLE_ID" TASKISLAND_APP_VERSION="$APPSTORE_VERSION" TASKISLAND_APP_BUILD="$APPSTORE_BUILD" TASKISLAND_MIN_MACOS="$MIN_MACOS" TASKISLAND_ARCHS="$APPSTORE_ARCHS" TASKISLAND_APP_DISPLAY_NAME="$APP_NAME" TASKISLAND_DEVELOPMENT_REGION="$APPSTORE_DEVELOPMENT_REGION" TASKISLAND_DEFAULT_LANGUAGE="$APPSTORE_DEFAULT_LANGUAGE" TASKISLAND_SKIP_SIGN=1 "$APP_SCRIPT" >/dev/null; then
            INFO_PLIST="$APP_DIR/Contents/Info.plist"
            BUILT_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DIR/Contents/Info.plist" 2>/dev/null || true)"
            BUILT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist" 2>/dev/null || true)"
            BUILT_BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_DIR/Contents/Info.plist" 2>/dev/null || true)"
            if [[ "$BUILT_BUNDLE_ID" == "$BUNDLE_ID" ]]; then
                ok "测试 .app 已写入正式 Bundle ID"
            else
                fail "测试 .app 的 Bundle ID 不匹配：$BUILT_BUNDLE_ID"
            fi
            if [[ "$BUILT_VERSION" == "$APPSTORE_VERSION" && "$BUILT_BUILD" == "$APPSTORE_BUILD" ]]; then
                ok "测试 .app 已写入 App Store 版本号和构建号"
            else
                fail "测试 .app 版本信息不匹配：$BUILT_VERSION ($BUILT_BUILD)"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "CFBundleDisplayName")" == "$APP_NAME" ]]; then
                ok "测试 .app 已写入 App Store 显示名称：$APP_NAME"
            else
                fail "测试 .app 显示名称不匹配"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "CFBundleDevelopmentRegion")" == "$APPSTORE_DEVELOPMENT_REGION" ]]; then
                ok "测试 .app 已写入开发语言区域：$APPSTORE_DEVELOPMENT_REGION"
            else
                fail "测试 .app 开发语言区域不匹配"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "TaskIslandDefaultLanguage")" == "$APPSTORE_DEFAULT_LANGUAGE" ]]; then
                ok "测试 .app 已写入默认界面语言：$APPSTORE_DEFAULT_LANGUAGE"
            else
                fail "测试 .app 默认界面语言不匹配"
            fi

            BUILT_MIN_MACOS="$(plist_print "$INFO_PLIST" "LSMinimumSystemVersion")"
            if [[ "$BUILT_MIN_MACOS" == "$MIN_MACOS" ]]; then
                ok "测试 .app 已写入最低 macOS 版本：$BUILT_MIN_MACOS"
            else
                fail "测试 .app 最低 macOS 版本不匹配：$BUILT_MIN_MACOS"
            fi

            BINARY_PATH="$APP_DIR/Contents/MacOS/TaskIsland"
            BUILT_ARCHS="$(lipo -archs "$BINARY_PATH" 2>/dev/null || true)"
            missing_archs=()
            for expected_arch in $APPSTORE_ARCHS; do
                if [[ " $BUILT_ARCHS " != *" $expected_arch "* ]]; then
                    missing_archs+=("$expected_arch")
                fi
            done
            if [[ "${#missing_archs[@]}" -eq 0 ]]; then
                ok "测试 .app 架构符合 App Store 配置：$BUILT_ARCHS"
            else
                fail "测试 .app 缺少架构：${missing_archs[*]}，实际为 ${BUILT_ARCHS:-empty}"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "LSApplicationCategoryType")" == "public.app-category.productivity" ]]; then
                ok "测试 .app 已写入效率分类"
            else
                fail "测试 .app 缺少效率分类"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "CFBundleURLTypes:0:CFBundleURLSchemes:0")" == "taskisland" ]]; then
                ok "测试 .app 已写入 taskisland URL Scheme"
            else
                fail "测试 .app 缺少 taskisland URL Scheme"
            fi

            if [[ -n "$(plist_print "$INFO_PLIST" "NSRemindersUsageDescription")" ]]; then
                ok "测试 .app 已写入提醒事项权限说明"
            else
                fail "测试 .app 缺少 NSRemindersUsageDescription"
            fi

            if [[ -n "$(plist_print "$INFO_PLIST" "NSRemindersFullAccessUsageDescription")" ]]; then
                ok "测试 .app 已写入提醒事项完整访问权限说明"
            else
                fail "测试 .app 缺少 NSRemindersFullAccessUsageDescription"
            fi

            if [[ "$(plist_print "$INFO_PLIST" "ITSAppUsesNonExemptEncryption")" == "false" ]]; then
                ok "测试 .app 已声明不使用非豁免加密"
            else
                fail "测试 .app 缺少 ITSAppUsesNonExemptEncryption=false"
            fi
        else
            fail "测试 .app 构建失败"
        fi
    fi
fi

printf '\nResult: %d error(s), %d warning(s)\n' "$errors" "$warnings"

if [[ "$errors" -gt 0 ]]; then
    exit 1
fi

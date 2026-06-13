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
BUNDLE_ID="${TASKISLAND_BUNDLE_ID:-}"
MIN_MACOS="${TASKISLAND_MIN_MACOS:-15.0}"
APPSTORE_ARCHS="${TASKISLAND_APPSTORE_ARCHS:-${TASKISLAND_ARCHS:-arm64 x86_64}}"
APP_NAME="${TASKISLAND_APPSTORE_BUNDLE_DISPLAY_NAME:-${TASKISLAND_APPSTORE_APP_NAME:-TaskIsland}}"
APPSTORE_DEVELOPMENT_REGION="${TASKISLAND_APPSTORE_DEVELOPMENT_REGION:-en}"
APPSTORE_DEFAULT_LANGUAGE="${TASKISLAND_APPSTORE_DEFAULT_LANGUAGE:-en}"
APP_SIGN_IDENTITY="${TASKISLAND_APPSTORE_APP_SIGN_IDENTITY:-${TASKISLAND_APP_SIGN_IDENTITY:-}}"
INSTALLER_SIGN_IDENTITY="${TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY:-${TASKISLAND_INSTALLER_SIGN_IDENTITY:-}}"
APP_DIR="${TASKISLAND_APPSTORE_APP_DIR:-$ROOT_DIR/.build/package/$APP_NAME.app}"
PKG_PATH="${TASKISLAND_APPSTORE_PKG_PATH:-$ROOT_DIR/dist/appstore/TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD.pkg}"
INFO_PLIST="$APP_DIR/Contents/Info.plist"
EMBEDDED_PROFILE="$APP_DIR/Contents/embedded.provisionprofile"

ok() {
    printf 'OK   %s\n' "$1"
}

fail() {
    printf 'FAIL %s\n' "$1" >&2
    exit 1
}

plist_print() {
    local plist="$1"
    local key="$2"
    /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

normalize_sha1() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]' | tr -d ':[:space:]'
}

certificate_sha1_for_identity() {
    local identity="$1"
    local cert_output sha1
    if [[ "$identity" =~ ^[0-9A-Fa-f]{40}$ ]]; then
        normalize_sha1 "$identity"
        return 0
    fi

    cert_output="$(security find-certificate -a -Z -c "$identity" 2>/dev/null || true)"
    sha1="$(printf '%s\n' "$cert_output" | awk '/SHA-1 hash:/{print $3; exit}')"
    normalize_sha1 "$sha1"
}

profile_contains_certificate_sha1() {
    local profile_plist="$1"
    local expected_sha1="$2"
    local index=0 cert_base64 cert_der cert_sha1

    while cert_base64="$(plutil -extract "DeveloperCertificates.$index" raw -o - "$profile_plist" 2>/dev/null)"; do
        cert_der="$(mktemp "${TMPDIR:-/tmp}/taskisland-profile-cert.XXXXXX")"
        printf '%s' "$cert_base64" | base64 -D > "$cert_der"
        cert_sha1="$(openssl x509 -inform DER -in "$cert_der" -noout -fingerprint -sha1 2>/dev/null | sed 's/^.*=//')"
        rm -f "$cert_der"
        if [[ "$(normalize_sha1 "$cert_sha1")" == "$expected_sha1" ]]; then
            return 0
        fi
        index=$((index + 1))
    done

    return 1
}

require_plist_value() {
    local plist="$1"
    local key="$2"
    local expected="$3"
    local label="$4"
    local actual
    actual="$(plist_print "$plist" "$key")"
    if [[ "$actual" == "$expected" ]]; then
        ok "$label：$actual"
    else
        fail "$label 不匹配，期望 $expected，实际 ${actual:-empty}"
    fi
}

[[ -n "$BUNDLE_ID" ]] || fail "缺少 TASKISLAND_BUNDLE_ID"
[[ -n "$APP_SIGN_IDENTITY" ]] || fail "缺少 TASKISLAND_APPSTORE_APP_SIGN_IDENTITY"
[[ -d "$APP_DIR" ]] || fail "找不到 .app：$APP_DIR"
[[ -f "$INFO_PLIST" ]] || fail "找不到 Info.plist：$INFO_PLIST"
[[ -f "$EMBEDDED_PROFILE" ]] || fail "找不到 embedded.provisionprofile：$EMBEDDED_PROFILE"
[[ -f "$PKG_PATH" ]] || fail "找不到 .pkg：$PKG_PATH"

require_plist_value "$INFO_PLIST" "CFBundleIdentifier" "$BUNDLE_ID" "Bundle ID"
require_plist_value "$INFO_PLIST" "CFBundleShortVersionString" "$APPSTORE_VERSION" "版本号"
require_plist_value "$INFO_PLIST" "CFBundleVersion" "$APPSTORE_BUILD" "构建号"
require_plist_value "$INFO_PLIST" "CFBundleDisplayName" "$APP_NAME" "App 显示名称"
require_plist_value "$INFO_PLIST" "CFBundleDevelopmentRegion" "$APPSTORE_DEVELOPMENT_REGION" "开发语言区域"
require_plist_value "$INFO_PLIST" "TaskIslandDefaultLanguage" "$APPSTORE_DEFAULT_LANGUAGE" "默认界面语言"
require_plist_value "$INFO_PLIST" "LSMinimumSystemVersion" "$MIN_MACOS" "最低 macOS 版本"
require_plist_value "$INFO_PLIST" "LSApplicationCategoryType" "public.app-category.productivity" "App 分类"
require_plist_value "$INFO_PLIST" "CFBundleURLTypes:0:CFBundleURLSchemes:0" "taskisland" "URL Scheme"
require_plist_value "$INFO_PLIST" "ITSAppUsesNonExemptEncryption" "false" "非豁免加密声明"

BINARY_PATH="$APP_DIR/Contents/MacOS/TaskIsland"
BUILT_ARCHS="$(lipo -archs "$BINARY_PATH" 2>/dev/null || true)"
for expected_arch in $APPSTORE_ARCHS; do
    [[ " $BUILT_ARCHS " == *" $expected_arch "* ]] || fail "应用二进制缺少架构 $expected_arch，实际为 ${BUILT_ARCHS:-empty}"
done
ok "应用二进制架构：$BUILT_ARCHS"

[[ -n "$(plist_print "$INFO_PLIST" "NSRemindersUsageDescription")" ]] || fail "缺少 NSRemindersUsageDescription"
ok "已写入 NSRemindersUsageDescription"
[[ -n "$(plist_print "$INFO_PLIST" "NSRemindersFullAccessUsageDescription")" ]] || fail "缺少 NSRemindersFullAccessUsageDescription"
ok "已写入 NSRemindersFullAccessUsageDescription"

PROFILE_PLIST="$(mktemp "${TMPDIR:-/tmp}/taskisland-embedded-profile.XXXXXX")"
ENTITLEMENTS_PLIST="$(mktemp "${TMPDIR:-/tmp}/taskisland-entitlements.XXXXXX")"
SIGNATURE_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/taskisland-pkg-signature.XXXXXX")"
trap 'rm -f "$PROFILE_PLIST" "$ENTITLEMENTS_PLIST" "$SIGNATURE_OUTPUT"' EXIT

security cms -D -i "$EMBEDDED_PROFILE" > "$PROFILE_PLIST" 2>/dev/null || fail "embedded.provisionprofile 无法解析"
ok "embedded.provisionprofile 可解析"

APP_SIGN_SHA1="$(certificate_sha1_for_identity "$APP_SIGN_IDENTITY")"
[[ -n "$APP_SIGN_SHA1" ]] || fail "无法解析 App 签名证书指纹：$APP_SIGN_IDENTITY"
if profile_contains_certificate_sha1 "$PROFILE_PLIST" "$APP_SIGN_SHA1"; then
    ok "embedded.provisionprofile 包含 App 签名证书：$APP_SIGN_SHA1"
else
    fail "embedded.provisionprofile 不包含 App 签名证书：$APP_SIGN_SHA1"
fi

PROFILE_APP_ID="$(plist_print "$PROFILE_PLIST" "Entitlements:application-identifier")"
if [[ "$PROFILE_APP_ID" == *".$BUNDLE_ID" ]]; then
    ok "embedded profile App ID 匹配：$PROFILE_APP_ID"
else
    fail "embedded profile App ID 不匹配：${PROFILE_APP_ID:-empty}"
fi

if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$PROFILE_PLIST" >/dev/null 2>&1; then
    fail "embedded profile 包含设备列表，疑似开发/Ad Hoc profile，不适合作为 Mac App Store 上传包"
fi
ok "embedded profile 未包含设备列表"

codesign --verify --deep --strict --verbose=2 "$APP_DIR" >/dev/null
ok ".app 代码签名验证通过"

codesign --display --entitlements :- "$APP_DIR" > "$ENTITLEMENTS_PLIST" 2>/dev/null || fail "无法读取 .app entitlements"
require_plist_value "$ENTITLEMENTS_PLIST" "com.apple.security.app-sandbox" "true" "App Sandbox"
require_plist_value "$ENTITLEMENTS_PLIST" "com.apple.security.files.user-selected.read-write" "true" "用户选择文件读写"
require_plist_value "$ENTITLEMENTS_PLIST" "com.apple.security.personal-information.calendars" "true" "EventKit 日历/提醒事项权限"

if find "$APP_DIR" \( -name ".DS_Store" -o -name "._*" \) -print -quit | grep -q .; then
    fail ".app 内仍有 .DS_Store 或 AppleDouble 资源叉文件"
fi
ok ".app 内未发现 .DS_Store 或 AppleDouble 文件"

pkgutil --check-signature "$PKG_PATH" > "$SIGNATURE_OUTPUT"
ok ".pkg 签名验证通过"

if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
    if grep -F -- "$INSTALLER_SIGN_IDENTITY" "$SIGNATURE_OUTPUT" >/dev/null; then
        ok ".pkg 使用预期安装包证书：$INSTALLER_SIGN_IDENTITY"
    else
        fail ".pkg 签名证书不是预期的安装包证书：$INSTALLER_SIGN_IDENTITY"
    fi
fi

if pkgutil --payload-files "$PKG_PATH" >/dev/null 2>&1; then
    if pkgutil --payload-files "$PKG_PATH" | grep -F "$APP_NAME.app/Contents/MacOS/TaskIsland" >/dev/null; then
        ok ".pkg payload 包含 $APP_NAME.app"
    else
        fail ".pkg payload 未找到 $APP_NAME.app"
    fi
else
    ok "当前系统无法展开检查 payload，已跳过 payload 明细检查"
fi

echo
echo "Verified Mac App Store package:"
echo "$PKG_PATH"

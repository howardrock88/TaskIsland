#!/usr/bin/env bash
set -euo pipefail

export COPYFILE_DISABLE=true
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${TASKISLAND_APPSTORE_ENV:-$ROOT_DIR/AppStore/submission.env}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

APP_NAME="${TASKISLAND_APPSTORE_BUNDLE_DISPLAY_NAME:-${TASKISLAND_APPSTORE_APP_NAME:-TaskIsland}}"
PKG_BASENAME="TaskIsland-AppStore"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APPSTORE_VERSION="${TASKISLAND_APPSTORE_VERSION:-$VERSION}"
APPSTORE_BUILD="${TASKISLAND_APPSTORE_BUILD:-1}"
APP_DIR="$ROOT_DIR/.build/package/$APP_NAME.app"
DIST_DIR="${TASKISLAND_APPSTORE_DIST_DIR:-$ROOT_DIR/dist/appstore}"
ENTITLEMENTS="$ROOT_DIR/AppStore/TaskIsland-AppStore.entitlements"
PKG_PATH="$DIST_DIR/$PKG_BASENAME-$APPSTORE_VERSION-b$APPSTORE_BUILD.pkg"

BUNDLE_ID="${TASKISLAND_BUNDLE_ID:-}"
APP_SIGN_IDENTITY="${TASKISLAND_APPSTORE_APP_SIGN_IDENTITY:-${TASKISLAND_APP_SIGN_IDENTITY:-}}"
INSTALLER_SIGN_IDENTITY="${TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY:-${TASKISLAND_INSTALLER_SIGN_IDENTITY:-}}"
MIN_MACOS="${TASKISLAND_MIN_MACOS:-15.0}"
APPSTORE_ARCHS="${TASKISLAND_APPSTORE_ARCHS:-${TASKISLAND_ARCHS:-arm64 x86_64}}"
PROVISIONING_PROFILE="${TASKISLAND_APPSTORE_PROVISIONING_PROFILE:-}"

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

if [[ -z "$BUNDLE_ID" ]]; then
    echo "Missing TASKISLAND_BUNDLE_ID, for example: com.yourname.TaskIsland" >&2
    exit 1
fi

if [[ -z "$APP_SIGN_IDENTITY" ]]; then
    echo "Missing TASKISLAND_APPSTORE_APP_SIGN_IDENTITY." >&2
    echo "Use your Mac App Store application signing certificate from Keychain." >&2
    exit 1
fi

if [[ -z "$INSTALLER_SIGN_IDENTITY" ]]; then
    echo "Missing TASKISLAND_APPSTORE_INSTALLER_SIGN_IDENTITY." >&2
    echo "Use your Mac App Store installer signing certificate from Keychain." >&2
    exit 1
fi

if [[ ! -f "$ENTITLEMENTS" ]]; then
    echo "Missing entitlements file: $ENTITLEMENTS" >&2
    exit 1
fi

if [[ -n "$PROVISIONING_PROFILE" && ! -f "$PROVISIONING_PROFILE" ]]; then
    echo "Missing provisioning profile: $PROVISIONING_PROFILE" >&2
    exit 1
fi

if [[ -z "$PROVISIONING_PROFILE" ]]; then
    echo "Missing TASKISLAND_APPSTORE_PROVISIONING_PROFILE." >&2
    echo "Create and download the Mac App Store provisioning profile first, then set its absolute path in AppStore/submission.env." >&2
    exit 1
fi

if [[ -n "$PROVISIONING_PROFILE" ]]; then
    PROFILE_PLIST="$(mktemp "${TMPDIR:-/tmp}/taskisland-profile.XXXXXX")"
    trap 'rm -f "$PROFILE_PLIST"' EXIT
    if ! security cms -D -i "$PROVISIONING_PROFILE" > "$PROFILE_PLIST"; then
        echo "Provisioning profile cannot be decoded: $PROVISIONING_PROFILE" >&2
        exit 1
    fi
    PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PROFILE_PLIST" 2>/dev/null || true)"
    if [[ "$PROFILE_APP_ID" != *".$BUNDLE_ID" ]]; then
        echo "Provisioning profile App ID does not match $BUNDLE_ID: ${PROFILE_APP_ID:-empty}" >&2
        exit 1
    fi
    if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$PROFILE_PLIST" >/dev/null 2>&1; then
        echo "Provisioning profile contains devices. Use a Mac App Store distribution profile, not a development or Ad Hoc profile." >&2
        exit 1
    fi
    APP_SIGN_SHA1="$(certificate_sha1_for_identity "$APP_SIGN_IDENTITY")"
    if [[ -z "$APP_SIGN_SHA1" ]]; then
        echo "Could not resolve SHA-1 hash for app signing certificate: $APP_SIGN_IDENTITY" >&2
        exit 1
    fi
    if ! profile_contains_certificate_sha1 "$PROFILE_PLIST" "$APP_SIGN_SHA1"; then
        echo "Provisioning profile does not include the configured app signing certificate: $APP_SIGN_SHA1" >&2
        echo "Create the profile again and select the matching Mac App Distribution certificate." >&2
        exit 1
    fi
fi

cd "$ROOT_DIR"

TASKISLAND_BUNDLE_ID="$BUNDLE_ID" \
TASKISLAND_APP_VERSION="$APPSTORE_VERSION" \
TASKISLAND_APP_BUILD="$APPSTORE_BUILD" \
TASKISLAND_MIN_MACOS="$MIN_MACOS" \
TASKISLAND_ARCHS="$APPSTORE_ARCHS" \
TASKISLAND_APP_DISPLAY_NAME="$APP_NAME" \
TASKISLAND_DEVELOPMENT_REGION="${TASKISLAND_APPSTORE_DEVELOPMENT_REGION:-en}" \
TASKISLAND_DEFAULT_LANGUAGE="${TASKISLAND_APPSTORE_DEFAULT_LANGUAGE:-en}" \
TASKISLAND_URL_NAME="${TASKISLAND_APPSTORE_URL_NAME:-TaskIsland Shortcuts}" \
TASKISLAND_REMINDERS_USAGE_DESCRIPTION="${TASKISLAND_APPSTORE_REMINDERS_USAGE_DESCRIPTION:-TaskIsland needs access to Reminders only when you import local tasks from Apple Reminders or export tasks to Apple Reminders.}" \
TASKISLAND_REMINDERS_FULL_ACCESS_USAGE_DESCRIPTION="${TASKISLAND_APPSTORE_REMINDERS_FULL_ACCESS_USAGE_DESCRIPTION:-TaskIsland needs full Reminders access to read incomplete reminders during import and create reminders during export.}" \
TASKISLAND_SKIP_SIGN=1 \
    bash "$ROOT_DIR/Scripts/package-app.sh"

if [[ -n "$PROVISIONING_PROFILE" ]]; then
    cp "$PROVISIONING_PROFILE" "$APP_DIR/Contents/embedded.provisionprofile"
fi

xattr -cr "$APP_DIR"
dot_clean -m "$APP_DIR" >/dev/null 2>&1 || true
find "$APP_DIR" -name ".DS_Store" -delete
find "$APP_DIR" -name "._*" -delete

codesign \
    --force \
    --deep \
    --sign "$APP_SIGN_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    "$APP_DIR"

codesign --verify --deep --strict --verbose=2 "$APP_DIR"
codesign --display --entitlements :- "$APP_DIR" >/dev/null

mkdir -p "$DIST_DIR"
rm -f "$PKG_PATH"

productbuild \
    --component "$APP_DIR" \
    /Applications \
    --sign "$INSTALLER_SIGN_IDENTITY" \
    "$PKG_PATH"

pkgutil --check-signature "$PKG_PATH"
"$ROOT_DIR/Scripts/verify-appstore-package.sh"

echo "Built Mac App Store upload package: $PKG_PATH"
echo "Upload it with Transporter or App Store Connect after creating the app record."

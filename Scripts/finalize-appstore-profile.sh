#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${TASKISLAND_APPSTORE_ENV:-$ROOT_DIR/AppStore/submission.env}"
ENV_TEMPLATE="$ROOT_DIR/AppStore/submission.env.example"
PROFILE_SOURCE="${1:-${TASKISLAND_PROFILE_SOURCE:-}}"
PROFILE_DEST="${TASKISLAND_APPSTORE_PROFILE_DEST:-$ROOT_DIR/证书/TaskIsland_Mac_App_Store.provisionprofile}"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

BUNDLE_ID="${TASKISLAND_BUNDLE_ID:-com.yuxiao.TaskIsland}"
APPSTORE_VERSION="${TASKISLAND_APPSTORE_VERSION:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
APPSTORE_BUILD="${TASKISLAND_APPSTORE_BUILD:-1}"
APP_DIR="$ROOT_DIR/.build/package/任务岛.app"
PKG_PATH="$ROOT_DIR/dist/appstore/TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD.pkg"
KIT_ZIP="$ROOT_DIR/dist/appstore/upload-kit/TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD-upload-kit.zip"

find_profile_candidates() {
    find "$ROOT_DIR/证书" "$HOME/Downloads" -maxdepth 3 -type f -name '*.provisionprofile' -print 2>/dev/null | sort
}

quote_env_value() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '"%s"' "$value"
}

set_env_value() {
    local key="$1"
    local value="$2"
    local quoted
    quoted="$(quote_env_value "$value")"

    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "$ENV_TEMPLATE" ]]; then
            cp "$ENV_TEMPLATE" "$ENV_FILE"
        else
            touch "$ENV_FILE"
        fi
    fi

    if grep -q "^$key=" "$ENV_FILE"; then
        perl -0pi -e "s#^$key=.*#$key=$quoted#m" "$ENV_FILE"
    else
        printf '%s=%s\n' "$key" "$quoted" >> "$ENV_FILE"
    fi
}

if [[ -z "$PROFILE_SOURCE" ]]; then
    candidates=()
    taskisland_candidates=()
    while IFS= read -r candidate; do
        candidates+=("$candidate")
        candidate_name="$(basename "$candidate")"
        candidate_name_lower="$(printf '%s' "$candidate_name" | tr '[:upper:]' '[:lower:]')"
        if [[ "$candidate_name_lower" == *taskisland* ]]; then
            taskisland_candidates+=("$candidate")
        fi
    done < <(find_profile_candidates)
    if [[ "${#taskisland_candidates[@]}" -eq 1 ]]; then
        PROFILE_SOURCE="${taskisland_candidates[0]}"
    else
        echo "Usage: Scripts/finalize-appstore-profile.sh /absolute/path/to/profile.provisionprofile" >&2
        echo >&2
        if [[ "${#candidates[@]}" -gt 0 ]]; then
            echo "Found provisioning profiles, but none could be safely auto-selected as TaskIsland:" >&2
            printf '  %s\n' "${candidates[@]}" >&2
        else
            echo "No provisioning profile found in Downloads or 证书/." >&2
        fi
        exit 1
    fi
fi

if [[ ! -f "$PROFILE_SOURCE" ]]; then
    echo "Provisioning profile not found: $PROFILE_SOURCE" >&2
    exit 1
fi

PROFILE_PLIST="$(mktemp "${TMPDIR:-/tmp}/taskisland-profile.XXXXXX")"
trap 'rm -f "$PROFILE_PLIST"' EXIT

if ! security cms -D -i "$PROFILE_SOURCE" > "$PROFILE_PLIST" 2>/dev/null; then
    echo "Provisioning profile cannot be decoded: $PROFILE_SOURCE" >&2
    exit 1
fi

PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PROFILE_PLIST" 2>/dev/null || true)"
PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PROFILE_PLIST" 2>/dev/null || true)"
PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PROFILE_PLIST" 2>/dev/null || true)"
PROFILE_TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$PROFILE_PLIST" 2>/dev/null || true)"
PROFILE_EXPIRES="$(/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' "$PROFILE_PLIST" 2>/dev/null || true)"

if [[ -z "$PROFILE_APP_ID" ]]; then
    echo "Provisioning profile does not contain an application-identifier entitlement." >&2
    exit 1
fi

if [[ "$PROFILE_APP_ID" != *".$BUNDLE_ID" ]]; then
    echo "Provisioning profile App ID does not match $BUNDLE_ID: $PROFILE_APP_ID" >&2
    exit 1
fi

if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$PROFILE_PLIST" >/dev/null 2>&1; then
    echo "Warning: this profile contains device entries. For Mac App Store submission, make sure you selected a Mac App Store distribution profile." >&2
fi

mkdir -p "$(dirname "$PROFILE_DEST")"
cp "$PROFILE_SOURCE" "$PROFILE_DEST"

set_env_value "TASKISLAND_BUNDLE_ID" "$BUNDLE_ID"
set_env_value "TASKISLAND_APPSTORE_PROVISIONING_PROFILE" "$PROFILE_DEST"

echo "Installed provisioning profile:"
echo "  Name: ${PROFILE_NAME:-unknown}"
echo "  UUID: ${PROFILE_UUID:-unknown}"
echo "  Team ID: ${PROFILE_TEAM_ID:-unknown}"
echo "  App ID: $PROFILE_APP_ID"
echo "  Expires: ${PROFILE_EXPIRES:-unknown}"
echo "  Path: $PROFILE_DEST"
echo

"$ROOT_DIR/Scripts/check-appstore-readiness.sh"
"$ROOT_DIR/Scripts/package-appstore.sh"
"$ROOT_DIR/Scripts/verify-appstore-package.sh"
"$ROOT_DIR/Scripts/prepare-appstore-upload-kit.sh"

echo
echo "Final App Store package:"
echo "$PKG_PATH"
echo
echo "Updated upload kit:"
echo "$KIT_ZIP"

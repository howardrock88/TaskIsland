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
PKG_PATH="${TASKISLAND_APPSTORE_PKG_PATH:-$ROOT_DIR/dist/appstore/TaskIsland-AppStore-$APPSTORE_VERSION-b$APPSTORE_BUILD.pkg}"
MODE="validate"
WAIT_ARGS=()

usage() {
    cat <<'USAGE'
Usage:
  Scripts/upload-appstore-package.sh --validate
  Scripts/upload-appstore-package.sh --upload [--wait]

Authentication is read from AppStore/submission.env or your shell environment.

Preferred API key auth:
  TASKISLAND_APPSTORE_API_KEY="ABC123DEFG"
  TASKISLAND_APPSTORE_API_ISSUER="00000000-0000-0000-0000-000000000000"
  TASKISLAND_APPSTORE_API_KEY_PATH="/absolute/path/AuthKey_ABC123DEFG.p8"

Apple ID auth with Keychain item:
  TASKISLAND_APPSTORE_UPLOAD_USERNAME="you@example.com"
  TASKISLAND_APPSTORE_UPLOAD_PASSWORD_KEYCHAIN="TASKISLAND_APPSTORE_CONNECT_PASSWORD"

To create the Keychain item once:
  xcrun altool --store-password-in-keychain-item TASKISLAND_APPSTORE_CONNECT_PASSWORD -u you@example.com -p APP_SPECIFIC_PASSWORD

Less preferred, for one-off shells:
  TASKISLAND_APPSTORE_UPLOAD_PASSWORD_ENV="APPSTORE_APP_SPECIFIC_PASSWORD"
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --validate)
            MODE="validate"
            ;;
        --upload)
            MODE="upload"
            ;;
        --wait)
            WAIT_ARGS=(--wait)
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [[ ! -f "$PKG_PATH" ]]; then
    echo "Missing App Store package: $PKG_PATH" >&2
    echo "Run Scripts/package-appstore.sh first." >&2
    exit 1
fi

AUTH_ARGS=()
if [[ -n "${TASKISLAND_APPSTORE_API_KEY:-}" && -n "${TASKISLAND_APPSTORE_API_ISSUER:-}" ]]; then
    AUTH_ARGS=(--api-key "$TASKISLAND_APPSTORE_API_KEY" --api-issuer "$TASKISLAND_APPSTORE_API_ISSUER")
    if [[ -n "${TASKISLAND_APPSTORE_API_KEY_PATH:-}" ]]; then
        AUTH_ARGS+=(--p8-file-path "$TASKISLAND_APPSTORE_API_KEY_PATH")
    fi
elif [[ -n "${TASKISLAND_APPSTORE_UPLOAD_USERNAME:-}" ]]; then
    password_spec=""
    if [[ -n "${TASKISLAND_APPSTORE_UPLOAD_PASSWORD_KEYCHAIN:-}" ]]; then
        password_spec="@keychain:$TASKISLAND_APPSTORE_UPLOAD_PASSWORD_KEYCHAIN"
    elif [[ -n "${TASKISLAND_APPSTORE_UPLOAD_PASSWORD_ENV:-}" ]]; then
        password_spec="@env:$TASKISLAND_APPSTORE_UPLOAD_PASSWORD_ENV"
    elif [[ -n "${TASKISLAND_APPSTORE_UPLOAD_PASSWORD:-}" ]]; then
        password_spec="$TASKISLAND_APPSTORE_UPLOAD_PASSWORD"
    fi

    if [[ -z "$password_spec" ]]; then
        echo "Missing App Store Connect password source." >&2
        echo "Use TASKISLAND_APPSTORE_UPLOAD_PASSWORD_KEYCHAIN or TASKISLAND_APPSTORE_UPLOAD_PASSWORD_ENV." >&2
        exit 1
    fi

    AUTH_ARGS=(--username "$TASKISLAND_APPSTORE_UPLOAD_USERNAME" --password "$password_spec")
else
    echo "Missing App Store Connect authentication." >&2
    echo
    usage >&2
    exit 1
fi

case "$MODE" in
    validate)
        xcrun altool --validate-app "$PKG_PATH" "${AUTH_ARGS[@]}"
        ;;
    upload)
        xcrun altool --upload-package "$PKG_PATH" "${WAIT_ARGS[@]}" "${AUTH_ARGS[@]}"
        ;;
esac

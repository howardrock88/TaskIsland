#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git worktree: $ROOT_DIR" >&2
    exit 1
fi

SENSITIVE_REGEX='(^AppStore/submission\.env$|^证书/|\.cer$|\.certSigningRequest$|\.provisionprofile$|\.mobileprovision$)'
GENERATED_REGEX='(^dist/appstore/(assets|upload-kit|TaskIsland-AppStore-.*\.pkg)|^dist/app-store-promo-assets/)'

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

check_ignored() {
    local path="$1"
    if git check-ignore -q "$path"; then
        ok "$path 已被 git 忽略"
    else
        fail "$path 没有被 git 忽略"
    fi
}

tracked_sensitive="$(git ls-files | rg "$SENSITIVE_REGEX" || true)"
if [[ -z "$tracked_sensitive" ]]; then
    ok "没有敏感证书/profile/env 文件被 Git 跟踪"
else
    fail "发现敏感文件已被 Git 跟踪："
    printf '%s\n' "$tracked_sensitive"
fi

staged_sensitive="$(git diff --cached --name-only | rg "$SENSITIVE_REGEX" || true)"
if [[ -z "$staged_sensitive" ]]; then
    ok "暂存区没有敏感证书/profile/env 文件"
else
    fail "发现敏感文件已进入暂存区："
    printf '%s\n' "$staged_sensitive"
fi

tracked_generated="$(git ls-files | rg "$GENERATED_REGEX" || true)"
if [[ -z "$tracked_generated" ]]; then
    ok "没有 App Store 生成产物被 Git 跟踪"
else
    warn "发现 App Store 生成产物已被 Git 跟踪，请确认是否必要："
    printf '%s\n' "$tracked_generated"
fi

check_ignored "AppStore/submission.env"
check_ignored "证书/example.cer"
check_ignored "证书/example.provisionprofile"
check_ignored "dist/appstore/assets/example.jpg"
check_ignored "dist/appstore/upload-kit/example.zip"

existing_sensitive="$(find "$ROOT_DIR/证书" "$ROOT_DIR/AppStore" -maxdepth 2 \( -name '*.cer' -o -name '*.certSigningRequest' -o -name '*.provisionprofile' -o -name '*.mobileprovision' -o -name 'submission.env' \) -print 2>/dev/null || true)"
if [[ -n "$existing_sensitive" ]]; then
    warn "本地存在敏感文件，这是正常的，但不要提交："
    printf '%s\n' "$existing_sensitive"
else
    ok "本地未发现证书/profile/env 敏感文件"
fi

printf '\nResult: %d error(s), %d warning(s)\n' "$errors" "$warnings"

if [[ "$errors" -gt 0 ]]; then
    exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR"

print_existing_changes() {
    local title="$1"
    shift
    local paths=("$@")
    local output

    output="$(git status --short --untracked-files=all -- "${paths[@]}" 2>/dev/null || true)"
    printf '\n## %s\n\n' "$title"
    if [[ -n "$output" ]]; then
        printf '%s\n' "$output"
    else
        printf 'No local changes.\n'
    fi
}

print_ignored_presence() {
    local title="$1"
    shift
    local paths=("$@")

    printf '\n## %s\n\n' "$title"
    for path in "${paths[@]}"; do
        if [[ -e "$path" ]]; then
            if git check-ignore -q "$path"; then
                printf 'ignored  %s\n' "$path"
            else
                printf 'visible  %s\n' "$path"
            fi
        fi
    done
}

cat <<'EOF'
# GitHub Publish Scope Preview

This is a read-only preview. It does not stage, commit, or push anything.
Use it before publishing the App Store preparation work to avoid mixing generated files, certificates, and unrelated assets into a commit.
EOF

print_existing_changes "App Store preparation files" \
    AppStore \
    Scripts/check-appstore-readiness.sh \
    Scripts/check-appstore-metadata-limits.sh \
    Scripts/check-sensitive-files.sh \
    Scripts/finalize-appstore-profile.sh \
    Scripts/list-appstore-signing-info.sh \
    Scripts/package-appstore.sh \
    Scripts/prepare-appstore-assets.sh \
    Scripts/prepare-appstore-promo-assets.sh \
    Scripts/prepare-appstore-upload-kit.sh \
    Scripts/verify-appstore-package.sh \
    dist/README.md \
    dist/appstore/.gitkeep \
    dist/github/.gitkeep

print_existing_changes "Public website / support pages" \
    docs

print_existing_changes "GitHub issue templates" \
    .github/ISSUE_TEMPLATE

print_existing_changes "Application source changes, review before committing" \
    VERSION \
    README.md \
    README.en.md \
    Sources \
    Scripts/package-app.sh \
    Scripts/package-dmg.sh \
    Scripts/package-pkg.sh

print_ignored_presence "Promo video project files, should stay local/ignored" \
    taskisland-promo-video \
    taskisland-promo-video-en

print_ignored_presence "Sensitive or generated local files, should stay untracked" \
    AppStore/submission.env \
    证书 \
    dist/app-store-promo-assets \
    dist/appstore/assets \
    dist/appstore/upload-kit \
    dist/appstore/TaskIsland-AppStore-0.1.7-b1.pkg

cat <<'EOF'

Suggested commit grouping:

1. App feature/version commit:
   - VERSION, Sources/, README*, package scripts related to direct distribution

2. App Store preparation commit:
   - AppStore/, App Store scripts, dist/.gitkeep files, dist/README.md

3. Public support pages commit:
   - docs/

4. GitHub community files commit:
   - .github/ISSUE_TEMPLATE/

Do not commit:
   - AppStore/submission.env
   - 证书/
   - *.cer, *.certSigningRequest, *.provisionprofile, *.mobileprovision
   - taskisland-promo-video/
   - taskisland-promo-video-en/
   - dist/app-store-promo-assets/
   - dist/appstore/assets/
   - dist/appstore/upload-kit/
   - dist/appstore/*.pkg
EOF

#!/usr/bin/env bash
set -euo pipefail

echo "Code signing identities available to codesign:"
security find-identity -v -p codesigning || true

echo
echo "Likely Mac App Store installer certificates in Keychain:"
FOUND_INSTALLER=0
for NAME in \
    "Mac Installer Distribution" \
    "3rd Party Mac Developer Installer"; do
    CERT_OUTPUT="$(security find-certificate -a -c "$NAME" -Z 2>/dev/null || true)"
    if [[ -n "$CERT_OUTPUT" ]]; then
        FOUND_INSTALLER=1
        echo "- $NAME"
        printf '%s\n' "$CERT_OUTPUT" | sed 's/^/  /'
    fi
done

if [[ "$FOUND_INSTALLER" -eq 0 ]]; then
    echo "- None found"
fi

echo
echo "Copy the exact certificate names into AppStore/submission.env."

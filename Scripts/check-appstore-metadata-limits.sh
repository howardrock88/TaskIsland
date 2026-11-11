#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COPY_PASTE_FILE="$ROOT_DIR/AppStore/appstore-connect-copy-paste.zh-Hans.md"
ZH_METADATA_FILE="$ROOT_DIR/AppStore/metadata.zh-Hans.md"
EN_METADATA_FILE="$ROOT_DIR/AppStore/metadata.en-US.md"
ZH_REVIEW_NOTES_FILE="$ROOT_DIR/AppStore/review-notes.zh-Hans.md"
EN_REVIEW_NOTES_FILE="$ROOT_DIR/AppStore/review-notes.en-US.md"

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

char_count() {
    perl -MEncode=decode -0777 -ne 'print length(decode("UTF-8", $_))'
}

byte_count() {
    LC_ALL=C wc -c | tr -d '[:space:]'
}

extract_code_after_label() {
    local file="$1"
    local label="$2"
    awk -v label="$label" '
        $0 == label { found = 1; next }
        found && $0 == "```text" { block = 1; next }
        block && $0 == "```" { exit }
        block { print }
    ' "$file"
}

extract_section() {
    local file="$1"
    local start="$2"
    local end="$3"
    awk -v start="$start" -v end="$end" '
        $0 == start { block = 1; next }
        block && $0 == end { exit }
        block { print }
    ' "$file" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

check_chars() {
    local label="$1"
    local value="$2"
    local limit="$3"
    local count
    count="$(printf '%s' "$value" | char_count)"
    if [[ -z "$value" ]]; then
        fail "$label 为空"
    elif [[ "$count" -le "$limit" ]]; then
        ok "${label}：$count/$limit 字符"
    else
        fail "$label 超出限制：$count/$limit 字符"
    fi
}

check_bytes() {
    local label="$1"
    local value="$2"
    local limit="$3"
    local count
    count="$(printf '%s' "$value" | byte_count)"
    if [[ -z "$value" ]]; then
        fail "$label 为空"
    elif [[ "$count" -le "$limit" ]]; then
        ok "${label}：$count/$limit bytes"
    else
        fail "$label 超出限制：$count/$limit bytes"
    fi
}

check_keyword_format() {
    local label="$1"
    local value="$2"
    if [[ "$value" == *" "* ]]; then
        warn "$label 包含空格，关键词字段会浪费 bytes"
    else
        ok "$label 未包含空格"
    fi
    if [[ "$value" == *, ]]; then
        warn "$label 末尾有逗号"
    fi
}

ZH_NAME="$(extract_code_after_label "$COPY_PASTE_FILE" "App 名称：")"
ZH_SUBTITLE="$(extract_code_after_label "$COPY_PASTE_FILE" "副标题：")"
ZH_KEYWORDS="$(extract_code_after_label "$COPY_PASTE_FILE" "关键词：")"
ZH_PROMO="$(extract_code_after_label "$COPY_PASTE_FILE" "推广文本：")"
ZH_WHATS_NEW="$(extract_code_after_label "$COPY_PASTE_FILE" "本版本更新：")"
ZH_DESCRIPTION="$(extract_section "$ZH_METADATA_FILE" "## 完整描述" "## 本版本更新")"

EN_NAME="$(extract_code_after_label "$COPY_PASTE_FILE" "App Name:")"
EN_SUBTITLE="$(extract_code_after_label "$COPY_PASTE_FILE" "Subtitle:")"
EN_KEYWORDS="$(extract_code_after_label "$COPY_PASTE_FILE" "Keywords:")"
EN_PROMO="$(extract_code_after_label "$COPY_PASTE_FILE" "Promotional Text:")"
EN_WHATS_NEW="$(extract_code_after_label "$COPY_PASTE_FILE" "What's New:")"
EN_DESCRIPTION="$(extract_section "$EN_METADATA_FILE" "## Description" "## What's New")"

check_chars "简体中文 App 名称" "$ZH_NAME" 30
check_chars "简体中文副标题" "$ZH_SUBTITLE" 30
check_bytes "简体中文关键词" "$ZH_KEYWORDS" 100
check_keyword_format "简体中文关键词" "$ZH_KEYWORDS"
check_chars "简体中文推广文本" "$ZH_PROMO" 170
check_chars "简体中文描述" "$ZH_DESCRIPTION" 4000
check_chars "简体中文本版本更新" "$ZH_WHATS_NEW" 4000

check_chars "英文 App Name" "$EN_NAME" 30
check_chars "英文 Subtitle" "$EN_SUBTITLE" 30
check_bytes "英文 Keywords" "$EN_KEYWORDS" 100
check_keyword_format "英文 Keywords" "$EN_KEYWORDS"
check_chars "英文 Promotional Text" "$EN_PROMO" 170
check_chars "英文 Description" "$EN_DESCRIPTION" 4000
check_chars "英文 What's New" "$EN_WHATS_NEW" 4000

check_bytes "中文 App Review Notes 文件" "$(cat "$ZH_REVIEW_NOTES_FILE")" 4000
check_bytes "英文 App Review Notes 文件" "$(cat "$EN_REVIEW_NOTES_FILE")" 4000

printf '\nResult: %d error(s), %d warning(s)\n' "$errors" "$warnings"

if [[ "$errors" -gt 0 ]]; then
    exit 1
fi

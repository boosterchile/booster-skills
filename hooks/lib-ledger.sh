#!/usr/bin/env bash
# booster-skills :: shared ledger helpers
# Sourced by session-start.sh, log-event.sh, stop.sh.
# bash 3.2 compatible. macOS (BSD) first, GNU fallback. NEVER blocks (no exit 2).

# Resolve the project dir and ledger dir.
ledger_dir() {
    local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    printf '%s/.claude/ledger' "$project_dir"
}

# Resolve session id from a hook JSON payload (stdin already captured in $1),
# falling back to the .current sidecar, then to a pid/time id.
resolve_session_id() {
    local input="$1" sid=""
    if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
        sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
    fi
    if [ -z "$sid" ]; then
        local cur; cur="$(cat "$(ledger_dir)/.current" 2>/dev/null || true)"
        if [ -n "$cur" ]; then
            sid="$(basename "$cur" .jsonl)"
        fi
    fi
    printf '%s' "${sid:-$(date -u +%s)_$$}"
}

# Path of the ledger file for a given session id. Stable across the session
# (no date prefix -> no date-rollover path mismatch). Date lives inside events.
ledger_file_for() {
    printf '%s/%s.jsonl' "$(ledger_dir)" "$1"
}

ts_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Append a raw JSON line to the ledger, creating the dir if needed.
ledger_append() {
    local file="$1" line="$2"
    mkdir -p "$(dirname "$file")" 2>/dev/null || return 0
    printf '%s\n' "$line" >> "$file" 2>/dev/null || true
}

# JSON-escape a string (minimal: backslash, quote, newline, tab).
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# Classify an artifact path into a kind. Aligned to the superpowers flow
# (docs/plans) AND the legacy .specs/ convention, so both are observable.
classify_path() {
    case "$1" in
        *.test.*|*.spec.*|*_test.*|*test_*|*_spec.*|*/__tests__/*) echo "test" ;;
        *.specs/*/spec.md)          echo "spec" ;;
        *.specs/*/plan.md|*docs/plans/*.md) echo "plan" ;;
        *.specs/*/verify.md)        echo "verify" ;;
        *.specs/*/review.md)        echo "review" ;;
        *.specs/*/ship.md)          echo "ship" ;;
        *docs/adr/*)                echo "adr" ;;
        *design-system/*)           echo "design" ;;
        */apps/*|*/packages/*|*/src/*|*/lib/*|*/components/*) echo "source" ;;
        *)                          echo "other" ;;
    esac
}

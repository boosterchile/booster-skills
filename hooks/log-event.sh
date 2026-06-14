#!/usr/bin/env bash
# booster-skills :: PostToolUse — log observable events to the ledger.
# Matches Write|Edit|MultiEdit|Read|Task. Purely observational; ALWAYS exit 0.
#
# Fixes the two bugs that made the agent-rigor ledger fiction:
#   - Read IS wired here (agent-rigor registered PostToolUse only for writes,
#     so its skill_read branch was dead code).
#   - No exit 2 anywhere -> impossible to deadlock or block a tool call.
#
# bash 3.2 / BSD-first.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-ledger.sh
. "${SCRIPT_DIR}/lib-ledger.sh"

INPUT="$(cat || true)"

# Without jq we cannot parse; degrade silently (observational layer, never block).
command -v jq >/dev/null 2>&1 || exit 0
[ -n "$INPUT" ] || exit 0

SID="$(resolve_session_id "$INPUT")"
FILE="$(ledger_file_for "$SID")"
TS="$(ts_now)"

TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[ -n "$TOOL" ] || exit 0

case "$TOOL" in
    Read)
        P="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
        case "$P" in
            *CLAUDE.md|*SKILL.md|*/skills/*|*/references/*|*/docs/adr/*)
                ledger_append "$FILE" "$(printf '{"ts":"%s","type":"skill_read","file":"%s"}' \
                    "$TS" "$(json_escape "$P")")"
                ;;
        esac
        ;;
    Task)
        STYPE="$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"' 2>/dev/null || echo unknown)"
        ledger_append "$FILE" "$(printf '{"ts":"%s","type":"subagent_invoked","subagent_type":"%s"}' \
            "$TS" "$(json_escape "$STYPE")")"
        ;;
    Write|Edit|MultiEdit)
        P="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
        [ -n "$P" ] || exit 0
        # Never log writes to the ledger itself (avoid recursion / noise).
        case "$P" in *"/.claude/ledger/"*) exit 0 ;; esac
        KIND="$(classify_path "$P")"
        SHA="unknown"; SIZE=0
        if [ -f "$P" ]; then
            SHA="$(shasum -a 256 "$P" 2>/dev/null | awk '{print $1}' || echo unknown)"
            SIZE="$(wc -c < "$P" 2>/dev/null | tr -d ' ' || echo 0)"
        fi
        ledger_append "$FILE" "$(printf '{"ts":"%s","type":"artifact_produced","tool":"%s","path":"%s","kind":"%s","sha256":"%s","bytes":%s}' \
            "$TS" "$TOOL" "$(json_escape "$P")" "$KIND" "$SHA" "${SIZE:-0}")"
        ;;
esac

exit 0

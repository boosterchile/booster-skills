#!/usr/bin/env bash
# booster-skills :: SessionStart — bootstrap an observational ledger.
# Purely observational. Never blocks. bash 3.2 / BSD-first.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-ledger.sh
. "${SCRIPT_DIR}/lib-ledger.sh"

INPUT="$(cat || true)"
SID="$(resolve_session_id "$INPUT")"
DIR="$(ledger_dir)"
FILE="$(ledger_file_for "$SID")"

mkdir -p "$DIR" 2>/dev/null || exit 0

# Idempotent: only write session_start if the file is new/empty.
if [ ! -s "$FILE" ]; then
    ledger_append "$FILE" "$(printf '{"ts":"%s","type":"session_start","session_id":"%s","cwd":"%s"}' \
        "$(ts_now)" "$SID" "$(json_escape "${CLAUDE_PROJECT_DIR:-$(pwd)}")")"
fi

# Sidecar so PostToolUse/Stop hooks that lack session_id can find the ledger.
printf '%s' "$FILE" > "${DIR}/.current" 2>/dev/null || true

exit 0

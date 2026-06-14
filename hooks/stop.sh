#!/usr/bin/env bash
# booster-skills :: Stop — log turn end + print a tiny session summary.
# Observational only. Never blocks. bash 3.2 / BSD-first.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-ledger.sh
. "${SCRIPT_DIR}/lib-ledger.sh"

INPUT="$(cat || true)"
SID="$(resolve_session_id "$INPUT")"
FILE="$(ledger_file_for "$SID")"
[ -f "$FILE" ] || exit 0

ledger_append "$FILE" "$(printf '{"ts":"%s","type":"turn_end"}' "$(ts_now)")"

# count <substring> <file> -> number of matching lines (0 if none). grep -c
# exits 1 on zero matches, so we swallow it and default to 0.
count() { local n; n="$(grep -c "$1" "$2" 2>/dev/null || true)"; printf '%s' "${n:-0}"; }

SRC="$(count '"kind":"source"' "$FILE")"
TST="$(count '"kind":"test"' "$FILE")"
REV="$(count '"type":"subagent_invoked"' "$FILE")"
SKR="$(count '"type":"skill_read"' "$FILE")"

cat <<EOF

[booster-skills] resumen de sesión
  Fuente:        $SRC
  Tests:         $TST
  Subagentes:    $REV
  Skills leídas: $SKR
  Ledger:        $FILE
EOF

exit 0

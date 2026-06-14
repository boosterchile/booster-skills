#!/usr/bin/env bash
# booster-skills :: weekly observational scorecard.
#
# Reads the per-session ledgers under <project>/.claude/ledger and reports what
# was ACTUALLY observable: artifacts by kind, test:source ratio (TDD proxy),
# review-subagent invocations, and commits in the window. No gates, no baseline
# pass/fail — it reports, you judge.
#
# Usage:
#   score-week.sh [--days N] [--format text|json] [--ledger-dir DIR]
#
# bash 3.2 / BSD-first (uses `date -v`), GNU fallback (`date -d`). Needs jq.
set -eu

DAYS=7
FORMAT="text"
LEDGER_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --days)       shift; DAYS="${1:-7}" ;;
        --format)     shift; FORMAT="${1:-text}" ;;
        --ledger-dir) shift; LEDGER_DIR="${1:-}" ;;
        *) ;;
    esac
    shift
done

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -n "$LEDGER_DIR" ] || LEDGER_DIR="${PROJECT_DIR}/.claude/ledger"

if ! command -v jq >/dev/null 2>&1; then
    echo "score-week: jq required (brew install jq)" >&2; exit 1
fi

# Cutoff timestamp (UTC ISO). BSD `date -v`, GNU `date -d` fallback.
if date -v-1d >/dev/null 2>&1; then
    CUTOFF="$(date -u -v-"${DAYS}"d +%Y-%m-%dT%H:%M:%SZ)"
else
    CUTOFF="$(date -u -d "-${DAYS} days" +%Y-%m-%dT%H:%M:%SZ)"
fi

# Gather ledger lines in window. Missing dir -> empty.
LINES=""
if [ -d "$LEDGER_DIR" ]; then
    LINES="$(cat "$LEDGER_DIR"/*.jsonl 2>/dev/null || true)"
fi

# Aggregate with jq. -s slurps the (possibly empty) stream into an array.
AGG="$(printf '%s\n' "$LINES" | jq -s --arg cutoff "$CUTOFF" '
    map(select((.ts // "") >= $cutoff)) as $ev |
    {
      sessions:  ($ev | map(select(.type=="session_start")) | length),
      source:    ($ev | map(select(.kind=="source"))  | length),
      test:      ($ev | map(select(.kind=="test"))     | length),
      spec:      ($ev | map(select(.kind=="spec"))     | length),
      plan:      ($ev | map(select(.kind=="plan"))     | length),
      adr:       ($ev | map(select(.kind=="adr"))      | length),
      review_art:($ev | map(select(.kind=="review"))   | length),
      subagents: ($ev | map(select(.type=="subagent_invoked")) | length),
      skill_reads:($ev| map(select(.type=="skill_read"))| length)
    } |
    . + { test_source_ratio:
            (if (.test + .source) > 0
             then (.test / (.test + .source)) else 0 end) }
' 2>/dev/null || echo '{}')"

# Commits in window (git understands "N days ago" regardless of platform).
COMMITS=0
if command -v git >/dev/null 2>&1 && git -C "$PROJECT_DIR" rev-parse >/dev/null 2>&1; then
    COMMITS="$(git -C "$PROJECT_DIR" log --since="${DAYS} days ago" --oneline 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
fi

if [ "$FORMAT" = "json" ]; then
    printf '%s' "$AGG" | jq --argjson commits "${COMMITS:-0}" --arg days "$DAYS" \
        '. + {commits: $commits, window_days: ($days|tonumber)}'
    exit 0
fi

get() { printf '%s' "$AGG" | jq -r ".$1 // 0"; }
RATIO="$(printf '%s' "$AGG" | jq -r '(.test_source_ratio*100)|floor')"

cat <<EOF
booster-skills · scorecard (últimos ${DAYS} días)
  Sesiones:                 $(get sessions)
  Archivos fuente:          $(get source)
  Archivos de test:         $(get test)
  Ratio test:source:        ${RATIO}%   (proxy de TDD; observacional)
  Specs:                    $(get spec)
  Planes:                   $(get plan)
  ADRs:                     $(get adr)
  Artefactos de review:     $(get review_art)
  Subagentes invocados:     $(get subagents)
  Skills/contratos leídos:  $(get skill_reads)
  Commits en ventana:       ${COMMITS}

Nota: métricas observacionales, sin umbral de aprobado/reprobado. Tendencia > valor puntual.
EOF

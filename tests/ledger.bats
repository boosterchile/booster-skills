#!/usr/bin/env bats
# booster-skills :: tests for the observational ledger hooks + scorecard.
# Run: bats tests/ledger.bats   (brew install bats-core)
#
# These tests feed synthetic hook payloads to the scripts and assert the
# ledger lines and scorecard numbers. They exist so the ledger can never
# silently become fiction again.

setup() {
    HOOKS="${BATS_TEST_DIRNAME}/../hooks"
    BENCH="${BATS_TEST_DIRNAME}/../benchmark"
    export CLAUDE_PROJECT_DIR="$(mktemp -d)"
    export SID="testsession"
    LEDGER="${CLAUDE_PROJECT_DIR}/.claude/ledger/${SID}.jsonl"
}

teardown() { rm -rf "$CLAUDE_PROJECT_DIR"; }

emit() { printf '%s' "$1" | "$HOOKS/$2"; }   # emit <json> <script>

@test "session-start creates ledger with session_start" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    [ -f "$LEDGER" ]
    grep -q '"type":"session_start"' "$LEDGER"
}

@test "log-event records a source artifact with correct kind" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    src="${CLAUDE_PROJECT_DIR}/packages/pricing-engine/src/calc.ts"
    mkdir -p "$(dirname "$src")"; echo "export const x=1" > "$src"
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$src\"}}" log-event.sh
    grep -q '"type":"artifact_produced"' "$LEDGER"
    grep -q '"kind":"source"' "$LEDGER"
}

@test "log-event classifies a test file as kind=test" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    t="${CLAUDE_PROJECT_DIR}/packages/pricing-engine/src/calc.test.ts"
    mkdir -p "$(dirname "$t")"; echo "test('x',()=>{})" > "$t"
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$t\"}}" log-event.sh
    grep -q '"kind":"test"' "$LEDGER"
}

@test "log-event records Read of a SKILL.md as skill_read (the bug agent-rigor never wired)" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"/x/skills/tdd-dominio-critico/SKILL.md\"}}" log-event.sh
    grep -q '"type":"skill_read"' "$LEDGER"
}

@test "log-event records Task subagent invocation" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Task\",\"tool_input\":{\"subagent_type\":\"security-scanner\"}}" log-event.sh
    grep -q '"type":"subagent_invoked"' "$LEDGER"
    grep -q '"subagent_type":"security-scanner"' "$LEDGER"
}

@test "log-event NEVER blocks: exit 0 even with drift wording in content" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    run emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/x/src/a.ts\",\"content\":\"// MVP quick fix for now, hack\"}}" log-event.sh
    [ "$status" -eq 0 ]
}

@test "log-event does not log writes to the ledger dir (no recursion)" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    before="$(wc -l < "$LEDGER")"
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"${CLAUDE_PROJECT_DIR}/.claude/ledger/${SID}.jsonl\"}}" log-event.sh
    after="$(wc -l < "$LEDGER")"
    [ "$before" -eq "$after" ]
}

@test "scorecard json reports counts and a test:source ratio" {
    emit "{\"session_id\":\"$SID\"}" session-start.sh
    for f in a.ts b.ts; do
        p="${CLAUDE_PROJECT_DIR}/src/$f"; mkdir -p "$(dirname "$p")"; echo x > "$p"
        emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$p\"}}" log-event.sh
    done
    p="${CLAUDE_PROJECT_DIR}/src/a.test.ts"; echo x > "$p"
    emit "{\"session_id\":\"$SID\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$p\"}}" log-event.sh
    run "$BENCH/score-week.sh" --days 7 --format json --ledger-dir "${CLAUDE_PROJECT_DIR}/.claude/ledger"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.source==2 and .test==1' >/dev/null
}

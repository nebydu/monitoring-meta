#!/usr/bin/env bash
# codex-gate.sh — monitoring-meta Stop hook (Git Bash 전용)
# Codex 호출 경로 = fallback(codex exec). 이유: codex-cli 0.134.0의 `codex review`가 --output-schema/--json 둘 다 미지원.
# JSON 파싱 = python. 이유: 이 환경에 jq 미설치(설치본 없음, Python 3.14 가용).
set -euo pipefail

# ── 경로 ────────────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel)"
CLAUDE_DIR="$REPO_ROOT/.claude"
STATE_FILE="$CLAUDE_DIR/.codex-gate-state"
LOG_FILE="$CLAUDE_DIR/codex-gate.log"
ESC_LOG="$CLAUDE_DIR/codex-gate-escalation.log"
SCHEMA="$CLAUDE_DIR/codex-schema.json"
LAST_MSG="$CLAUDE_DIR/.codex-last-message.json"
ISSUES_FILE="$CLAUDE_DIR/.codex-gate-issues.txt"
CODEX_ERR="$CLAUDE_DIR/.codex-gate-stderr.txt"

# empty tree object hash — 아직 커밋이 없을 때(HEAD 부재) diff 비교 기준
EMPTY_TREE="4b825dc642cb6eb9a060e54bf8d69288fbee4904"

# ── 유틸 ────────────────────────────────────────────────────────────────
log_line() { # verdict | crit_count | viol_count | triggered_files
  printf '%s | %s | %s | %s | %s\n' "$(date -Is)" "$1" "$2" "$3" "$4" >> "$LOG_FILE"
}
escalate() { # message
  printf '%s | %s\n' "$(date -Is)" "$1" >> "$ESC_LOG"
}
read_state() {
  FAIL_COUNT=0; PARSE_FAIL_COUNT=0
  if [ -f "$STATE_FILE" ]; then
    read -r FAIL_COUNT PARSE_FAIL_COUNT < "$STATE_FILE" || true
  fi
  FAIL_COUNT=${FAIL_COUNT:-0}
  PARSE_FAIL_COUNT=${PARSE_FAIL_COUNT:-0}
}
write_state() { printf '%s %s\n' "$FAIL_COUNT" "$PARSE_FAIL_COUNT" > "$STATE_FILE"; }
reset_state() { FAIL_COUNT=0; PARSE_FAIL_COUNT=0; write_state; }

# ── 1) 무한 Stop 루프 가드 ───────────────────────────────────────────────
INPUT="$(cat)"
STOP_ACTIVE="$(printf '%s' "$INPUT" | python -c '
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print("1" if d.get("stop_hook_active") else "0")
except Exception:
    print("0")
' 2>/dev/null || echo "0")"
[ "$STOP_ACTIVE" = "1" ] && exit 0

read_state

# ── 2) 트리거 가드 — spec 관련 변경이 있을 때만 Codex 호출 ────────────────
if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  BASE="HEAD"
else
  BASE="$EMPTY_TREE"
fi

CHANGED="$( { git -c core.quotepath=false diff --name-only "$BASE"; \
              git -c core.quotepath=false ls-files --others --exclude-standard; } | sort -u )"

TRIGGERED=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    docs/phase0-snapshot/*) ;;                 # 참조 스냅샷 → 트리거 제외
    adr/*.md)  TRIGGERED="${TRIGGERED}${f}"$'\n' ;;
    docs/*.md) TRIGGERED="${TRIGGERED}${f}"$'\n' ;;   # 통합본/envelope/kafka-payloads 등 docs/ 신규·변경 spec
  esac
done <<EOF
$CHANGED
EOF

# pipefail+set -e 환경: TRIGGERED가 비면 grep이 exit 1을 내므로 || true로 방어
TRIG_CSV="$(printf '%s' "$TRIGGERED" | grep -v '^$' | tr '\n' ',' | sed 's/,$//' || true)"

if [ -z "$TRIG_CSV" ]; then
  # handoff/, e2e/, .claude/ 등 작업 산출물만 변경 → 매번 검토 비용 크므로 스킵
  log_line "skipped" 0 0 "(no spec change)"
  exit 0
fi

# ── 3) 검토 입력 구성 (추적 변경 diff + 미추적 신규 spec 파일 내용) ───────
REVIEW_INPUT="$(git -c core.quotepath=false diff "$BASE")"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if ! git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    # 미추적 파일은 diff에 안 잡히므로 내용을 직접 합류
    REVIEW_INPUT="${REVIEW_INPUT}
--- NEW FILE: ${f} ---
$(cat "$REPO_ROOT/$f" 2>/dev/null)"
  fi
done <<EOF
$TRIGGERED
EOF

# ── 4) Codex 호출 (fallback: codex exec, read-only) ──────────────────────
PROMPT="통합본 v0.9 내부 일관성 + 8토픽 spec(kafka-payloads, envelope) 정합성 + ADR 결정과 spec 정의의 불일치 + Open question으로 남겨야 할 사항을 무심코 결정한 흔적이 있는지 검토. 아래 diff를 read-only로만 검토하고 codex-schema.json 형식의 JSON으로만 응답."

rm -f "$LAST_MSG" "$ISSUES_FILE"
set +e
printf '%s' "$REVIEW_INPUT" | codex exec --sandbox read-only \
  --output-schema "$SCHEMA" \
  -o "$LAST_MSG" \
  "$PROMPT" >/dev/null 2>"$CODEX_ERR"
set -e

# ── 5) 결과 파싱 (python) ────────────────────────────────────────────────
set +e
PARSE_OUT="$(python -c '
import sys, json
last_msg, issues_path = sys.argv[1], sys.argv[2]
try:
    with open(last_msg, "r", encoding="utf-8") as fp:
        d = json.load(fp)
    verdict = str(d.get("verdict", "")).strip()
    crit = d.get("critical_issues") or []
    viol = d.get("spec_violations") or []
    if verdict not in ("pass", "fail"):
        raise ValueError("invalid verdict: %r" % verdict)
    with open(issues_path, "w", encoding="utf-8") as g:
        for c in crit:
            g.write("[critical] " + str(c) + "\n")
        for v in viol:
            g.write("[spec] " + str(v) + "\n")
    sys.stdout.write("%s\t%d\t%d" % (verdict, len(crit), len(viol)))
except Exception as e:
    sys.stderr.write(str(e))
    sys.exit(3)
' "$LAST_MSG" "$ISSUES_FILE" 2>/dev/null)"
PARSE_RC=$?
set -e

# ── 5a) 파싱 실패 ────────────────────────────────────────────────────────
if [ "$PARSE_RC" -ne 0 ] || [ -z "$PARSE_OUT" ]; then
  PARSE_FAIL_COUNT=$((PARSE_FAIL_COUNT + 1))
  if [ "$PARSE_FAIL_COUNT" -ge 2 ]; then
    escalate "Codex 응답 파싱 2회 연속 실패 — 사람 확인 필요 (triggered: $TRIG_CSV)"
    log_line "parse_error(escalated)" 0 0 "$TRIG_CSV"
    reset_state
    exit 0
  fi
  write_state
  log_line "parse_error" 0 0 "$TRIG_CSV"
  {
    echo "[codex-gate] Codex 응답 파싱 실패. 원본 출력 앞 200자:"
    head -c 200 "$LAST_MSG" 2>/dev/null || true
    head -c 200 "$CODEX_ERR" 2>/dev/null || true
    echo ""
  } >&2
  exit 2
fi

VERDICT="$(printf '%s' "$PARSE_OUT" | cut -f1)"
CRIT_COUNT="$(printf '%s' "$PARSE_OUT" | cut -f2)"
VIOL_COUNT="$(printf '%s' "$PARSE_OUT" | cut -f3)"

# ── 5b) verdict == pass ──────────────────────────────────────────────────
if [ "$VERDICT" = "pass" ]; then
  log_line "pass" "$CRIT_COUNT" "$VIOL_COUNT" "$TRIG_CSV"
  reset_state
  exit 0
fi

# ── 5c) verdict == fail ──────────────────────────────────────────────────
PARSE_FAIL_COUNT=0   # 파싱은 성공했으므로 연속 파싱 실패 카운터 리셋
FAIL_COUNT=$((FAIL_COUNT + 1))
if [ "$FAIL_COUNT" -gt 3 ]; then
  escalate "Codex 검증 fail 3회 초과 — 사람 확인 필요 (triggered: $TRIG_CSV)"
  log_line "fail(escalated)" "$CRIT_COUNT" "$VIOL_COUNT" "$TRIG_CSV"
  reset_state
  exit 0
fi
write_state
log_line "fail" "$CRIT_COUNT" "$VIOL_COUNT" "$TRIG_CSV"
{
  echo "[codex-gate] Codex 검증 FAIL — 종료 보류. 아래 항목을 해소한 뒤 다시 종료하십시오:"
  cat "$ISSUES_FILE" 2>/dev/null
} >&2
exit 2

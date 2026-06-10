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
emit_system_message() { # message
  # stdout을 UTF-8로 고정: Windows 콘솔 기본 인코딩(cp949)이 em-dash 등을 못 실어 크래시하는 것 방지
  python -c 'import json, sys; sys.stdout.reconfigure(encoding="utf-8"); print(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False))' "$1"
}
escalate() { # message
  printf '%s | %s\n' "$(date -Is)" "$1" >> "$ESC_LOG"
  # force-pass는 검증을 건너뛴 사건 → SKIP/PASS보다 더 잘 보여야 하므로 systemMessage로 노출
  emit_system_message "게이트 강제 통과 — 사람 확인 필요: $1"
}
read_state() { # gate_key triggered_key
  STATE_STATUS="new"; FAIL_COUNT=0; PARSE_FAIL_COUNT=0
  if [ ! -f "$STATE_FILE" ]; then
    return 0
  fi
  # 캐시(passed/escalated 재사용)는 gate_key(=내용+prompt+schema+hook) 완전 일치 시에만 적용한다.
  # fail streak(연속 실패 카운트)은 triggered(파일 집합) 일치 시 승계한다 — diff가 바뀌어도 같은 파일을
  # 계속 고치며 실패하면 카운트가 누적되어 3회 escalation에 실제로 도달한다(이전엔 diff마다 리셋되어 무력).
  STATE_OUT="$(python -c '
import json, sys
path, gate_key, trig = sys.argv[1], sys.argv[2], sys.argv[3]
status, fail, parse = "new", 0, 0
try:
    with open(path, "r", encoding="utf-8") as fp:
        d = json.load(fp)
    if d.get("gate_key") == gate_key:
        status = str(d.get("status") or "new")
    if d.get("triggered") == trig:
        fail = int(d.get("fail_count") or 0)
        parse = int(d.get("parse_fail_count") or 0)
    sys.stdout.write(f"{status}\t{fail}\t{parse}")
except Exception:
    sys.stdout.write("new\t0\t0")
' "$STATE_FILE" "$1" "$2" 2>/dev/null || printf 'new\t0\t0')"
  STATE_STATUS="$(printf '%s' "$STATE_OUT" | cut -f1)"
  FAIL_COUNT="$(printf '%s' "$STATE_OUT" | cut -f2)"
  PARSE_FAIL_COUNT="$(printf '%s' "$STATE_OUT" | cut -f3)"
  FAIL_COUNT=${FAIL_COUNT:-0}
  PARSE_FAIL_COUNT=${PARSE_FAIL_COUNT:-0}
}
write_state() { # status
  python -c '
import json, sys
path, status, gate_key, diff_hash, triggered, fail, parse, updated_at = sys.argv[1:9]
data = {
    "gate_key": gate_key,
    "triggered": triggered,
    "diff_hash": diff_hash,
    "fail_count": int(fail),
    "parse_fail_count": int(parse),
    "status": status,
    "updated_at": updated_at,
}
with open(path, "w", encoding="utf-8") as fp:
    json.dump(data, fp, ensure_ascii=False, indent=2)
    fp.write("\n")
' "$STATE_FILE" "$1" "$GATE_KEY" "$DIFF_HASH" "$TRIG_CSV" "$FAIL_COUNT" "$PARSE_FAIL_COUNT" "$(date -Is)"
}
log_target() {
  printf '%s | key=%s | status=%s' "$TRIG_CSV" "$GATE_KEY" "${STATE_STATUS:-new}"
}

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

# ── 2) 트리거 가드 — spec/handoff/harness 관련 변경이 있을 때만 Codex 호출 ──
if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  BASE="HEAD"
else
  BASE="$EMPTY_TREE"
fi

CHANGED="$( { git -c core.quotepath=false diff --name-only "$BASE"; \
              git -c core.quotepath=false ls-files --others --exclude-standard; } | sort -u )"

SPEC_TRIGGERED=""
HARNESS_TRIGGERED=""
FEATURE_TRIGGERED=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    docs/phase0-snapshot/*) ;;                 # 참조 스냅샷 → 트리거 제외
    docs/features/*.md) FEATURE_TRIGGERED="${FEATURE_TRIGGERED}${f}"$'\n' ;;  # descriptive 레이어 → 전용 프롬프트(docs/*.md 보다 먼저 매치돼야 함)
    adr/*.md)  SPEC_TRIGGERED="${SPEC_TRIGGERED}${f}"$'\n' ;;
    docs/*.md) SPEC_TRIGGERED="${SPEC_TRIGGERED}${f}"$'\n' ;;   # 통합본/envelope/kafka-payloads 등 docs/ 신규·변경 spec
    handoff/adr-*/*.md) SPEC_TRIGGERED="${SPEC_TRIGGERED}${f}"$'\n' ;;   # 작업 단위 디렉터리 구조: handoff/adr-NNN/adr-NNN-*.md
    .claude/hooks/*.sh|.claude/hooks/*.cmd|.claude/settings.json|.claude/codex-schema.json)
      HARNESS_TRIGGERED="${HARNESS_TRIGGERED}${f}"$'\n'
      ;;
  esac
done <<EOF
$CHANGED
EOF

TRIGGERED="${SPEC_TRIGGERED}${HARNESS_TRIGGERED}${FEATURE_TRIGGERED}"

# pipefail+set -e 환경: TRIGGERED가 비면 grep이 exit 1을 내므로 || true로 방어
TRIG_CSV="$(printf '%s' "$TRIGGERED" | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
SPEC_CSV="$(printf '%s' "$SPEC_TRIGGERED" | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
HARNESS_CSV="$(printf '%s' "$HARNESS_TRIGGERED" | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//' || true)"
FEATURE_CSV="$(printf '%s' "$FEATURE_TRIGGERED" | grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//' || true)"

if [ -z "$TRIG_CSV" ]; then
  # 게이트 트리거 = spec(docs/·adr/·handoff/adr-*/*.md) 또는 harness(.claude/hooks/*.sh·*.cmd·settings.json·codex-schema.json) 또는 feature(docs/features/*.md).
  # 그 외(e2e/, 일반 handoff/, 기타 .claude/ 산출물 등)만 바뀐 경우 → 매번 검토 비용이 크므로 스킵.
  log_line "skipped" 0 0 "(no gate-triggering change)"
  emit_system_message "[codex-gate] SKIP: Codex 검증 트리거 대상(spec docs/adr/handoff-adr · harness hooks/settings/schema · feature docs/features) 변경 없음."
  exit 0
fi

# ── 3) 검토 입력 구성 (트리거 파일 diff + 미추적 신규 파일 내용) ──────────
REVIEW_INPUT=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    REVIEW_INPUT="${REVIEW_INPUT}
$(git -c core.quotepath=false diff "$BASE" -- "$f")"
  else
    # 미추적 파일은 diff에 안 잡히므로 내용을 직접 합류
    REVIEW_INPUT="${REVIEW_INPUT}
--- NEW FILE: ${f} ---
$(cat "$REPO_ROOT/$f" 2>/dev/null)"
  fi
done <<EOF
$TRIGGERED
EOF

# ── 검토 프롬프트 구성 — spec/harness 모드를 합산(둘 다면 병합, 어느 한쪽 지시도 누락되지 않게) ──
SPEC_PROMPT="통합본 v0.9 내부 일관성 + 8토픽 spec(kafka-payloads, envelope) 정합성 + ADR 결정과 spec 정의의 불일치 + Open question으로 남겨야 할 사항을 무심코 결정한 흔적이 있는지 검토. handoff/adr-*/*.md가 포함되면 ADR/최종 handoff/사전 분석 문서 간 위상 충돌도 검토."
HARNESS_PROMPT="Claude Code Stop hook/harness 변경 리뷰. Bash/Windows Git Bash 호환성, 상태 파일/캐시 로직, trigger 범위, fail/pass/escalation 흐름, 로그와 systemMessage가 오해를 만들 가능성을 중점 검토."
FEATURE_PROMPT="docs/features/ 경로의 파일은 기술(descriptive) 문서 레이어다 — 코드의 현재 구현 흐름을 서술하며 규범(spec)이 아니다. 이 경로의 파일에 한해 다음만 검토: (1) 통합본 v0.9·ADR을 새로 결정하거나 8토픽 payload/envelope 규범을 변경한 흔적, (2) 통합본·ADR과 충돌하는 서술, (3) 미구현 spec을 구현된 것처럼 단정한 곳, (4) 코드 앵커로 라인번호·commit hash를 쓴 곳(금지), (5) 사전 분석/계획 문구가 규칙 문서 위상에 잔존. docs/features/ 파일에는 통합본 자체의 내부 일관성·8토픽 payload 정합성을 적용하지 않는다(이 레이어는 포인터만 단다). diff에 docs/features/ 외 파일(통합본·adr·handoff 등)이 함께 있으면 그 파일에는 이 제한을 적용하지 말고 해당 파일용 spec 검토 지시를 따른다."
PROMPT=""
[ -n "$SPEC_CSV" ] && PROMPT="$SPEC_PROMPT"
[ -n "$HARNESS_CSV" ] && PROMPT="${PROMPT:+$PROMPT
}$HARNESS_PROMPT"
[ -n "$FEATURE_CSV" ] && PROMPT="${PROMPT:+$PROMPT
}$FEATURE_PROMPT"
PROMPT="$PROMPT
아래 diff를 read-only로만 검토하고 codex-schema.json 형식의 JSON으로만 응답."

# 같은 변경분은 같은 gate_key를 갖는다. 통과/확인 필요 상태면 재호출하지 않는다.
# gate_key에 prompt + schema + hook 자체 해시를 포함 → diff가 같아도 검토 정책(prompt/schema/hook)이
# 바뀌면 gate_key가 달라져 stale PASS를 재사용하지 않고 새 기준으로 재검증한다.
DIFF_HASH="$(printf '%s' "$REVIEW_INPUT" | python -c 'import hashlib, sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())')"
SCHEMA_HASH="$(python -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$SCHEMA" 2>/dev/null || echo nohash)"
SELF_HASH="$(python -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "${BASH_SOURCE[0]:-$0}" 2>/dev/null || echo nohash)"
GATE_KEY="$(python -c 'import hashlib, sys; print(hashlib.sha256(("\0".join(sys.argv[1:])).encode("utf-8")).hexdigest())' "$TRIG_CSV" "$DIFF_HASH" "$PROMPT" "$SCHEMA_HASH" "$SELF_HASH")"

read_state "$GATE_KEY" "$TRIG_CSV"
if [ "$STATE_STATUS" = "passed" ]; then
  log_line "skipped(already_passed)" 0 0 "$(log_target)"
  emit_system_message "[codex-gate] SKIP(already_passed): 같은 변경분은 이미 Codex 검증 PASS 완료. 대상: $TRIG_CSV"
  exit 0
fi
if [ "$STATE_STATUS" = "escalated" ]; then
  log_line "skipped(already_force_passed)" 0 0 "$(log_target)"
  emit_system_message "[codex-gate] SKIP(already_force_passed): 이 변경분은 검증 누적 실패로 게이트가 '강제 통과(사람 확인 필요)' 처리된 상태입니다 — 종료는 허용되지만 Codex 검증을 통과한 것은 아닙니다. 변경분을 수정하면 새 기준으로 재검증합니다. 대상: $TRIG_CSV"
  exit 0
fi

# ── 4) Codex 호출 (fallback: codex exec, read-only) — PROMPT는 위 §3에서 모드 병합으로 구성됨 ──
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
    STATE_STATUS="escalated"
    FAIL_COUNT=0; PARSE_FAIL_COUNT=0   # escalation 발동 → streak 리셋(다음 수정분은 0부터 재누적)
    log_line "parse_error(escalated)" 0 0 "$(log_target)"
    write_state "escalated"
    exit 0
  fi
  STATE_STATUS="parse_error"
  write_state "parse_error"
  log_line "parse_error" 0 0 "$(log_target)"
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
  FAIL_COUNT=0
  PARSE_FAIL_COUNT=0
  STATE_STATUS="passed"
  log_line "pass" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target)"
  write_state "passed"
  emit_system_message "[codex-gate] PASS: Codex 검증 완료. blocking issue 없음, 수정사항 없음. 대상: $TRIG_CSV"
  exit 0
fi

# ── 5c) verdict == fail ──────────────────────────────────────────────────
PARSE_FAIL_COUNT=0   # 파싱은 성공했으므로 연속 파싱 실패 카운터 리셋
FAIL_COUNT=$((FAIL_COUNT + 1))
if [ "$FAIL_COUNT" -ge 3 ]; then
  escalate "Codex 검증 fail 3회 도달 — 사람 확인 필요 (triggered: $TRIG_CSV)"
  STATE_STATUS="escalated"
  FAIL_COUNT=0; PARSE_FAIL_COUNT=0   # escalation 발동 → streak 리셋(다음 수정분은 0부터 재누적)
  log_line "fail(escalated)" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target)"
  write_state "escalated"
  exit 0
fi
STATE_STATUS="failing"
write_state "failing"
log_line "fail" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target)"
{
  echo "[codex-gate] Codex 검증 FAIL — 종료 보류. 아래 항목을 해소한 뒤 다시 종료하십시오:"
  cat "$ISSUES_FILE" 2>/dev/null
} >&2
exit 2

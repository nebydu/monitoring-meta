#!/usr/bin/env bash
# codex-gate.sh — monitoring-meta Stop hook (Git Bash 전용)
# Codex 호출 경로 = fallback(codex exec). 이유: codex-cli 0.134.0의 `codex review`가 --output-schema/--json 둘 다 미지원.
# JSON 파싱 = python. 이유: 이 환경에 jq 미설치(설치본 없음, Python 3.14 가용).
# 검증 윈도우(2026-06-11 사각지대 보완): 종전 BASE=HEAD는 미커밋 변경만 봐서 같은 턴에 커밋하면
# 게이트가 우회됐다(통합본 v0.10이 실제 사례). 이제 상태 파일의 verified_commit(마지막 검증 commit)
# 기준으로 "커밋분 + 작업 트리 + 미추적"을 모두 윈도우에 포함한다. 전진 규칙: 윈도우가 BASE..HEAD
# 전 구간을 커버했고 검증이 실제로 완료(skip=트리거 0 확인 / pass)됐을 때만 전진.
# escalated(강제 통과)는 전진하지 않는다 — 미검증 내용이 baseline로 흡수되는 것 차단. 같은 diff의
# 재방문은 gate_key 캐시(already_force_passed)가 막으므로 deadlock 없음. 해소=수정 또는 state 삭제.
# 단절 이력(vc가 HEAD와 공통 조상 없음)과 기준 없음(vc·origin/main 공통 조상 모두 부재)은
# fail-closed — 게이트가 종료를 차단한다. 통과 가능한 BASE는 vc/merge-base/bootstrap-origin/
# bootstrap-origin-mb(diverged branch는 origin/main과의 공통 조상)/empty-tree 5종뿐.
# 해소 = 사람이 해당 커밋 구간의 spec 변경을 직접 검증 완료한 뒤 verified_commit 갱신, 또는 push로
# origin/main 생성(state 삭제 시에도 origin이 있으면 bootstrap이 미push 커밋을 포함해 재검증).
# 차단 이벤트는 BLOCK_LOG에 기록한다(escalation 로그와 분리 — 강제 통과와 차단은 다른 사건).
set -euo pipefail

# ── 경로 ────────────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel)"
CLAUDE_DIR="$REPO_ROOT/.claude"
STATE_FILE="$CLAUDE_DIR/.codex-gate-state"
LOG_FILE="$CLAUDE_DIR/codex-gate.log"
ESC_LOG="$CLAUDE_DIR/codex-gate-escalation.log"
BLOCK_LOG="$CLAUDE_DIR/codex-gate-block.log"   # fail-closed 차단(단절·기준 없음) 전용 — 강제 통과(ESC_LOG)와 분리
SCHEMA="$CLAUDE_DIR/codex-schema.json"
LAST_MSG="$CLAUDE_DIR/.codex-last-message.json"
ISSUES_FILE="$CLAUDE_DIR/.codex-gate-issues.txt"
CODEX_ERR="$CLAUDE_DIR/.codex-gate-stderr.txt"

# empty tree object hash — 아직 커밋이 없을 때(HEAD 부재) diff 비교 기준
EMPTY_TREE="4b825dc642cb6eb9a060e54bf8d69288fbee4904"

# ── 유틸 ────────────────────────────────────────────────────────────────
now_iso() { date +%Y-%m-%dT%H:%M:%S%z; }   # date -Is 대체 — MSYS/Git Bash 버전별 -I 지원 차이 방어
log_line() { # verdict | crit_count | viol_count | triggered_files
  printf '%s | %s | %s | %s | %s\n' "$(now_iso)" "$1" "$2" "$3" "$4" >> "$LOG_FILE"
}
emit_system_message() { # message
  # stdout을 UTF-8로 고정: Windows 콘솔 기본 인코딩(cp949)이 em-dash 등을 못 실어 크래시하는 것 방지
  python -c 'import json, sys; sys.stdout.reconfigure(encoding="utf-8"); print(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False))' "$1"
}
escalate() { # message
  printf '%s | %s\n' "$(now_iso)" "$1" >> "$ESC_LOG"
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
        # cache_status = 에피소드 캐시 축(구버전 필드명 status에서 개명 — 하위 호환 폴백 유지)
        status = str(d.get("cache_status") or d.get("status") or "new")
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
write_state() { # status [new_verified_commit]
  # vc 전진을 같은 1회 기록에 포함(원자성) — 인자 생략/빈 값이면 기존 vc 보존.
  python -c '
import json, sys
path, status, gate_key, diff_hash, triggered, fail, parse, updated_at, new_vc = sys.argv[1:10]
old = {}
try:
    with open(path, "r", encoding="utf-8") as fp:
        old = json.load(fp)
except Exception:
    pass
# cache_status = "이 gate_key(diff 에피소드)의 캐시 상태" 축. 마지막 hook 결과 축은 last_result.
data = {
    "gate_key": gate_key,
    "triggered": triggered,
    "diff_hash": diff_hash,
    "fail_count": int(fail),
    "parse_fail_count": int(parse),
    "cache_status": status,
    "updated_at": updated_at,
}
vc = new_vc or str(old.get("verified_commit") or "")
if vc:
    data["verified_commit"] = vc
    data["vc_updated_at"] = updated_at if new_vc else str(old.get("vc_updated_at") or "")
# last_result = "마지막 hook 결과" 단일 축 — skip(update_verified_commit)과 에피소드 status를 통합 표기.
# 상태 파일을 소비하는 자동화는 반드시 last_result를 기준으로 읽는다(status/gate_key는 캐시 축 — 최신 결과 아님).
data["last_result"] = status
with open(path, "w", encoding="utf-8") as fp:
    json.dump(data, fp, ensure_ascii=False, indent=2)
    fp.write("\n")
' "$STATE_FILE" "$1" "$GATE_KEY" "$DIFF_HASH" "$TRIG_CSV" "$FAIL_COUNT" "$PARSE_FAIL_COUNT" "$(now_iso)" "${2:-}"
}
update_verified_commit() { # commit base_info — skip 경로 전용 state 갱신
  # 캐시 축 필드(gate_key/diff_hash/triggered/fail_count/cache_status)는 보존하고, vc·last_skip_*·
  # last_result를 갱신한다. 구버전 필드명 status는 cache_status로 1회 마이그레이션한다.
  # last_skip_*/last_result는 캐시 축과 독립 — 운영자·자동화는 "마지막 hook 결과"를 last_result로 읽는다.
  [ -z "${1:-}" ] && return 0
  python -c '
import json, sys
path, commit, base_info, updated_at = sys.argv[1:5]
data = {}
try:
    with open(path, "r", encoding="utf-8") as fp:
        data = json.load(fp)
except Exception:
    data = {}
# 구버전(필드명 status) state 마이그레이션 — 캐시 의미 보존 후 개명
if "status" in data and "cache_status" not in data:
    data["cache_status"] = data.pop("status")
data["verified_commit"] = commit
data["vc_updated_at"] = updated_at
data["last_skip_at"] = updated_at
data["last_skip_base_info"] = base_info
data["last_result"] = "skipped"
# baseline이 전진하면 이전 에피소드의 fail streak은 사라진 변경분에 대한 것 — 리셋해 새 에피소드
# 오염 방지(9차 리뷰: 잔존 streak이 이후 무관한 변경의 조기 escalation을 유발하는 edge 차단).
# gate_key/cache_status는 보존 — 동일 diff 재등장 시 캐시 의미가 그대로 유효하다.
data["fail_count"] = 0
data["parse_fail_count"] = 0
with open(path, "w", encoding="utf-8") as fp:
    json.dump(data, fp, ensure_ascii=False, indent=2)
    fp.write("\n")
' "$STATE_FILE" "$1" "${2:-}" "$(now_iso)"
}
log_target() {
  # cache_status = 에피소드 캐시 축 — "마지막 hook 결과"(last_result)와 다름을 로그 명칭으로 구분
  printf '%s | key=%s | cache_status=%s' "$TRIG_CSV" "$GATE_KEY" "${STATE_STATUS:-new}"
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

# ── 2) 검증 윈도우 BASE 결정 + 트리거 가드 ──────────────────────────────
# BASE 결정이 트리거 가드보다 먼저다: 단절/기준 없음 상태에서는 커밋분의 트리거 변경 여부 자체를
# 열거할 수 없으므로, 트리거 유무와 무관하게 fail-closed 차단이 유일하게 안전하다.
# (트리거 가드는 BASE가 신뢰 가능한 경우에만 의미가 있다.)
# 검증 윈도우 BASE 결정 — verified_commit(vc) 이후 커밋분도 포함 (머리 주석 참조)
CUR_HEAD=""
if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  CUR_HEAD="$(git rev-parse HEAD)"
fi
VERIFIED_COMMIT="$(python -c '
import json, sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as fp:
        print(str(json.load(fp).get("verified_commit") or ""))
except Exception:
    print("")
' "$STATE_FILE" 2>/dev/null || echo "")"

BASE_KIND=""       # 통과 가능: vc | merge-base | bootstrap-origin | bootstrap-origin-mb | empty-tree / 차단: disconnected | no-baseline
VC_ADVANCE_OK=1    # 이번 윈도우가 BASE..HEAD 전 구간을 커버 → skip/pass/escalated 시 vc 전진 허용
if [ -z "$CUR_HEAD" ]; then
  BASE="$EMPTY_TREE"; BASE_KIND="empty-tree"; VC_ADVANCE_OK=0
elif [ -z "$VERIFIED_COMMIT" ]; then
  # 부트스트랩 — origin/main이 HEAD의 조상이면 그것을 기준으로(미push 커밋 = 미검증 가능 구간을
  # 첫 실행 윈도우에 포함 — "직전에 커밋된 변경이 부트스트랩으로 흡수"되는 사각지대 차단).
  # origin/main이 없거나 조상이 아니면 HEAD(소급 검증 없음 — 로그에 명시).
  ORIGIN_MAIN="$(git rev-parse --verify -q origin/main 2>/dev/null || true)"
  if [ -n "$ORIGIN_MAIN" ] && git merge-base --is-ancestor "$ORIGIN_MAIN" "$CUR_HEAD" 2>/dev/null; then
    BASE="$ORIGIN_MAIN"; BASE_KIND="bootstrap-origin"
  elif [ -n "$ORIGIN_MAIN" ] && MB_BOOT="$(git merge-base "$ORIGIN_MAIN" "$CUR_HEAD" 2>/dev/null)" && [ -n "$MB_BOOT" ]; then
    # origin/main이 조상은 아니지만 공통 조상이 있는 경우(diverged feature branch) — 공통 조상부터
    # 부트스트랩(9차 리뷰: 조상 강제 시 일반 feature branch에서 영구 차단됨)
    BASE="$MB_BOOT"; BASE_KIND="bootstrap-origin-mb"
  else
    # 기준(vc·origin/main 공통 조상) 없음 — 커밋 이력을 검증할 방법이 없으므로 단절 이력과 동일하게
    # fail-closed로 차단한다(8차 리뷰 반영 — 종전 "작업 트리만 검사 후 통과"는 state 삭제/신규
    # repo에서 커밋된 트리거 변경의 우회 경로였음). 통과 가능한 BASE는 머리 주석의 5종으로 고정.
    NO_BASELINE_MSG="검증 기준 없음(verified_commit·origin/main 공통 조상 부재) — 커밋 이력 검증 불가(강제 통과 아님). 해소: push로 origin/main 생성(=push된 이력을 신뢰 기준으로 채택), 또는 사람이 전체 커밋 이력의 spec 변경을 직접 검증 완료한 경우에만 .claude/.codex-gate-state에 verified_commit을 현재 HEAD($(printf '%s' "$CUR_HEAD" | cut -c1-12))로 기록(이 기록 자체가 '사람이 이 구간을 검증했다'는 선언이며, 검증 없이 기록하면 baseline이 미검증 이력을 흡수한다)하고 검증 사유를 codex-gate-block.log에 한 줄 남길 것"
    printf '%s | BLOCK(기준 없음) | %s\n' "$(now_iso)" "$NO_BASELINE_MSG" >> "$BLOCK_LOG"
    log_line "blocked(no-baseline)" 0 0 "base=no-baseline head=$(printf '%s' "$CUR_HEAD" | cut -c1-12)"
    emit_system_message "[codex-gate] BLOCK(기준 없음): $NO_BASELINE_MSG"
    {
      echo "[codex-gate] BLOCK(기준 없음) — 종료 보류: $NO_BASELINE_MSG"
    } >&2
    exit 2
  fi
elif git merge-base --is-ancestor "$VERIFIED_COMMIT" "$CUR_HEAD" 2>/dev/null; then
  BASE="$VERIFIED_COMMIT"; BASE_KIND="vc"
else
  # rebase·amend로 vc가 조상이 아님 → 공통 조상부터 보수적 확대 윈도우
  MB="$(git merge-base "$VERIFIED_COMMIT" "$CUR_HEAD" 2>/dev/null || true)"
  if [ -n "$MB" ]; then
    # 정책(고정): merge-base 윈도우는 HEAD의 신규 이력 전체(merge-base..HEAD + 작업 트리)를 커버하므로
    # 검증 완료(pass / 트리거 0 skip) 시 vc 전진을 허용한다. rebase 전 옛 이력은 HEAD에서 도달
    # 불가능하므로 윈도우 커버리지와 무관하다.
    # INFO는 별도 emit하지 않고 최종 결과 메시지에 합친다 — Stop hook stdout은 단일 JSON 기대(8차 리뷰).
    BASE="$MB"; BASE_KIND="merge-base"
  else
    # 단절 이력 — vc..HEAD 커밋분을 열거·검증할 수 없다(merge-base 부재). 부분 검사 후 SKIP/PASS를
    # 내보내면 "통과처럼 동작"하므로 fail-closed로 게이트를 차단한다(4차 리뷰 반영).
    # 해소책은 verified_commit 수동 갱신 단일 경로 — state 삭제는 origin 없는 환경에서 부트스트랩
    # 미검증 경로로 빠져 fail-closed 약속을 깨므로 안내하지 않는다(7차 리뷰 반영).
    DISCONNECT_MSG="verified_commit($(printf '%s' "$VERIFIED_COMMIT" | cut -c1-12))가 HEAD($(printf '%s' "$CUR_HEAD" | cut -c1-12))와 단절 — 커밋분 검증 불가(강제 통과 아님). 해소: 사람이 해당 커밋 구간의 spec 변경을 직접 검증 완료한 경우에만 .claude/.codex-gate-state의 verified_commit을 현재 HEAD로 갱신하고, 검증 사유를 codex-gate-block.log에 한 줄 남길 것"
    printf '%s | BLOCK(단절) | %s\n' "$(now_iso)" "$DISCONNECT_MSG" >> "$BLOCK_LOG"
    log_line "blocked(disconnected)" 0 0 "base=disconnected head=$(printf '%s' "$CUR_HEAD" | cut -c1-12)"
    # stderr(차단 채널 — 기존 FAIL 흐름과 동일)와 systemMessage(structured 소비자용)를 병행 발신
    emit_system_message "[codex-gate] BLOCK(단절 이력): $DISCONNECT_MSG"
    {
      echo "[codex-gate] BLOCK(단절 이력) — 종료 보류: $DISCONNECT_MSG"
    } >&2
    exit 2
  fi
fi
BASE_INFO="base=${BASE_KIND}:$(printf '%s' "$BASE" | cut -c1-12) head=$(printf '%s' "${CUR_HEAD:-(none)}" | cut -c1-12) vc_advance=$VC_ADVANCE_OK"
# 모드별 정보 주석 — 최종 결과 메시지에 합쳐 단일 systemMessage 유지(stdout JSON 1개).
# 단절 이력·기준 없음은 위에서 fail-closed로 차단되어 여기 안 온다.
MERGE_NOTE=""
[ "$BASE_KIND" = "merge-base" ] && MERGE_NOTE=" (rebase/amend 감지 — 공통 조상부터 확대 재검증함)"
[ "$BASE_KIND" = "bootstrap-origin" ] && MERGE_NOTE=" (부트스트랩 — origin/main 이전 이력은 push된 신뢰 기준으로 간주)"
[ "$BASE_KIND" = "bootstrap-origin-mb" ] && MERGE_NOTE=" (부트스트랩 — origin/main과의 공통 조상 이전 이력은 push된 신뢰 기준으로 간주)"
# pass 시 write_state에 넘길 vc 전진 값(윈도우 미커버 시 빈 값 = 보존).
# escalated는 검증 미완이므로 항상 빈 값 — 머리 주석의 전진 규칙 참조.
# REVIEW_INPUT(§3)도 같은 $BASE로 diff를 만들므로, 전진 조건과 Codex가 실제로 검토한 범위는
# 구조적으로 동일 윈도우다(4차 리뷰의 "전진 조건↔리뷰 범위 결합" 확인 사항).
ADVANCE_VC=""
[ "$VC_ADVANCE_OK" = "1" ] && ADVANCE_VC="$CUR_HEAD"

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
  # BASE..HEAD+작업트리에 트리거 파일 없음이 확인된 윈도우(조상 BASE)에서만 vc 전진 — 단절 fallback은 금지.
  # 의도적으로 vc만 갱신(status/gate_key 미기록): skip에서 full write_state를 하면 gate_key가 비어
  # 직전 passed/escalated 캐시가 파괴된다. vc(baseline 축)와 status(마지막 리뷰 에피소드 축)는 독립 축.
  if [ "$VC_ADVANCE_OK" = "1" ]; then
    update_verified_commit "$CUR_HEAD" "$BASE_INFO"
  fi
  log_line "skipped" 0 0 "(no gate-triggering change) | $BASE_INFO | cache_status=preserved"
  emit_system_message "[codex-gate] SKIP: Codex 검증 트리거 대상(spec docs/adr/handoff-adr · harness hooks/settings/schema · feature docs/features) 변경 없음. ($BASE_INFO)$MERGE_NOTE"
  exit 0
fi

# ── 3) 검토 입력 구성 (트리거 파일 diff + 미추적 신규 파일 내용) ──────────
REVIEW_INPUT=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1 || [ ! -e "$REPO_ROOT/$f" ]; then
    # 추적 중인 파일과 "윈도우 내 삭제"(BASE에 있고 인덱스·디스크에 없음) 모두 diff가 정확히 표현한다.
    # 삭제 파일을 미추적 분기로 보내면 cat 실패(exit 1)가 set -e로 hook 전체를 조용히 죽인다
    # (2026-06-13 실사례 — stub 삭제 커밋이 윈도우에 들어오자 "non-blocking, no stderr" 실패).
    REVIEW_INPUT="${REVIEW_INPUT}
$(git -c core.quotepath=false diff "$BASE" -- "$f")"
  else
    # 미추적 신규 파일은 diff에 안 잡히므로 내용을 직접 합류
    REVIEW_INPUT="${REVIEW_INPUT}
--- NEW FILE: ${f} ---
$(cat "$REPO_ROOT/$f" 2>/dev/null || true)"
  fi
done <<EOF
$TRIGGERED
EOF

# ── 검토 프롬프트 구성 — spec/harness 모드를 합산(둘 다면 병합, 어느 한쪽 지시도 누락되지 않게) ──
SPEC_PROMPT="통합본(docs/master-design.md) 내부 일관성 + 8토픽 spec(kafka-payloads, envelope) 정합성 + ADR 결정과 spec 정의의 불일치 + Open question으로 남겨야 할 사항을 무심코 결정한 흔적이 있는지 검토. handoff/adr-*/*.md가 포함되면 ADR/최종 handoff/사전 분석 문서 간 위상 충돌도 검토."
HARNESS_PROMPT="Claude Code Stop hook/harness 변경 리뷰. Bash/Windows Git Bash 호환성, 상태 파일/캐시 로직, trigger 범위, fail/pass/escalation 흐름, 로그와 systemMessage가 오해를 만들 가능성을 중점 검토."
FEATURE_PROMPT="docs/features/ 경로의 파일은 기술(descriptive) 문서 레이어다 — 코드의 현재 구현 흐름을 서술하며 규범(spec)이 아니다. 이 경로의 파일에 한해 다음만 검토: (1) 통합본(docs/master-design.md)·ADR을 새로 결정하거나 8토픽 payload/envelope 규범을 변경한 흔적, (2) 통합본·ADR과 충돌하는 서술, (3) 미구현 spec을 구현된 것처럼 단정한 곳, (4) 코드 앵커로 라인번호·commit hash를 쓴 곳(금지), (5) 사전 분석/계획 문구가 규칙 문서 위상에 잔존. docs/features/ 파일에는 통합본 자체의 내부 일관성·8토픽 payload 정합성을 적용하지 않는다(이 레이어는 포인터만 단다). diff에 docs/features/ 외 파일(통합본·adr·handoff 등)이 함께 있으면 그 파일에는 이 제한을 적용하지 말고 해당 파일용 spec 검토 지시를 따른다."
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
    log_line "parse_error(escalated)" 0 0 "$(log_target) | $BASE_INFO"
    # escalated는 검증 미완 — vc 전진하지 않음(미검증 흡수 차단). 같은 diff 재방문은 gate_key 캐시가 skip.
    write_state "escalated"
    exit 0
  fi
  STATE_STATUS="parse_error"
  write_state "parse_error"
  log_line "parse_error" 0 0 "$(log_target) | $BASE_INFO"
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
  log_line "pass" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target) | $BASE_INFO"
  # 단절 fallback(BASE=HEAD)은 커밋분(vc..HEAD)을 검증하지 않았으므로 pass여도 vc 전진 금지(ADVANCE_VC="").
  write_state "passed" "$ADVANCE_VC"
  # 단절 이력·기준 없음은 BASE 결정 단계에서 fail-closed로 차단되어 여기 도달하지 않는다.
  emit_system_message "[codex-gate] PASS: Codex 검증 완료 — blocking issue 없음. 대상: $TRIG_CSV ($BASE_INFO)$MERGE_NOTE"
  exit 0
fi

# ── 5c) verdict == fail ──────────────────────────────────────────────────
PARSE_FAIL_COUNT=0   # 파싱은 성공했으므로 연속 파싱 실패 카운터 리셋
FAIL_COUNT=$((FAIL_COUNT + 1))
if [ "$FAIL_COUNT" -ge 3 ]; then
  escalate "Codex 검증 fail 3회 도달 — 사람 확인 필요 (triggered: $TRIG_CSV)"
  STATE_STATUS="escalated"
  FAIL_COUNT=0; PARSE_FAIL_COUNT=0   # escalation 발동 → streak 리셋(다음 수정분은 0부터 재누적)
  log_line "fail(escalated)" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target) | $BASE_INFO"
  # escalated는 검증 미완 — vc 전진하지 않음(미검증 흡수 차단). 같은 diff 재방문은 gate_key 캐시가 skip.
  write_state "escalated"
  exit 0
fi
STATE_STATUS="failing"
write_state "failing"
log_line "fail" "$CRIT_COUNT" "$VIOL_COUNT" "$(log_target) | $BASE_INFO"
{
  echo "[codex-gate] Codex 검증 FAIL — 종료 보류. 아래 항목을 해소한 뒤 다시 종료하십시오:"
  cat "$ISSUES_FILE" 2>/dev/null
} >&2
exit 2

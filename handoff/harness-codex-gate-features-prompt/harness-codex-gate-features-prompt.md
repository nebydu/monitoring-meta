# 작업 spec — harness-codex-gate-features-prompt

> **상태: ✅ 적용 완료** — codex-gate.sh에 (c) 분리 프롬프트 반영(이 핸드오프와 같은 커밋). 아래는 적용 spec 원문(이력 보존).
>
> **harness 작업(meta 자신의 Stop hook 수정).** 형제 repo 무관. 코드 수정 대상 = monitoring-meta repo 로컬 `.claude/hooks/codex-gate.sh` 1개 — 여기서 "harness"는 **harness repo가 아니라 meta 자신의 hook(운영 스크립트) 영역**을 뜻한다. meta `.claude/settings.json`의 Stop hook이 이 로컬 파일을 직접 호출한다(harness 글로벌 plugin 미사용).
> 이 핸드오프는 "기능 문서 레이어 신설" 작업의 **Step 4 결정((c) 분리 프롬프트)**에 따른 분리 산출물이다.
> 결정 근거: descriptive 문서(`docs/features/`)를 normative spec 프롬프트로 검증하면 무익한 "8토픽 payload 정합 검증 불가" 항목이 반복된다(실증). 위상에 맞는 전용 프롬프트로 분리한다.

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID | `harness-codex-gate-features-prompt` |
| 대상 | meta harness (`.claude/hooks/codex-gate.sh`) |
| 작성일 | 2026-06-10 |
| 근거 결정 | 기능 문서 레이어 작업 Step 4 = (c) 분리 프롬프트 (사람 승인 2026-06-10) |

## 2. 배경 / 목표

`docs/features/`는 **기술(descriptive)** 문서 레이어다(규범 아님). 현재 codex-gate.sh 트리거 가드의 `case "$f" in ... docs/*.md)`가 `*`의 `/` 가로지름 때문에 `docs/features/**.md`를 **spec 변경으로 포착**하고, SPEC_PROMPT("통합본 내부 일관성 + 8토픽 payload/envelope 정합 + ADR 불일치")로 검증한다. 이 프롬프트는 descriptive 문서에 부적합 → Codex가 매 호출 "diff에 규범 본문 없어 정합 검증 불가"라는 무익 항목을 반환한다.

**목표:** `docs/features/`만을 위한 **descriptive 전용 프롬프트 분기**를 신설해, 위상에 맞는 항목만 검토하게 한다. 자동 게이트는 유지(통합본/ADR 충돌 서술·규범 무단 결정·미구현 단정·코드 앵커 위반 검출).

## 3. 작업 범위

### 해야 할 것 (codex-gate.sh 변경점)

1. **트리거 분기 추가** — `case "$f" in` 블록에서 `docs/phase0-snapshot/*) ;;` 다음, **`docs/*.md)` 보다 먼저**(case는 첫 매치 우선) 분기 추가:
   ```sh
   docs/features/*.md) FEATURE_TRIGGERED="${FEATURE_TRIGGERED}${f}"$'\n' ;;
   ```
   → 신규 변수 `FEATURE_TRIGGERED`에 모은다(기존 `SPEC_TRIGGERED`/`HARNESS_TRIGGERED`와 동급).

2. **CSV 산출 추가** — `SPEC_CSV`/`HARNESS_CSV` 옆에 `FEATURE_CSV` 추가(동일 패턴: `grep -v '^$' | sort -u | tr '\n' ',' | sed 's/,$//' || true`).

3. **TRIGGERED 합산에 포함** — `TRIGGERED="${SPEC_TRIGGERED}${HARNESS_TRIGGERED}${FEATURE_TRIGGERED}"` (리뷰 입력 구성·미추적 신규 파일 합류 루프가 features 파일도 포함하도록).

4. **descriptive 전용 프롬프트 정의** — `FEATURE_PROMPT`:
   > "이 diff는 기술(descriptive) 문서 레이어 `docs/features/`다 — 코드의 현재 구현 흐름을 서술하는 문서이며 규범(spec)이 아니다. 다음만 검토하라: (1) 통합본 v0.9·ADR을 새로 **결정**하거나 8토픽 payload/envelope **규범을 변경**한 흔적, (2) 통합본·ADR과 **충돌하는 서술**, (3) **미구현 spec을 구현된 것처럼 단정**한 곳, (4) 코드 앵커로 **라인번호·commit hash**를 쓴 곳(금지), (5) 사전 분석/계획 문구가 규칙 문서 위상에 잔존. **통합본 자체의 내부 일관성·8토픽 payload 정합성은 이 문서의 검토 대상이 아니다**(이 레이어는 포인터만 단다). codex-schema.json 형식의 JSON으로만 응답."

5. **PROMPT 머지에 합산** — 기존 spec+harness 머지 패턴과 동일하게:
   ```sh
   [ -n "$FEATURE_CSV" ] && PROMPT="${PROMPT:+$PROMPT
   }$FEATURE_PROMPT"
   ```
   (features-only면 FEATURE_PROMPT만, features+일반 docs 동시 변경이면 SPEC_PROMPT와 합산 — 두 위상 지시 모두 전달.)

### 하지 말 것 (out of scope)

- `codex-schema.json` 변경 금지(verdict/critical_issues/spec_violations 공통 스키마 그대로 사용 — descriptive 검토도 동일 출력 구조로 충분).
- gate_key/상태머신/fail-streak/escalation 로직 변경 금지(PROMPT가 gate_key 입력에 이미 포함 → 프롬프트 분기만으로 stale PASS 재사용 없이 새 기준 재검증됨).
- `docs/features/` 외 트리거 범위 변경 금지.

## 4. 리스크 / 되돌리기

- **case 순서 함정**: `docs/features/*.md)`가 `docs/*.md)` 뒤에 오면 영영 매치 안 됨(첫 매치 우선). 반드시 앞에 배치.
- **`set -euo pipefail`**: 신규 변수 초기화 누락 시 unbound 에러. `FEATURE_TRIGGERED=""`를 `SPEC_TRIGGERED=""` 옆에서 초기화.
- 되돌리기: `git revert`만(상태 파일 `.codex-gate-state`는 gate_key 불일치로 자동 무효화 — 수동 삭제 불필요).

## 5. 완료 기준 / 검증

- [ ] `docs/features/_template.md` 한 줄 수정 후 세션 종료 → Codex 호출 프롬프트가 FEATURE_PROMPT임(SPEC_PROMPT의 "8토픽 payload 정합" 항목 **미출현**), `codex-gate.log` verdict 기록 정상.
- [ ] `docs/통합본_v0_9.md` + `docs/features/*.md` 동시 변경 → 두 프롬프트 **합산** 전달 확인.
- [ ] features 무변경·일반 spec만 변경 → 기존 SPEC_PROMPT 단독(회귀 없음).
- [ ] `bash -n .claude/hooks/codex-gate.sh` 문법 통과.

## 6. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": [".claude/hooks/codex-gate.sh"],
  "findings": ["변경 요약 / 검증 결과"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

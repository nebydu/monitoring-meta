# codex-gate verified_commit 수동 전진 — 예외 감사 기록 (2026-06-13)

> **성격**: fail-closed 게이트의 baseline(verified_commit)을 사람이 수동 전진시킨 **예외 조치의 감사 기록**. proposal-review(revise, C1=감사 기록 구조화 / C2=재발 통제) 보완으로 작성. 1줄 `codex-gate-block.log`를 재현 가능한 증거 묶음으로 보강한다.

## 1. 사건 요약

- **FAIL 이벤트**: `2026-06-13T17:03:00` codex-gate FAIL (fail_count 1). 윈도우 `base=vc:e737016 head=5b54a30`, 트리거 파일 = `docs/phase1/ROADMAP_PHASE1_v0_3.md` 1개뿐.
- **조치**: verified_commit `e737016b865a` → `5b54a30b2799` 수동 전진. `2026-06-13T18:25:36`.
- **결과**: 수동 재실행 SKIP/EXIT=0 (`base=vc:5b54a30 head=5b54a30`).

## 2. 증거 묶음 (재현 가능)

| 항목 | 값 |
|---|---|
| 커밋 범위(전진 구간) | `e737016b865a..5b54a30b2799` |
| 이 구간 게이트 트리거 파일 | `docs/phase1/ROADMAP_PHASE1_v0_3.md` (1개) |
| 이 구간 **비트리거** 파일 | `handoff/phase1-041/{000-impact,infra,hub,script-agent}.md` (handoff는 `handoff/adr-*`만 트리거 — 비대상) |
| T4-5 evidence 근거 커밋 | `e737016` (kafka-payloads/envelope stale 정정) |
| 그 근거의 PASS 로그 | `codex-gate.log:219` — `2026-06-13T14:41:07 \| pass \| ... docs/envelope.md,docs/kafka-payloads.md,docs/phase1/ROADMAP_PHASE1_v0_3.md \| ... base=vc:53a1224a2f26 head=e737016b865a` → 이 PASS가 verified_commit을 e737016로 전진시킴 |
| T4-2 evidence 근거 | `handoff/phase1-041/phase1-041-000-impact.md` §5 (analyzer blocker 0 — 통합본 Open/미결 ADR 저촉 없음) + 사람 §5 결정 4건 |
| 사용자 승인 | AskUserQuestion 2026-06-13 ("verified_commit 전진 (권장)" 선택) |
| block.log 기록 | `codex-gate-block.log` — VERIFIED-ADVANCE(manual, false-positive) 1줄 |

## 3. 수동 대조 체크리스트 결과 (메인 세션 직접 검증)

ROADMAP 변경(5b54a30)이 근거 문서·확정 결정과 정합한지 대조:

- [x] **계약 *내용* 변경 0** — kafka-payloads/envelope/통합본 §8.3 무수정(이번 윈도우엔 ROADMAP만).
- [x] **T4-2 status=IN_PROGRESS(발주 완료)** — `phase1-041` handoff 존재와 일치.
- [x] **§5 결정 4건**(payload 토픽만 분리/동시 컷오버/env 2키/회귀 R-A+R-B+R-C) — `phase1-041-000-impact.md` §5 + 사람 확정과 일치.
- [x] **T4-5 status=IN_PROGRESS(1차 정합화)** — e737016에서 설정, 14:41 PASS 받음.
- [x] **액티브 큐 이동**(지금 가능→발주 완료) — 발주 상태와 일치.
- **부정합 발견: 0.**

## 4. verified_commit 수동 전진 허용 조건 (재발 시 기준 — 5개 전부 충족 시에만)

1. 현재 윈도우의 **트리거 파일이 계획 추적 반영뿐**(ROADMAP status/evidence)이고 계약 *내용* 변경이 없다.
2. evidence가 인용하는 **근거가 이미 PASS된 직전 커밋**(codex-gate.log로 확인 가능)이거나 **게이트 정책상 비트리거 문서**(handoff 등)다.
3. ROADMAP 변경의 정합성을 **독립 대조**(§3 체크리스트)해 부정합 0.
4. **사용자 승인** 존재.
5. **block.log + 본 예외 감사 기록**에 증거 묶음을 남긴다.

> 위 5개 중 하나라도 불충족이면 수동 전진하지 않는다 — 실제 검증 누락을 오탐으로 오인할 위험. 특히 트리거 파일에 계약 문서(kafka-payloads/envelope/통합본/adr)가 포함되면 그건 진짜 검증 대상이므로 우회 금지.

## 5. 되돌리기

- state 파일: `C:\workspace\monitoring\monitoring-meta\.claude\.codex-gate-state` (git 비추적).
- 복원값: `verified_commit`을 `e737016b865ad35eb1b8e4615213df09d24baf44`로 되돌리면 FAIL 상태 복원.
- FAIL 재현: 복원 후 `'{}' | bash .claude/hooks/codex-gate.sh` → `base=vc:e737016 head=5b54a30` 윈도우로 ROADMAP만 트리거돼 동일 FAIL.

## 6. 후속 작업 (수동 우회 패턴화 차단 — proposal-review C2)

**근본 해소 방향(우선순위)**: ROADMAP 트리거 *제외*보다 — ROADMAP은 ADR status 등 실제 spec 사실도 담으므로 — **ROADMAP status/evidence 변경 시 참조 handoff(또는 직전 PASS된 근거 커밋)를 게이트 검토 입력에 포함**하도록 `codex-gate.sh`/SPEC_PROMPT를 개선한다(codex-gate.log로 직전 PASS 근거를 추적해 diff에 합류, 또는 ROADMAP이 인용한 handoff를 입력에 동반). 이는 hook 변경이라 별도 작업 + 게이트 재검증 동반([[gate-review-loop-lesson]] — 1~2회 제한).

**임시 규칙**: 그 hook 개선 전까지 ROADMAP-only 트리거 FAIL은 §4 허용 조건 5개 충족 확인 후에만 수동 전진. **T4-2 구현 후 meta 복귀 게이트에서 ROADMAP을 DONE 전환할 때 재발 예상** — 그때도 §4 적용.

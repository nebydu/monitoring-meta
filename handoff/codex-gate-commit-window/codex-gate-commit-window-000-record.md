# 작업 기록 — codex-gate 검증 윈도우 도입 (commit-window)

> **work-id**: `codex-gate-commit-window`
> **성격**: meta 자체 hook(`.claude/hooks/codex-gate.sh`) 개선 기록 + 12라운드 Codex 자기 검증 추적. harness plugin core 반영은 `codex-gate-commit-window-harness.md`로 분배.
> **작성일**: 2026-06-11
> **사람 결정**: ① meta hook은 meta가 직접 수정(§0 자체 자동화 예외 명문화, 2026-06-11) ② 리뷰 12라운드 후 사람 승인으로 종결(escalation의 "사람 확인" 충족, 2026-06-11)

## 1. 문제 (사각지대)

Stop hook 트리거가 "HEAD 대비 작업 트리 diff(미커밋+미추적)"만 봐서, **세션이 spec 변경을 같은 턴에 커밋하면 hook 실행 시점엔 작업 트리가 깨끗 → 무조건 skip**. 통합본 v0.10(70d6a7c)이 실제 우회 사례(수동 동등 검증으로 보완했음 — `handoff/v0-10-notation/codex-gate-v0-10-notation-20260611.json`).

## 2. 설계 (최종)

상태 파일(`.claude/.codex-gate-state`)에 `verified_commit`(vc) 추가. 검증 윈도우 = **BASE..HEAD 커밋분 + 작업 트리 + 미추적**.

**통과 가능한 BASE 5종** (그 외 전부 fail-closed 차단):

| BASE_KIND | 조건 | vc 전진 |
|---|---|---|
| `vc` | vc가 HEAD의 조상 | skip(트리거 0)·pass 시 HEAD로 |
| `merge-base` | vc 비조상(rebase/amend) → 공통 조상 | 동일(윈도우가 신규 이력 전체 커버) |
| `bootstrap-origin` | vc 없음, origin/main이 조상 | 동일(push된 이력=신뢰 기준) |
| `bootstrap-origin-mb` | vc 없음, origin/main과 공통 조상만(diverged) | 동일 |
| `empty-tree` | HEAD 없음 | 전진 없음 |

**차단(fail-closed, exit 2)**: `disconnected`(vc·HEAD 공통 조상 없음), `no-baseline`(vc·origin/main 기준 모두 없음). 해소 = 사람이 직접 검증 후 vc 수동 기록(+사유를 `codex-gate-block.log`에) 또는 push로 origin/main 생성.

**전진 금지**: escalated(강제 통과 — 미검증 흡수 차단, 동일 diff 재방문은 gate_key 캐시가 skip), fail/parse_error, 차단 경로.

**상태 축 분리**: `cache_status`(에피소드 캐시, 구 `status`에서 개명+마이그레이션) ↔ `last_result`(마지막 hook 결과 — 자동화는 이것만 소비). skip 시 fail streak 리셋(사라진 변경분의 streak이 새 에피소드 오염 방지). 차단 로그는 `codex-gate-block.log`로 분리(escalation 로그와 다른 사건).

**메시지**: stdout systemMessage는 실행당 단일 JSON(Stop hook 계약). merge-base/bootstrap은 최종 메시지에 주석 합류.

## 3. 검증

- 격리 스크래치 repo + codex 스텁(토큰 0)으로 시나리오 12종 PASS: 미커밋 트리거 회귀 / **커밋분 트리거(사각지대 해소 핵심 증명)** / pass 후 skip+vc 전진 / 비트리거 커밋 전진 / amend→merge-base / diverged→bootstrap-origin-mb / state 비트리거(gitignore) / 단절 차단+vc 보존 / 기준 없음 차단 / fail 3회 escalation+vc 비전진+already_force_passed 캐시 / skip streak 리셋 / 단일 systemMessage.
- 실전 Codex 자기 검증 12라운드(아래 §4).

## 4. Codex 자기 검증 12라운드 요약

hook 수정분 자체를 게이트가 HARNESS_PROMPT로 리뷰. **1~11차 지적으로 실질 결함 ~15건 수정**(대표: 단절 메시지 모순, 부트스트랩 흡수, escalated 전진 금지, fail-closed 2종, diverged 영구 차단, streak 오염, stdout 단일 JSON, 원자적 state 기록, 로그 축 분리). 12차에서 escalation #4 발동 — **critical 2건이 사실 오류로 판명**되어 사람 승인으로 종결:

- "더티 트리 PASS 후 커밋 시 커밋분 흡수" → **오류**. PASS의 vc=검증 시점 HEAD(커밋 전)이므로 이후 커밋은 vc 이후 이력 — 다음 diff에 나타나 재검증된다(흡수가 아니라 1회 중복 재검증, 의도된 트레이드오프).
- "already_force_passed 분기 부재" → **오류**. hook 무변경 구간에 기존 존재 — diff-only 리뷰의 시야 한계.
- 잔여 spec 지적은 "worktree는 항상 BASE 대비 diff에 포함"을 놓친 오류, 또는 신뢰 기준점(trust anchor) 철학 — origin/main=사람이 publish한 신뢰 기준은 명시된 정책.

## 5. 알려진 한계 (문서화된 트레이드오프)

- 더티 트리 pass 후 동일 내용 커밋 → 1회 중복 재검증(흡수 아님). meta 표준 흐름(턴 내 커밋 후 Stop)에선 미발생.
- bootstrap의 신뢰 기준 = push된 origin/main 이력. push 전 검증을 강제하지는 않음(어떤 baseline 체계든 신뢰 기준점 필요 — 정책으로 명시).
- 수동 vc 기록의 사유 로그는 hook이 강제하지 않음(운영 절차로 안내만).

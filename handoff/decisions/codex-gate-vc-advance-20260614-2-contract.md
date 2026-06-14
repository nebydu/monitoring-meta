# codex-gate verified_commit 수동 전진 — T4-2 계약 갱신 게이트 (2026-06-14, 2차)

> `codex-gate-vc-advance-20260614.md`(ADR#19 전진) 후속. T4-2 계약 문서 갱신(`e7ca16c`)+1차 정정(`f912481`) 후 게이트가 2차 FAIL. **critical 1건은 코드 대조 후 정정**, **나머지 3건은 구조적 오탐**으로 분류해 verified_commit 전진으로 종결. 사용자 승인(AskUserQuestion 2026-06-14 "수동 전진 + 오탐 감사기록").

## 1. 사건

- 윈도우: verified_commit `ae86856` → HEAD. 트리거 = `docs/kafka-payloads.md`·`docs/master-design.md`·`docs/phase1/ROADMAP_PHASE1_v0_3.md`·`docs/features/*`.
- 게이트 FAIL 2회:
  - **1차**(features §0/§9 stale 기준·ROADMAP #5 중복·T4-1 commit hash) → 전부 타당, 정정 커밋 `f912481`.
  - **2차**(아래 §2 4건) → critical 1 정정 + 오탐 3건.

## 2. 2차 지적 분류

| 지적 | 분류 | 처리 |
|---|---|---|
| **critical 1**: features result hop "envelope 3종" 서술 | **실질** | 코드 대조 — `../script-agent/internal/kafka/envelope.go:19` `BuildHeaders`는 **envelope 4종 규약**, `BuildHeaders(id,"")`로 호출 시 **x-trace-id만 생략**(trace 부재). command hop은 "4종(trace 생략)"으로 맞게 썼는데 result hop만 "3종"으로 비대칭 → 통합본 4종 전제와 충돌처럼 보임. "**4종 규약(x-trace-id trace 부재 시 생략)**"으로 정정(`25a65a5`) |
| **spec 2**: features 기준 meta commit이 commit hash | **오탐 (헌장 배치)** | `docs/features/README.md:18` — "기준 meta commit은 **코드 앵커가 아닌 spec 참조 시점 메타데이터**이며 코드 앵커 금지 규칙과 별개"라고 헌장이 명시. `heartbeat-collection.md`·`agent-lifecycle-audit.md` 기존 문서도 hash 사용(확립 패턴). 미변경 |
| **spec 3**: ROADMAP "ADR#19 신설" 근거가 diff에 ADR 파일 없음 | **오탐 (윈도우 밖)** | `adr/0019-result-payload-staging.md`는 `e7b70d6`(verified_commit `ae86856`**보다 이전**)에 실재 — 윈도우 밖이라 diff에 없을 뿐. [[codex-gate-roadmap-falsepos]] 패턴 |
| **spec 4**: T4-2 완료 근거 e2e 결과가 diff에 없음 | **오탐 (비트리거)** | `e2e/results/20260614-164044.md`는 게이트 비트리거라 codex 입력에 미포함. `e7ca16c`에 실재 |

## 3. 증거 (재현 가능)

- adr/0019 실재: `git show e7b70d6:adr/0019-result-payload-staging.md`
- e2e 결과 실재: `e2e/results/20260614-164044.md`(커밋 `e7ca16c`, PASS 64/0/0)
- 헌장: `docs/features/README.md:18`(기준 meta commit = spec 시점 메타, 허용)
- BuildHeaders 4종 규약: `../script-agent/internal/kafka/envelope.go:19` + `envelope_test.go:11`("trace_id 있을 때 4개 헤더 모두 채워진다")

## 4. 조치

verified_commit `ae86856` → 본 감사기록 커밋 전진. `adr/0019`·e2e 결과·계약 문서·features가 윈도우에 흡수되어 **spec 3·4 구조적 오탐이 근본 해소**(전진 후 윈도우 비어 SKIP). critical 1은 코드 대조로 실질 해소(미검증 흡수 아님).

## 5. 허용 조건 (`codex-gate-vc-advance-20260614.md` §4 준용)

1. critical 지적은 **코드 대조로 실질 해소**(추측 아님) — envelope 4종 규약 확인.
2. 오탐 3건은 **구조적**(윈도우 밖 verified 커밋 / 비트리거 입력 / README 헌장 배치) — 계약 *내용* 오류 아님.
3. **사용자 승인** 존재.
4. block.log + 본 감사기록에 증거 묶음.

## 6. 되돌리기

state 파일 `.claude/.codex-gate-state`의 `verified_commit`을 `ae868560c094ca953775ec873f8a959e7351c571`로 복원하면 FAIL 재현.

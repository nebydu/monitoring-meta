# phase1-044 — T4-5 envelope/topic 계약 문서 갱신 (1차 정합화)

> **work-id**: phase1-044 (T4-5) · **owner**: monitoring-meta 단독 · **성격**: 계약 문서(spec) 정합화 — 코드 0, 계약 *내용* 변경 0.
> **status**: T4-5 = **IN_PROGRESS** (1차 정합화 DONE / 2차 갱신은 T4-2 분리 구현 후 meta 복귀 게이트에서).

## 0. 배경

ROADMAP §13 T4-5 = "§7 8토픽 계약 매트릭스 갱신 + drift check". 사용자가 **spec-first 순서**(T4-5 계약 먼저 확정 → T4-2 발주)를 택해, T4-2 발주 전에 계약 문서를 정합화한다. 선행 결정 전부 RESOLVED(D-4(1)·D-4(2)·D-5) — **계약 내용 결정 0**.

## 1. 정합 재확인 결과 (drift check)

계약 3문서 + ROADMAP §7 매트릭스를 8토픽 계약(envelope 4종 적용 / key rule / 명명)에서 전수 대조 — **이미 정합·최신, 내용 변경 0**:

| 축 | 결과 |
|---|---|
| 통합본 §6.9.2·§6.9.5·§8.3(ADR#2 protobuf·#5 명명·#6 키) ↔ `docs/kafka-payloads.md` ↔ `docs/envelope.md` ↔ ROADMAP §7 | key rule(command=`target_agent_id` / result=`agent_id` / audit=actor 단위 / alert=`(rule_id,target_id)` / notification=`incident_id`) 세 문서 일치 |
| §7 매트릭스 | D-4(1)/D-5 반영 최신 — **갱신 불요**(내용 변경 0) |
| 8토픽 명명(규칙 B) | command-topic(단일)·result-topic-job/log·audit-topic·heartbeats-topic(복수형 예외)·alert/notification·metrics-topic(Phase 2) — 세 문서 일치 |

## 2. 정정한 drift — stale 구 분할파일 참조 5곳 (경로/표기만)

통합본이 `docs/master-design.md` 단일 파일로 통합된 뒤 남은 **구 분할파일명 참조**. 계약 *내용*과 무관, 참조 경로/§ 표기만 현행화(open-alignment의 "13장 §A" 표기와 일관):

| 파일 | 위치 | before | after |
|---|---|---|---|
| kafka-payloads.md | 데모 일관성 절 | `v0_9/04_데이터흐름.md` 6.9 매트릭스 | `docs/master-design.md`(통합본) §6.9 데모 일관성 매트릭스 |
| kafka-payloads.md | command-topic 절 | 통합본 `§13_open §A` | 통합본 13장 §A |
| envelope.md | §4.1 토픽 명칭 규약 | `§13_open §A` | 통합본 13장 §A |
| envelope.md | §9 Open 도입문 | 통합본 6.8.6 / `13_open.md` | 통합본 6.8.6 / 13장(Open) |
| envelope.md | §9 O2 행 | `13_open §E` | 13장 §E |

**전수 재확인**: 정정 후 `v0_9`·`통합본_v0_9`·`04_데이터흐름`·`13_open`·`0N_한글`·`CHANGELOG.md`·`v0_9_diff` 패턴 grep = 두 계약 문서 모두 **잔여 0**.

> ROADMAP의 `§13_open` 표기는 계약 문서가 아니고 source_ref 추적용이라 T4-5 범위 밖(소급 sweep 금지 방침).

## 3. 산출물

- 정정 5곳(kafka-payloads 2·envelope 3) — 계약 내용 변경 0.
- ROADMAP §13 T4-5 status `TODO`→`IN_PROGRESS` + acceptance_evidence(1차 DONE/2차 대기).
- spec-drift 보고: `handoff/spec-drift/` (spec-sync 산출 — meta 기준 문서 ↔ 형제 repo 사본).
- 이 문서.

## 4. 2차 갱신 대기 (T4-2 분리 구현 후 — meta 복귀 게이트)

T4-2(`job-results`→`result-topic-job`/`log` 분리)가 hub·script-agent·infra에서 구현+e2e 60/0/0 완료되면 **monitoring-meta 세션으로 복귀**해 아래를 갱신하고 T4-5를 **DONE** 전환한다(계약 문서 소유=meta, 형제 repo가 갱신하지 않음):

- `docs/kafka-payloads.md` 토픽 매핑표(`job-results` 현행 물리명 → 분리 반영)·result-topic-job/log 각 절 "현행 물리명".
- 통합본 §6.9.5 토픽 일관성 표(`job-results` 행 "T4-2 잔여"→완료).
- ROADMAP §13 T4-2 status=DONE·T4-5 status=DONE + acceptance_evidence, 액티브 큐.
- 후속 spec-sync drift 재검사.

이 게이트는 T4-2 발주 handoff(`handoff/phase1-041/`)의 acceptance에 명시한다.

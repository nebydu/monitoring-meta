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

## 3.5. payload 위상 명시 슬라이스 (복귀 게이트 선행 — 2026-06-14)

T4-2 구현 중 발견: hub가 옵션 A로 공통 `JobResult`를 구현(2토픽 구독 완료, mvn test 그린)했는데, `docs/kafka-payloads.md`의 result-topic-job/log payload는 **Phase 1 도달 목표 스키마**(평면 `exit_code`/`stdout_ref`/`metrics`, status 소문자 / `occurred_at`/평면화)로만 정의돼 있고 "이 스키마는 목표이고 T4-2는 옵션 A로 공통 payload를 유지한다"는 **위상 표기가 없었다.** 그 결과 hub codex-gate가 코드(공통 JobResult)↔계약(목표) drift를 "계약 위반 critical"로 오판했다.

→ 복귀 게이트(§4)의 나머지를 기다리지 않고, payload 위상을 선행 정식화해 오판을 해소한다. **위상 주석 2회 시도가 codex-gate FAIL → ADR 승격으로 종결**한 경위:

**1·2차 시도(위상 주석)의 한계 (codex-gate FAIL ×2 — 2026-06-14)**:
- 1차: JSON을 "목표"라 두고 "코드가 달라도 위반 아니다"라고만 적어 *현재/목표* 모호 + 현 단계 검증 기준 미명시(기준점 소멸).
- 2차: 현 단계 기준을 "코드 + handoff §5.1"로 앵커 → ⓐ **8토픽 spec 안에 현 단계 payload 정의가 없는 spec 공백** ⓑ 옵션 A를 spec보다 낮은 handoff 근거로 확정한 **위상 역전**. codex critical 재지적.

**→ 종결: ADR#19 승격 + 두 계약 병기** (사용자 "확장" 선택 2026-06-14):
| 변경 | 내용 |
|---|---|
| `adr/0019-result-payload-staging.md` (신규) | 옵션 A를 ADR로 격상 — "토픽 분리(T4-2)와 payload 정렬은 독립 단계, 현 단계 계약=공통 `JobResult`(데모 §5.2), 정렬은 후속 Track". 데모 §5.2.3이 예고한 ADR을 닫음 |
| kafka-payloads result-topic-job/log 절 | **① 현 단계 계약(공통 `JobResult` JSON 직접 명시)** + **② 목표 계약(평면, 기존)** 병기. job 절에 공통 `JobResult` 정식 정의, log 절은 단일 앵커 참조(중복 제거). 근거=ADR#19+데모 §5.2(둘 다 spec 위상) |
| master-design §8.3 + ROADMAP §5.1 매트릭스·T4-2 행 | ADR#19 행 추가(목록 정합), T4-2 비고에 위상 명시 |
| 매핑표 `job-results` 행 | ADR 귀속 분리: 토픽 분리=ADR#5/D-5 간접, payload 단계화=ADR#19 |

**해소 확인**: ⓐ 현 단계 계약이 spec에 직접 존재 → spec 공백 해소 ⓑ 결정 소유가 ADR#19(handoff 아님) → 위상 역전 해소 ⓒ 미결 ADR은 `occurred_at`=ADR#10/T3-7·`file_state`=ADR#14만 실재 매핑, 나머지(status enum·`mode`·`metrics`·job_type화)는 "후속 Track 위임"으로 선결정 회피.

**후속 확인 사안 (file_state — codex-gate 3차 지적)**: kafka-payloads 목표 스키마 ②가 `result-topic-log`에 `file_state`를 payload 필드로 포함하나, ADR#14·데모 §5.2.3은 `file_state`를 Agent local·BE 미전송으로 둔다 — **기존 spec의 잠재 모순**(본 작업이 표면화). ADR#14 해석이 걸려 추측 금지 → 목표 스키마 정렬 Track(후속)에서 별도 확정. 이번엔 현 단계 계약 ①의 file_state 단정 서술만 제거해 표면 충돌을 없앴고, **목표 스키마는 무변경**으로 둔다.

**경계**: 이 슬라이스는 *payload 위상 정식화(ADR#19)*까지. §4의 나머지(매핑표 토픽명 일치 전환·통합본 §6.9.5/§6.9.2/§4.4.1 상태·ROADMAP T4-2 DONE·spec-sync·features 2문서)는 여전히 컷오버+e2e 60/0/0 후 복귀 게이트 몫이다.

## 4. 2차 갱신 대기 (T4-2 분리 구현 후 — meta 복귀 게이트)

T4-2(`job-results`→`result-topic-job`/`log` 분리)가 hub·script-agent·infra에서 구현+e2e 60/0/0 완료되면 **monitoring-meta 세션으로 복귀**해 아래를 갱신하고 T4-5를 **DONE** 전환한다(계약 문서 소유=meta, 형제 repo가 갱신하지 않음):

- `docs/kafka-payloads.md` 토픽 매핑표(`job-results` 현행 물리명 → 분리 반영)·result-topic-job/log 각 절 "현행 물리명".
- 통합본 §6.9.5 토픽 일관성 표(`job-results` 행 "T4-2 잔여"→완료).
- ROADMAP §13 T4-2 status=DONE·T4-5 status=DONE + acceptance_evidence, 액티브 큐.
- 후속 spec-sync drift 재검사.

이 게이트는 T4-2 발주 handoff(`handoff/phase1-041/`)의 acceptance에 명시한다.

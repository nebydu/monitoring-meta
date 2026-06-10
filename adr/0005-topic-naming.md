# ADR-0005: Kafka 토픽 명명 규칙 + envelope/재명명 실행 순서

- 상태(Status): **Accepted (승인)** — D-4(1) 구체 명명 컨벤션이 2026-06-06 사람 승인으로 닫히면서 전체 ADR이 Proposed → Accepted로 전환됐다. 부분 결정 D-4(2)(2026-06-04)·D-4(1)(2026-06-06) 모두 RESOLVED.
- 대상 Phase: Phase 1
- 근거 기준 문서: 통합본 v0.9 §4.4.1(신규 시스템 Kafka 토픽) / §4.4.2(메시징 매트릭스 "Topic 네이밍") / §6.8(매트릭스 "command-topic routing" = "Phase 1 (다중 zone 진입 시)") / §8.3 ADR#4·#5·#6, `docs/kafka-payloads.md`(현행 물리 토픽명 → 최종 논리명 매핑), `docs/envelope.md` §4(envelope 4종 적용 대상)
- 관련 ROADMAP: `docs/phase1/ROADMAP_PHASE1_v0_3.md` §7(8토픽 계약 매트릭스)·§13 Track 4(T4-1)·§17 D-4
- 영향 repo: hub, script-agent, infra, monitoring-meta

### Decision status (부분 결정 구조)

| 결정 | 상태 | 일자 | 근거 |
|---|---|---|---|
| D-4(2) 실행 순서 (envelope 먼저) | **Accepted / Resolved** | 2026-06-04 | §2.1 (envelope=헤더, 토픽명 독립) |
| D-4(1) 구체 명명 컨벤션 | **Accepted / Resolved** | 2026-06-06 | §3 후보 B 승인 ((1)=B / (2)=단일 command-topic / (3)=신규까지 적용) |

> 위 표가 본 ADR의 부분 결정 구조다. **전체 ADR 상태(Status) = Accepted**다. D-4(2)는 2026-06-04에, D-4(1)은 2026-06-06에 각각 사람 승인으로 닫혔다. D-4(1) 승인으로 본 ADR이 Accepted로 전환됨에 따라 Track 4 T4-1(토픽 재명명)의 BLOCKED가 해제됐다(§5 Consequences).

---

## 0. 성격 / 범위 선언 (혼동 금지)

- 본 ADR은 통합본 v0.9가 **이미 확정한 명명 *원칙*** 을 변경하지 않는다. 명명 원칙("zone 단위 + 의미 기반", 환경 prefix 없음)은 통합본 §4.4.1·§4.4.2·§8.3 ADR#5에 박힌 **확정 사실**이다. 본 ADR이 결정한 것은 그 원칙을 따르는 **구체 명명 컨벤션**(D-4(1))과 envelope 적용·재명명의 **실행 순서**(D-4(2))뿐이다.
- 본 ADR은 ROADMAP §17 D-4를 정식 ADR로 **격상**해 추적한다. 토픽의 **분리/추가 여부·Phase**는 본 ADR 밖의 확정 사실이다: result-topic 분리=통합본 §6.9.2 항목1 Phase 1 확정 / alert·notification 추가=§6.9.3·§6.9.5 Phase 1 확정(과거 D-9는 2026-06-03 RESOLVED).
- **토픽 최종 논리명(name)은 D-4(1) 승인(2026-06-06)으로 확정됐다.** 실제 물리 재명명 작업(commands 등 현행 물리명 → 최종 논리명)은 본 ADR 밖 Track 4 T4-1에서 별도 handoff로 수행한다.

---

## 1. Context

### 1.1 통합본이 이미 확정한 것 (원칙 — 변경 대상 아님)

- **명명 원칙 = "zone 단위 + 의미 기반"** (통합본 §8.3 ADR#5 결정 컬럼, §4.4.2 "Topic 네이밍 = 의미 기반 명명"). 데모(Phase 0)의 "환경 prefix 없음"에서 본개발은 "zone 단위 + 의미 기반"으로 간다.
- **AMS 레거시의 IP-Port 동적 토픽(안티패턴)은 폐기**하고 역할별 의미 기반 명명을 채택한다(§4.4.1 도입문).
- **§4.4.1 baseline 토픽 표(v0.7 시점)**: `command-topic`(zone 단위), `result-topic-job`, `result-topic-log`, `audit-topic`, `heartbeats-topic`, `alert-topic`, `notification-topic`, `metrics-topic`. 단 "토픽 개수는 고정이 아니라 운영/구현 단계에서 필요에 따라 추가·통합 가능. 위는 v0.7 시점 baseline"이라고 명시 — 즉 baseline 이름은 규칙(후보 B)의 한 **사례**다.
- **§6.8 매트릭스 "command-topic routing"**: "zone 단위 + hash partition" vs "단일 commands 토픽"의 routing 도입 시점을 **"Phase 1 (다중 zone 진입 시)"** 로 *조건부* 명시한다. 즉 현 단계(zone=1, 단일 폐쇄망)에서는 단일 토픽이 일치가고, zone 단위 routing은 다중 zone 진입이라는 미래 트리거에 의존된다.
- `docs/envelope.md` §4.1 주: envelope 4종 적용은 zone suffix와 무관하게 동일하다.

### 1.2 본 ADR이 결정한 것 (D-4)

- **D-4(1) 구체 명명 컨벤션**: §4.4.1 baseline 이름을 그대로 고정할지, 일반 규칙(`<domain>-topic[-{subtype}][-{zone}]` 등)을 명시해 신규 토픽까지 강제할지, zone suffix 전개 정책을 어떻게 둘지. → §2.2에서 승인 결과로 확정.
- **D-4(2) 실행 순서**: 나머지 토픽 envelope 적용(Track 0)과 ADR#5 토픽 재명명/재구조(Track 4)의 순서. → §2.1에서 RESOLVED.

---

## 2. Decision

### 2.1 D-4(2) 실행 순서 = "envelope 먼저 (Track 0 → Track 4)" — **RESOLVED (2026-06-04)**

나머지 토픽 envelope 적용(Track 0)을 토픽 재명명/재구조(Track 4)보다 **먼저** 수행한다.

근거:
- **envelope은 Kafka *헤더*(transport 메타데이터)이고 토픽 *이름*과 독립적**이다(`docs/envelope.md` §1·§4). envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`)은 토픽명이 무엇이든, zone suffix가 어떻게 전개되든 동일하게 적용된다(envelope §4.1 주 — "envelope 4종 적용은 zone suffix와 무관하게 동일"). 따라서 envelope 선적용은 토픽 최종 이름에 막히지 않는다.
- 역방향(재명명 먼저)은 producer/consumer 토픽 참조를 전면 수정하는 cross-cutting 변경이라 리스크가 크고(ROADMAP §13 머리 "Track 4는 cross-cutting 리스크가 높음"), envelope 선적용은 이 블로킹을 피한다.
- envelope 선적용 산출물(헤더 주입/검증 코드)은 재명명 후에도 그대로 유효하므로 재작업이 발생하지 않는다.

이 결정은 ROADMAP §9 Track 0 머리 주석·§13 T0-2·§17 D-4(2)에 반영한다.

### 2.2 D-4(1) 구체 명명 컨벤션 = **RESOLVED (2026-06-06) — 후보 B 승인**

사람 승인(2026-06-06)으로 §3 후보 중 다음이 확정됐다:

1. **(1) 명명 컨벤션 = 후보 B (규칙 명시)**: `<domain>-topic[-{subtype}][-{zone}]` 의미 기반 일반 규칙을 명시하고, §4.4.1 baseline 8토픽은 그 규칙의 사례로 둔다. `heartbeats-topic`의 복수형 domain은 baseline 호환을 위해 유지하되 **명시 예외**로 기록한다(아래 §2.2.1).
2. **(2) zone 전개 = 단일 토픽**: `command-topic`을 **suffix 없는 단일 물리 토픽**으로 확정한다. 현 단계 zone=1(단일 폐쇄망)이라 zone_id가 의미 없고, 통합본 §6.8 매트릭스가 zone 단위 routing 도입 시점을 "Phase 1 (다중 zone 진입 시)"로 *조건부* 명시한 것과 일치한다. **다중 zone 진입 시 `command-topic-{zone}` 전개는 미래 트리거**(§4 Open)로만 남긴다.
3. **(3) 적용 범위 = 신규 토픽까지**: 승인된 규칙을 baseline 8토픽뿐 아니라 Phase 2 신규 토픽(metric ingest·rule-engine 계열 등)까지 선제 강제한다.

승인값은 통합본 §8.3 ADR#5 원칙("zone 단위 + 의미 기반", 환경 prefix 없음)과 §6.8 routing 시점 조건을 모두 만족한다(추측 아닌 기준 문서 직접 도출).

#### 2.2.1 최종 토픽 논리명 (규칙 B 적용 결과)

| 최종 논리명 | 규칙 B 적용 | 비고 |
|---|---|---|
| `command-topic` | `<domain=command>-topic` (zone suffix 없음, 단일) | (2) 단일 토픽 확정. 다중 zone 진입 시 `-{zone}` 전개(미래, §4 Open) |
| `result-topic-job` | `<domain=result>-topic-<subtype=job>` | — |
| `result-topic-log` | `<domain=result>-topic-<subtype=log>` | result 분리 ADR 소속=D-5 (별개) |
| `audit-topic` | `<domain=audit>-topic` | — |
| `heartbeats-topic` | `<domain=heartbeats>-topic` (복수형) | **명시 예외**: baseline 호환 위해 복수형 domain 유지 |
| `alert-topic` | `<domain=alert>-topic` | 신설=Phase 1 확정(§6.9.3·§6.9.5) |
| `notification-topic` | `<domain=notification>-topic` | 신설=Phase 1 확정(§6.9.3·§6.9.5) |
| `metrics-topic` | `<domain=metrics>-topic` (복수형) | Phase 2. metric 도메인 토픽은 규칙 B 사례 |

> 현행 물리명(`commands`/`job-results`/`audit-events`/`heartbeats`) → 최종 논리명 매핑은 `docs/kafka-payloads.md`에 기록한다. **물리명은 T4-1 재명명 전 현행이며, 위 논리명이 최종**이다. 실제 재명명은 Track 4 T4-1.

---

## 3. D-4(1) 구체 명명 컨벤션 후보안 (의사결정 이력 — 보존)

> **승인 결과 (2026-06-06): (1)=후보 B / (2)=단일 command-topic / (3)=신규 토픽까지 적용.** 아래 비교표는 의사결정 이력으로 보존한다. 세 후보는 모두 통합본 §8.3 ADR#5 원칙("zone 단위 + 의미 기반", 환경 prefix 없음)을 만족한다.

### 3.1 후보 비교표

| 축 | 후보 A — baseline 이름 고정 | 후보 B — `<domain>-topic[-{subtype}][-{zone}]` 규칙 명시 ★ 승인 | 후보 C — prefix/zone-suffix 전개 정책 명시 |
|---|---|---|---|
| 핵심 | §4.4.1 baseline 8개 이름을 그대로 최종 이름으로 고정 | 일반 규칙을 정의하고 신규 토픽도 규칙으로 강제. baseline은 규칙의 한 사례 | 환경 prefix 도입 여부 + `{zone}` placeholder vs 실제 zone 인스턴스명 전개를 명시 |
| 토픽 이름 예 | `command-topic`(zone), `result-topic-job`, `alert-topic`, `notification-topic`, `metrics-topic` 고정 | `command-topic`, `result-topic-job`, `<domain>-topic` 패턴. 신규 도메인은 `<domain>-topic`로 자동 | 후보 A/B 이름 + (prefix 없음 유지 vs `<env>.` 도입) + zone suffix를 `command-topic-{zone}`(placeholder) vs `command-topic-zone-seoul`(실제명) 중 택 |
| 통합본 근거 | §4.4.1 baseline 표 직접 채택 | §4.4.2 "의미 기반 명명" 원칙 + §4.4.1 baseline을 규칙으로 일반화 | §8.3 ADR#5 "환경 prefix 없음" + §4.4.1 "(zone 단위)" 표기·envelope §4.1 zone 물리 실현 |
| 장점 | 가장 단순. baseline과 kafka-payloads 현행 잠정명이 일치 → 재명명 최소 | 신규 토픽(Phase 2 metric ingest, rule-engine 계열 등)도 일관 명명 보장 | zone 다중화·환경 분리(dev/stg/prod) 시 운영 모호성 제거 |
| 단점 | 신규 토픽 명명 규칙이 암묵적 → 향후 일관성 표류 위험 | 기존 baseline 일부가 규칙과 어긋나면(예: `heartbeats-topic` 복수형) 규칙 예외 처리 필요 → 승인 시 명시 예외로 해소(§2.2.1) | 결정 축이 많아 승인 비용 큼. prefix 도입 시 §8.3 "prefix 없음"과 충돌 검토 필요 |
| producer 영향(hub/script-agent) | 거의 없음(현행 잠정명 유지) | 신규 토픽 추가 시 규칙 준수 강제 — publisher 토픽 상수 명명 규약 추가 | zone suffix 전개 방식이 producer 토픽 결정 로직에 직접 영향 |
| consumer 영향(hub) | 거의 없음 | 구독 토픽 패턴(prefix/와일드카드) 명명 규약 영향 | 환경 prefix 도입 시 consumer subscription·ACL 범위 변경 |
| infra 영향 | 토픽 생성 스크립트 baseline 그대로 | 토픽 생성 자동화에 규칙 반영 | zone/환경별 토픽 provisioning 정책에 직접 영향(가장 큼) |

### 3.2 명시 결정 리스트 (승인 완료 2026-06-06)

1. **(1) 구체 컨벤션 후보 선택** — **승인: 후보 B (규칙 명시)**. baseline 8토픽은 규칙 사례, `heartbeats-topic` 복수형은 명시 예외(§2.2.1).
2. **(2) zone suffix 전개 방식** — **승인: 단일 물리 토픽**. `command-topic`을 suffix 없는 단일 물리 토픽으로 확정. zone=1 현 단계에서 zone_id 무의미, 통합본 §6.8 "Phase 1 (다중 zone 진입 시)" 조건부 명시와 일치. 다중 zone 진입 시 `-{zone}` 전개는 미래 트리거(§4 Open).
3. **(3) 신규 토픽 명명 적용 범위** — **승인: 신규 토픽까지**. 규칙 B를 baseline 8토픽 + Phase 2 신규 토픽(metric ingest / rule-engine 계열 등)까지 선제 강제.

> **§A Open 차단 해소 (2026-06-06)**: 단일 토픽 채택((2))으로 zone 인스턴스명이 불필요해졌다. 즉 D-4(1) (2)는 더 이상 통합본 §13_open §A(zone topology, ROADMAP D-8)에 의존되지 않는다. 이로써 D-4(1) 세 항목 전부 closed → 본 ADR Accepted 전환. (단 *실제 zone 인스턴스명*과 *다중 zone 전개* 자체는 §A 미결로 §4 Open에 남는다.)

---

## 4. Open / 본 ADR이 확정하지 않는 것

- **다중 zone 진입 시 zone suffix 전개** (미래 트리거): `command-topic-{zone}` 전개는 다중 zone 진입 시점에만 도입한다(통합본 §6.8 "Phase 1 (다중 zone 진입 시)" 조건). 도입 시 별도 Track 4 재명명 + 통합본 §13_open §A(zone topology) 해소가 선행돼야 한다. **지금 고정/추측하지 않는다(forward note).**
- **실제 zone 인스턴스명**: zone 인스턴스의 실제 개수·명명(`command-topic-zone-N` 등)은 통합본 §13_open §A 미결 Open — 추측 금지(ROADMAP D-8). 단일 토픽 채택으로 *현 단계*에는 불필요하나, 다중 zone 전개 시점에 §A 해소가 필요하다.
- **result-topic 분리 ADR 소속(job-results→ADR#5 간접)**: ROADMAP D-5로 추적. 본 ADR은 명명 규칙만 다루며 분리 자체는 §6.9.2 항목1 Phase 1 확정. (명명 규칙은 D-4(1)로 닫힘; ADR 소속만 D-5 Open.)

---

## 5. Consequences

- **D-4(2) RESOLVED** 효과: Track 0(envelope 나머지 토픽 적용)을 D-4(1)과 무관하게 즉시 착수 가능 → `handoff/phase1-001/phase1-001-envelope-scope.md`로 분배(완료).
- **D-4(1) RESOLVED (2026-06-06)** 효과: 본 ADR이 Accepted로 전환되어 **Track 4 T4-1(토픽 재명명)의 BLOCKED가 해제**된다. T4-1은 실행 순서(D-4(2) RESOLVED, envelope 먼저)에 따라 Track 0 완료 이후 착수하며, 별도 handoff(`handoff/phase1-040/phase1-040-topic-naming.md`)로 분배 대기다(실제 재명명은 본 ADR 밖 후속 작업).
- ROADMAP §7 매트릭스의 "(토픽명/zone suffix 명명 규칙 = ADR#5/D-4 의존, 현재 kafka-payloads 이름은 잠정)" 마커는 **확정 규칙(B)·최종 논리명**으로 갱신된다(이 승인 작업에서 ROADMAP §7 동시 갱신).
- `docs/kafka-payloads.md`의 잠정 토픽명(`command-topic-{zone}` placeholder 등)은 **최종 논리명**으로 정정된다(`command-topic` 단일 + 다중 zone 진입 시 `-{zone}` 미래 주석).

## 6. Compliance / Regression

- 데모 spec v0.2.1 회귀 0: D-4(1) 승인은 spec 저작(결정 기록)일 뿐 실제 토픽 물리명을 바꾸지 않는다. Phase 0 토픽(`commands`/`heartbeats` 등 물리명) 회귀 위험 없음. 실제 재명명(T4-1)은 Phase 1 forward 변경이며 별도 회귀 검증 대상이다(Phase 0 회귀 아님).
- envelope 선적용(D-4(2))은 헤더 추가일 뿐 토픽명 불변 → Phase 0 발행 회귀 없음(envelope §6 하위호환).

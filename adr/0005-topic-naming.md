# ADR-0005: Kafka 토픽 명명 규칙 + envelope/재명명 실행 선후

- 상태(Status): **Proposed (제안)** — D-4(2) 부분만 RESOLVED, D-4(1) 구체 컨벤션은 비준 대기
- 대상 Phase: Phase 1
- 근거 정본: 통합본 v0.9 §4.4.1(신규 시스템 Kafka 토픽) / §4.4.2(메시징 매트릭스 "Topic 네이밍") / §8.3 ADR#4·#5·#6, `docs/kafka-payloads.md`(현행 잠정 토픽명), `docs/envelope.md` §4(envelope 4종 적용 대상)
- 관련 ROADMAP: `docs/phase1/ROADMAP_PHASE1_v0_3.md` §7(8토픽 계약 매트릭스)·§13 Track 4(T4-1)·§17 D-4
- 영향 repo: hub, script-agent, infra, monitoring-meta

---

## 0. 위상 / 범위 선언 (혼동 금지)

- 본 ADR은 통합본 v0.9가 **이미 확정한 명명 *원칙*** 을 변경하지 않는다. 명명 원칙("zone 단위 + 의미 기반", 환경 prefix 없음)은 통합본 §4.4.1·§4.4.2·§8.3 ADR#5에 박힌 **확정 사실**이다. 본 ADR이 여는 것은 그 원칙을 따르는 **구체 명명 컨벤션**(D-4(1))과 envelope 적용·재명명의 **실행 선후**(D-4(2))뿐이다.
- 본 ADR은 ROADMAP §17 D-4를 정식 ADR로 **승격**해 추적한다. 토픽의 **분리/추가 여부·Phase**는 본 ADR 밖의 확정 사실이다: result-topic 분리=통합본 §6.9.2 항목1 Phase 1 확정 / alert·notification 추가=§6.9.3·§6.9.5 Phase 1 확정(과거 D-9는 2026-06-03 RESOLVED).
- **토픽 최종 이름(name)은 본 ADR이 동결하지 않는다.** D-4(1)은 후보안만 제시하고 사람 비준을 대기한다(추측 금지 — CLAUDE.md §2).

---

## 1. Context

### 1.1 통합본이 이미 확정한 것 (원칙 — 변경 대상 아님)

- **명명 원칙 = "zone 단위 + 의미 기반"** (통합본 §8.3 ADR#5 결정 컬럼, §4.4.2 "Topic 네이밍 = 의미 기반 명명"). 데모(Phase 0)의 "환경 prefix 없음"에서 본개발은 "zone 단위 + 의미 기반"으로 간다.
- **AMS 레거시의 IP-Port 동적 토픽(안티패턴)은 폐기**하고 역할별 의미 기반 명명을 채택한다(§4.4.1 도입문).
- **§4.4.1 baseline 토픽 표(v0.7 시점)**: `command-topic`(zone 단위), `result-topic-job`, `result-topic-log`, `audit-topic`, `heartbeats-topic`, `alert-topic`, `notification-topic`, `metrics-topic`. 단 "토픽 개수는 고정이 아니라 운영/구현 단계에서 필요에 따라 추가·통합 가능. 위는 v0.7 시점 baseline"이라고 명시 — 즉 baseline 이름은 **잠정**이다.
- `docs/kafka-payloads.md`는 `command-topic-{zone}` placeholder를 쓰고 나머지 7토픽은 논리명=물리명으로 둔다(현행 잠정).
- `docs/envelope.md` §4.1 주: `command-topic`은 논리명, `command-topic-{zone}`은 zone 단위 물리 실현이며 envelope 4종 적용은 zone suffix와 무관하게 동일하다.

### 1.2 본 ADR이 결정해야 하는 것 (D-4)

- **D-4(1) 구체 명명 컨벤션**: §4.4.1 baseline 이름을 그대로 동결할지, 일반 규칙(`<domain>-topic[-{zone}]` 등)을 명문화해 신규 토픽까지 강제할지, prefix/zone suffix 전개 정책을 어떻게 둘지.
- **D-4(2) 실행 선후**: 나머지 토픽 envelope 적용(Track 0)과 ADR#5 토픽 재명명/재구조(Track 4)의 선후.

---

## 2. Decision

### 2.1 D-4(2) 실행 선후 = "envelope 먼저 (Track 0 → Track 4)" — **RESOLVED (2026-06-04)**

나머지 토픽 envelope 적용(Track 0)을 토픽 재명명/재구조(Track 4)보다 **먼저** 수행한다.

근거:
- **envelope은 Kafka *헤더*(transport 메타데이터)이고 토픽 *이름*과 독립적**이다(`docs/envelope.md` §1·§4). envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`)은 토픽명이 무엇이든, zone suffix가 어떻게 전개되든 동일하게 적용된다(envelope §4.1 주 — "envelope 4종 적용은 zone suffix와 무관하게 동일"). 따라서 envelope 선적용은 토픽 최종 이름 미정(D-4(1))에 막히지 않는다.
- 역방향(재명명 먼저)은 producer/consumer 토픽 참조를 전면 수정하는 cross-cutting 변경이라 리스크가 크고(ROADMAP §13 머리 "Track 4는 cross-cutting 리스크가 높음"), D-4(1) 비준 전에는 착수할 수 없다. envelope 선적용은 이 블로킹을 피한다.
- envelope 선적용 산출물(헤더 주입/검증 코드)은 재명명 후에도 그대로 유효하므로 재작업이 발생하지 않는다.

이 결정은 ROADMAP §9 Track 0 머리 주석·§13 T0-2·§17 D-4(2)에 반영한다.

### 2.2 D-4(1) 구체 명명 컨벤션 = **[결정 필요] — 비준 대기 (동결 금지)**

§3 후보안 표를 사람이 검토해 비준한다. 본 ADR은 어느 후보로도 결정하지 않는다. 비준 전까지 구현 세션은 `docs/kafka-payloads.md`의 현행 잠정 토픽명을 쓰되, 비준 후 재명명에 대비해 토픽명을 상수/설정으로 외부화해 둔다.

---

## 3. [결정 필요] D-4(1) 구체 명명 컨벤션 후보안 (동결 금지 — 사람 비준 대기)

> 아래 세 후보는 모두 통합본 §8.3 ADR#5 원칙("zone 단위 + 의미 기반", 환경 prefix 없음)을 **만족**한다. 차이는 baseline 동결 vs 일반 규칙 강제 vs prefix/zone suffix 전개 정책이다. **어느 후보로 결정한다고 쓰지 않는다.**

### 3.1 후보 비교표

| 축 | 후보 A — baseline 이름 동결 | 후보 B — `<domain>-topic[-{zone}]` 규칙 명문화 | 후보 C — prefix/zone-suffix 전개 정책 명시 |
|---|---|---|---|
| 핵심 | §4.4.1 baseline 8개 이름을 그대로 최종 이름으로 동결 | 일반 규칙을 정의하고 신규 토픽도 규칙으로 강제. baseline은 규칙의 한 사례 | 환경 prefix 도입 여부 + `{zone}` placeholder vs 실제 zone 인스턴스명 전개를 명시 |
| 토픽 이름 예 | `command-topic`(zone), `result-topic-job`, `alert-topic`, `notification-topic`, `metrics-topic` 고정 | `command-topic-{zone}`, `result-topic-job`, `<domain>-topic` 패턴. 신규 도메인은 `<domain>-topic`로 자동 | 후보 A/B 이름 + (prefix 없음 유지 vs `<env>.` 도입) + zone suffix를 `command-topic-{zone}`(placeholder) vs `command-topic-zone-seoul`(실제명) 중 택 |
| 통합본 근거 | §4.4.1 baseline 표 직접 채택 | §4.4.2 "의미 기반 명명" 원칙 + §4.4.1 baseline을 규칙으로 일반화 | §8.3 ADR#5 "환경 prefix 없음" + §4.4.1 "(zone 단위)" 표기·envelope §4.1 zone 물리 실현 |
| 장점 | 가장 단순. baseline과 kafka-payloads 현행 잠정명이 일치 → 재명명 최소 | 신규 토픽(Phase 2 metric ingest, rule-engine 계열 등)도 일관 명명 보장 | zone 다중화·환경 분리(dev/stg/prod) 시 운영 모호성 제거 |
| 단점 | 신규 토픽 명명 규칙이 암묵적 → 향후 일관성 표류 위험 | 기존 baseline 일부가 규칙과 어긋나면(예: `heartbeats-topic` 복수형) 규칙 예외 처리 필요 | 결정 축이 많아 비준 비용 큼. prefix 도입 시 §8.3 "prefix 없음"과 충돌 검토 필요 |
| producer 영향(hub/script-agent) | 거의 없음(현행 잠정명 유지) | 신규 토픽 추가 시 규칙 준수 강제 — publisher 토픽 상수 명명 규약 추가 | zone suffix 전개 방식이 producer 토픽 결정 로직에 직접 영향(`command-topic-{zone}` 해석) |
| consumer 영향(hub) | 거의 없음 | 구독 토픽 패턴(prefix/와일드카드) 명명 규약 영향 | 환경 prefix 도입 시 consumer subscription·ACL 범위 변경 |
| infra 영향 | 토픽 생성 스크립트 baseline 그대로 | 토픽 생성 자동화에 규칙 반영 | zone/환경별 토픽 provisioning 정책에 직접 영향(가장 큼) |

### 3.2 명시 결정 필요 리스트 (사람 비준 대기)

1. **(1) 구체 컨벤션 후보 선택** — 후보 A / B / C(또는 조합) 중 어느 것을 최종 명명 규칙으로 비준하는가.
2. **(2) zone suffix 전개 방식** — `command-topic-{zone}`을 (i) placeholder 논리명으로 유지하고 실제 토픽은 zone 인스턴스별(`command-topic-zone-N` 등)로 물리 생성할지, (ii) 단일 물리 토픽으로 둘지. 통합본 §4.4.1은 "(zone 단위)", kafka-payloads는 `{zone}` placeholder, envelope §4.1은 "zone 단위로 분리된 물리 토픽 `command-topic-{zone}`"으로 본다 — 물리 전개 인스턴스명 규칙이 미정.
3. **(3) 신규 토픽 명명 적용 범위** — 비준된 규칙을 (i) §4.4.1 baseline 8토픽에만 적용할지, (ii) Phase 2 신규 토픽(`metrics-topic` 외 metric ingest / rule-engine 계열 등)까지 소급/선제 강제할지.

> (2)는 zone topology 정보(통합본 §13_open §A / ROADMAP G-3·D-8)에 일부 종속된다 — zone 인스턴스 실제 개수·명명은 site별 운영 정보 입수에 걸린다. 이 부분이 **통합본 미결 Open(§A)** 와 닿으면 추측으로 메우지 않는다.

---

## 4. Open / 본 ADR이 확정하지 않는 것

- **D-4(1) 구체 명명 컨벤션·zone suffix 전개·적용 범위**: §3 후보안으로만 제시. 사람 비준 전까지 토픽 최종 이름 동결 금지.
- **zone topology / 실제 zone 인스턴스명**: 통합본 §13_open §A 미결 Open — 추측 금지(ROADMAP D-8).
- **토픽 재구조 *물리 작업*(재명명 PR)**: 본 ADR은 선후(envelope 먼저)만 결정. 실제 재명명 구현은 D-4(1) 비준 후 Track 4(T4-1)에서 별도 handoff로 수행.
- **result-topic 분리 ADR 귀속(job-results→ADR#5 간접)**: ROADMAP D-5로 추적. 본 ADR은 명명 규칙만 다루며 분리 자체는 §6.9.2 항목1 Phase 1 확정.

---

## 5. Consequences

- **D-4(2) RESOLVED** 효과: Track 0(envelope 나머지 토픽 적용)을 D-4(1) 비준과 무관하게 즉시 착수 가능 → `handoff/phase1-001-envelope-scope.md`로 분배.
- **D-4(1) 비준 대기** 효과: Track 4 T4-1(토픽 재명명)은 본 ADR 비준(`adr/0005` Accepted 전환)까지 BLOCKED 유지. 구현 세션은 토픽명을 상수/설정으로 외부화해 비준 후 재명명 비용을 최소화한다.
- 본 ADR 비준 시 ROADMAP §7 매트릭스의 "(토픽명/zone suffix 명명 규칙 = ADR#5/D-4 종속, 현재 kafka-payloads 이름은 잠정)" 마커를 확정 이름으로 갱신하고, kafka-payloads.md 잠정 토픽명을 최종명으로 정정한다.

## 6. Compliance / Regression

- 데모 spec v0.2.1 회귀 0: 명명 규칙 비준 전에는 토픽명을 바꾸지 않으므로 Phase 0 토픽(`commands`/`heartbeats` 등 물리명) 회귀 위험 없음. 재명명 PR은 별도 회귀 검증 대상.
- envelope 선적용(D-4(2))은 헤더 추가일 뿐 토픽명 불변 → Phase 0 발행 회귀 없음(envelope §6 하위호환).

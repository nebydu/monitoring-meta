# Kafka Envelope 헤더 규약 (envelope 세부 규약 정본)

> **문서 위상**
> - 이 문서는 **envelope 4종 헤더 세부 규약의 정본(Phase 1+ 도달 목표)** 이다. 즉 envelope 헤더 규약에 한해 정본이며, **상위 아키텍처 결정은 통합본 v0.9를 따른다**(아래 우선순위 참조).
> - 데모 spec v0.2.1 (`../hub/docs/monitoring-demo-message-spec-v0.2.1.md` §2.2)은 **Phase 0 코드가 회귀 없이 지켜야 할 동작 spec(ground truth)** 으로 위상이 다르다. 둘을 같은 ground truth로 다루지 않는다.
> - 충돌 시 **통합본 v0.9 6.8/6.9가 상위 근거**다. 이 문서의 모든 "결정"은 통합본 6.8/6.9 또는 사람이 확정한 Q1~Q5에 근거가 있다.
>
> - 작성 일시: 2026-05-27
> - 근거 문서:
>   - `docs/통합본_v0_9.md` 6.8(메시지 envelope 및 ID 컨벤션) / 6.9(데모 정합성 매트릭스) / 4.4.1(토픽 표) / 8.2(ADR 결정표)
>   - `docs/kafka-payloads.md` (별첨 payload spec — "envelope는 별도 — shared-libs/envelope")
>   - `../hub/docs/monitoring-demo-message-spec-v0.2.1.md` §2.2 (Phase 0 회귀 기준 헤더 정의)
>   - `handoff/envelope-draft-analysis.md` (1라운드 분석 §1~§9)
> - 확정 결정 출처: 사람 confirm된 Q1~Q5 (**2026-05-27 확정**; `handoff/envelope-draft-analysis.md` §7 확정 기록 참조).

---

## 1. 개요 / 위상

**envelope = Kafka 헤더로 운반되는 메시지 메타데이터 규약이다. payload(메시지 본문)가 아니다.**

- payload 구조는 `docs/kafka-payloads.md`가 정의하고, envelope(헤더 메타데이터)는 본 문서가 정의한다(통합본 6.8.1, kafka-payloads 도입부).
- envelope은 **transport-layer 헤더 규약**이며 payload 직렬화 형식(JSON/Avro/Protobuf)과 **독립적으로 정의된다**. Schema Registry 도입(payload 스키마 관리 경로)은 envelope 구조를 바꾸지 않는다(§8, 통합본 8.2 ADR #1).

### 적용 범위 (8토픽의 이분 구조 — 통합본 4.4.1 / 6.8.1)

| 구분 | 토픽 | envelope 4종 적용 |
|---|---|:-:|
| **공통 토픽군 (6)** | `command-topic`, `result-topic-job`, `result-topic-log`, `audit-topic`, `alert-topic`, `notification-topic` | 적용 |
| **OTLP 위임군 (2)** | `heartbeats-topic`, `metrics-topic` | 미적용(예외) — §4 |

> OTLP 위임군은 OTel Collector가 발행하며 OTLP 표준 헤더를 그대로 쓴다. envelope 4종 헤더는 적용되지 않는다(통합본 6.8.1 예외문, 4.4.1).

---

## 2. 헤더 필드 정의

envelope은 **4종 헤더**로 구성된다(통합본 6.8.1, 데모 spec §2.2). 헤더 키 문자열은 데모 spec과 동일하게 유지한다(Phase 0 하위호환 — §6).

| 헤더 키 | 필수/선택 | 타입 | 포맷 | 값 규칙 | 출처 |
|---|:-:|---|---|---|---|
| `x-message-id` | ● 필수 | string | UUIDv4 | 메시지 자체의 고유 식별자. 발행자가 메시지마다 새로 생성. 중복 감지(at-least-once 대비)에 사용 | 통합본 6.8.1 / 데모 §2.2 |
| `x-message-version` | ● 필수 | string | 정수의 string 표기 | payload의 **호환성(major) 버전**. 데모 `"1"`. 호환 깨짐(major)에만 증가하고 호환 변경(minor)은 값 불변(Q1; kafka-payloads 변경 정책) | 통합본 6.8.1 / 8.2 / 데모 §2.2 |
| `x-source` | ● 필수 | string | kebab-case 모듈명 | 발행자 식별. **폐쇄 enum 아님 — 명명 규칙 + 비규범 "알려진 값" 목록**(Q2) | 통합본 6.8.1 / 데모 §2.2 |
| `x-trace-id` | ○ 선택 | string | OTel 표준 16바이트 hex | OTel trace context propagation. 값이 없으면 헤더 자체를 생략한다 | 통합본 6.8.1 / 데모 §2.2 |

### 2.1 `x-message-id`
- UUIDv4 string. 발행자가 메시지마다 새로 발급한다.
- **Phase 0**: 발행만 하고 검사하지 않는다(데모 §2.2).
- **Phase 1+**: consumer 측에서 중복 검사(dedup)를 도입한다(통합본 6.8.1, ADR #15, baseline Redis TTL 5분). 단 **헤더 발행 포맷은 불변**이고 검사는 consumer 측 추가 동작이다. 검사 **정확한 시점**은 §9 O1(Open)로 보존한다.

### 2.2 `x-message-version` (Q1 결정 반영)
- **타입은 string 표기를 유지한다**(데모/양쪽 repo 모두 `"1"`). 코드 회귀 0.
- **의미 = payload의 호환성(major) 버전이다.** payload 스키마 변경 정책(kafka-payloads)상:
  - **호환 깨짐(major — 필드 제거/타입 변경)** → `x-message-version` 값을 정수로 증가시킨다.
  - **호환 변경(minor — 필드 추가/optional)** → `x-message-version` 값은 **불변**이다.
  - 즉 이 헤더는 payload의 **전체(major.minor) 스키마 버전이 아니라 major 호환성 버전만** 운반한다. minor 변화는 헤더에 싣지 않는다. **minor 버전의 기록 위치는 본 envelope 규약 범위 밖**이며 payload 스키마 관리 정책 소관이다(kafka-payloads는 minor bump 존재만 명시하고 기록 위치는 미상세 — envelope이 단정하지 않는다).
- 통합본 8.2의 "단순 정수" 표기와 정합한다.
- Schema Registry 도입(Phase 2+)과의 정책 연동은 §9 O2(Open)로 보존한다(통합본 8.2 ADR #1 = 1차 미도입은 결정, 연동은 Open).

### 2.3 `x-source` (Q2 결정 반영)
- **폐쇄(closed) enum이 아니다.** 다음 명명 규칙(규범)을 따른다:
  - kebab-case로 표기한 **발행 모듈명**을 값으로 쓴다.
- **알려진 값 목록(비규범, non-normative — 정보 제공용)**: 신규 발행자 추가 시 **spec bump 없이 이 목록만 갱신**한다.
  - `script-agent`, `monitoring-be`, `otel-collector` — Phase 0 데모 발행자(데모 §2.2).
  - `infra-agent`, `rule-engine` 등 — Phase 1+ 신규 발행자(통합본 6.8.1). Alert Processor / Incident Service / Notification Service 등 신규 발행자도 자기 식별자를 부여한다(통합본 6.8.1 마지막 문단, 6.9.3).
- **주의 — `otel-collector`의 적용 경로**: 데모 §2.2의 `x-source` 목록은 `otel-collector`를 포함하나, OTel Collector가 발행하는 토픽(`heartbeats-topic`/`metrics-topic`)은 §4.2의 OTLP 위임군으로 **envelope 4종 헤더를 적용하지 않는다**. 따라서 `otel-collector`는 데모 목록에서 승계된 값이며, 현재 envelope을 싣는 공통 토픽군(6)에서 이 값이 등장하는 경로는 없다. OTLP 발행자가 공통 토픽군에 envelope 발행자로 합류하는지는 본 문서가 단정하지 않는다(데모 목록 보존 + 적용 경로 미확인).
- **consumer 가드**: consumer는 알려진 값 목록에 없는 `x-source` 값을 만나도 깨지지 않아야 한다(폐쇄 enum이 아니므로). Phase 0 → Phase 1 진입 회귀 가드(§6).
- **검증 범위 제외**: 위 "알려진 값 목록"은 **비규범(정보 제공용)**이므로 spec-sync drift 검사나 consumer 검증 규칙의 **대조 대상이 아니다**. 목록에 없는 값도 명명 규칙만 지키면 정상이며, `otel-collector`처럼 현재 envelope 적용 경로가 없는 값이 목록에 남아 있어도 충돌이 아니다.

### 2.4 `x-trace-id`
- OTel 표준 16바이트 hex string. OTel context propagation 용도.
- **선택(○)**: 값이 빈 문자열/없음이면 **헤더 자체를 생략**한다(양쪽 repo 구현 정합, 데모 §2.2 "○").
- **Phase 0**: 발행만 하고 검사하지 않는다.
- **Phase 1+**: BE consume 시 trace context를 복원하는 코드가 추가된다(통합본 6.8.1, 6.6.4 — "Phase 1에서 BE consume 시 trace context 복원 코드 필요"). 발행 동작은 동일하고 복원은 consumer 측 추가 동작이다.

---

## 3. envelope 경계 원칙 (Q4 결정 반영)

### 3.1 원칙 (산문)
envelope은 **도메인 데이터가 아닌 전송 메타데이터**만 담는다. 메시지가 "무엇을 의미하는가"(도메인)는 payload에, "어떻게 전송·식별·추적되는가"(transport)는 envelope 헤더에 둔다. **본 문서가 정의하는 envelope 헤더는 위 §2의 4종으로 한정**된다. (그 외 전송 헤더의 추가 도입 여부·절차는 본 문서가 결정하지 않으며, 필요 시 envelope 규약 개정으로 다룬다 — 즉 "모든 추가 Kafka 헤더 전면 금지"를 규범화한 것은 아니다.)

### 3.2 negative list — envelope에 넣지 않는 것
다음은 envelope 헤더로 올리지 **않는다**. payload 또는 메시지 키에 둔다(통합본 6.8.2 키 정책 / kafka-payloads 각 payload):

- **도메인 시각**: `occurred_at`, `triggered_at`, `resolved_at`, `started_at`, `finished_at`, `scheduled_at`, `sent_at` 등 → payload(통합본 6.8.4 timestamp 규약).
- **도메인 식별자**: `execution_id`, `agent_id`, `job_id`, `schedule_id`, `rule_id`, `alert_id`, `incident_id`, `target_agent_id`, `target_id` 등 → payload / 메시지 키(통합본 6.8.2, 6.8.3).
- **도메인 상태/제어 필드**: `mode`(prod/validation), `valid_until`, `status`, `severity`, `event_type` 등 → payload(kafka-payloads).

> 단 `trace_id`는 예외적으로 헤더(`x-trace-id`)와 payload(`alert-topic`)에 **둘 다** 등장한다 — 이는 의도된 중복이며 §5의 불변식이 적용된다.

---

## 4. 토픽별 적용

### 4.1 공통 토픽군 (6) — envelope 4종 적용

| 토픽 | envelope | 비고 |
|---|:-:|---|
| `command-topic` | 4종 | 표준 적용. 키 = `target_agent_id`(통합본 6.8.2) |
| `result-topic-job` | 4종 | 표준 적용. 키 = `agent_id` |
| `result-topic-log` | 4종 | 표준 적용. 키 = `agent_id` |
| `audit-topic` | 4종 | 표준 적용. 통합본 6.6.3상 audit 메시지에 `x-trace-id`를 적용(데모 적용)한 사실이 있다 — 단 헤더 정의(§2.4)상 여전히 **선택(○)**이며 본 문서가 audit 전용 필수화를 새로 정하지는 않는다. 키 = `agent_id`/`user_id`/`system` |
| `alert-topic` | 4종 | 표준 적용. payload에 `trace_id` 동일 사본 존재(§5). 키 = `(rule_id, target_id)` 조합, **rule_id null이면 `("agent-offline", target_id)`**(Agent OFFLINE은 룰 기반 아님 — kafka-payloads/통합본 6.8.2) |
| `notification-topic` | 4종 | 표준 적용. 키 = `incident_id` |

> **토픽 명칭 규약**: 위 표의 토픽명은 **논리명**이며 실제 토픽명은 `docs/kafka-payloads.md` / 통합본 4.4.1을 따른다. 특히 `command-topic`은 Zone 독립 토폴로지(통합본 7.1)에서 **zone 단위로 분리된 물리 토픽 `command-topic-{zone}`**(통합본 4.4.1 "zone 단위", 1232 `command-topic-zone-N`)으로 실현된다. envelope 4종 적용은 zone suffix와 **무관하게 동일**하다. 나머지 7토픽은 논리명=물리명이다.
>
> **메시지 키 정책의 정본**은 `docs/kafka-payloads.md` / 통합본 6.8.2이다. 위 표의 키 표기는 envelope 적용 맥락을 위한 **참고**이며, 세부(예: alert-topic의 rule_id null 대체키)는 정본을 따른다.

### 4.2 OTLP 위임군 (2) — envelope 예외

`heartbeats-topic`과 `metrics-topic`은 OTel Collector가 발행하며 **envelope 4종 헤더를 적용하지 않는다**(통합본 6.8.1 예외문, 4.4.1).

- 이들 토픽은 **OTLP 표준 헤더**를 그대로 쓴다. 본 envelope spec이 규정하는 것은 "OTLP 위임군에는 envelope 4종 헤더를 적용하지 않는다"는 것**뿐**이다(통합본 6.8.1 예외문, 4.4.1). 이는 OTLP가 `x-message-id`/`x-message-version` 등 envelope 4종을 **동등 대체 보장한다는 의미가 아니다.** 이 영역의 메시지 식별·버전 관리는 OTLP/Collector 표준 동작을 따르며 envelope 4종과 1:1 대응을 보장하지 않는다.
- **trace context 연계**: 통합본 6.8.1은 "trace context는 OTLP resource attribute에 자연 포함"된다고 기술한다. 단 이는 OTLP/Collector 구현·설정에 의존하는 서술이며 본 spec이 독립적으로 보장하는 규범은 아니다. 따라서 "OTLP 위임군에 `x-trace-id`가 불필요하다"는 강한 결론으로 박지 않고, 그 영역의 trace 전달 메커니즘·보장 수준은 OTLP 표준에 위임하는 것으로 한정한다.
- timestamp: 이 영역만 **OTLP UnixNano**를 쓴다(통합본 6.8.4 — envelope 규약 예외와 같은 이유).
- **payload 직렬화·Phase 위상은 두 토픽이 다르다**(envelope 4종 헤더와는 무관한 별개 사항):
  - `heartbeats-topic` — Phase 0 데모부터 존재. 직렬화는 데모 `otlp_json` → **Phase 1에서 protobuf 전환**(ADR #2; 통합본 6.9, kafka-payloads). 예외군 payload 직렬화 정정이다.
  - `metrics-topic` — **Phase 2 신규 토픽**이며 **Phase 1에선 미사용**이다(kafka-payloads `metrics-topic` "Phase 2, Phase 1에선 미사용"; 통합본 6.9.5). 직렬화는 OTLP MetricsData protobuf 표준. Phase 1 protobuf 전환 대상은 heartbeats뿐이며 metrics는 여기에 포함되지 않는다.

---

## 5. trace_id 불변식 (Q3 결정 반영)

`trace_id`는 두 곳에 등장하며 이는 **의도된 중복(모순 아님)** 이다:
- **헤더 `x-trace-id`** — OTel trace context propagation 용. **transport 정본**.
- **payload `trace_id`** (`alert-topic`, optional — kafka-payloads) — alert를 execution chain에 묶는 **도메인 상관 키**(통합본 6.8.3 — `(execution_id, trace_id)`로 chain). 헤더 값의 **도메인 사본**.

**불변식 (규범)**:
> payload `trace_id`가 존재할 때, 그 값은 동일 메시지의 헤더 `x-trace-id` 값과 **동일하다**(값의 동일성 규약 — Q3 확정, 통합본 6.8.3 "envelope `x-trace-id`와 동일").

- 이 불변식은 **값의 동일성에 관한 규약**이며, **위반 검사 시점·책임·처리 정책은 본 문서 범위 밖**이다(consumer 측 검사 동작은 Phase별 결정 — §2.1·§9 참조).
- 헤더 `x-trace-id`가 생략된 메시지라면 payload `trace_id`도 부재(optional)인 것이 일반적이다.

---

## 6. 데모 spec v0.2.1 하위호환 (Phase 0 회귀 보장)

envelope 헤더 4종은 데모 v0.2.1 ↔ v0.9가 **포맷 수준 완전 하위호환**이다. Phase 0 발행 코드는 회귀 없이 통과한다.

| 항목 | Phase 0 회귀 기준(데모 §2.2) | Phase 1+ 목표(본 문서) | 호환성 |
|---|---|---|---|
| `x-message-id` | UUID, 발행만·검사 없음 | UUID 동일, consumer 측 검사 추가(ADR #15) | 하위호환 — 발행 포맷 불변 |
| `x-message-version` | string `"1"` 고정 | string `"1"`, major 호환성 버전 의미(Q1; major에만 증가) | 호환 — 값 동일 |
| `x-source` | `script-agent`/`monitoring-be`/`otel-collector` 3종 | 명명 규칙 + 알려진 값(superset)(Q2) | 확장 — 데모 3종은 부분집합 |
| `x-trace-id` | ○, 발행만·검사 없음 | ○, consumer 측 trace 복원 추가 | 하위호환 — 발행 동작 동일 |
| OTLP 예외군 | `heartbeats-topic`만 예외(OTLP 표준 헤더, 데모 §2.2). metrics-topic은 데모 v0.2.1에 없음 | `heartbeats-topic` 예외 유지(직렬화 Phase 1 protobuf 전환) + **Phase 2 신규** `metrics-topic`도 동일 예외 | 확장 — Phase 0엔 heartbeats만, metrics는 Phase 2 추가 |

**회귀 0 보장 조건**: 헤더 키 4종 문자열 · `x-message-version` 값 `"1"` · source 데모 3종 · 옵셔널 trace 생략 로직. 양쪽 repo 현 구현이 이미 충족한다(1라운드 분석 §1 코드 정합).

**Phase 1 신규 동작(추가일 뿐, 발행 회귀 아님)**:
- consumer 측 `x-message-id` 중복 검사(ADR #15).
- consumer 측 `x-trace-id` trace context 복원.
- consumer는 알 수 없는 `x-source` 값에 깨지지 않을 것(§2.3 가드).

> 위 신규 동작은 모두 **consumer 측 동작 추가** 또는 **예외 토픽 직렬화**이며, Phase 0 발행 코드 동작은 변경되지 않는다.

---

## 7. 구현 분배 (shared-libs/envelope) (Q5 결정 반영)

`kafka-payloads.md`가 언급한 "shared-libs/envelope"의 실체를 다음 모델로 정의한다.

- **envelope 헤더 세부 규약의 정본 = 본 문서(`docs/envelope.md`).** 단 문서 위계상 **통합본 v0.9 6.8/6.9가 상위 근거**이며(상단 문서 위상 참조), 본 문서는 그 아래에서 envelope 4종 헤더의 세부 규약을 정의하는 정본이다. 통합본과 충돌 시 통합본이 우선한다.
- hub(Java)·script-agent(Go)는 본 문서를 따르는 **언어별 thin 구현 가이드**를 적용한다(언어별 얇은 헤더 빌드/파싱 구현).
- **Phase 1 동기화 방식 = 수동 동기화 + spec-sync 통제**(Q5 확정). 각 repo가 본 정본을 보고 구현하며, 정본↔구현 drift는 `spec-sync` 검사로 검출한다. 단 spec-sync의 **검사 범위·실행 주체·실패 기준 등 운영 세부는 구현 계획으로 별도 정의**하며, 본 문서는 "수동 동기화 + spec-sync 통제"라는 **방식 결정만** 담는다.
- **코드 생성 / IDL 통합은 Phase 2+ 후보로만 표기**한다(결정 아님). envelope은 Kafka 헤더 메타데이터라 payload 직렬화 IDL(Avro/Protobuf)과 층위가 달라, IDL을 택해도 헤더 규약은 별도 markdown spec으로 남는다(1라운드 분석 §5).

### 현재 구현 위치 참조 (Read 전용 — 수정 대상 아님)
- script-agent: `internal/model/envelope.go`(헤더 키 상수 + 고정값), `internal/kafka/envelope.go`(`BuildHeaders`, 옵셔널 trace 생략 로직).
- hub: `producer/CommandPublisher.java`에 헤더 키·source·version 인라인(별도 envelope 모듈 없이 publisher 내부). envelope 모듈화 시 추출 대상.

> 위 구현 일치는 현재 "사람이 spec을 보고 맞춤"으로만 보장된다 → spec-sync가 통제 수단.

---

## 8. 버전·진화 정책

- **`x-message-version` 운용(Q1)**: 현재 단순 정수(string 표기). 이 헤더는 payload의 **major 호환성 버전**만 운반한다 — 호환 깨짐(major)에만 값을 증가시키고, 호환 변경(minor: 필드 추가/optional)은 헤더 값을 바꾸지 않는다(kafka-payloads 변경 정책). §2.2 정의와 동일하며, payload의 minor 버전의 기록 위치는 본 envelope 규약 범위 밖(payload 스키마 관리 정책 소관, 미상세)이다.
- **Schema Registry / IDL은 Phase 2+ 후보**다(통합본 8.2 ADR #1 = 1차 미도입은 결정). SR 도입은 **payload 스키마 관리 경로**이지 envelope **헤더 구조**를 바꾸지 않는다(§1 — 이 구조 불변은 결정). 다만 SR 도입 시 `x-message-version` **값의 의미**가 SR schema 버전과 어떻게(또는 연동될지 여부 자체부터) 연동되는지는 **결정되지 않았다 → §9 O2(Open)**. 본 문서는 그 연동 방향·영향 범위를 단정하지 않는다.
- envelope 헤더 규약은 payload가 JSON이든 Avro/Protobuf이든 **불변**이다(§1).

---

## 9. 미결정 사안 (Open — 결정 아님, 보존)

다음은 결정이 아니라 보존 항목이다. **본 문서 본문에 결정으로 박지 않는다.** Phase에 따라 결정 예정이며 통합본 6.8.6 / `13_open.md`를 참조한다.

| # | 항목 | 출처 | 상태 |
|---|---|---|---|
| O1 | `x-message-id` 중복 검사 **정확한 시점** | 통합본 6.8.6, ADR #15 | Open. baseline(Phase 1 Redis TTL 5분)은 결정, **정확한 시점**은 Open |
| O2 | Schema Registry 도입과 `x-message-version` **정책 연동** | 통합본 6.8.6, ADR #1, 13_open §E | Open. 1차 미도입은 결정, SR 도입 시점·version 연동은 Open |
| O3 | `alert-topic` 조합 키 partition 분배 효율성(Rule×대상 편향 hot partition) | 통합본 6.8.6 | Open. envelope 헤더와 직접 무관(키 정책)하나 6.8.6 소속이므로 보존 |

> 위 항목은 추측으로 메우지 않는다. 결정이 필요하면 사람 호출 + 해당 ADR/Open question 갱신 경로를 따른다.

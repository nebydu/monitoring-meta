# spec-drift 보고서 — envelope.md 신규 정본 vs 비교 대상 3종

- **생성일**: 2026-05-27
- **생성자**: spec-sync sub-agent
- **기준 timestamp**: 20260527-143000
- **정본**: `docs/envelope.md` (신규 작성, Phase 1+ 목표 spec)
- **이 보고서의 역할**: drift 검출·보고만. 동기화는 사람 또는 각 repo sub-agent가 수행.

---

## 비교 inventory

| 비교 대상 | 파일 경로 | 역할 |
|---|---|---|
| A | `../hub/docs/monitoring-demo-message-spec-v0.2.1.md` §2.2 | Phase 0 회귀 기준(정본) |
| B | `../script-agent/docs/monitoring-demo-message-spec-v0.2.1.md` §2.2 | Phase 0 회귀 기준(사본) |
| C | `../hub/src/main/java/com/monitoring/hub/producer/CommandPublisher.java` | hub 구현 — 헤더 키·source·version 값 |
| D | `../script-agent/internal/model/envelope.go` + `internal/kafka/envelope.go` | script-agent 구현 — 헤더 키·source·version 값 |
| E | `docs/통합본_v0_9.md` §6.8 | 상위 근거 spec |
| F | `docs/kafka-payloads.md` 도입부 + 변경 정책 | envelope 언급 정합 |

---

## 섹션 1 — 데모 spec v0.2.1 §2.2 (A) vs envelope.md §2·§6

### 위상 전제
- **A(hub 정본)**와 **B(script-agent 사본)**는 완전 동일(라인 수, 섹션 구조, 변경 이력 전체 일치). 이하 "데모 spec"으로 통칭.
- 비교 기준: envelope.md가 데모 spec의 포맷을 **깨뜨리는가**. Phase 1+ 추가분(consumer 측 검사, 신규 x-source 값 등)은 drift가 아닌 정상 확장이다.

### 헤더 키 4종 비교

| 헤더 키 | 데모 spec §2.2 | envelope.md §2 | 판정 |
|---|---|---|---|
| `x-message-id` | 키 = `x-message-id`, UUID string, 필수 ● | 동일. 키·타입·필수성 불변 | **일치** |
| `x-message-version` | 키 = `x-message-version`, string, 필수 ●, 값 `"1"` | 동일. 추가로 "정수 단조 증가 의미" 규정(Q1). string 타입·`"1"` 값 불변 | **일치 (Phase 1 의미 추가, 포맷 불변)** |
| `x-source` | 키 = `x-source`, string, 필수 ●, 값 `script-agent \| monitoring-be \| otel-collector` | 동일 키·타입·필수성. 데모 3종은 "알려진 값 목록(비규범)"의 부분집합 | **일치 (데모 3종 보존, 신규 값 추가는 Phase 1 확장)** |
| `x-trace-id` | 키 = `x-trace-id`, string, 선택 ○ | 동일. 값 없으면 헤더 자체 생략 | **일치** |

### heartbeats 예외 비교

| 항목 | 데모 spec | envelope.md | 판정 |
|---|---|---|---|
| heartbeats 토픽 예외 | "OTel Collector 발행이라 위 헤더 규약 적용 안 됨" | 동일 + metrics-topic도 예외 추가(통합본 4.4.1 근거) | **일치 (데모 예외 보존, metrics-topic 예외 추가는 Phase 1 확장)** |

### 결론 (데모 spec vs envelope.md)

**진짜 drift 없음.** envelope.md가 데모 보장 포맷을 깨뜨리는 항목(헤더 키 이름 변경, 필수→삭제, 타입 비호환)은 발견되지 않는다. 모든 차이는 Phase 1+ 추가·확장(consumer 측 동작 추가, x-source 알려진 값 목록 확장, metrics-topic 예외 명시, trace 불변식 §5, envelope 경계 원칙 §3)이다.

---

## 섹션 2 — hub 구현 (CommandPublisher.java, C) vs envelope.md §2

### 헤더 키 상수

| 상수 | 구현값 | envelope.md | 판정 |
|---|---|---|---|
| `HEADER_MESSAGE_ID` | `"x-message-id"` | `x-message-id` | **일치** |
| `HEADER_MESSAGE_VERSION` | `"x-message-version"` | `x-message-version` | **일치** |
| `HEADER_SOURCE` | `"x-source"` | `x-source` | **일치** |
| `HEADER_TRACE_ID` | `"x-trace-id"` | `x-trace-id` | **일치** |

### 고정값

| 항목 | 구현값 | envelope.md | 판정 |
|---|---|---|---|
| MESSAGE_VERSION | `"1"` | `"1"` (string, 정수 단조 증가 의미) | **일치** |
| SOURCE | `"monitoring-be"` | 알려진 값 목록에 포함(`monitoring-be`) | **일치** |

### x-trace-id 생략 로직

구현: `if (traceIdOrNull != null && !traceIdOrNull.isBlank())` → 조건 미충족 시 헤더 추가 생략.
envelope.md §2.4: "값이 없으면 헤더 자체를 생략한다".
**일치** — null 및 blank 모두 생략 처리.

### x-message-id 생성 방식

구현: `UUID.randomUUID().toString()` — UUIDv4 string.
envelope.md §2.1: UUIDv4 string, 발행자가 메시지마다 새로 발급.
**일치**.

### drift 발견 항목

**drift 없음.** 다만 아래 사항은 Phase 1 작업 시 주의가 필요하며 정보로 기록한다(drift 아님):
- hub는 CommandPublisher에만 헤더를 인라인으로 구현한다. envelope.md §7은 "언어별 thin 구현 가이드" 및 "hub: producer/CommandPublisher.java에 헤더 키·source·version 인라인(별도 envelope 모듈 없이 publisher 내부). envelope 모듈화 시 추출 대상"이라 명시하고 있어, 현재 구현은 spec과 정합한 상태다.
- AuditPublisher, JobResultPublisher 등 hub 내 다른 publisher가 존재한다면 동일 헤더 상수를 재사용하는지는 본 보고서 범위(CommandPublisher 한정) 밖이다.

---

## 섹션 3 — script-agent 구현 (D: model/envelope.go + kafka/envelope.go) vs envelope.md §2

### 헤더 키 상수 (model/envelope.go)

| 상수 | 구현값 | envelope.md | 판정 |
|---|---|---|---|
| `HeaderMessageID` | `"x-message-id"` | `x-message-id` | **일치** |
| `HeaderMessageVersion` | `"x-message-version"` | `x-message-version` | **일치** |
| `HeaderSource` | `"x-source"` | `x-source` | **일치** |
| `HeaderTraceID` | `"x-trace-id"` | `x-trace-id` | **일치** |

### 고정값 (model/envelope.go)

| 항목 | 구현값 | envelope.md | 판정 |
|---|---|---|---|
| MessageVersion | `"1"` | `"1"` | **일치** |
| SourceAgent | `"script-agent"` | 알려진 값 목록에 포함 | **일치** |

### x-trace-id 생략 로직 (kafka/envelope.go)

구현: `if traceID != ""` → 빈 문자열이면 헤더 생략.
envelope.md §2.4: "값이 빈 문자열/없음이면 헤더 자체를 생략한다".
**일치**.

### x-message-id 생성 (kafka/envelope.go)

구현: `uuid.NewString()` (github.com/google/uuid — UUIDv4).
envelope.md §2.1: UUIDv4 string.
**일치**.

### drift 발견 항목

**drift 없음.** 구현은 envelope.md §2의 모든 헤더 키·타입·필수성·생략 로직을 충족한다.

---

## 섹션 4 — 통합본 v0.9 §6.8 (E) vs envelope.md

### 헤더 정의 비교

| 항목 | 통합본 §6.8.1 | envelope.md §2 | 판정 |
|---|---|---|---|
| x-message-id | 필수 ●, 메시지 식별, UUID | 동일 | **일치** |
| x-message-version | 필수 ●, payload 스키마 버전, 데모 `1` 고정 | 동일 + 정수 단조 증가 의미 명시(Q1) | **일치 (envelope.md가 세부 명시 추가)** |
| x-source | 필수 ●, 발행자 식별 | 동일 + 명명 규칙(kebab-case 모듈명) + 알려진 값 목록(Q2) | **일치 (envelope.md가 세부 명시 추가)** |
| x-trace-id | 선택 ○, OTel trace propagation | 동일 + 생략 조건 명시 | **일치 (envelope.md가 세부 명시 추가)** |
| heartbeats+metrics 예외 | 명시(§6.8.1 예외문) | 동일(§4.2) | **일치** |

### 6.8.1 x-message-version 표기 미세 차이

통합본 §6.8.1 표: `x-message-version` 설명에서 "데모 `1` 고정"이라 기재됨(백틱 없이 숫자 `1`).
envelope.md §2 표: "데모 `"1"` 고정"(string 명시, Q1 결정 반영).

이는 **표기 수준의 차이**이며 의미 불일치가 아니다. 통합본 §6.8.1은 value `1`을 간략히 표기했고, envelope.md는 "string 표기를 유지한다"를 명시적으로 추가했다(Q1 결정 반영). 호환 깨짐 없음.

**판정: 일치 (envelope.md가 세부 결정 반영)**

### 신규 내용 (통합본에 없고 envelope.md에 추가된 것)

이하는 drift가 아니라 envelope.md가 통합본 6.8 이후 사람 confirm된 Q1~Q5를 바탕으로 추가한 정규화 내용이다:
- §3 envelope 경계 원칙 + negative list (통합본은 6.8.2~6.8.4에 분산)
- §5 trace_id 불변식 (통합본 6.8.3 기반, envelope.md에서 명시적 규범으로 격상)
- §6 데모 spec 하위호환 호환성 표 (통합본 6.9 기반)
- §7 shared-libs/envelope 구현 분배 모델 (Q5 결정 반영)
- §9 Open 항목 보존 테이블

**판정: 통합본이 근거, envelope.md가 세부 정규화를 추가한 것이므로 drift 아님.**

---

## 섹션 5 — kafka-payloads.md (F) vs envelope.md §7

### 비교 항목

| kafka-payloads.md 언급 | envelope.md | 판정 |
|---|---|---|
| 도입부: "envelope는 별도(`v0_9/04_데이터흐름.md` 6.8 + shared-libs/envelope)" | §7: 정본 = `docs/envelope.md`, hub/script-agent는 언어별 thin 구현 | **경미한 경로 표기 차이** — 아래 상세 참조 |
| 변경 정책 말미: "호환 깨짐 → major bump + `x-message-version` 증가" | §8: payload 스키마 호환 깨짐(major) 시 x-message-version 값 증가 | **일치** |
| `heartbeats-topic` (envelope 예외 — OTLP 표준) | §4.2: 동일 | **일치** |
| `metrics-topic` (Phase 2, envelope 예외 — OTLP 표준) | §4.2: 동일 | **일치** |

### 경미한 경로 표기 차이 상세

kafka-payloads.md 도입부(1줄, 3번째 줄)에서 envelope 참조 위치를 `v0_9/04_데이터흐름.md 6.8 + shared-libs/envelope`로 표기하고 있다.

현재 상황:
- 통합본 분할 구조에서 `04_데이터흐름.md`는 별도 파일로 존재하지 않고, `docs/통합본_v0_9.md`에 통합되어 있다.
- envelope 정본은 `docs/envelope.md`로 신규 작성되었다(shared-libs/envelope는 구현 위치이고, spec 정본은 `docs/envelope.md`).

**판정: 정보성 표기 차이.** kafka-payloads.md가 envelope 규약을 자체 정의하거나 모순을 일으키지는 않는다. 다만 "shared-libs/envelope"라는 표현이 구현 위치인지 spec 정본인지 혼동을 줄 수 있다.

- **호환 깨짐 여부**: 없음. kafka-payloads.md는 "envelope는 별도"라고만 했고, 별도 spec이 `docs/envelope.md`로 확정된 것은 Phase 1 신규 결정이다.
- **사본 갱신 필요 여부**: kafka-payloads.md의 1줄 표기를 `docs/envelope.md`를 가리키도록 갱신하면 더 정확해지나, 의미 불일치(포맷 깨짐)는 없으므로 **긴급도 낮음**.

---

## 섹션 6 — 데모 spec 양쪽 사본 간 drift (hub vs script-agent)

(이번 baseline 지시에 따라 양쪽 사본 간 drift도 확인)

**결과: 완전 일치.** 섹션 구조(섹션 1~8 전체 헤딩 목록), 변경 이력(v0.1/v0.2/v0.2.1), §2.2 헤더 표, §2.3 메시지 키 표가 양쪽 사본(`../hub/docs/` vs `../script-agent/docs/`)에서 동일하다. drift 없음.

---

## 전체 drift 요약

| 비교 쌍 | drift 여부 | 분류 | 비고 |
|---|---|---|---|
| envelope.md vs 데모 spec §2.2 | 없음 | — | Phase 1 추가분은 정상 확장 |
| envelope.md vs hub 구현(CommandPublisher.java) | 없음 | — | 헤더 키·값·생략 로직 전부 일치 |
| envelope.md vs script-agent 구현(model/envelope.go + kafka/envelope.go) | 없음 | — | 헤더 키·값·생략 로직 전부 일치 |
| envelope.md vs 통합본 §6.8 | 없음 | — | envelope.md가 세부 결정 추가, 근거는 통합본 |
| envelope.md vs kafka-payloads.md | 경미한 표기 차이 | 정보성 | "shared-libs/envelope" 경로 표기 → `docs/envelope.md`로 갱신 권장(긴급 아님) |
| hub 사본 vs script-agent 사본 (데모 spec) | 없음 | — | 양쪽 완전 동일 |

**escalation 필요 항목**: 없음. critical/conflict 없음.

---

## 사본 갱신 후보 (긴급도 낮음)

kafka-payloads.md 도입부 1줄 표기 갱신 후보:

현행:
```
이 파일은 **본 시스템 8 Kafka 토픽의 메시지 본문(payload) 구조**. envelope는 별도(`v0_9/04_데이터흐름.md` 6.8 + shared-libs/envelope).
```

갱신 후보:
```
이 파일은 **본 시스템 8 Kafka 토픽의 메시지 본문(payload) 구조**. envelope(Kafka 헤더 4종 규약)는 별도 — `docs/envelope.md` (Phase 1+ 정본). 구현은 각 repo 언어별 thin 구현(shared-libs/envelope 참조).
```

단, kafka-payloads.md는 `docs/` 하위의 정본 문서이므로 **수정은 analyzer 또는 사람이 직접 수행**한다(spec-sync는 보고만).

---

## 미결 Open 항목 (보고서 범위 내 추적)

envelope.md §9에 보존된 아래 항목은 이번 drift 검출 과정에서도 결정 없이 그대로다. 사람 결정 필요 시 별도 ADR/Open question 경로를 따른다.

| # | 항목 | 상태 |
|---|---|---|
| O1 | x-message-id 중복 검사 정확한 시점 | Open(baseline Redis TTL 5분은 결정) |
| O2 | Schema Registry 도입과 x-message-version 정책 연동 | Open(1차 미도입은 결정) |
| O3 | alert-topic 조합 키 partition hot spot | Open(envelope과 직접 무관) |

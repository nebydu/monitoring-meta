# envelope spec 후보안 + 결정 사안 분석

- 작성 일시: 2026-05-27
- 기준 문서 기준: `docs/통합본_v0_9.md`(Phase 1+ 목표 spec), `docs/kafka-payloads.md`(별첨 payload spec)
- 회귀 기준(ground truth): 데모 spec v0.2.1 (`../hub/docs/monitoring-demo-message-spec-v0.2.1.md`, `docs/phase0-snapshot/PROJECT_OVERVIEW.md` §7에 합본)
- **1라운드: `docs/envelope.md` 미확정. 본 문서는 후보안 분석만이며 기준 문서 envelope spec을 확정하지 않는다.**
- 성격 원칙: 데모 spec v0.2.1 = "Phase 0 코드가 회귀 없이 지켜야 할 동작 spec". 통합본 v0.9 = "Phase 1+ 도달 목표 spec". 둘을 같은 ground truth로 다루지 않는다.
- 사람 확정 방침(직전 라운드): **B-1~B-4는 지금 결정하지 않고 "후보안 + 추천"으로 문서에 정리**한다.

---

## 1. envelope 후보 필드 목록

envelope = "도메인 데이터가 아닌 메타데이터"를 payload에서 분리해 **Kafka 헤더**로 운반하는 4종 (통합본 6.8.1, 데모 spec §2.2). payload 안에 넣지 않는다.

| 헤더 | 출처 | 의미 | 필수/선택 | 타입(추정) |
|---|---|---|:-:|---|
| `x-message-id` | 통합본 6.8.1 / 데모 §2.2 / hub `CommandPublisher.java` L41 / script-agent `model/envelope.go` L8 | 메시지 자체 식별(UUID). 중복 감지용. 데모는 발행만·검사 없음, Phase 1부터 검사(ADR #15) | ● | UUIDv4 string |
| `x-message-version` | 통합본 6.8.1 / 데모 §2.2 / 양쪽 repo | payload 스키마 버전. 데모 `1` 고정. Schema Registry(ADR #1) 도입 시 정책 확장 | ● | string (데모 `"1"`) |
| `x-source` | 통합본 6.8.1 / 데모 §2.2 / 양쪽 repo | 발행자 식별. 통합본 값 집합 = `script-agent` / `infra-agent` / `monitoring-be` / `otel-collector` / `rule-engine` 등. 데모 = `script-agent` / `monitoring-be` / `otel-collector` 3종 | ● | string(enum 확장형) |
| `x-trace-id` | 통합본 6.8.1 / 데모 §2.2 / 양쪽 repo(옵셔널 생략 로직 보유) | OTel trace context propagation. 데모는 발행만·검사 없음. Phase 1부터 BE consume 시 trace 복원 | ○ | OTel 표준 16바이트 hex string |

코드 일치 확인:
- 헤더 키 4종 문자열이 hub(`CommandPublisher` L41~44)·script-agent(`model/envelope.go` L8~11)에서 **완전 일치**. `x-message-version` 값 `"1"`, source 값(`monitoring-be` / `script-agent`)도 일치.
- 양쪽 모두 `x-trace-id`는 값이 빈 문자열/null이면 헤더 자체를 생략 (script-agent `kafka/envelope.go` L25, hub `CommandPublisher` L71) → 데모 spec §2.2 "○(선택)" 동작과 일치.

> **성격 메모.** 위 표의 "필수/선택"과 "데모 동작"은 Phase 0 회귀 기준이다. Phase 1+ 목표(중복 검사 도입, trace 복원, source 값 확장)는 통합본 결정이며 데모 코드가 아직 구현하지 않는다.

---

## 2. envelope과 payload 경계 결정 사안 (B-1 ~ B-4)

직전 라운드 식별 경계 쟁점. 사람 방침에 따라 **결정하지 않고 후보안+추천만** 기재. 번호별 결정 질문은 §7에 모음.

### B-1. `x-message-version` 값 타입 — string vs integer
- 현황: 데모/양쪽 repo 모두 **string `"1"`**. kafka-payloads 변경정책은 "major bump + `x-message-version` 증가"(정수 증가 뉘앙스). 통합본 8.2 결정표는 "단순 정수(Schema Registry 미도입 하)".
- 후보 A: string 유지(`"1"`) — 현 코드 회귀 0, semver(`"1.2"`) 확장 여지.
- 후보 B: integer 의미로 재정의 — 8.2 "단순 정수" 표현과 일치하나 코드가 string이라 직렬화 표기는 헤더 byte이므로 실질 동일.
- **추천: 후보 A(string 표기 유지) + "값은 정수 단조 증가"로 의미 규정.** 코드 회귀 없음 + 8.2 의도 충족.

### B-2. `x-source` 값 집합 확정 위치 (envelope spec vs 각 발행자)
- 현황: 통합본 6.8.1은 "등"으로 열거(열린 집합). 신규 발행자도 자기 식별자 부여(6.8.1 마지막 문단).
- 후보 A: envelope spec이 **enum 폐쇄 집합**으로 고정 → 신규 발행자 추가 때마다 spec bump.
- 후보 B: envelope spec은 **명명 규칙(kebab, 모듈명)만 규정**, 값 목록은 발행자 등록부로 분리 관리.
- **추천: 후보 B(명명 규칙 + 알려진 값 목록 비규범 부록).** Phase 1/2에서 rule-engine·alert-processor 등 발행자가 계속 늘어나므로(6.9.3) 폐쇄 enum은 잦은 bump 유발.

### B-3. `trace_id`의 envelope 헤더 ↔ alert-topic payload 이중 등장
- 현황: `x-trace-id`(헤더, 6.8.1) + `alert-topic` payload `trace_id`(kafka-payloads L139, optional) 둘 다 존재. 6.8.3은 payload `trace_id`를 "envelope `x-trace-id`와 동일"로 명시.
- 판정: **의도된 중복(모순 아님)**. 헤더는 전송/propagation용, payload `trace_id`는 alert를 execution chain에 묶는 도메인 상관 키(6.8.3 "execution_id + trace_id로 chain"). → 통합본-update-proposal 불필요.
- 후보 A: payload `trace_id` 제거, 헤더만 기준 문서 → consumer가 chain 위해 헤더를 payload로 복사해야 함(불편).
- 후보 B: 둘 다 유지 + "헤더가 transport 기준 문서, payload는 동일 값의 도메인 사본"으로 envelope spec에 관계 명시.
- **추천: 후보 B.** 단 "두 값은 항상 동일해야 한다"는 불변식을 envelope spec에 명시.

### B-4. envelope 헤더 vs payload 중복 식별자 (`agent_id`, `execution_id` 등)
- 현황: `agent_id`·`execution_id`·`target_agent_id` 등은 **메시지 키 / payload**에 있고 envelope 헤더로 올리지 않음(6.8.2 키 정책, kafka-payloads 각 payload).
- 판정: 경계 명확. envelope = 전송 메타데이터 4종 한정, 도메인 식별자는 payload/키. 추가 결정 불필요하나 **envelope spec에 "도메인 ID는 envelope에 넣지 않는다"는 경계 원칙을 명시**할지가 B-4 쟁점.
- 후보 A: 원칙만 산문으로 서술.
- 후보 B: "envelope에 포함하지 않는 것" 명시 목록(negative list) 추가.
- **추천: 후보 B(negative list).** 신규 발행자가 식별자를 헤더로 올리는 drift를 사전 차단.

---

## 3. 토픽별 envelope 변형 (8토픽)

통합본 6.8.1 = envelope 4종 헤더가 적용되는 "공통 토픽군"과 OTLP 예외군의 **이분 구조**.

| 토픽 | envelope 4종 적용 | 변형/예외 | 근거 |
|---|:-:|---|---|
| `command-topic` | ● | 표준 4종. 키 = `target_agent_id` | 6.8.1/6.8.2 |
| `result-topic-job` | ● | 표준 4종. 키 = `agent_id` | 6.8.1/6.8.2 |
| `result-topic-log` | ● | 표준 4종. 키 = `agent_id` | 6.8.1/6.8.2 |
| `audit-topic` | ● | 표준 4종. **`x-trace-id` 데모 적용 권장**(6.6.4 트레이스, 6.6.5) | 6.8.1, 6.6 |
| `alert-topic` | ● | 표준 4종. payload에 `trace_id` 동일 사본(B-3). 키 = `(rule_id, target_id)` | 6.8.1/6.8.2 |
| `notification-topic` | ● | 표준 4종. 키 = `incident_id` | 6.8.1/6.8.2 |
| `heartbeats-topic` | ✕ (예외) | OTel Collector 발행. OTLP 표준 헤더 그대로, envelope 4종 미적용. trace는 OTLP resource attribute에 자연 포함 | 6.8.1 예외문, 4.4.1 |
| `metrics-topic` | ✕ (예외) | 동일 OTLP 예외(Phase 2). kafka-payloads는 OTLP MetricsData protobuf | 6.8.1 예외문, kafka-payloads |

핵심: **6개 공통 토픽 = envelope 4종 / 2개 OTLP 토픽(heartbeats·metrics) = envelope 예외.** OTLP 예외군은 직렬화(데모 `otlp_json` → Phase 1 protobuf, ADR #2)·timestamp(UnixNano)·키(Collector 기본)·헤더 모두 OTLP 표준을 따른다.

---

## 4. 데모 spec v0.2.1 ↔ v0.9 envelope 호환성 매트릭스

### 4.1 envelope 헤더 필드 단위 비교

| 항목 | 데모 v0.2.1 (Phase 0 회귀 기준) | 통합본 v0.9 (Phase 1+ 목표) | 호환성 / 가드 |
|---|---|---|---|
| `x-message-id` | UUID, 발행만·검사 없음 (§2.2) | UUID, Phase 1부터 중복 검사(ADR #15, Redis TTL 5분) | **하위호환.** 발행 포맷 동일. Phase 1은 consumer 측 검사 추가뿐 → Phase 0 코드 회귀 없음 |
| `x-message-version` | string `"1"` 고정 (§2.2) | string `"1"`, 정책 확장(B-1) | **호환.** 값 동일 |
| `x-source` | `script-agent` / `monitoring-be` / `otel-collector` 3종 (§2.2) | + `infra-agent` / `rule-engine` 등 확장 (6.8.1) | **확장(superset).** 데모 3종은 부분집합 → 회귀 없음. 신규 값은 신규 발행자에만 |
| `x-trace-id` | ○, 발행만·검사 없음 (§2.2) | ○, Phase 1부터 BE consume 시 trace 복원 | **하위호환.** 발행 동작 동일, 복원은 consumer 추가 |
| heartbeats envelope 예외 | OTLP 표준 헤더 (§2.2 단서) | 동일 + metrics-topic도 예외 (6.8.1) | **호환.** 데모 heartbeats 예외 그대로 |

### 4.2 데모 → Phase 1 정정 11개 중 envelope 관련 항목 (6.9.2 기준)

6.9.2 "데모 정정 대상" 11개 중 **envelope에 직접 영향**:
- `x-message-id` 중복 검사 (발행만 → BE consumer dedup 윈도우, Phase 1, ADR #15) — **envelope 의미 정정.** 단 헤더 포맷 불변, consumer 동작만 추가.
- Heartbeat 직렬화 (`otlp_json` → protobuf, Phase 1, ADR #2) — envelope **예외군** 토픽의 payload 직렬화 정정. envelope 4종 헤더와 무관(예외 토픽).

envelope **간접/무관** 정정(나머지 9개): `job-results` 토픽 분리, 영속 저장소, 인증, Frontend, Agent 자가 등록, Quartz JobStore, LOG_JOB occurred_at, audit actor.type 확장, command-topic zone routing. 이 중 토픽 분리·zone routing은 envelope **적용 대상 토픽 개수**만 바꿀 뿐 헤더 규약 자체는 불변.

### 4.3 Phase 0 회귀 가드 (envelope 관점)
- **회귀 0 보장 조건**: 헤더 키 4종 문자열·`x-message-version` 값 `"1"`·source 값(데모 3종)·옵셔널 trace 생략 로직 — 양쪽 repo 현 구현이 이미 충족(§1 코드 일치).
- **Phase 1 진입 가드**: (1) consumer가 x-message-id 미검사 메시지도 수용(검사는 추가 기능), (2) consumer가 알 수 없는 `x-source` 값에 깨지지 않을 것(enum 폐쇄 시 위험 → B-2 후보 B 권장), (3) `x-trace-id` 부재 메시지 정상 처리(데모는 대부분 생략).

> **성격 결론.** envelope 헤더 4종은 데모↔v0.9가 **포맷 수준 완전 하위호환**이다. 정정은 전부 "consumer 측 동작 추가" 또는 "예외 토픽 직렬화"이며, Phase 0 발행 코드는 회귀 없이 통과한다.

---

## 5. shared-libs/envelope 모듈 성격

### 5.1 통합본 결정 현황
- `kafka-payloads.md` L3: "envelope는 별도(`v0_9/04_데이터흐름.md` 6.8 + **shared-libs/envelope**)" — 모듈 **이름만 언급**.
- 통합본 본문(6.8, 8장 기술스택, 7장 아키텍처)에 **shared-libs/envelope 모듈의 구현 위치·언어·hub/script-agent 분배 방식 결정이 없다.**
- 판정: **모순이 아니라 미정의(undefined).** kafka-payloads가 가리킨 "shared-libs/envelope"의 실체 정의가 통합본에 부재. → §7 결정 사안 + §8 보존. 통합본-update-proposal 별도 파일은 만들지 않음(본문 내부 모순 아님, 단순 미정의).

### 5.2 현재 양쪽 repo 실태 (독립 구현)
- script-agent: `internal/model/envelope.go`(헤더 키 상수 + 고정값), `internal/kafka/envelope.go`(`BuildHeaders`) — **Go 독립 구현**.
- hub: `producer/CommandPublisher.java`에 헤더 키 상수·source·version **인라인** — 별도 envelope 모듈조차 없이 publisher 내부 하드코딩.
- 즉 polyrepo에서 hub(Java)·script-agent(Go)가 **각자 envelope을 독립 구현** 중이고, 일치는 "사람이 spec을 보고 맞춤"으로만 보장됨.

### 5.3 polyrepo 분배 전략 후보
| 전략 | 방식 | 장점 | 단점 |
|---|---|---|---|
| (1) 수동 동기화(현행) | envelope.md 기준 문서 + 각 repo가 spec 보고 구현 | 추가 인프라 0, Phase 0 동작 중 | drift 위험(spec-sync로만 검출), 언어별 2벌 유지 |
| (2) 코드 생성 | 단일 정의(YAML/JSON) → Java/Go 코드 생성 | 단일 기준 문서에서 양 언어 동기 | 빌드 파이프라인·생성기 도입 비용, polyrepo에 생성물 배포 경로 필요 |
| (3) IDL | Avro/Protobuf IDL로 envelope+payload 정의 → SR/codegen | Schema Registry(ADR #1) 경로와 자연 결합 | envelope은 Kafka **헤더**라 IDL(=payload 직렬화) 대상과 층위 다름 → 헤더는 IDL 밖에 별도 규약 필요 |

- 핵심 제약: envelope은 payload가 아니라 **Kafka 헤더 메타데이터**다. IDL(Avro/Protobuf)은 payload 직렬화 스키마이므로 envelope 헤더 4종을 그대로 담기 어렵다(B-3 trace_id처럼 payload로 내려야 IDL 대상). → 전략 (3)을 택해도 envelope **헤더 규약은 별도 markdown spec으로 남는다**.
- **추천: Phase 1은 (1) 수동 동기화 유지 + spec-sync drift 검사로 통제, "shared-libs/envelope"는 "기준 문서 envelope.md + 언어별 thin 구현 가이드"로 정의.** 코드 생성(2)은 발행자 수가 늘어 drift 비용이 커지는 Phase 2 재고 카드로. (사람 결정 필요 — §7)

---

## 6. Schema Registry 진화 경로

### 6.1 ADR #1 현황
- 통합본 8.2: **Schema Registry 1차 미도입**(baseline 결정됨). Phase 2/3 Apicurio 검토. `x-message-version` + spec(markdown)으로 통제.
- kafka-payloads L5/L182: JSON 직렬화 baseline, Phase 2/3 SR 도입 시 **이 payload 파일이 IDL 입력**.
- 13_open §E: "Schema Registry 도입 시점 — 컨슈머 다양성/schema 변경 빈도"는 **재검토 카드(Open)**.

### 6.2 envelope에 미치는 영향
- payload는 SR 진화 대상(JSON → Avro/Protobuf). **envelope 헤더 4종은 SR 진화와 층위가 다르다** — 헤더는 Kafka record header(byte string)이지 직렬화 payload가 아니므로 SR이 직접 관리하지 않는다.
- 따라서 envelope spec은 **직렬화 형식과 무관하게 정의 가능한 구조여야 한다.** payload가 JSON이든 Avro이든 envelope 4종 헤더 규약은 불변. SR 도입 시 변하는 것은 `x-message-version` **값의 의미**(단순 정수 → SR schema id/버전 연동, 6.8.6 Open)뿐.
- 진화 경로:
  - Phase 1: markdown spec(envelope.md) + payload markdown(kafka-payloads). `x-message-version` = 단순 정수.
  - Phase 2/3: payload markdown → Avro/Protobuf IDL(SR). envelope 헤더 규약은 markdown 유지. `x-message-version` ↔ SR schema 버전 연동 정책 결정 필요(ADR #1 + 6.8.6 Open).
- **envelope spec 작성 원칙(2라운드 반영용)**: "envelope은 transport-layer 헤더 규약이며 payload 직렬화 형식(JSON/Avro/Protobuf)과 독립적으로 정의된다"를 명시. SR 도입은 payload 스키마 관리 경로이지 envelope 구조 변경이 아님.

---

## 7. 결정 사안 → **확정됨** (사람 confirm: 2026-05-27)

> **확정 이력**: 아래 Q1~Q5는 1라운드에서 "사람 답 필요"로 제시했고, **2026-05-27 meta 세션에서 사람이 추천안 전부 채택("추천안으로 진행")으로 확정**했다. 확정 내용은 `docs/envelope.md`에 반영됐다(반영처는 각 항목 말미 표기). 본 §7은 그 확정 기록이다.

### Q1 (B-1). `x-message-version` 정책 — **확정: 후보 A 채택 (+ major-only 일치)**
- 채택: string 표기 `"1"` 유지. 값의 의미 = **payload의 major(호환성) 버전** — 호환 깨짐(major)에만 증가, 호환 변경(minor)은 헤더 값 **불변**. minor 버전의 기록 위치는 envelope 규약 범위 밖(payload 스키마 정책 소관).
- 보충: 1라운드 표현 "정수 단조 증가"는 codex-gate 검증 과정에서 kafka-payloads 변경 정책과 일치하도록 **"major-only"로 구체화**했다(코드 회귀 0, 통합본 8.2 "단순 정수" 일치).
- 반영처: envelope.md §2.2 / §8.

### Q2 (B-2). `x-source` 값 집합 관리 — **확정: 후보 B 채택**
- 채택: 폐쇄 enum 아님. 명명 규칙(kebab-case 모듈명) + 비규범 "알려진 값" 목록. 신규 발행자는 spec bump 없이 목록만 갱신.
- 반영처: envelope.md §2.3.

### Q3 (B-3). `trace_id` 헤더↔payload 관계 — **확정: 후보 B 채택**
- 채택: 헤더 `x-trace-id`(transport 기준 문서) + payload `trace_id`(동일 값 도메인 사본) 둘 다 유지 + "항상 동일해야 한다" 불변식 명시.
- 반영처: envelope.md §5.

### Q4 (B-4). envelope 경계 명시 — **확정: 후보 B 채택**
- 채택: 원칙 산문 서술 + negative list("envelope에 넣지 않는 것") 병기.
- 반영처: envelope.md §3.

### Q5. shared-libs/envelope 모듈 실체 — **확정: 후보 (1) 채택**
- 채택: Phase 1 수동 동기화 + spec-sync 통제. "기준 문서 envelope.md + 언어별 thin 구현 가이드" 모델. 코드 생성/IDL 통합은 Phase 2+ 후보로만 표기.
- 반영처: envelope.md §7.

---

## 8. 미결정으로 남길 사안 (임의 결정 금지 — 보존)

통합본 6.8.6 Open question 및 관련 미결정 ADR. **추측으로 메우지 않고 보존**한다.

| # | 항목 | 출처 | 상태 |
|---|---|---|---|
| O1 | `x-message-id` 중복 검사 도입 **정확한 시점** | 통합본 6.8.6, ADR #15 | Open (ADR #15 baseline = Phase 1 Redis TTL 5분은 결정, "정확한 시점"은 Open) |
| O2 | Schema Registry 도입과 `x-message-version` **정책 연동** | 통합본 6.8.6, ADR #1, 13_open §E | Open (ADR #1 = 1차 미도입은 결정, SR 도입 시점·version 연동은 Open) |
| O3 | `alert-topic` 조합 키 partition 분배 효율성 (Rule×대상 편향 hot partition) | 통합본 6.8.6 | Open. envelope 헤더와 직접 무관(키 정책)하나 6.8.6 소속이므로 보존 |
| O4 | shared-libs/envelope 모듈 실체(구현 위치/언어/분배) | kafka-payloads L3 언급, 통합본 본문 부재 | **미정의** → §7 Q5로 사람 확정 대기. 추측 구현 금지 |

> 위 항목은 envelope.md 기준 문서에 **결정으로 쓰지 않고**, "Phase에 따라 결정 예정 / 13_open 참조"로 표기해야 한다.

---

## 9. 영향 범위

### 9.1 hub 코드 경로 (Read 전용 확인, 수정 금지)
- `hub/src/main/java/com/monitoring/hub/producer/CommandPublisher.java` L37~44, L67~73 — envelope 헤더 키·version·source 인라인 하드코딩. envelope 모듈화(Q5) 시 추출 대상.
- `hub/src/main/java/com/monitoring/hub/ingest/*` (AuditConsumer/JobResultConsumer/HeartbeatConsumer) — Phase 1 x-message-id 검사(ADR #15)·x-trace-id 복원(O1) 추가 지점.

### 9.2 script-agent 코드 경로 (Read 전용 확인, 수정 금지)
- `script-agent/internal/model/envelope.go` — 헤더 키 상수 + 고정값(version `"1"`, source `script-agent`).
- `script-agent/internal/kafka/envelope.go` `BuildHeaders` — 헤더 생성 + 옵셔널 trace 생략 로직. envelope 모듈화(Q5) 시 기준 문서 가이드 대상.
- `script-agent/internal/kafka/envelope_test.go` — 회귀 테스트 기준(Read만).

### 9.3 ADR 항목
- ADR #1 (Schema Registry, 1차 미도입) — §6, O2.
- ADR #15 (x-message-id 중복 검사, Phase 1 Redis TTL) — §4.2, O1.
- ADR #2 (Heartbeat 직렬화 otlp_json→protobuf) — §3 예외군, §4.2.
- ADR #6 (메시지 키) — §3 키 정책 일치(결정됨).

### 9.4 후속 작업
1. 사람이 §7 Q1~Q5 결정 입력.
2. 2라운드: `docs/envelope.md` 기준 문서 작성(본 분석 §1~§3 + 결정 반영, §8 Open은 보존 표기).
3. `spec-sync` drift 검사 → 데모 spec §2.2 ↔ envelope.md ↔ 양쪽 repo 구현 일치 확인.
4. 세션 Stop 시 `codex-gate`가 통합본 6.8/6.9 ↔ envelope.md 일관성 read-only 검증.

> **통합본-update-proposal 미생성 사유**: 후보 모순 2건(① kafka-payloads "shared-libs/envelope" 실체 부재, ② trace_id 이중 등장)은 검토 결과 **본문 내부 모순이 아니라 ①미정의·②의도된 중복**으로 판정. 별도 제안서 대신 §5/§7 Q5(①)·§2 B-3/§7 Q3(②)에 반영.

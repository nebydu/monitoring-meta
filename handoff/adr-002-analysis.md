# ADR-002 영향 분석 — heartbeat 메시지 JSON(otlp_json) → protobuf(otlp_proto) 전환

> **작성**: analyzer sub-agent (2026-05-31)
> **work-id**: `adr-002` / **target**: cross-repo (hub + script-agent + infra)
> **상태**: **사전 분석 산출물 (SUPERSEDED — 참고용).** 최종 결정은 `adr/0002-heartbeat-otlp-proto.md`에서 **Accepted**(A-1 / B-1 / C-1 / 토픽명 분리)로 종결되었다. 본문 §9의 blocker 목록과 말미 결과 스키마의 `status: "blocked"`는 **분석 시점(결정 전)의 기록**이며 현재 미결 사항이 아니다 — 해당 blocker는 모두 ADR에서 해소/위임되었다(키 정책은 통합본 §8.2 결정 채택, SR은 ADR #1 준수, 토픽명·shared-libs 설계·운영 baseline은 별도 작업/Open으로 분리).
> **문서 위상 (혼동 금지)**
> - **Phase 0 회귀 기준(ground truth)**: 데모 spec v0.2.1 (`../hub/docs/monitoring-demo-message-spec-v0.2.1.md` §5.4 / §7.2.1 / ADR 후보 #2) + `docs/phase0-snapshot/PROJECT_OVERVIEW.md`. → "현재 깨지면 안 되는 동작".
> - **Phase 1+ 도달 목표**: 통합본 v0.9 §6.7 / §8.2 / ADR #2(8.3) + `docs/kafka-payloads.md`(heartbeats-topic 절) + `docs/envelope.md` §4.2. → "도달 목표".
> - 두 기준을 같은 ground truth로 다루지 않는다.

---

## 0. 요약 (핵심 통찰 먼저)

**heartbeat의 wire format(직렬화 형식) 소유자는 OTel Collector다.** 양쪽 repo 코드 어느 쪽도 heartbeat Kafka 메시지의 wire bytes를 직접 만들거나 직접 디코드하지 않는다.

- **producer 측 = script-agent(Go)**: Kafka heartbeats 토픽을 **직접 다루지 않는다.** OTel **SDK**로 `agent.heartbeat` Gauge를 OTLP HTTP로 Collector에 push할 뿐이다(`internal/heartbeat/heartbeat.go`). wire format 선택권이 Agent에 없다.
- **transport 변환 = OTel Collector(infra)**: `infra/otel-collector-config.yml`의 kafka exporter `encoding: otlp_json` 한 줄이 현재 wire format을 결정한다. ADR #2의 실제 전환 지점.
- **consumer 측 = hub(Java)**: `HeartbeatConsumer`가 Kafka에서 String으로 받아 **OTLP JSON 트리를 Jackson으로 직접 파싱**한다. protobuf 전환 시 가장 큰 코드 변경이 여기서 일어난다.

따라서 ADR #2는 "양쪽 repo가 공유 proto 스키마를 만들고 protoc로 코드 생성" 류의 일반적 protobuf 전환과 **무게중심이 다르다.** 핵심은 (1) Collector encoding 한 줄 + (2) hub 디코더 교체 + (3) 컷오버 전략이며, script-agent는 거의 무변경일 가능성이 크다. 단, "OTLP 표준 protobuf를 그대로 쓸지(권장 후보) vs 커스텀 proto 스키마를 둘지"가 미결정 분기이며 이에 따라 그림이 크게 달라진다(§3, §9).

---

## 1. 현재 상태 (as-is) — Phase 0 데모 동작

### 1.1 end-to-end 경로

```
script-agent (Go, OTel SDK)
   agent.heartbeat Gauge(value=1, attr agent_id), 10초 주기
   → OTLP HTTP (http://localhost:14318 → 컨테이너 4318)
OTel Collector (otel/opentelemetry-collector-contrib:0.110.0)
   otlp receiver → kafka exporter (encoding: otlp_json, topic: heartbeats)
   → Kafka heartbeats 토픽 (메시지 value = OTLP JSON 문자열)
hub (Java, Spring Kafka)
   HeartbeatConsumer @KafkaListener(topics=heartbeats, String consumer)
   → Jackson ObjectMapper.readTree(payload)
   → resourceMetrics[].scopeMetrics[].metrics[] 순회, name=="agent.heartbeat"
   → dataPoint.attributes에서 agent_id(stringValue), timeUnixNano(string) 추출
   → HeartbeatLatestMap.upsert + AgentRegistry.updateLastSeen
```

### 1.2 양쪽 repo + infra 코드상 구체 지점 (Read 전용)

| 구분 | 위치 | 현재 동작 |
|---|---|---|
| producer(SDK) | `script-agent/internal/heartbeat/heartbeat.go` | `otlpmetrichttp` exporter + PeriodicReader. `Float64ObservableGauge("agent.heartbeat")`, attr `agent_id`. resource `service.name=script-agent`. **Kafka·직렬화 형식 비관여** |
| producer(설정) | `script-agent/internal/config/config.go` | `OTLP_ENDPOINT`(기본 `http://localhost:4318`), `HEARTBEAT_INTERVAL_SECONDS`(기본 10). heartbeat 전용 토픽/encoding 설정 없음 |
| producer(lifecycle) | `script-agent/cmd/agent/main.go` | `heartbeat.Start(...)` best-effort, 종료 시 `hbProvider.Shutdown` |
| transport | `infra/otel-collector-config.yml` | kafka exporter `encoding: otlp_json`, `topic: heartbeats`, brokers `kafka:29092` |
| transport(토픽 생성) | `infra/docker-compose.yml` (kafka-init) | `heartbeats` 토픽 partitions=1, replication=1 사전 생성 |
| consumer | `hub/.../ingest/heartbeat/HeartbeatConsumer.java` | OTLP **JSON 트리** 수동 파싱. gauge/sum 컨테이너 모두 탐색. timeUnixNano를 string→long→Instant |
| consumer(factory) | `hub/.../config/KafkaConfig.java` | `heartbeatConsumerFactory` = **String/String** deserializer (typed record 아님). 토픽 상수 `HEARTBEATS="heartbeats"` |
| consumer(저장) | `hub/.../store/HeartbeatLatestMap.java`, `domain/heartbeat/HeartbeatState.java` | agent_id별 latest map, lastSeen 더 최신일 때만 갱신 |
| consumer(test) | `hub/.../ingest/heartbeat/HeartbeatConsumerTest.java` | OTLP **JSON 문자열** 리터럴 5종 케이스로 검증 — protobuf 전환 시 동반 변경 대상 |

### 1.3 envelope 헤더 적용 여부 (현재)

heartbeats 토픽은 **envelope 4종 헤더 미적용**이다. OTel Collector가 발행하며 OTLP 표준 헤더만 쓴다.
- hub `HeartbeatConsumer` Javadoc: "OTLP 표준 헤더 envelope이므로 spec §2.2의 4종 헤더 검사는 적용하지 않는다."
- 데모 spec v0.2.1 §7.2.2: "`heartbeats` 토픽은 OTel Collector가 발행 — 위 헤더 규약 미적용."
- 정본(`docs/envelope.md` §4.2, 통합본 §6.8.1 예외문): heartbeats-topic은 OTLP 위임군으로 envelope 4종 예외. **이 위상은 protobuf 전환 후에도 불변.**

### 1.4 데모와 통합본의 토픽명 차이 (회귀 기준 주의)

- 데모 Phase 0 토픽명 = **`heartbeats`** (infra kafka-init / hub `KafkaConfig.Topics.HEARTBEATS` / Collector config).
- 통합본/정본 논리명 = **`heartbeats-topic`** (통합본 §4.4.1, envelope.md §4.2, kafka-payloads.md).
- 이 토픽명 정정(`heartbeats` → `heartbeats-topic`)은 데모 정정 11개 항목(통합본 §6.9.2)에 속하는 **별개 사안**이며 ADR #2(직렬화)와 직접 묶이지 않는다. 단 컷오버를 토픽 분리로 한다면 자연스럽게 함께 처리될 수 있다(§6).

---

## 2. Phase 1+ 목표 spec 요구사항

### 2.1 정본이 요구하는 것

| 출처 | 요구 |
|---|---|
| 통합본 §6.7.2 | "직렬화 데모 단계 `otlp_json`, **Phase 1에서 protobuf 전환** (ADR #2)" |
| 통합본 §6.7.4 | "**protobuf 전환 incompatibility.** Phase 1 진입 시 OTel Collector exporter encoding `otlp_json` → `otlp_proto` + Heartbeat Consumer 디코더 동시 변경 필요" |
| 통합본 §8.3 (ADR #2) | 데모 `otlp_json` → 본개발 `Phase 1 protobuf`, 본문 04 §6.7 |
| 통합본 §6.9.2 (데모 정정) | "Heartbeat 직렬화: protobuf(OTLP) ← `otlp_json`, Phase 1 (ADR #2)" |
| kafka-payloads.md (heartbeats-topic) | "페이로드는 OTLP MetricsData protobuf (Phase 1, ADR #2). 데모는 `otlp_json` → Phase 1 protobuf 전환. 파싱은 OTel Java SDK 사용. shared-libs/otel 모듈이 wrapper 제공." |
| envelope.md §4.2 | heartbeats-topic은 OTLP 위임군. "직렬화는 데모 `otlp_json` → Phase 1에서 protobuf 전환(ADR #2)". envelope 4종 헤더는 전환과 무관하게 계속 미적용 |

### 2.2 정본이 이미 시사하는 방향 (단, 강한 결정은 아님)

- kafka-payloads.md는 **"OTLP MetricsData protobuf"** + **"OTel Java SDK 파싱"** + **"shared-libs/otel wrapper"** 를 명시한다. 즉 정본은 **커스텀 proto가 아니라 OTLP 표준 protobuf**를 시사하고, hub의 수동 JSON 파싱 → OTel SDK 디코더 전환을 시사한다.
- 단 이는 별첨 payload spec의 서술이며, ADR #2 자체의 결정란(스키마 공유 방식·컷오버 전략·`shared-libs/otel` 실체)은 **아직 비어 있다**(§9 blocker).

---

## 3. protobuf 전환 후보안 (스키마/공유 방식)

heartbeat는 OTel 파이프라인이라 "스키마"의 의미가 일반 Kafka payload와 다르다. 두 축으로 나눈다: **(A) wire schema를 무엇으로 할지**, **(B) 그 스키마/디코더를 어떻게 공유·관리할지**.

### 3.1 (A) wire schema 후보

**후보 A-1 — OTLP 표준 MetricsData protobuf 그대로 (정본 시사안)**
- Collector `encoding: otlp_proto`로만 바꾸면 wire는 OTLP 표준 `ExportMetricsServiceRequest`/`MetricsData` protobuf.
- 장점: proto 스키마를 **우리가 정의·관리하지 않는다**(OpenTelemetry proto가 곧 스키마). Agent SDK·Collector·hub SDK가 모두 같은 표준을 공유. metrics-topic(Phase 2)과 일관. kafka-payloads.md "OTLP MetricsData protobuf" 서술과 정합.
- 단점: payload가 무겁고 범용(전체 MetricsData 트리). hub가 OTel Java SDK 의존성을 새로 들여야 함. agent_id/timeUnixNano 추출 로직은 트리 구조라 JSON 때와 동일한 깊이.

**후보 A-2 — 커스텀 경량 proto (예: `Heartbeat{agent_id, unix_nano}`)**
- heartbeat에 필요한 2~3개 필드만 담는 자체 proto 메시지를 정의.
- 장점: payload 최소, 디코딩 단순.
- 단점: **OTel 파이프라인을 벗어난다.** Collector 표준 exporter로는 못 만들고, Agent가 Kafka에 직접 producer를 갖거나 Collector custom processor가 필요 → 데모의 "Agent는 Kafka heartbeats 직접 안 다룸" 구조를 깸. 통합본 §6.7(OTel SDK push) / kafka-payloads(OTLP MetricsData) 방향과 충돌 소지. **정본 위배 가능성** → 채택 시 통합본 영향 검토 필요(§9).

**후보 A-3 — OTLP protobuf + Schema Registry 등록**
- A-1에 더해 Apicurio 등 SR에 OTLP proto 스키마 등록.
- 장점: Phase 2/3 SR 도입(ADR #1)과 선제 정합.
- 단점: ADR #1은 **1차(Phase 1) 미도입이 결정**(통합본 §8.2). Phase 1에서 SR을 끌어오는 것은 ADR #1 결정과 충돌 → **임의 결정 금지**(§9). OTLP는 그 자체가 protobuf 표준이라 SR 없이도 호환 관리가 된다는 통합본 §6.1.1167 서술도 있음.

> **분석자 관점(결정 아님)**: 정본 서술·데모 구조 보존·ADR #1 정합을 종합하면 **A-1이 정본과 가장 마찰이 적다.** 단 최종 채택은 사람 결정 사안.

### 3.2 (B) 스키마/디코더 공유·관리 방식 후보

A-1을 전제로 한 공유 방식 후보(커스텀 proto A-2라면 별도):

**후보 B-1 — 공유 안 함 (각 컴포넌트가 표준 OTel 라이브러리 의존)**
- Agent=OTel Go SDK, Collector=contrib 빌드, hub=OTel Java SDK. proto는 각자 라이브러리에 내장된 OpenTelemetry proto를 씀.
- 장점: meta가 proto 파일을 소유·배포할 필요 없음. 가장 가벼움. kafka-payloads "shared-libs/otel = wrapper 제공"과 정합(스키마가 아니라 파싱 wrapper만 공유).
- 단점: 버전 skew 위험(OTel proto 버전 불일치). 통제는 라이브러리 버전 핀으로.

**후보 B-2 — meta 정본에 .proto 사본 보관 + 각 repo가 참조/생성**
- OTLP proto를 meta가 vendoring하고 양쪽이 protoc 코드 생성.
- 장점: 단일 정본. 단점: OTLP 표준 proto를 재배포·재생성하는 중복. A-1에서는 과잉.

**후보 B-3 — 공유 repo / shared-libs 모듈 신설**
- kafka-payloads.md가 언급한 `shared-libs/otel`을 실제 모듈로 만들어 hub 측 OTLP 파싱 wrapper 제공.
- 장점: hub 내 heartbeat/metrics(Phase 2) 파싱 일원화. 단점: 모듈 신설 비용. **`shared-libs/otel`의 실체(언어·배포·소유)는 정본 미정의** → §9 blocker.

> envelope.md §7과 동일 논리: envelope(헤더 markdown spec)과 payload 직렬화(IDL)는 층위가 다르다. heartbeat은 payload 직렬화 층이며 OTLP 표준에 위임하므로, "공유"의 실체는 **proto 파일 공유보다 OTel 라이브러리 버전 정합 + (hub 측) 파싱 wrapper**에 가깝다.

---

## 4. 메시지 계약 옵션 (필드 매핑 / 진화 규칙)

A-1(OTLP 표준) 기준으로 정리. A-2(커스텀)면 별도 계약 설계가 필요하다.

### 4.1 논리 필드 (전환 전후 불변이어야 하는 계약)

| 논리 필드 | 현재(otlp_json 경로) | 전환 후(otlp_proto 경로) | 비고 |
|---|---|---|---|
| metric name | `metrics[].name == "agent.heartbeat"` | 동일 (OTLP Metric.name) | 불변 |
| metric type | Gauge (value=1) | 동일 (Gauge dataPoints) | hub는 이미 gauge/sum 양쪽 탐색 |
| `agent_id` | dataPoint.attributes[key=agent_id].value.stringValue | OTLP KeyValue(AnyValue.string_value) | 불변 (의미) |
| timestamp | dataPoint.timeUnixNano (JSON에선 string) | dataPoint.time_unix_nano (proto fixed64) | **JSON은 string 인코딩, proto는 정수** — 디코더 변경의 핵심 |
| resource attr | service.name=script-agent | 동일 | 불변 |

### 4.2 필드 번호 / optional 정책

- **A-1 채택 시 필드 번호는 우리가 정하지 않는다** — OpenTelemetry proto 정의를 따름. 필드 번호/optional 정책 결정 자체가 불필요(OTLP가 소유).
- **A-2(커스텀) 채택 시에만** 필드 번호(`agent_id=1`, `unix_nano=2` 등)·optional·proto3 기본값 정책을 우리가 결정해야 함 → 이 경우 §9 blocker로 추가 결정 필요.

### 4.3 버전 진화 규칙

- envelope `x-message-version`은 **heartbeats-topic에 적용되지 않는다**(예외군). 따라서 heartbeat 버전은 envelope 헤더로 운반되지 않는다.
- OTLP 자체의 버전 진화는 OpenTelemetry proto 호환 정책에 위임(통합본 §6.1.1167 "OTLP 자체가 Protobuf 표준이라 SR 없이도 호환성 관리 가능").
- kafka-payloads.md "변경 정책"의 major/minor bump는 **envelope 적용 6토픽 대상**이며 heartbeats(예외군)에는 직접 적용되지 않는다.

---

## 5. envelope 헤더와의 관계

- heartbeats-topic은 **OTLP 위임군**이라 envelope 4종 헤더와 **직교**한다. payload를 protobuf로 바꿔도 envelope 규약은 변하지 않는다(애초에 미적용이므로).
- envelope.md §1: "envelope은 payload 직렬화 형식(JSON/Avro/Protobuf)과 독립적으로 정의된다." → ADR #2는 envelope.md를 건드리지 않는다.
- 즉 **ADR #2와 envelope 작업은 분리 가능**하다. envelope drift 검사(spec-sync)의 대조 대상도 아니다.
- 단 1차 검증 시 회귀 가드로 확인할 점: 전환 후에도 heartbeats 토픽에 envelope 4종 헤더가 **새로 끼어들지 않아야** 한다(Collector가 OTLP 표준 헤더만 발행하는 현 동작 유지).

---

## 6. producer / consumer 책임 분담 + 컷오버 (Phase 0 하위호환)

### 6.1 책임 분담 (A-1 전제)

| 역할 | 컴포넌트 | ADR #2에서의 책임 |
|---|---|---|
| heartbeat 생성 | script-agent (OTel Go SDK) | **변경 거의 없음.** wire format을 모름. SDK/resource는 그대로 |
| wire format 결정 | **infra / OTel Collector** | `encoding: otlp_json → otlp_proto` (전환의 1차 주체) |
| heartbeat 디코드 | hub (OTel Java SDK 또는 protobuf 디코더) | **가장 큰 코드 변경.** JSON 트리 파싱 → proto 디코딩, String consumer → byte[] consumer |
| 스키마 소유 | OpenTelemetry(표준) | 우리가 소유하지 않음 |

### 6.2 컷오버 후보 (데모 v0.2.1 동작을 깨지 않는 전환)

heartbeats-topic은 데모에서 **(가) 검증 완료**(통합본 §6.9.1)이므로 회귀 0이 중요하다. 단 heartbeat는 휘발성(latest map, 재갱신됨)이라 다른 토픽보다 컷오버 리스크가 낮다.

**후보 C-1 — 빅뱅 컷오버 (encoding + 디코더 동시 교체)**
- Collector encoding을 otlp_proto로 바꾸고 hub 디코더도 동시 배포.
- 장점: 단순. heartbeat는 in-memory latest map이라 짧은 불일치 구간에도 다음 heartbeat(10초)로 자동 복구. 통합본 §6.7.4가 "동시 변경 필요"로 이미 이 모델을 시사.
- 단점: 배포 타이밍이 어긋나면(Collector 먼저 / hub 나중) 그 구간 heartbeat가 디코드 실패 → 일시적 OFFLINE 오판 위험. 데모/단일 Zone이면 수용 가능, 다수 Zone이면 위험.

**후보 C-2 — hub 듀얼 디코드 (proto 우선, JSON fallback) 후 encoding 전환**
- hub가 byte[] 받아 proto 디코드 시도 → 실패 시 JSON 파싱 fallback. 이후 Collector encoding 전환, 안정화 뒤 fallback 제거.
- 장점: 배포 순서 무관, 회귀 0에 가장 안전. 단점: hub에 한시적 이중 경로 코드.

**후보 C-3 — 토픽 분리 (`heartbeats` JSON 유지 + `heartbeats-topic` proto 신설)**
- 신토픽으로 proto 발행, consumer 이행 후 구토픽 폐기. 토픽명 정정(§1.4)과 동시 처리.
- 장점: 구·신 완전 격리. 단점: Collector 파이프라인/consumer 이중 운영 기간. heartbeat 휘발성 특성상 과한 안전장치일 수 있음.

> **분석자 관점(결정 아님)**: heartbeat 휘발성 + 데모 단일 Zone이면 C-1로 충분하나, "회귀 0" 엄격 적용 + 멀티 Zone 대비라면 C-2가 안전. C-3는 토픽명 정정을 함께 끌고 갈 때만 비용 정당화. **컷오버 전략은 사람 결정 사안**(§9).

---

## 7. 영향 범위 (파일/모듈 단위, 빌드·의존성)

> 아래는 **분석 결과**이며 meta는 코드를 수정하지 않는다. 실제 변경은 각 repo 세션에서 수행.

### 7.1 infra (transport — 변경 1차 주체, A-1 기준)
- `infra/otel-collector-config.yml`: `encoding: otlp_json` → `otlp_proto` (1줄).
- `infra/docker-compose.yml`: 토픽 분리(C-3) 채택 시 kafka-init에 신토픽 추가. C-1/C-2면 무변경.
- 빌드 영향: 없음(contrib 이미지 동일, kafka exporter는 otlp_proto 지원).

### 7.2 hub (consumer — 가장 큰 코드 변경, A-1 기준)
- `ingest/heartbeat/HeartbeatConsumer.java`: OTLP **JSON 트리 파싱 → proto 디코딩**. 추출 대상(agent_id, time_unix_nano)은 동일하나 입력이 byte[]/proto 객체로 바뀜.
- `config/KafkaConfig.java`: `heartbeatConsumerFactory`/`heartbeatListenerFactory`를 **String → byte[]**(ByteArrayDeserializer) 기반으로 변경. `Topics.HEARTBEATS` 토픽명 정정 시 함께.
- `ingest/heartbeat/HeartbeatConsumerTest.java`: JSON 문자열 리터럴 5종 → proto 바이트 fixture로 재작성(동반 필수).
- (신설 가능) `shared-libs/otel` 성격의 OTel Java SDK 파싱 wrapper — kafka-payloads.md 시사. 실체 미정(§9).
- 빌드/의존성: **OpenTelemetry Java(proto/SDK) 의존성 신규 추가**(pom.xml). 가장 큰 의존성 영향.
- 무변경: `domain/heartbeat/HeartbeatState.java`, `store/HeartbeatLatestMap.java`, `store/AgentRegistry`(논리 계약 불변).

### 7.3 script-agent (producer — A-1이면 거의 무변경)
- `internal/heartbeat/heartbeat.go`: **변경 불필요 가능성 큼**(SDK가 OTLP HTTP로 push, wire format은 Collector 소관). OTLP Go SDK 버전 정합만 확인.
- `internal/config/config.go`, `cmd/agent/main.go`: 무변경.
- 빌드/의존성: 없음(또는 OTel Go SDK 버전 핀).
- **단, A-2(커스텀 proto) 채택 시**: Agent가 Kafka 직접 producer + proto 직렬화를 갖게 되어 영향이 대폭 커짐 → A-2는 script-agent 비용을 크게 올린다.

### 7.4 meta (문서)
- 토픽명 정정(§1.4)·`shared-libs/otel` 실체 확정 시 kafka-payloads.md / envelope.md 정합 갱신은 **별도 제안서(handoff/통합본-update-proposal)** 경로. 본 분석에서는 수정하지 않음.

---

## 8. ADR 초안 스켈레톤 (결정란 공란 — 사람이 채움)

```
# ADR-002: heartbeat 메시지 직렬화 otlp_json → protobuf 전환

## Status
Proposed  (Phase 1 대상, 통합본 v0.9 ADR #2)

## Context
- 데모 Phase 0: OTel Collector kafka exporter encoding=otlp_json (infra), hub가 OTLP JSON 트리 수동 파싱.
- heartbeat wire format 소유자 = OTel Collector. Agent(Go)는 OTLP SDK push만, hub(Java)는 디코드만.
- 통합본 §6.7.4 / ADR #2 / kafka-payloads.md가 Phase 1 protobuf 전환을 목표로 명시.
- heartbeats-topic은 envelope 4종 예외군 → envelope 규약과 직교.

## Decision (← 사람이 채움)
- [ ] wire schema: A-1 OTLP 표준 protobuf  /  A-2 커스텀 proto  /  A-3 OTLP+SR   (§3.1)
- [ ] 공유·관리 방식: B-1 라이브러리 의존  /  B-2 meta vendoring  /  B-3 shared-libs/otel 모듈   (§3.2)
- [ ] 컷오버 전략: C-1 빅뱅  /  C-2 hub 듀얼 디코드  /  C-3 토픽 분리   (§6.2)
- [ ] 토픽명 정정(heartbeats → heartbeats-topic) 동시 처리 여부   (§1.4)
- [ ] shared-libs/otel 실체(언어/배포/소유)   (§9)
- [ ] Schema Registry 연계 — Phase 1 미도입(ADR #1) 준수 여부 확인   (§9)

## Consequences (← 결정 후 채움)
- infra: §7.1 / hub: §7.2 / script-agent: §7.3

## Compliance / Regression
- 데모 v0.2.1 §5.4 heartbeat 동작 회귀 0. heartbeats-topic envelope 미적용 유지.
- 논리 계약(name=agent.heartbeat, agent_id, time_unix_nano) 불변 (§4.1).
```

---

## 9. 결정 필요 사안 (사람 입력 대기 — blockers)

추측으로 메우지 않는다. 아래는 모두 사람 결정 또는 미결정 ADR/Open question과 충돌하는 항목이다.

1. **[wire schema 결정]** A-1(OTLP 표준 protobuf) vs A-2(커스텀 proto) vs A-3(+SR). 정본은 A-1을 시사하나 ADR #2 결정란은 비어 있음. **A-2 채택 시 데모의 "Agent는 Kafka heartbeats 직접 안 다룸" 구조 및 통합본 §6.7/kafka-payloads 방향과 충돌 가능** → 통합본 영향 검토 필요.
2. **[공유·관리 방식]** B-1/B-2/B-3. 특히 kafka-payloads.md가 언급한 **`shared-libs/otel`의 실체(언어·배포·소유 주체)가 정본에 미정의** — 추측 금지.
3. **[컷오버 전략]** C-1/C-2/C-3 미결정. "회귀 0" 엄격도 + Zone 수에 따라 달라짐. ADR #2 결정란 공란.
4. **[Schema Registry 연계 — Open과 충돌]** ADR #1은 **Phase 1 SR 미도입이 결정**(통합본 §8.2). 그러나 SR 도입 시점·`x-message-version`/스키마 버전 연동은 **envelope.md §9 O2 / 13_open §E(추정) = Open**. heartbeat proto를 SR에 등록(A-3)하려면 이 Open을 건드리게 됨 → **임의 결정 금지, 사람 호출**.
5. **[heartbeats-topic 메시지 키 — Open]** 통합본 §6.7.5 / §8.2: "데모는 OTel 기본(분배 불보장), Agent 단위 ordering 필요 여부 (8장)" = **미결정 Open**. protobuf 전환과 직접 묶이진 않으나 Collector exporter 설정을 손대는 김에 같이 검토될 수 있어 보존. 키 정책은 임의 결정 금지.
6. **[토픽명 정정 묶음 여부]** `heartbeats`(데모) → `heartbeats-topic`(정본) 정정은 데모 정정 11개 항목(통합본 §6.9.2)의 별개 사안. ADR #2와 함께 처리할지 분리할지 결정 필요.
7. **[metrics-topic 범위 확인]** Phase 1 protobuf 전환 대상은 **heartbeats뿐**이며 metrics-topic은 Phase 2 신규·Phase 1 미사용(envelope.md §4.2, 통합본 §6.9.5). ADR #2 범위에 metrics를 끌어들이지 않도록 결정 시 명시 필요(혼동 방지).

---

## 결과 스키마

```json
{
  "status": "blocked",
  "outputs": ["handoff/adr-002-analysis.md"],
  "findings": [
    "heartbeat wire format 소유자는 OTel Collector다. script-agent(Go)는 OTLP SDK push만, hub(Java)는 디코드만 하며 양쪽 모두 wire bytes를 직접 만들지 않는다.",
    "ADR #2 전환의 1차 주체는 infra(otel-collector-config.yml encoding 1줄)와 hub(HeartbeatConsumer JSON 트리 파싱 → proto 디코딩 + KafkaConfig String→byte[] + 테스트 재작성 + OTel Java 의존성 추가)이며, A-1(OTLP 표준) 채택 시 script-agent는 거의 무변경이다.",
    "heartbeats-topic은 envelope 4종 예외군이라 protobuf 전환은 envelope.md와 직교한다(envelope 작업과 분리 가능).",
    "정본(kafka-payloads.md)은 'OTLP MetricsData protobuf + OTel Java SDK 파싱 + shared-libs/otel wrapper'로 A-1 방향을 시사하나, ADR #2 결정란(스키마·공유·컷오버)은 비어 있다.",
    "데모 토픽명 'heartbeats'와 정본 논리명 'heartbeats-topic' 불일치는 데모 정정 별개 항목이며 ADR #2와 직접 묶이지 않는다.",
    "Phase 1 전환 대상은 heartbeats뿐, metrics-topic은 Phase 2 신규/Phase 1 미사용이다."
  ],
  "blockers": [
    "wire schema 결정 A-1/A-2/A-3 미정 (A-2 커스텀은 데모 구조·통합본 §6.7 방향과 충돌 가능)",
    "shared-libs/otel 실체(언어/배포/소유)가 정본 미정의",
    "컷오버 전략 C-1/C-2/C-3 미정",
    "Schema Registry 연계: ADR #1 Phase 1 미도입은 결정이나 SR 도입·version 연동은 envelope.md §9 O2 / 13_open §E Open — A-3 채택 시 충돌",
    "heartbeats-topic 메시지 키 ordering은 통합본 §6.7.5/§8.2 Open",
    "토픽명 정정(heartbeats→heartbeats-topic)을 ADR #2와 묶을지 여부 미결정"
  ],
  "next_action": "사람이 §9의 6개 결정 사안(특히 wire schema A-1/A-2/A-3, 컷오버 C-1/C-2/C-3)을 입력하면 analyzer가 ADR #2 결정란을 채우고 handoff/adr-002-hub.md, handoff/adr-002-script-agent.md(필요 시 adr-002-infra) 분배 파일을 작성한다."
}
```

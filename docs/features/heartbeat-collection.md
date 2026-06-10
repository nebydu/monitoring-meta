> **이 문서는 기술(descriptive) 문서다 — 코드의 현재 상태를 서술한다. 규범의 답은 통합본 v0.9 / `adr/`에 있다.**

# 기능: heartbeat 수집·전송 흐름

## 0. 메타 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 기능 ID | `heartbeat-collection` | 파일명과 일치 |
| 시나리오 한 줄 | `script-agent가 살아있음을 hub가 주기적으로 인지` | 인덱스 표와 동일 |
| 관여 repo | `script-agent`, `infra`, `hub` | |
| 기준 meta commit | `77fc0a2195bd3bf44edea5513cd11d3261a0e0cc` | 이 문서가 참조한 통합본/`adr/` 등 **spec의 시점**을 고정한다. **형제 repo 코드 시점이 아니다** — 코드가 실제 동작한 시점 증거는 §9의 e2e 결과. 본문 코드 앵커로 쓰지 않는다 |
| 최종 갱신일 | `2026-06-10` | |
| 검증 상태 | `검증됨` | §9 최종 검증 기준과 연동 |

## 1. 기능 개요

script-agent는 기동 중에 `agent.heartbeat` OTLP Gauge 메트릭을 주기적으로 OTel Collector로 push한다. Collector는 이를 `heartbeats-topic`에 OTLP protobuf(otlp_proto)로 재발행하고, hub의 `HeartbeatConsumer`가 소비해 `HeartbeatOtlpDecoder`로 디코드한 뒤 `HeartbeatLatestMap`과 `AgentRegistry`에 agent별 최신 `last_seen`을 갱신한다.

heartbeat 수신은 **`last_seen` 갱신까지만** 수행한다(코드 확인). agent의 `ONLINE`/`OFFLINE` 상태(state)는 heartbeat이 바꾸지 않으며 audit 경로가 설정한다 — `AGENT_STARTED` 수신 시 `ONLINE`, `AGENT_STOPPED` 수신 시 `OFFLINE`. hub UI(/)는 각 agent의 `last_seen`·state·`heartbeatTimeoutSeconds`를 함께 렌더링한다(생존 표시 판정의 운영 임계·자동 전이는 §8 참조).

## 2. 사용자 시나리오

- script-agent 프로세스가 기동되면 `heartbeat.Start()`가 OTLP HTTP push 루프를 시작한다.
- 설정된 주기마다(기본값은 코드에 주입된 `interval` 파라미터 — 운영 baseline은 ADR-0002 Open 사항) `agent.heartbeat` Gauge(value=1, attribute `agent_id`)가 OTel Collector로 전달된다.
- Collector는 `heartbeats-topic`에 otlp_proto 인코딩으로 재발행한다.
- hub가 메시지를 소비·디코드해 해당 agent의 `last_seen`을 갱신한다(state는 불변).
- hub UI(/)는 갱신된 `last_seen`과 `heartbeatTimeoutSeconds`로 해당 agent의 생존 여부를 표시한다(`ONLINE`/`OFFLINE` state 자체는 audit 경로가 설정).

## 3. 관련 spec 참조 (규범 문서 포인터)

이 레이어는 결정하지 않고 포인터만 단다.

- 통합본 v0.9: `§6.7` heartbeat 직렬화(otlp_proto 전환), `§8.2` 메시지 키 = OTel Collector 기본(ordering 불필요)
- ADR: `adr/0002-heartbeat-otlp-proto.md` — A-1(wire=OTLP 표준 protobuf)/B-1(표준 라이브러리 의존)/C-1(빅뱅 컷오버) 결정; heartbeat 주기·timeout 운영 baseline은 Open(본 ADR 미확정)
- ADR: `adr/0005-topic-naming.md` — `heartbeats-topic` 최종 논리명 확정(복수형 domain은 명시 예외 — baseline 호환)
- 페이로드: `docs/kafka-payloads.md` `heartbeats-topic` 절 — OTLP MetricsData protobuf, metric name `agent.heartbeat`, attribute `agent_id`
- 봉투: `docs/envelope.md` §4.2 — heartbeats-topic은 OTLP 위임군 예외. envelope 4종 헤더(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`) 미적용

## 4. 관여 repo·컴포넌트

- `script-agent`: `internal/heartbeat` 패키지 — OTLP HTTP exporter + PeriodicReader 기반 MeterProvider 구성, `agent.heartbeat` observable gauge 등록
- `infra`: `otel-collector-config.yml` — otlp receiver(HTTP:4318), kafka exporter(`encoding: otlp_proto`, `topic: heartbeats-topic`); `docker-compose.yml` — OTel Collector 컨테이너(`otel/opentelemetry-collector-contrib:0.110.0`), kafka-init 토픽 사전 생성
- `hub`: `config.KafkaConfig` — `Topics.HEARTBEATS` 상수 + `heartbeatConsumerFactory`(ByteArrayDeserializer) + `heartbeatListenerFactory`; `ingest/heartbeat.HeartbeatConsumer`; `ingest/heartbeat.HeartbeatOtlpDecoder`; `store.HeartbeatLatestMap`; `domain/heartbeat.HeartbeatState`; `store.AgentRegistry`

## 5. 흐름 따라가기 (hop-by-hop)

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1 | `script-agent:internal/heartbeat` | `heartbeat.Start` → `startWithExporter` | - | 기동 로그 `"agent started"` (audit 경로 별개) |
| 2 | `script-agent:internal/heartbeat` | `meter.Float64ObservableGauge("agent.heartbeat")` | - | PeriodicReader가 interval마다 Collect 호출; OTLP HTTP → Collector:4318 |
| 3 | `infra:otel-collector-config.yml` | `otlp` receiver (HTTP:4318) → `kafka` exporter | `heartbeats-topic` | Collector 내부 파이프라인; `encoding: otlp_proto` |
| 4 | `hub:config.KafkaConfig` | `heartbeatConsumerFactory` (ByteArrayDeserializer) | `heartbeats-topic` | group-id `hub-heartbeat-consumer`; `KafkaConfig.Topics.HEARTBEATS = "heartbeats-topic"` |
| 5 | `hub:ingest/heartbeat.HeartbeatConsumer` | `HeartbeatConsumer.consume(ConsumerRecord<String, byte[]>)` | - | Spring KafkaListener 수신 로그 `Received: 1 records` (DEBUG) |
| 6 | `hub:ingest/heartbeat.HeartbeatOtlpDecoder` | `HeartbeatOtlpDecoder.decode(byte[])` → `ExportMetricsServiceRequest.parseFrom` | - | `METRIC_NAME="agent.heartbeat"`, `ATTR_AGENT_ID="agent_id"`, `getTimeUnixNano()`(proto fixed64) |
| 7 | `hub:store.HeartbeatLatestMap` | `HeartbeatLatestMap.upsert(HeartbeatState)` | - | `ConcurrentHashMap.merge`; agent별 최신 last_seen 유지(더 오래된 timestamp는 무시) |
| 8 | `hub:store.AgentRegistry` | `AgentRegistry.updateLastSeen(agentId)` | - | `last_seen`만 갱신(`computeIfPresent` — 미등록 agent_id는 no-op). **state 불변** |

**생존 표시(ONLINE/OFFLINE) 경계**: heartbeat 경로는 `last_seen`만 갱신한다. agent state(`AgentState.ONLINE`/`OFFLINE`)는 audit 경로(`AgentRegistry.register`=ONLINE / `AuditConsumer`→`markOffline`=OFFLINE)가 설정하며 heartbeat과 무관하다. hub UI(/)의 생존 표시는 `last_seen`·state·`heartbeatTimeoutSeconds`를 뷰(`index`)가 렌더링한 결과다(e2e §6에서 ONLINE 표시 관찰). timeout 기반 자동 OFFLINE 전이(서버측 sweeper)는 데모 단계 미구현(§8).

**envelope 예외 확인**: `HeartbeatConsumer.consume()`은 envelope 4종 헤더 검사를 수행하지 않는다(코드로 직접 확인). `docs/envelope.md` §4.2 OTLP 위임군 예외 위상을 준수.

**메시지 키**: OTel Collector 기본값을 그대로 사용한다(통합본 §8.2 결정 — ordering 불필요). key deserializer는 `StringDeserializer`로 유지하며, ADR-0002 C-1 컷오버 변경 범위는 value deserializer(`String → ByteArrayDeserializer`)에 국한된다.

## 6. 흐름 다이어그램

```
script-agent (internal/heartbeat)
    │  OTLP HTTP (metric: agent.heartbeat, Gauge=1, attr: agent_id)
    ▼
infra: OTel Collector (otlp receiver :4318)
    │  kafka exporter, encoding=otlp_proto
    ▼
Kafka: heartbeats-topic  (byte[], 키=OTel 기본)
    │  ByteArrayDeserializer, group=hub-heartbeat-consumer
    ▼
hub: HeartbeatConsumer.consume()
    │  HeartbeatOtlpDecoder.decode() → ExportMetricsServiceRequest.parseFrom()
    │    └─ resource_metrics → scope_metrics → metrics[name=agent.heartbeat]
    │         └─ Gauge dataPoints → agent_id(attr) + time_unix_nano(fixed64)
    ▼
hub: HeartbeatLatestMap.upsert(HeartbeatState)
    + AgentRegistry.updateLastSeen(agentId)   // last_seen만 갱신, state 불변
    ▼
hub UI(/): last_seen + heartbeatTimeoutSeconds 로 생존 표시
           (ONLINE/OFFLINE state는 audit 경로가 설정 — heartbeat 무관)
```

## 7. 검증 방법

> `데모 spec v0.2.1`은 **Phase 0 회귀 검증 기준**이며 도달 목표 규범이 아니다(규범 = 통합본 v0.9 / ADR — §3). 아래 e2e 항목명의 `§5.4` 인용은 회귀 0 근거로서다.

- **e2e**: `e2e/results/20260610-152424.md` — PASS 58/0/0
  - §1 ADR-0002 C-1 빅뱅 컷오버 정합 (infra `otlp_proto` ↔ hub `ByteArrayDeserializer` + proto 디코더)
  - §2 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 (metric name `agent.heartbeat` / `agent_id` / `service.name=script-agent` / value=1 / `time_unix_nano`)
  - §3 envelope 예외 위상 (`heartbeats-topic`: OTLP 위임군 → envelope 헤더 검사 없음)
  - §6 동적 E2E 시나리오: heartbeat 수신 + 디코드 성공 실증; `§6-T4-D` heartbeats-topic 오프셋 > 0 실증
  - §8 T4-1 토픽 재명명 정합 (`hub/KafkaConfig.Topics.HEARTBEATS = "heartbeats-topic"`, infra otel exporter 신명)
- **단위 테스트**: `hub mvn test` PASS (Tests run: 100, Failures: 0, Errors: 0, Skipped: 4); `script-agent go test ./...` PASS

## 8. 미구현·잔여 사항

- **heartbeat 주기·timeout 운영 baseline**: ADR-0002 Open — 운영값 미확정. 데모 baseline(10초 주기 / 30초 timeout)은 참조값이며 본 ADR 미확정(통합본 §6.7 도달 목표).
- **생존 판정(ONLINE/OFFLINE 자동 전이) 정책**: `last_seen`만으로 timeout 기반 자동 OFFLINE 전이를 수행하는 서버측 sweeper는 **데모 단계 미구현**(`AppProperties` 주석 — "데모 단계에서는 별도 sweeper를" 두지 않음). 현재 `OFFLINE`은 `AGENT_STOPPED` 명시 수신으로만 설정된다. `heartbeatTimeoutSeconds` 운영값·자동 전이 도입은 ADR-0002 Open(주기·timeout baseline)에 연동.
- **`shared-libs/otel` wrapper 모듈**: ADR-0002 **B-1(표준 라이브러리 의존)은 결정됨**. 단 `HeartbeatOtlpDecoder`는 현재 hub 내부 클래스이며 별도 Maven 모듈(`shared-libs/otel`)로 **추출되지 않은 상태**다 — 그 wrapper의 구체 설계·배포·소유는 ADR-0002가 확정하지 않은 별도 범위(Open).
- **script-agent 주석·문서의 구 토픽명 `heartbeats` 잔존**: `heartbeat.go`·`README.md`·`types.go`가 heartbeat 토픽을 구명 `heartbeats`로 지칭(최종 논리명 `heartbeats-topic` — ADR-0005). 동작 무관(코드 토픽 상수는 이미 신명, e2e §8 PASS). 정정 작업 = `handoff/heartbeat-topic-comment-drift-script-agent.md`. heartbeat.go의 `otlp_json` 문구는 Phase 0→Phase 1 전환을 정확히 기술한 것이라 보존 대상.

## 9. 최종 검증 기준 (필수)

- **기준 e2e 결과**: `e2e/results/20260610-152424.md` (PASS 58/0/0) — 형제 repo 코드가 실제 동작한 시점 증거. 동적 모드(`--dynamic --reuse-infra`) 활성, Docker 데몬 v29.4.3, Kafka healthy 재활용.
- **spec 참조 시점**: §0 기준 meta commit `77fc0a2195bd3bf44edea5513cd11d3261a0e0cc` (통합본 v0.9 / `adr/0002-heartbeat-otlp-proto.md` / `adr/0005-topic-naming.md` / `docs/kafka-payloads.md` / `docs/envelope.md`)
- **Phase 0 회귀 기준(데모 spec v0.2.1 §5.4 — 규범 아닌 회귀 근거)**: 논리 계약 불변 — metric name `agent.heartbeat` / attribute `agent_id` / resource `service.name=script-agent` / Gauge value=1 / `time_unix_nano`(proto fixed64). e2e §2 전 항목 PASS.

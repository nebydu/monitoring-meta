# 작업 spec — adr-002 (hub)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID | `adr-002` | heartbeat otlp_json → otlp_proto 전환 |
| 대상 repo | `hub` | **가장 큰 코드 변경**(디코더 교체) |
| 기준 monitoring-meta commit | `f59c9caa3a6ea1cfa4d860f82944e8abdf940d6d` | full hash |
| 작성일 | 2026-05-31 | |
| 근거 ADR | `adr/0002-heartbeat-otlp-proto.md` | 결정: A-1 / B-1 / C-1 / 토픽명 분리 |

## 2. 문서 성격 상기

ground truth 우선순위: 코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(도달 목표).
- heartbeats-topic은 envelope 4종 예외군 → 본 작업은 envelope 헤더 검사를 추가하지 않는다.

## 3. ground truth 참조 경로

- `../monitoring-meta/adr/0002-heartbeat-otlp-proto.md` — 본 작업 결정
- `../monitoring-meta/docs/kafka-payloads.md` — heartbeats-topic payload 기준 문서(OTLP MetricsData protobuf, OTel Java SDK 파싱)
- `../monitoring-meta/handoff/adr-002/adr-002-analysis.md` — 영향 분석서(§4.1 논리 계약, §7.2 hub)
- `docs/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준(각 repo 사본)

## 4. 배경 / 목표

현재 `HeartbeatConsumer`는 Kafka에서 String을 받아 OTLP **JSON 트리**를 Jackson으로 수동 파싱한다. Phase 1 목표는 OTLP **protobuf** 디코딩이다. 끝났을 때 도달 상태: hub가 OTLP protobuf(byte[])를 OTel Java SDK로 디코드해 동일 논리 필드를 추출한다.

## 5. 작업 범위

### 해야 할 것 (영향 분석서 §7.2)
- `ingest/heartbeat/HeartbeatConsumer.java`: OTLP JSON 트리 파싱 → **proto 디코딩**. payload는 기준 문서(kafka-payloads.md `heartbeats-topic`)이 규정한 **OTLP MetricsData protobuf**를 **OTel Java SDK로 디코드**한다(기준 문서대로 — 자체 proto·protoc 생성 없음). 추출 대상(agent_id, time_unix_nano)은 동일. ※ Collector `otlp_proto` 출력의 실제 top-level 컨테이너는 OTel SDK 디코더가 처리하므로 별도 wire wrapper 타입을 ADR/spec에서 단정하지 않는다(SDK API를 따른다).
- `config/KafkaConfig.java`: **value(payload) deserializer만** String → byte[](ByteArrayDeserializer)로 변경(`heartbeatConsumerFactory`/`heartbeatListenerFactory`). **key serializer·파티셔닝·메시지 키 정책은 변경하지 말 것** — 키 정책은 기준 문서 통합본 §8.2 ADR 결정표가 "`heartbeats-topic` 키 = OTel Collector 기본(ordering 불필요)"로 **이미 결정**했으므로 그대로 따른다(ordering은 Open 아님).
- `ingest/heartbeat/HeartbeatConsumerTest.java`: JSON 문자열 리터럴 5종 케이스 → **proto 바이트 fixture**로 재작성.
- `pom.xml`: **OpenTelemetry Java(proto/SDK) 의존성 신규 추가**. 버전은 Collector/Agent와 일치되는 버전으로 핀(B-1).

### 하지 말 것 (out of scope)
- **이 작업에서 물리 토픽명(`Topics.HEARTBEATS = "heartbeats"`)을 변경하지 말 것.** 토픽명 정정(물리 `heartbeats` ↔ 논리 `heartbeats-topic`)은 별개 작업이며 ADR #2는 토픽명을 결정하지 않는다.
- envelope 4종 헤더 검사 추가 금지(heartbeats는 예외군).
- 도메인 모델 변경 금지: `domain/heartbeat/HeartbeatState.java`, `store/HeartbeatLatestMap.java`, `store/AgentRegistry`는 논리 계약 불변 → 손대지 않음.
- **proto 스키마를 공유 산출물로 만들지 말 것**(B-1: 표준 OTel 라이브러리 내장 proto 사용, 자체 .proto·protoc 생성 금지). 단 kafka-payloads.md가 말하는 `shared-libs/otel`(파싱 wrapper) 모듈의 실체화는 ADR #2에서 확정하지 않았다 — **이 작업에서는 디코더를 hub 내부에 두되, 추후 wrapper 모듈로 추출될 수 있도록 결합도를 낮춰 둘 것**(spec의 `shared-libs/otel` 정의를 부정·축소하지 않는다).
- Schema Registry 연동 금지(A-1).

## 6. Phase 0 회귀 방지 기준

- 데모 spec v0.2.1 §5.4 heartbeat 동작 회귀 0. 논리 계약(name=`agent.heartbeat`, agent_id, time_unix_nano, value=1, resource service.name=script-agent) 불변.
- 주의: `time_unix_nano`는 JSON에서는 string이었으나 proto에서는 fixed64(정수)다 — 디코더 변경의 핵심 지점.
- **컷오버 C-1(빅뱅): infra encoding 전환(adr-002-infra)과 반드시 동시 배포.** hub만 먼저 배포하면 아직 JSON으로 오는 메시지를 proto로 디코드 시도 → 실패. 배포 순서를 infra 세션과 맞출 것.

## 7. 미결정 사안

없음. (A-1/B-1/C-1/토픽명 분리 모두 2026-05-31 확정.)

## 8. 완료 기준 / 검증

- [ ] hub가 OTLP protobuf heartbeat을 디코드해 `HeartbeatLatestMap`/`AgentRegistry` 정상 갱신.
- [ ] `HeartbeatConsumerTest` proto fixture 기준 통과.
- [ ] 테스트: `mvn test`.
- [ ] Phase 0 회귀 없음(§6).
- [ ] polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

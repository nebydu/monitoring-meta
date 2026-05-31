# ADR-0002: heartbeat 메시지 직렬화 otlp_json → protobuf(otlp_proto) 전환

- 상태(Status): **Accepted** (2026-05-31 결정)
- 대상 Phase: Phase 1
- 근거 정본: 통합본 v0.9 §6.7 / §8.2(ADR 결정표), `docs/kafka-payloads.md` §`heartbeats-topic`, `docs/envelope.md` §4.2
- 기준 monitoring-meta commit: `f59c9caa3a6ea1cfa4d860f82944e8abdf940d6d`
- 영향 분석서: `handoff/adr-002-analysis.md`

---

## 용어 (토픽명 — 혼동 금지)

- **논리 토픽명(정본, 8토픽 spec 기준)** = `heartbeats-topic`.
- **데모 물리 토픽명(현 코드)** = `heartbeats`.
- 본 ADR의 대상은 `heartbeats-topic`의 **직렬화 형식**이다. 토픽명 자체(물리↔논리 정정)는 본 ADR 밖이다(Decision 4).

## Context

데모(Phase 0)에서 heartbeat는 OTel Collector kafka exporter `encoding: otlp_json`으로 발행되고, hub가 OTLP JSON 트리를 Jackson으로 수동 파싱한다. 통합본 §6.7.4 / kafka-payloads.md가 Phase 1 protobuf 전환을 명시한다.

핵심 구조(영향 분석서 §0): heartbeat **wire format의 소유자는 OTel Collector(infra)**다. script-agent(Go)는 OTLP SDK로 push만, hub(Java)는 디코드만 한다. 따라서 본 전환의 무게중심은 **(1) Collector encoding 1줄 + (2) hub 디코더 교체**다.

## Decision

본 ADR은 정본을 **재정의하지 않고**, 아래 4가지만 결정한다. 정본이 이미 규정/결정한 사항(payload 타입·파싱 방식·envelope 예외 위상·메시지 키 정책)은 참조만 하며 본 ADR로 변경하지 않는다.

1. **wire schema = A-1 (OTLP 표준 protobuf)**
   - Collector kafka exporter `encoding`을 `otlp_json` → `otlp_proto`로 전환한다.
   - payload는 정본(kafka-payloads.md `heartbeats-topic`)이 규정한 **OTLP MetricsData protobuf**를 그대로 따른다. proto 스키마는 OpenTelemetry 표준에 위임한다(자체 .proto·필드 번호 없음). 본 ADR은 payload 타입을 새로 정하거나 정본을 변경하지 않는다.
2. **공유·관리 = B-1 (표준 라이브러리 의존, 자체 proto 산출물 없음)**
   - wire bytes를 다루는 컴포넌트(Collector exporter, hub 디코더)는 OTel 표준 라이브러리 내장 proto에 의존한다. 버전 skew는 라이브러리 버전 핀으로 통제한다. meta는 proto 파일을 vendoring·배포하지 않는다.
   - script-agent는 OTLP SDK로 push만 하며 proto wire를 직접 다루지 않는다.
   - 파싱 방식(OTel Java SDK)과 `shared-libs/otel` wrapper는 **정본 kafka-payloads.md가 규정한 대로 따른다**(본 ADR이 재정의하지 않음). 그 모듈의 구체 설계는 hub 구현 세션이 정본을 따라 처리한다(`handoff/adr-002-hub.md`).
3. **컷오버 = C-1 (빅뱅)**
   - Collector encoding 전환과 hub 디코더 교체를 **동시 배포**한다(통합본 §6.7.4 "동시 변경 필요"). heartbeat은 휘발성(latest map)이라 배포 경계의 짧은 불일치는 다음 heartbeat 주기로 자동 복구된다(주기/timeout 값은 아래 Open — 데모 baseline 인용일 뿐 본 ADR이 확정하지 않는다).
   - 변경 범위는 **payload(value) 직렬화에 국한**한다: hub의 **value deserializer만** String→byte[]로 바꾼다.
   - **메시지 키 정책은 변경하지 않는다.** 키 정책은 정본 §8.2 ADR 결정표가 이미 **"heartbeats-topic 키 = OTel Collector 기본 (ordering 불필요)"로 결정**했으므로, 본 ADR은 그 결정을 그대로 따르고 key serializer·파티셔닝을 손대지 않는다(§6.7.5의 `[Open]`은 §8.2에서 해소된 것으로 본다 — 정본 우선순위 정리).
4. **토픽명은 본 ADR이 결정하지 않는다.**
   - 물리 `heartbeats` ↔ 논리 `heartbeats-topic`의 토픽명 처리는 본 ADR 범위 밖의 **별도 사안**이다(직렬화 형식과 분리한다).
   - 스코프 제한(결정 아님): **이 ADR의 구현 PR에는 토픽명 변경을 포함하지 않는다**(직렬화 전환과 토픽명 처리를 한 PR에 섞지 않기 위함).

## Open / 별도 작업 (본 ADR이 확정하지 않음)

- **heartbeat 주기 / timeout 운영 baseline**(데모 baseline 10초 / 30초): 운영 값 검증은 Open이다. 본 ADR은 데모 baseline을 인용만 하며 운영값을 확정하지 않는다.
- **토픽명 처리**(Decision 4): 본 ADR 밖 별도 사안.
- **`shared-libs/otel` 모듈의 구체 설계·배포·소유**: 정본 범위. 본 ADR이 정하지 않는다.
- **Schema Registry 도입**: ADR #1의 "Phase 1 미도입" 결정을 따른다(본 ADR은 SR을 다루지 않는다).
- **metrics-topic**: Phase 2 신규/Phase 1 미사용. 범위 밖.

> 메시지 키 / ordering은 더 이상 Open이 **아니다** — 정본 §8.2가 "OTel 기본, ordering 불필요"로 결정했고 본 ADR은 이를 따른다(Decision 3).

## Consequences

영향 범위(영향 분석서 §7):
- **infra**(1차 주체): `otel-collector-config.yml` `encoding` 1줄. → `handoff/adr-002-infra.md`
- **hub**(가장 큰 변경): `HeartbeatConsumer` 디코더 교체, `KafkaConfig` **value deserializer** String→byte[], 테스트 재작성, OTel Java 의존성 추가. → `handoff/adr-002-hub.md`
- **script-agent**(거의 무변경): OTel Go SDK 버전 정합 확인만. → `handoff/adr-002-script-agent.md`

## Compliance / Regression

- 데모 spec v0.2.1 §5.4 heartbeat 동작 회귀 0이 기준. polyrepo 종단 검증은 meta `e2e-tester`로 수행.
- 논리 계약 불변: metric name `agent.heartbeat`, attr `agent_id`(string), `time_unix_nano`(JSON string → proto fixed64), value=1, resource `service.name=script-agent`.
- 메시지 키: 정본 §8.2 결정(`heartbeats-topic` 키 = OTel Collector 기본, ordering 불필요)을 따른다. 본 ADR은 변경하지 않는다.
- envelope 적용 여부는 **`docs/envelope.md` §4.2 정본을 따른다**(`heartbeats-topic`은 OTLP 위임군 예외 — 본 ADR은 이 위상을 변경·재정의하지 않는다).
- 컷오버 C-1: infra encoding 전환과 hub 디코더 배포는 **반드시 동시**여야 한다(순서 어긋남 = 일시적 디코드 실패).

# 영향 분석 — topics-and-keys (T2-4 ∪ T4-4 합본)

> analyzer 산출. **결정하지 않는다.** 두 작업(신규 토픽 추가 / 신규 토픽 메시지 키 정의)의 영향·의존·순서·회귀 기준을 정리한다.

## 0. 메타

| 항목 | 값 |
|---|---|
| work-id | `topics-and-keys` |
| 합본 대상 | `alert/notification 토픽 추가(T2-4)` ∪ `메시지 키 토픽별 정의(T4-4)` |
| 기준 monitoring-meta commit | `666a16e9a60d0df328e463417eed0a77a4e5e2e3` (alert key wire 인코딩 spec 반영분 포함) |
| 작성일 | 2026-06-24 |
| 근거 ADR | `adr/0005-topic-naming.md`(Accepted), ADR#6(통합본 §8.3 결정표 — 별도 ADR 파일 없음, 결정 확정) |
| 합본 근거 | 두 작업이 **동일 신규 토픽(alert/notification)**을 대상으로 하고, hub·monitoring-meta를 공유함 |

## 1. 두 작업을 한 단위로 묶는 이유

- T2-4 = `alert-topic`/`notification-topic` **물리 토픽 신설** + producer/consumer 경로 골격.
- T4-4 = **신규 토픽의 메시지 키** 토픽별 정의(ADR#6 잔여).
- 두 작업이 같은 두 토픽을 대상으로 한다. 토픽 신설과 그 토픽의 키 규약을 분리해 발주하면 같은 코드 지점(producer의 토픽명·키 지정)을 두 번 건드린다. **토픽 신설 = 토픽명 + envelope + 키**가 한 계약이므로 한 단위가 자연스럽다.
- 공유 repo: hub(producer/consumer 보유 예정), monitoring-meta(계약 문서 갱신 주체). infra(토픽 프로비저닝), script-agent(T4-4 명목 대상)는 §4·§5에서 실제 영향을 판정한다.

## 2. 현황 — 현재 코드 동작 (Phase 0 + Phase 1 기진행분)

### 2.1 토픽 설정 방식 (현재)

- **hub**: `KafkaConfig.Topics` 상수 클래스에 토픽명 집중(`command-topic`/`result-topic-job`/`result-topic-log`/`audit-topic`/`heartbeats-topic`). 5개 토픽 상수만 존재 — `alert-topic`/`notification-topic` 없음.
  - producer: `CommandPublisher`(command-topic, 키 = `command.targetAgentId()` 명시 지정).
  - consumer: `AuditConsumer`/`JobResultConsumer`(멀티토픽)/`HeartbeatConsumer`.
- **script-agent**: `internal/config/config.go`에 토픽을 env override 가능 필드로(`KAFKA_TOPIC_COMMANDS` 등 기본값 = 논리명). result 발행 키 = `result.AgentID`(`internal/jobresult/publisher.go`에서 명시 지정). alert/notification 관련 코드 없음.
- **infra**: `docker-compose.yml`의 `kafka-init`이 토픽을 명시 사전 생성 — 현재 5개(`command-topic result-topic-job result-topic-log audit-topic heartbeats-topic`). `KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"`(안전망). alert/notification 미생성.

### 2.2 키 지정 방식 (현재 — 기구현분)

- 기존 토픽 키는 **명시 지정 방식**으로 이미 구현됨(ADR#6 PARTIAL, §5.1 #6).
  - command-topic: hub `CommandPublisher`가 `target_agent_id`를 ProducerRecord 키로 전달.
  - result-topic-job/log: script-agent `jobresult.Publisher`가 `agent_id`를 키로 전달.
- 신규 토픽(alert/notification)의 producer 코드 자체가 아직 없음 → 키 적용 지점도 미존재.

## 3. 목표 spec 요구 (Phase 1+ 도달 목표)

### 3.1 토픽 신설 (T2-4) — 모두 확정

| 토픽 | 최종 논리명(확정) | producer | consumer | envelope | 근거 |
|---|---|---|---|---|---|
| alert-topic | `alert-topic` (규칙 B `<domain=alert>-topic`) | Rule Engine 전 인스턴스 + Agent State Service | Alert Processor → Incident Service | 4종 적용 | 통합본 §4.4.1·§6.9.3·§6.9.5, ADR#5 §2.2.1 |
| notification-topic | `notification-topic` (규칙 B) | Incident Service | Notification Service | 4종 적용 | 통합본 §4.4.1·§6.9.3·§6.9.5, ADR#5 §2.2.1 |

- 토픽 신설 자체 = Phase 1 확정(과거 D-9 RESOLVED 2026-06-03 / 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표).
- 최종 논리명 = D-4(1)(2026-06-06 후보 B 승인, `adr/0005` Accepted)으로 확정.
- envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`) 적용 = `docs/envelope.md` §4.1 공통 토픽군(6) 소속.
- payload 계약 = `docs/kafka-payloads.md` `alert-topic`/`notification-topic` 절(필드 확정).

### 3.2 메시지 키 (T4-4) — 모두 확정

| 토픽 | 키 | rule | 근거 |
|---|---|---|---|
| alert-topic | `(rule_id, target_id)` 조합 | `rule_id`가 null이면 `("agent-offline", target_id)` (Agent OFFLINE은 룰 기반 아님) | 통합본 §6.8.2 키 표·§6.9.5, kafka-payloads `alert-topic`, envelope §4.1 |
| notification-topic | `incident_id` | — | 통합본 §6.8.2 키 표·§6.9.5, kafka-payloads `notification-topic`, envelope §4.1 |

- ADR#6(통합본 §8.3) = "메시지 키 토픽별 정의(Agent/actor/Rule×대상/Incident)" 확정.
- alert-topic 조합 키 = 6.4 Dedup 키 `(rule_id, target_id, severity)`에서 severity 제외 — 같은 Rule×대상의 모든 severity가 한 partition으로 모임(severity 전이 처리 유리, 통합본 §6.8.2).

## 4. scope 경계 — 본 합본이 하는 것 / 안 하는 것 (핵심)

> **가장 중요한 분리.** T2-4 행의 `blocked_by = "T1-1 등 선행 인프라"`는 **토픽 추가/키 정의 자체에 걸리는 미결정이 아니다.** T1-1(영속 저장소)에 의존하는 것은 alert/notification을 **producing/consuming하는 서비스**(Alert Processor·Incident Service·Notification Service — Redis Dedup/PG alert·incident 필요)이며, 이들은 T2-1~T2-3/T3-1의 영역이다. **물리 토픽 존재 + 토픽명 상수 + envelope 적용 + 메시지 키 규약**은 그 서비스들과 독립적으로 선제 확정할 수 있다.

### 본 합본이 하는 것 (계약·인프라 정렬 레이어)
- infra: `alert-topic`/`notification-topic` 두 토픽을 `kafka-init` 사전 생성 목록에 추가.
- hub: `KafkaConfig.Topics`에 두 토픽 상수 추가.
- hub: 신규 토픽 producer/consumer를 **만든다면**, 그 발행 시 envelope 4종 첨부 + 메시지 키를 §3.2 규약대로 지정하는 **계약을 박는다**(키 지정 로직·envelope 헬퍼 재사용).
- monitoring-meta(후속): 계약 문서 일관성 확인(이미 kafka-payloads/envelope/통합본에 반영됨 — §7).

### 본 합본이 하지 않는 것 (out of scope — 다른 Track)
- Rule Engine(T2-1), Alert Processor + Dedup(T2-2), Incident Service(T2-3), Notification Service + 채널 어댑터(T3-1) **서비스 빌드** — T1-1 등에 의존하는 도메인 로직.
- Agent OFFLINE → Alert 발화(T2-6).
- alert/notification payload를 채우는 도메인 데이터 생성 로직(rule 평가·dedup·그룹핑·상태 전환).
- Notification 재시도 정책 등 T3-1 서비스 내부 사안(통합본 Open question — T2-4/T4-4 핵심 범위 밖).

> **작업 깊이 결정 (해소됨)**: hub가 어디까지 갈지는 **계획 레이어 선택**이었고(§6 참조), **(b) producer 골격까지로 확정**됐다(2026-06-25 사람 결정). 도메인 로직(rule 평가·dedup·incident 그룹핑)은 어느 쪽이든 본 합본 밖이다.

## 5. repo별 영향

### 5.1 hub (영향 있음 — spec 작성)
- `KafkaConfig.Topics`: `alert-topic`/`notification-topic` 상수 2개 추가.
- producer 골격(AlertPublisher/NotificationPublisher) 추가(작업 깊이 (b) 확정): envelope 4종 헤더(`messaging.EnvelopeHeaders` 재사용) + canonical 키 적용.
  - alert key wire 인코딩 = **`alert-key:v1:{rule_id}:{target_id}`**, rule_id null이면 **`alert-key:v1:agent-offline:{target_id}`** — **규범 출처=spec**(`docs/kafka-payloads.md` `alert-topic` 키 절 + 통합본 §6.8.2에 반영, meta 결정 2026-06-25). 의미 계약 `(rule_id, target_id)`의 wire 표현으로 producer·향후 consumer·테스트가 같은 계약을 검증. key builder 함수 + 두 분기 단위 테스트.
  - notification key = `incident_id` 원문 문자열.
  - **`x-source`**: envelope §2.4상 **이미 필수 헤더**(신규 spec 제약 아님). 그 필수 요건을 placeholder로 채우지 않도록 publisher가 `source`를 필수 주입 파라미터로 받게 한다(호출 측이 실제 발행 모듈명 주입, D-2 이후 모듈명 변동 대비).
- 회귀: 기존 토픽 상수·CommandPublisher 키(`target_agent_id`) 동작 불변. envelope 발행 로직 재사용 시 기존 헤더 회귀 0.

### 5.2 infra (영향 있음 — spec 작성)
- `docker-compose.yml` `kafka-init` 사전 생성 목록에 `alert-topic notification-topic` 2개 추가(현재 5개 → 7개). **7 = §7 8토픽 논리 계약 중 Phase 1 런타임 활성분**(8 − `metrics-topic`[Phase 2 미생성] = 7; 8과 7은 다른 축, 불일치 아님).
- partition/replication: 현재 init이 토픽별로 동일 옵션을 주는 구조(루프). 신규 2토픽도 동일 baseline(단일 broker, replication=1). alert-topic은 조합 키 hot partition 위험이 통합본 §6.8.6 Open(O3)으로 보존돼 있으나, **이는 partition 수 튜닝 사안이며 토픽 신설 자체를 막지 않음** — baseline partition 수로 생성하고 튜닝은 별도 Open.
- **rollback/운영 메모(O3)**: Kafka partition 수는 단순 되돌리기가 아니다(증설은 키→partition 매핑을 바꿔 ordering 보장이 깨짐). baseline으로 시작하되 hot partition 완화가 필요해지면 **신규 토픽 재생성(다른 partition 수) 또는 마이그레이션** 경로를 택해야 하며, 어느 경로든 O3 Open 해소 시 별도 운영 결정으로 추적한다(본 합본 범위 밖).
- 회귀: 기존 5토픽 init·auto-create 안전망 불변.

### 5.3 script-agent (영향 없음 — 파일 생략, 근거 명기)
- **T4-4가 명목 대상 repo로 script-agent를 잡고 있으나, 실제 영향 없음.**
  - 근거: alert-topic producer = Rule Engine + Agent State Service / consumer = Alert Processor. notification-topic producer = Incident Service / consumer = Notification Service. **모두 hub/BE 측 컴포넌트이며 script-agent가 아니다**(통합본 §4.4.1 생산자/소비자 열).
  - script-agent 코드에 alert/notification 관련 producer/consumer 없음(grep 확인). script-agent의 기존 키(result-topic-job/log = `agent_id`)는 이미 기구현(§5.1 #6)이며 본 합본이 건드리지 않음.
  - T4-4가 ROADMAP에서 script-agent를 대상에 넣은 것은 "토픽별 키 정의"가 양쪽 repo에 걸친 ADR#6 전체를 가리키기 때문이며, **신규 토픽 키 부분에 한정하면 script-agent 작업분은 0**이다.
- 따라서 `topics-and-keys-script-agent.md`는 **생성하지 않는다.** (본 절이 그 근거다.)
- **회귀 확인 항목(명시)**: script-agent는 alert/notification producer·consumer가 아니며, 본 합본으로 다음이 **불변**임을 못 박는다 — `result-topic-job`/`result-topic-log` key=`agent_id`, `command-topic` key=`target_agent_id`(소비 측), OTLP 위임 토픽(heartbeats/metrics, ADR-0002 경로) 불변. script-agent 세션 작업 0이므로 회귀 검증도 meta e2e의 기존 경로 가드로 충분(별도 script-agent 작업 없음).

### 5.4 monitoring-meta (후속 — 계약 문서, repo spec 파일 없음)
- §7 "meta 후속" 참조. meta는 계약 문서(통합본/kafka-payloads/envelope) 갱신 주체이나, **두 토픽의 계약은 이미 세 문서에 모두 반영돼 있다**(kafka-payloads `alert-topic`/`notification-topic` 절, envelope §4.1, 통합본 §4.4.1·§6.8.2·§6.9.3·§6.9.5). 본 합본에서 meta 신규 계약 작성분은 없고 일관성 확인만 남음.

## 6. 결정 필요 사안 (사람 입력 대기)

> 통합본 `[Open question]`·미결정 ADR·AMS 가정 충돌은 **토픽 추가·키 정의 자체에 걸리는 것이 없다**(오케스트레이터 선검증대로 확인). 아래는 **계획 레이어 선택**이며 통합본 Open이 아니다 — analyzer가 단정하지 않고 사람 확정에 넘긴다.

1. **hub 작업 깊이** — **확정: (b)** (2026-06-25, 사람 결정): 토픽 상수 + producer 골격(`AlertPublisher`/`NotificationPublisher` 류, 키·envelope 적용 검증 가능한 수준, 도메인 로직 제외)까지. (a) 계약-only는 기각. hub spec §5.3에 확정 표기.
2. **alert-topic 키 wire 인코딩** — **확정+spec 반영: `alert-key:v1:{rule_id}:{target_id}`** (null이면 `agent-offline`), 구분자 `:` 고정·버전 `v1` (meta 결정 2026-06-25). **규범 출처=spec**: `docs/kafka-payloads.md` `alert-topic` 키 절 + 통합본 §6.8.2에 **이미 반영**(ROADMAP/handoff가 spec보다 먼저 규범화하지 않음 — 위상 정상). (전제: 식별자에 `:` 없음 — 코드 세션 착수 시 확인, 위반 시 멈춤.)
3. **alert-topic hot partition 튜닝**(통합본 §6.8.6 O3 Open): partition 수·키 정책 변경은 **토픽 신설을 막지 않으며** baseline partition으로 생성 후 별도 추적. blocker 아님(보존 항목, rollback 메모 §5.2).

> 위 항목 중 통합본 미결 Open(§6.8.6 O3)은 토픽 신설 범위 밖(튜닝)이라 **본 합본을 막지 않는다.** 1번(작업 깊이)·2번(키 인코딩) 모두 확정됐다. **본 합본을 차단하는 미결정은 없다.**

## 7. meta 후속 (계약 문서 — 별도 repo spec 없음)

- 통합본/kafka-payloads/envelope 3종에 alert/notification 토픽·키 **의미** 계약 반영 완료. alert key의 **wire 인코딩(`alert-key:v1:...`)도 본 합본과 동일 커밋에 `kafka-payloads.md` `alert-topic` 키 절 + 통합본 §6.8.2에 반영 완료**(meta 결정 2026-06-25, 결정 기록 `proposal-review-topics-and-keys-r2.json`) — 규범 출처는 spec, handoff는 참조. 잔여 계약 후속(features 등 서술 문서)은 복귀 게이트에서 정리.
- hub/infra 작업 완료 후, meta는 `e2e-tester`로 polyrepo 종단 검증(신규 토픽 회귀 가드)을 별도 수행. 신규 토픽에 대한 e2e 케이스 추가 여부는 e2e 산출물 영역(본 합본 밖).
- spec drift 검사(`spec-sync`)는 작업 완료 후 기준 문서↔코드 토픽 상수/키 일치를 검출.

## 8. 의존·순서·회귀 기준 (요약)

- **의존**: T2-4(토픽 신설) → T2-6/T3-1(전용 경로 합류). T4-4(신규 키) blocked_by = T4-1(DONE). 본 합본 자체의 선행 차단 없음(infra 토픽 생성 = broker 기동만 필요).
- **순서**: infra(토픽 사전 생성) → hub(토픽 상수 + 키 규약). 단 hub 토픽 상수 추가는 infra와 독립적으로 가능(auto-create 안전망). 권고 순서 = infra → hub 동시/병행.
- **회귀 기준 (양 repo 공통)**:
  - Phase 0 e2e baseline(현행 64/0/0, `e2e/results/20260614-164044.md`) 불변.
  - 기존 5토픽 상수·producer 키(command=`target_agent_id`, result=`agent_id`) 동작 불변.
  - 기존 kafka-init 5토픽·auto-create 안전망 불변.
  - envelope 4종 발행 로직(기존 토픽) 회귀 0.

## 9. 영향받는 기능 문서 (`docs/features/`)

- **해당 없음.**
- 근거: features 레이어는 **구현 완료된 사용자 가시 시나리오 흐름**만 다룬다(`docs/features/README.md` §1). 본 합본은 **토픽 추가 + 키 규약 정렬(인프라·계약 레이어)**이며, alert/notification을 producing/consuming하는 사용자 가시 흐름(Rule 평가 → Alert → Incident → Notification 파이프라인)은 본 합본 scope 밖(T2-1~T3-1, 미구현)이다. 토픽이 존재해도 그 위를 흐르는 사용자 가시 시나리오가 아직 구현되지 않으므로 신규 기능 문서 대상이 아니다.
- 기존 기능 문서 4종(heartbeat-collection/script-job-execution/log-job-collection/agent-lifecycle-audit)은 기존 5토픽 흐름만 다루며 신규 2토픽과 무관 → 보완 대상도 아님.
- 향후 Rule→Alert→Notification 파이프라인이 **구현 완료**되면 그때 신규 기능 문서 대상이 된다(본 합본이 아니라 T2-1~T3-1 완료 시점).

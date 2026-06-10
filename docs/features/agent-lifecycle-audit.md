> **이 문서는 기술(descriptive) 문서다 — 코드의 현재 상태를 서술한다. 규범의 답은 통합본 v0.9 / `adr/`에 있다.**

# 기능: agent 생명주기 인지·감사 추적 흐름

## 0. 메타 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 기능 ID | `agent-lifecycle-audit` | 파일명과 일치 |
| 시나리오 한 줄 | `agent 기동 → AGENT_STARTED(audit-topic) → hub AgentRegistry 등록 / job 실행 → JOB_EXECUTED / agent 종료 → AGENT_STOPPED → OFFLINE 마킹` | 인덱스 표와 동일 |
| 관여 repo | `script-agent`, `hub`, `infra` | |
| 기준 meta commit | `5c2ef6b4df338cf55b500bf3cd20ee2c381fc67e` | 이 문서가 참조한 통합본/`adr/` 등 **spec의 시점**을 고정한다. **형제 repo 코드 시점이 아니다** — 코드가 실제 동작한 시점 증거는 §9의 e2e 결과. 본문 코드 앵커로 쓰지 않는다 |
| 최종 갱신일 | `2026-06-10` | |
| 검증 상태 | `검증됨` | §9 최종 검증 기준과 연동 |

## 1. 기능 개요

script-agent 프로세스의 기동·종료와 job 실행 이력은 `audit-topic`을 통해 hub에 전달된다. 감사 이벤트는 3종이다: AGENT_STARTED(기동 직후), AGENT_STOPPED(정상 종료 직전), JOB_EXECUTED(job 실행 완료 시). hub의 `AuditConsumer`가 이를 소비하여 `AuditRingBuffer`에 적재하고, AGENT_STARTED 수신 시에는 `AgentRegistry.register`로 agent를 등록(state=ONLINE), AGENT_STOPPED 수신 시에는 `AgentRegistry.markOffline`으로 OFFLINE으로 마킹한다. hub UI(/)는 `AgentRegistry.findAll()`로 agent 목록과 state를 실시간으로 표시한다.

이 문서는 AGENT_STARTED/STOPPED가 양쪽 repo에 걸쳐 있어 생명주기 인지와 감사 추적을 하나의 수직 슬라이스로 합쳐 서술한다.

## 2. 사용자 시나리오

- script-agent 프로세스가 기동되면 agent_id 영속 → Kafka writer/reader 초기화 후 `audit.Publisher.AgentStarted`를 호출해 AGENT_STARTED 이벤트를 `audit-topic`에 발행한다(best-effort: 실패 시 WARN + 계속).
- hub `AuditConsumer`가 AGENT_STARTED를 수신해 `AgentRegistry.register`를 호출한다. agent_id가 신규이면 등록(state=ONLINE), 기존이면 재기동으로 보아 hostname/os/version 갱신 + state=ONLINE 복귀.
- 사용자는 hub UI(/)의 agents 패널에서 해당 agent가 ONLINE으로 표시되는 것을 확인한다.
- job이 실행 완료될 때마다 `audit.Publisher.JobExecuted`가 JOB_EXECUTED 이벤트를 발행한다(`execution_id`, `schedule_id`, `job_id`, `job_type`, SCRIPT_JOB이면 `exit_code` 추가). hub `AuditConsumer`는 ring buffer에 적재만 한다(현 단계).
- 사용자가 agent 프로세스를 종료(Ctrl+C/SIGTERM)하면, signal 수신 후 `audit.Publisher.AgentStopped`가 AGENT_STOPPED를 발행한다(5초 budget; best-effort: 실패 시 WARN + 종료 계속).
- hub `AuditConsumer`가 AGENT_STOPPED를 수신해 `AgentRegistry.markOffline`으로 agent state를 OFFLINE으로 변경한다. agent는 registry에서 제거되지 않고 OFFLINE 상태로 남는다.
- 사용자는 hub UI(/)에서 해당 agent가 OFFLINE으로 표시되는 것을 확인한다.

## 3. 관련 spec 참조 (규범 문서 포인터)

이 레이어는 결정하지 않고 포인터만 단다.

- 통합본 v0.9: `§3.2` AgentRegistry(ONLINE/OFFLINE 전이 정책), `§5.3` 감사 이벤트 3종, `§5.3.1` AGENT_STARTED metadata, `§5.3.2` AGENT_STOPPED, `§5.3.3` JOB_EXECUTED
- 데모 spec v0.2.1: `§5.3` audit 이벤트 — **Phase 0 회귀 기준**, 통합본과 동일 ground truth 아님
- ADR: `adr/0005-topic-naming.md` — `audit-topic` 최종 논리명 확정
- 페이로드/봉투: `docs/kafka-payloads.md` `audit-topic` 절; `docs/envelope.md` §2.2~§2.3

## 4. 관여 repo·컴포넌트

- `script-agent`: `cmd/agent/main.go` (생명주기 orchestration — AgentStarted/AgentStopped 발행 타이밍, signal 처리); `internal/audit.Publisher` (이벤트 빌드 + `audit-topic` 발행); `internal/kafka.BuildHeaders` (envelope 3종 헤더); `internal/model.AuditEvent`·`model.AuditAction`(AGENT_STARTED/STOPPED/JOB_EXECUTED); `internal/config.Config.KafkaTopicAuditEvents` (`audit-topic`)
- `hub`: `ingest.audit.AuditConsumer` (`audit-topic` consumer, AGENT_STARTED/STOPPED/JOB_EXECUTED 분기); `store.AgentRegistry` (`register`=ONLINE 등록·복귀, `markOffline`=OFFLINE 마킹, `updateLastSeen`=heartbeat 경로 전용); `store.AuditRingBuffer`; `messaging.EnvelopeHeaders` (`inspectSource` 관찰 전용 가드); `config.KafkaConfig` (`Topics.AUDIT_EVENTS="audit-topic"`); `web.UiController` (UI `/` agents 패널 + audit-events 패널)
- `infra`: `docker-compose.yml` kafka-init — `audit-topic` 사전 생성

## 5. 흐름 따라가기 (hop-by-hop)

### 5.1 AGENT_STARTED (기동)

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1 | `script-agent:cmd/agent/main` | `main.run` → `audit.Publisher.AgentStarted` | - | agent_id 영속 후, Kafka writer 초기화 직후. 5초 startup context |
| 2 | `script-agent:internal/audit.Publisher` | `Publisher.buildAgentStarted` → `Publisher.publish` | `audit-topic` | envelope 3종 헤더(x-message-id/x-message-version/x-source="script-agent"); key=agentID; metadata: hostname/os/agent_version/started_at |
| 3 | `hub:ingest.audit.AuditConsumer` | `AuditConsumer.consume` → `EnvelopeHeaders.inspectSource` | `audit-topic` | x-source 관찰 전용 가드; group=auditEventListenerFactory 기본 group |
| 4 | `hub:ingest.audit.AuditConsumer` | `handleAgentStarted` | - | `registry.register(agentId, hostname, os, agentVersion)` |
| 5 | `hub:store.AgentRegistry` | `AgentRegistry.register` | - | 신규: `AgentInfo(state=ONLINE, last_seen=now)` 생성; 재기동: hostname/version 갱신 + state=ONLINE 복귀; `INFO AGENT_STARTED received: agent_id=...` |
| 6 | `hub:web.UiController` | `UiController.index` | - | `agentRegistry.findAll()` → agents 패널; state=ONLINE 표시 |

### 5.2 JOB_EXECUTED (job 실행 완료 시)

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1 | `script-agent:internal/job.Dispatcher` | `Dispatcher.Dispatch` → `auditor.JobExecuted` | - | job-results 발행 성공 후 호출 |
| 2 | `script-agent:internal/audit.Publisher` | `Publisher.buildJobExecuted` → `Publisher.publish` | `audit-topic` | metadata: execution_id/schedule_id/job_id/job_type; SCRIPT_JOB이면 exit_code 추가; occurred_at=result.FinishedAt |
| 3 | `hub:ingest.audit.AuditConsumer` | `AuditConsumer.consume` → `case JOB_EXECUTED` | `audit-topic` | `buffer.add(event)` 적재; `DEBUG JOB_EXECUTED received: event_id=...` |
| 4 | `hub:store.AuditRingBuffer` | `AuditRingBuffer.add` | - | CircularFifoQueue ring buffer; AgentRegistry 변경 없음 |
| 5 | `hub:web.UiController` | `UiController.index` | - | `auditBuffer.snapshot()` reversed → audit-events 패널 |

### 5.3 AGENT_STOPPED (종료)

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1 | `script-agent:cmd/agent/main` | `main.run` → `auditor.AgentStopped(shutdownCtx, reason)` | - | Ctrl+C/SIGTERM 수신 후 consumer goroutine drain 완료 후 발행; 5초 budget; reason = signal 이름("interrupt"/"terminated") 또는 "consumer-error" |
| 2 | `script-agent:internal/audit.Publisher` | `Publisher.buildAgentStopped` → `Publisher.publish` | `audit-topic` | metadata: reason; envelope 3종 헤더; key=agentID |
| 3 | `hub:ingest.audit.AuditConsumer` | `AuditConsumer.consume` → `handleAgentStopped` | `audit-topic` | x-source 관찰 가드; `registry.markOffline(agentId)` |
| 4 | `hub:store.AgentRegistry` | `AgentRegistry.markOffline` | - | `computeIfPresent` → state=OFFLINE; 미등록 agent_id면 no-op; 맵에서 제거하지 않음; `INFO AGENT_STOPPED received: agent_id=... reason=...` |
| 5 | `hub:web.UiController` | `UiController.index` | - | agents 패널; state=OFFLINE 표시 |

**AGENT_STARTED best-effort**: 발행 실패 시 WARN 로깅만 하고 agent는 계속 기동된다. hub가 AGENT_STARTED를 못 받으면 해당 agent는 AgentRegistry에 등록되지 않는다(heartbeat의 `updateLastSeen`도 미등록 agent에는 no-op).

**AGENT_STOPPED best-effort**: 발행 실패 시 WARN 로깅만 하고 종료 흐름은 계속된다. hub가 AGENT_STOPPED를 못 받으면 해당 agent는 ONLINE 상태로 남는다(자동 OFFLINE 전이 sweeper 미구현 — §8).

**state 전이 경계**: heartbeat 경로(`HeartbeatConsumer`)는 `AgentRegistry.updateLastSeen`만 호출하며 state를 변경하지 않는다. ONLINE/OFFLINE 전이는 이 audit 경로만 담당한다(heartbeat-collection.md §5 "생존 표시 경계" 참조).

## 6. 흐름 다이어그램

```
script-agent 기동 (main.run)
    │  agent_id 영속, Kafka writer 초기화
    ▼
audit.Publisher.AgentStarted()  →  Kafka: audit-topic
    │  {action=AGENT_STARTED, actor={type=agent,id}, metadata={hostname,os,agent_version,started_at}}
    │  envelope 헤더 3종 (x-source="script-agent")
    ▼
hub: AuditConsumer.consume → handleAgentStarted
    │  AgentRegistry.register(agentId, hostname, os, agentVersion)
    │    → state=ONLINE, last_seen=now
    ▼
hub UI(/): agents 패널 state=ONLINE 표시

── [job 실행마다] ──────────────────────────────────────
script-agent: Dispatcher.Dispatch → audit.Publisher.JobExecuted()
    →  Kafka: audit-topic  {action=JOB_EXECUTED, metadata={execution_id,job_type,...}}
    ▼
hub: AuditConsumer → AuditRingBuffer.add (AgentRegistry 변경 없음)
hub UI(/): audit-events 패널

── [종료 시] ────────────────────────────────────────────
script-agent: signal(SIGTERM/SIGINT) 수신 → consumer drain
    ▼
audit.Publisher.AgentStopped(reason)  →  Kafka: audit-topic
    │  {action=AGENT_STOPPED, metadata={reason}}
    ▼
hub: AuditConsumer.consume → handleAgentStopped
    │  AgentRegistry.markOffline(agentId)  →  state=OFFLINE (맵에서 미제거)
    ▼
hub UI(/): agents 패널 state=OFFLINE 표시
```

## 7. 검증 방법

> `데모 spec v0.2.1`은 **Phase 0 회귀 검증 기준**이며 도달 목표 규범이 아니다(규범 = 통합본 v0.9 / ADR — §3).

- **e2e**: `e2e/results/20260610-152424.md` — PASS 58/0/0
  - §6-AUDIT: `hub 로그에서 AGENT_STARTED 수신 확인 — audit-topic 경로(agent→kafka→hub) 정상 실증`; 로그 라인 `AGENT_STARTED received: agent_id=... hostname=... os=windows/amd64 agent_version=0.1.0`
  - §6-T4-C: `script-agent 기동/등록 확인` — script-agent `"agent started"` 로그 실증
  - §7 x-source 가드 회귀: `hub/AuditConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인`
  - §8 R-B: `hub/KafkaConfig.Topics.AUDIT_EVENTS = "audit-topic"` / `script-agent/config.go: KAFKA_TOPIC_AUDIT_EVENTS default="audit-topic"` / `hub/AuditConsumerTest.java: TOPIC="audit-topic"` 확인
  - §8 R-A: `hub/AuditConsumer.java: Topics.AUDIT_EVENTS 상수 참조(단일 진실)` 확인
- **단위 테스트**: `hub mvn test` PASS (AuditConsumerTest 포함); `script-agent go test ./...` PASS (audit.Publisher 단위 테스트 포함 `internal/model/audit_test.go`).

## 8. 미구현·잔여 사항

- **heartbeat timeout 기반 자동 OFFLINE 전이(sweeper)**: 현재 OFFLINE 전이는 AGENT_STOPPED 명시 수신으로만 일어난다. AGENT_STOPPED를 발행하지 못하고 죽은 agent(crash 등)는 ONLINE 상태로 남는다. `heartbeatTimeoutSeconds` 기반 자동 OFFLINE 전이 sweeper 미구현(heartbeat-collection.md §8 참조; ADR-0002 Open).
- **JOB_EXECUTED hub 처리**: 현재 `AuditRingBuffer.add`만 수행. schedule_id/job_id 기반 상관(job-results ↔ JOB_EXECUTED) 자동 매칭 미구현.
- **AuditRingBuffer 도메인 영속화**: in-memory ring buffer(capacity 기본값은 AppProperties에서). hub 재시작 시 감사 이력 소멸.
- **AgentRegistry 도메인 영속화**: in-memory ConcurrentHashMap. hub 재시작 시 전체 agent 등록 정보 소멸. 재기동 agent가 AGENT_STARTED를 재발행해야 재등록된다.
- **AGENT_STOPPED consumer-error 경로**: `Dispatcher.Dispatch` publish 실패 시 consumer가 자기 종료하며 `stopReason="consumer-error"`로 AGENT_STOPPED가 발행된다. 이 경로에서 hub가 AGENT_STOPPED를 못 받을 가능성(예: Kafka 자체 장애)은 sweeper 없이는 ONLINE 잔존으로 이어짐 — §8 sweeper 미구현과 연동.

## 9. 최종 검증 기준 (필수)

- **기준 e2e 결과**: `e2e/results/20260610-152424.md` (PASS 58/0/0) — 형제 repo 코드가 실제 동작한 시점 증거. 동적 모드(`--dynamic --reuse-infra`) 활성, Docker 데몬 v29.4.3.
- **spec 참조 시점**: §0 기준 meta commit `5c2ef6b4df338cf55b500bf3cd20ee2c381fc67e` (통합본 v0.9 / `adr/0005-topic-naming.md` / `docs/kafka-payloads.md` / `docs/envelope.md`)
- **Phase 0 회귀 기준(데모 spec v0.2.1 — 규범 아닌 회귀 근거)**: §6-AUDIT AGENT_STARTED 수신 실증; §4 단위 테스트 PASS(AuditConsumerTest 포함); §8 토픽 상수 신명 정합.
- **주의**: AGENT_STOPPED 동적 수신(허브 OFFLINE 마킹)은 e2e §6에서 직접 실증되지 않음(e2e 종료 시 script-agent SIGTERM 전송되나 hub OFFLINE 확인 로그는 캡처 범위 외). AGENT_STARTED 수신과 코드 확인에 근거한 서술.

> **이 문서는 기술(descriptive) 문서다 — 코드의 현재 상태를 서술한다. 규범의 답은 통합본(`docs/master-design.md`) / `adr/`에 있다.**

# 기능: SCRIPT_JOB 실행 흐름

## 0. 메타 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 기능 ID | `script-job-execution` | 파일명과 일치 |
| 시나리오 한 줄 | `스케줄 등록 → Quartz 트리거 → command-topic → script-agent SCRIPT_JOB 실행 → result-topic-job → hub 수신·표시` | 인덱스 표와 동일 |
| 관여 repo | `hub`, `script-agent`, `infra` | |
| 기준 meta commit | `5c2ef6b4df338cf55b500bf3cd20ee2c381fc67e` | 이 문서가 참조한 통합본/`adr/` 등 **spec의 시점**을 고정한다. **형제 repo 코드 시점이 아니다** — 코드가 실제 동작한 시점 증거는 §9의 e2e 결과. 본문 코드 앵커로 쓰지 않는다 |
| 최종 갱신일 | `2026-06-14` | |
| 검증 상태 | `검증됨` | §9 최종 검증 기준과 연동 |

## 1. 기능 개요

사용자가 REST POST `/schedules` (또는 UI 폼)로 SCRIPT_JOB 스케줄을 등록하면 hub의 Quartz가 cron 주기마다 `command-topic`으로 명령을 발행한다. script-agent는 명령을 수신해 지정된 스크립트를 실행하고(`timeout_seconds` 강제 중단, `output_cap_bytes` truncate), 실행 결과를 `result-topic-job` 토픽으로 발행한다. hub의 `JobResultConsumer`가 `result-topic-job`을 구독해 `JobResultRingBuffer`에 적재하고 콘솔 UI(/)에 표시한다.

## 2. 사용자 시나리오

- 사용자가 POST `/schedules` 또는 UI 폼(`/ui/schedules`)으로 job_type=SCRIPT_JOB, script_path/args/timeout/output_cap, target_agent_id, cron_expression을 제출한다.
- hub `ScheduleService`가 `JobDefinition`·`ScheduleDefinition`을 생성하고 Quartz에 `CronTrigger`를 등록한다.
- Quartz cron이 fire할 때마다 `ScheduleTriggerJob`이 execution_id(UUIDv4)와 valid_until(다음 fire 시각의 90%)을 산출해 `CommandPublisher`로 `command-topic`에 발행한다(envelope 4종 헤더 첨부, 메시지 키=target_agent_id).
- script-agent `consumeCommands`가 명령을 fetch해 `Dispatcher.Dispatch`에 전달한다. target_agent_id 불일치 또는 valid_until 만료이면 silent skip.
- `ScriptRunner.Run`이 `exec.CommandContext`로 스크립트를 실행한다. `timeout_seconds > 0`이면 `context.WithTimeout`으로 강제 중단하며 결과는 TIMEOUT. `output_cap_bytes`만큼만 stdout/stderr를 보존하고 초과분은 drop(truncated=true).
- 실행 완료 후 `jobresult.Publisher`가 job_type=SCRIPT_JOB 분기로 `result-topic-job`에 결과를 발행하고, `audit.Publisher`가 `JOB_EXECUTED` 감사 이벤트를 `audit-topic`으로 발행한다.
- hub `JobResultConsumer`가 `result-topic-job`에서 결과를 수신해 `JobResultRingBuffer`에 적재한다.
- 사용자는 hub UI(/)의 job-results 패널에서 실행 결과(execution_id, status, exit_code, stdout/stderr cap)를 확인한다.

## 3. 관련 spec 참조 (규범 문서 포인터)

이 레이어는 결정하지 않고 포인터만 단다.

- 통합본(`docs/master-design.md`): `§6.2` Job 실행 흐름 — 명령 발행·valid_until 만료 정책(ADR #16)·Quartz misfire `DO_NOTHING`(ADR #17)·Script Agent 명령 수신 routing, `§6.6` JOB_EXECUTED 감사 채널(ADR #3), `§6.8` envelope·메시지 키(ADR #6). ※ 종전 `§5.x` 포인터는 데모 spec 절 번호의 오기였음 — 데모 spec 포인터는 아래 행이 따로 담당
- 데모 spec v0.2.1: `§5.1` command 흐름, `§5.2.1` SCRIPT_JOB 결과 — **Phase 0 회귀 기준**, 통합본과 동일 ground truth 아님
- ADR: `adr/0005-topic-naming.md` — `command-topic` 최종 논리명 확정(T4-1 재명명 완료). `result-topic-job`은 T4-2 result-topic 분리(result-topic 분리(T4-2)) 완료 후의 **현행 물리명**이며 SCRIPT_JOB 결과 전용 토픽이다. payload 구조(`JobResult`)는 현 단계 공통 유지(ADR #19 — 평면 목표 스키마로의 정렬은 후속 Track).
- 페이로드/봉투: `docs/kafka-payloads.md` `command-topic` 절·`result-topic-job` 절; `docs/envelope.md` §2.2 헤더 4종, §2.3 x-source 가드(비규범 관찰 전용)

## 4. 관여 repo·컴포넌트

- `hub`: `api.ScheduleController` (POST /schedules REST 진입점); `web.UiController` (POST /ui/schedules 폼 진입점); `scheduler.ScheduleService` + `scheduler.ScheduleTriggerJob` (Quartz 트리거 등록·fire); `store.JobRegistry`·`store.ScheduleRegistry` (in-memory 레지스트리); `producer.CommandPublisher` (envelope 헤더 첨부, command-topic 발행); `store.CommandRingBuffer`; `ingest.jobresult.JobResultConsumer` (멀티토픽 listener — `result-topic-job`·`result-topic-log` 동시 구독); `store.JobResultRingBuffer` (공용 ring buffer); `messaging.EnvelopeHeaders` (헤더 키 단일 진실 + inspectSource 관찰 전용 가드); `config.KafkaConfig` (`Topics.COMMANDS="command-topic"`, `Topics.RESULT_JOB="result-topic-job"`, `Topics.RESULT_LOG="result-topic-log"`)
- `script-agent`: `cmd/agent/main.go` (`consumeCommands` consumer loop); `internal/kafka` 패키지 (`kafka.SourceFromHeaders` 관찰 전용 가드); `internal/job.Dispatcher` (target_agent_id·valid_until 판정, 동기 처리); `internal/job.ScriptRunner` (exec, timeout, CapBuffer); `internal/job.CapBuffer`; `internal/jobresult.Publisher` (job_type 분기 — SCRIPT_JOB → `result-topic-job` 발행); `internal/audit.Publisher` (JOB_EXECUTED 발행); `internal/config.Config` (`KafkaTopicCommands`, `KafkaTopicResultJob`, `KafkaTopicResultLog`)
- `infra`: `docker-compose.yml` kafka-init — `command-topic`·`result-topic-job`·`result-topic-log` 사전 생성

## 5. 흐름 따라가기 (hop-by-hop)

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1 | `hub:api.ScheduleController` 또는 `hub:web.UiController` | `ScheduleController.register` / `UiController.submitSchedule` | - | POST `/schedules` 또는 POST `/ui/schedules` |
| 2 | `hub:scheduler.ScheduleService` | `ScheduleService.register` → `scheduleQuartzJob` | - | `INFO registered schedule: schedule_id=... cron=...` |
| 3 | `hub:scheduler.ScheduleTriggerJob` | `ScheduleTriggerJob.execute` | - | Quartz cron fire; `execution_id` = UUIDv4; `valid_until` = issued + interval * 0.9 |
| 4 | `hub:producer.CommandPublisher` | `CommandPublisher.publish(Command, null)` | `command-topic` | envelope 헤더 4종 첨부(x-message-id/x-message-version/x-source="monitoring-be"/x-trace-id 생략); key=target_agent_id; `INFO COMMAND sent: ...` |
| 5 | `script-agent:cmd/agent/main` | `consumeCommands` → `kafka.SourceFromHeaders` (관찰만) | `command-topic` | x-source 관찰 전용 DEBUG 로깅; fetch 실패 시 warn + 재시도 |
| 6 | `script-agent:internal/job.Dispatcher` | `Dispatcher.Dispatch` | - | target_agent_id 불일치 → DEBUG skip; valid_until 만료 → DEBUG skip; 알 수 없는 job_type → ERROR drop |
| 7 | `script-agent:internal/job.ScriptRunner` | `ScriptRunner.Run` → `exec.CommandContext` | - | timeout_seconds > 0 → `context.WithTimeout` 적용; stdout/stderr → `CapBuffer`(output_cap_bytes); exit 0 → SUCCESS, deadline → TIMEOUT, 그 외 → FAIL |
| 8 | `script-agent:internal/jobresult.Publisher` | `jobresult.Publisher.Publish` (job_type=SCRIPT_JOB 분기) | `result-topic-job` | envelope 헤더 3종(x-message-id/x-message-version/x-source="script-agent"); key=agentID; env `KAFKA_TOPIC_RESULT_JOB` |
| 9 | `script-agent:internal/audit.Publisher` | `audit.Publisher.JobExecuted` | `audit-topic` | JOB_EXECUTED 이벤트(execution_id/schedule_id/job_id/job_type/exit_code); occurred_at=result.FinishedAt |
| 10 | `hub:ingest.jobresult.JobResultConsumer` | `JobResultConsumer.consume` → `EnvelopeHeaders.inspectSource` | `result-topic-job` | 멀티토픽 listener(`@KafkaListener(topics={RESULT_JOB, RESULT_LOG})`); x-source 관찰 전용 가드; group=`hub-job-result-consumer`; `INFO JOB_RESULT received: execution_id=... status=...` |
| 11 | `hub:store.JobResultRingBuffer` | `JobResultRingBuffer.add` | - | CircularFifoQueue(capacity=`hub.job.ring-buffer-size`, 기본 100); 두 토픽(RESULT_JOB/RESULT_LOG) 공용; capacity 초과 시 오래된 항목 자동 evict |
| 12 | `hub:web.UiController` | `UiController.index` | - | `jobResultBuffer.snapshot()` → reversed → UI `/` job-results 패널 렌더링 |

**발행 순서 보장**: `Dispatcher`는 `jobresult.Publisher.Publish` 성공 후 `audit.Publisher.JobExecuted`를 호출한다. results 발행 실패 시 audit 시도 없이 즉시 fail-fast 반환 — "audit 있는데 결과 없음" 비대칭 방지. results 성공 후 audit 실패 시 재기동에서 results 중복 가능(execution_id로 dedup 필요 — 데모 단계 미구현).

**x-source 가드**: hub `EnvelopeHeaders.inspectSource()`는 관찰 전용(throw/reject 없음). script-agent `kafka.SourceFromHeaders()`도 값 추출만 수행. 미지값·부재 시에도 처리 흐름 무변.

**Quartz misfire 정책**: `MISFIRE_INSTRUCTION_DO_NOTHING` — hub 재시작 시 누락된 fire는 실행하지 않고 흘려보냄. hub는 Quartz RAMJobStore(in-memory) 사용이므로 재시작 시 모든 schedule 소멸.

**멀티토픽 listener**: `JobResultConsumer`는 `result-topic-job`과 `result-topic-log` 두 토픽을 단일 `@KafkaListener`로 구독한다. `JobResultRingBuffer`는 두 토픽 결과를 공용 단일 ring buffer에 적재한다.

## 6. 흐름 다이어그램

```
사용자 (POST /schedules 또는 UI 폼)
    │
    ▼
hub: ScheduleService.register()
    │  JobDefinition + ScheduleDefinition → in-memory registry
    │  Quartz CronTrigger 등록 (MISFIRE_DO_NOTHING)
    ▼
hub: ScheduleTriggerJob.execute()  [cron fire마다]
    │  execution_id=UUIDv4, valid_until=issued+interval*0.9
    ▼
hub: CommandPublisher.publish(Command, null)
    │  envelope 헤더 4종 (x-source="monitoring-be", x-trace-id 생략)
    │  key = target_agent_id
    ▼
Kafka: command-topic  (JSON Command payload)
    │  group=<agentID>  key-based ordering per agent
    ▼
script-agent: consumeCommands → Dispatcher.Dispatch
    │  SourceFromHeaders() 관찰(DEBUG), target_agent_id 일치, valid_until 미만
    ▼
script-agent: ScriptRunner.Run → exec.CommandContext
    │  timeout_seconds → context.WithTimeout → TIMEOUT if deadline
    │  stdout/stderr → CapBuffer(output_cap_bytes) → truncated=true if exceeded
    │  exit 0 → SUCCESS / 비0 → FAIL
    ▼
script-agent: jobresult.Publisher.Publish  →  Kafka: result-topic-job  (SCRIPT_JOB 전용)
script-agent: audit.Publisher.JobExecuted  →  Kafka: audit-topic (JOB_EXECUTED)
    │
    ▼
hub: JobResultConsumer.consume  (@KafkaListener topics={result-topic-job, result-topic-log})
    │  EnvelopeHeaders.inspectSource() 관찰, group=hub-job-result-consumer
    ▼
hub: JobResultRingBuffer.add(JobResult)  [두 토픽 공용]
    ▼
hub UI(/): jobResults 패널 (reversed snapshot)
```

## 7. 검증 방법

> `데모 spec v0.2.1`은 **Phase 0 회귀 검증 기준**이며 도달 목표 규범이 아니다(규범 = 통합본 / ADR — §3).

- **e2e**: `e2e/results/20260614-164044.md` — PASS 64/0/0
  - §6-T4-A: 라이브 kafka 토픽 목록에 `result-topic-job`·`result-topic-log` 존재, 구명 `job-results` 미생성 확인
  - §6-CMD: hub `/schedules` POST 성공 → `command-topic` 발행 확인(`INFO COMMAND sent:` 로그 실증)
  - §6-LOG: LOG_JOB `JOB_RESULT received` 로그에서 `JobResultConsumer`가 두 토픽을 단일 listener로 수신함을 간접 실증 — hub `[ntainer#2-0-C-1]` 스레드 패턴
  - §7 x-source 가드 회귀: `hub/JobResultConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인`, `script-agent/kafka/envelope.go: SourceFromHeaders() 추가 확인`
  - §8 R-B: `hub/KafkaConfig.Topics.RESULT_JOB = "result-topic-job"` / `hub/KafkaConfig.Topics.RESULT_LOG = "result-topic-log"` / `hub/KafkaConfig.Topics.JOB_RESULTS 구명 상수 제거됨` / `script-agent/config.go: KAFKA_TOPIC_RESULT_JOB default="result-topic-job"` 확인
  - §8 R-A: `hub/CommandPublisher.java: KafkaConfig.Topics.COMMANDS 상수 참조(단일 진실)` 확인
- **단위 테스트**: `hub mvn test` PASS (Tests run: 103, Failures: 0, Errors: 0, Skipped: 4); `script-agent go test ./...` PASS — `JobResultConsumerTest.java` R-C 분기 정확성(SCRIPT_JOB→result-topic-job, LOG_JOB→result-topic-log) 포함

## 8. 미구현·잔여 사항

- **Quartz 스케줄 영속화**: 현재 Quartz RAMJobStore(in-memory). hub 재시작 시 모든 schedule·trigger 소멸. 본개발 영역(JDBCJobStore 도입 검토).
- **execution_id 중복 제거(dedup)**: hub `JobResultConsumer`는 중복 수신 시 dedup 없이 ring buffer에 그대로 적재. audit도 동일. `execution_id` 기반 dedup은 데모 단계 미구현.
- **`JobResultConsumer`에서 `audit-topic` JOB_EXECUTED와의 상관**: `execution_id`로 result-topic-job ↔ JOB_EXECUTED 감사를 상관 가능하나, 현재 ring buffer 스냅샷 join은 UI 렌더 시점 수동. 자동 매칭 로직 미구현.
- **valid_until이 null인 경우**: `nextFireTime`이 null이면(트리거의 마지막 fire) `valid_until = issued + 60초` 고정값 부여. 본개발에서 별도 정책 검토.
- **payload 평면화(후속 Track)**: 현재 `JobResult`는 SCRIPT_JOB·LOG_JOB 공통 구조(ADR #19, 현 단계 유지). 목표 스키마로의 필드 정렬은 후속 Track 작업이며 현재 미구현.

## 9. 최종 검증 기준 (필수)

- **기준 e2e 결과**: `e2e/results/20260614-164044.md` (PASS 64/0/0) — 형제 repo 코드가 실제 동작한 시점 증거. 동적 모드(`--dynamic`) 활성, Docker 데몬 v29.4.3.
- **spec 참조 시점**: §0 기준 meta commit `5c2ef6b4df338cf55b500bf3cd20ee2c381fc67e` (통합본 v0.9 / `adr/0005-topic-naming.md` / `docs/kafka-payloads.md` / `docs/envelope.md`)
- **Phase 0 회귀 기준(데모 spec v0.2.1 — 규범 아닌 회귀 근거)**: §6-CMD command 발행 성공 실증; §7 x-source 가드 회귀 0; §8 R-B 토픽 상수 신명 정합(result-topic-job/log, 구명 JOB_RESULTS 제거); §8 R-A 동작 등가.

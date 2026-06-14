> **이 문서는 기술(descriptive) 문서다 — 코드의 현재 상태를 서술한다. 규범의 답은 통합본(`docs/master-design.md`) / `adr/`에 있다.**

# 기능: LOG_JOB 수집 흐름

## 0. 메타 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 기능 ID | `log-job-collection` | 파일명과 일치 |
| 시나리오 한 줄 | `스케줄 등록 → command-topic → script-agent LOG_JOB 실행(offset 추적·tail-f 스타일) → result-topic-log → hub 수신·표시` | 인덱스 표와 동일 |
| 관여 repo | `hub`, `script-agent`, `infra` | |
| 기준 meta commit | `e7ca16c32b60da8886a0c9a1a8f6594390bcde4c` | 이 문서가 참조한 통합본/`adr/` 등 **spec의 시점**을 고정한다. **형제 repo 코드 시점이 아니다** — 코드가 실제 동작한 시점 증거는 §9의 e2e 결과. 본문 코드 앵커로 쓰지 않는다 |
| 최종 갱신일 | `2026-06-14` | |
| 검증 상태 | `검증됨` | §9 최종 검증 기준과 연동 |

## 1. 기능 개요

사용자가 job_type=LOG_JOB으로 스케줄을 등록하면, 발행·수신 경로(`command-topic` → `result-topic-log`)는 SCRIPT_JOB과 구조적으로 동일하다(`docs/features/script-job-execution.md` §5 hop 1~5, 10~12 참조). 다른 점은 executor 동작과 결과 토픽이다. script-agent의 `LogRunner`는 지정된 로그 파일을 읽되, **첫 실행은 파일 끝부터** 시작해 이후 실행마다 마지막으로 읽은 offset을 `LOG_STATE_DIR` 아래 `<job_id>.json`에 영속해 이어 읽는다. rotation(file_id 변경) 또는 truncate(size 감소) 감지 시 자동으로 offset 0으로 리셋한다. 패턴 매칭된 라인 수와 최대 10개 샘플을 `LogResult`에 담아 `result-topic-log` 토픽으로 발행한다.

## 2. 사용자 시나리오

- 사용자가 POST `/schedules` 또는 UI 폼으로 job_type=LOG_JOB, log_path/pattern/encoding, target_agent_id, cron_expression을 제출한다.
- hub `ScheduleService`가 Quartz `CronTrigger`를 등록한다. cron fire마다 `ScheduleTriggerJob`이 명령을 발행한다(동작은 `script-job-execution.md` §5 hop 1~4와 동일).
- script-agent `consumeCommands`가 명령을 fetch → `Dispatcher.Dispatch` → `LogRunner.Run` 호출.
- **첫 실행**(file_state 없음): 파일 끝 offset에서 시작. matched=0, samples=[].
- **이후 실행**: `LOG_STATE_DIR/<job_id>.json`에서 `{offset, size, file_id}` 로드 → rotation/truncate 판정 → 해당 offset부터 라인 스캔 → regex 매칭.
- **rotation 감지**: file_id(POSIX inode / Windows file index)가 변경됐으면 offset 0(새 파일 처음부터). in-place truncate(currentSize < state.Offset)면 offset 0.
- 스캔 완료 후 새 offset을 `<job_id>.json`에 atomic write-then-rename으로 저장한다.
- `jobresult.Publisher`가 job_type=LOG_JOB 분기로 `LogResult{matched_lines_count, sample_lines(최대 10)}` 담긴 `JobResult`를 `result-topic-log`에 발행한다.
- `audit.Publisher`가 JOB_EXECUTED를 `audit-topic`으로 발행한다.
- hub `JobResultConsumer`가 결과를 수신·적재하고 UI(/)에 표시한다.

## 3. 관련 spec 참조 (규범 문서 포인터)

이 레이어는 결정하지 않고 포인터만 단다.

- 통합본(`docs/master-design.md`): `§6.2` Job 실행 흐름 — LOG_JOB 명령·file_state는 Agent local(ADR #14), `§6.3` 로그 수집 흐름 — LOG_JOB occurred_at 추가(ADR #10), `§6.6` JOB_EXECUTED 감사 채널(ADR #3). ※ 종전 `§5.x` 포인터는 데모 spec 절 번호의 오기였음 — 데모 spec 포인터는 아래 행이 따로 담당
- 데모 spec v0.2.1: `§5.1.2` LOG_JOB, `§5.2.2` LogResult — **Phase 0 회귀 기준**, 통합본과 동일 ground truth 아님
- ADR: `adr/0005-topic-naming.md` — `command-topic` 최종 논리명 확정(T4-1 재명명 완료). `result-topic-log`는 T4-2 result-topic 분리(result-topic 분리(T4-2)) 완료 후의 **현행 물리명**이며 LOG_JOB 결과 전용 토픽이다. payload 구조(`JobResult`)는 현 단계 공통 유지(ADR #19 — 평면 목표 스키마로의 정렬은 후속 Track).
- 페이로드/봉투: `docs/kafka-payloads.md` `command-topic` 절·`result-topic-log` 절; `docs/envelope.md` §2.2~§2.3

## 4. 관여 repo·컴포넌트

발행·수신 경로(hub Quartz/CommandPublisher/JobResultConsumer/JobResultRingBuffer/UiController)는 `script-job-execution.md` §4와 동일. LOG_JOB 특유 컴포넌트:

- `script-agent`: `internal/job.LogRunner` (LOG_JOB executor, file_state 추적); `internal/job.FileState` / `loadFileState` / `saveFileState` / `decideReadFrom` (state 영속·rotation 판정); `internal/job.scanForPattern` (bufio.Scanner + regex 라인 매칭); `internal/config.Config.LogStateDir` (`LOG_STATE_DIR` env, 기본 `./.agent_state`); `internal/jobresult.Publisher` (job_type=LOG_JOB 분기 → `result-topic-log` 발행, env `KAFKA_TOPIC_RESULT_LOG`)
- `infra`: `docker-compose.yml` kafka-init — `command-topic`·`result-topic-job`·`result-topic-log` 사전 생성 (SCRIPT_JOB과 공용 kafka-init 루프)

## 5. 흐름 따라가기 (hop-by-hop)

hop 1~5(스케줄 등록 → command-topic 발행 → script-agent fetch)와 hop 10~12(result-topic-log 수신 → hub 표시)는 `script-job-execution.md` §5와 구조가 동일하다. LOG_JOB 특유 부분만 아래에 기술한다.

| 단계 | 컴포넌트 / repo | 진입점 식별자 | 토픽 | 관찰 지점(로그/상태) |
|---|---|---|---|---|
| 1~5 | (SCRIPT_JOB과 동일) | `script-job-execution.md` §5 참조 | `command-topic` | — |
| 6 | `script-agent:internal/job.Dispatcher` | `Dispatcher.Dispatch` → `LogRunner.Run` | - | target_agent_id 일치, valid_until 미만 확인 후 LogRunner 호출 |
| 7a | `script-agent:internal/job.LogRunner` | `LogRunner.Run` → `loadFileState` | - | `LOG_STATE_DIR/<job_id>.json` 로드; 파일 없음 → hasState=false |
| 7b | `script-agent:internal/job.LogRunner` | `decideReadFrom` | - | hasState=false → currentSize(파일 끝); file_id 변경 또는 truncate → 0; 그 외 → state.Offset |
| 7c | `script-agent:internal/job.LogRunner` | `scanForPattern` | - | bufio.Scanner 라인 순회; regex 매칭 → matched++, sample(최대 10); ctx 취소 시 부분 결과 |
| 7d | `script-agent:internal/job.LogRunner` | `saveFileState` | - | write-temp-then-rename atomic; `{offset, size, file_id}` JSON; 실패 시 결과는 유효, 다음 실행에서 첫 실행으로 재처리 |
| 8 | `script-agent:internal/jobresult.Publisher` | `jobresult.Publisher.Publish` (job_type=LOG_JOB 분기) | `result-topic-log` | `JobResult.Log = &LogResult{matched_lines_count, sample_lines}`; envelope **4종 규약** 헤더(x-trace-id는 trace 부재 시 생략, command hop과 동일 패턴); key=agentID; env `KAFKA_TOPIC_RESULT_LOG` |
| 9 | `script-agent:internal/audit.Publisher` | `audit.Publisher.JobExecuted` | `audit-topic` | JOB_EXECUTED(execution_id/schedule_id/job_id/job_type="LOG_JOB") |
| 10~12 | (SCRIPT_JOB과 동일) | `script-job-execution.md` §5 참조 | `result-topic-log` | `JobResultConsumer`(멀티토픽 listener) → `JobResultRingBuffer`(공용) → UI 패널 |

**rotation 감지 로직**: `decideReadFrom`은 OS에 의존하지 않는 순수 함수로 분리되어 단위 테스트된다. file_id는 플랫폼별로 `internal/job/filestate_unix.go`(inode) / `internal/job/filestate_windows.go`(file index)로 분기해 추출한다.

**state 저장 실패 처리**: `saveFileState` 실패는 `LogResult` 발행을 막지 않는다. 다음 실행에서 file_state 없음(hasState=false)으로 처리되어 파일 끝부터 재시작한다(일부 라인 재카운트 가능).

**encoding**: UTF-8만 지원(데모). spec 필드는 있지만 `strings.EqualFold(spec.Encoding, "UTF-8")` 이외의 값이면 FAIL 반환.

**멀티토픽 수신**: hub `JobResultConsumer`는 `result-topic-job`과 `result-topic-log` 두 토픽을 단일 `@KafkaListener`로 구독하며 `JobResultRingBuffer`는 두 토픽 결과를 공용으로 적재한다.

## 6. 흐름 다이어그램

```
사용자 (POST /schedules, job_type=LOG_JOB)
    │
    ▼
hub: ScheduleService → Quartz CronTrigger → ScheduleTriggerJob
    │  [cron fire마다] execution_id, valid_until 산출
    ▼
hub: CommandPublisher.publish()  →  Kafka: command-topic
    │  envelope 헤더 4종, key=target_agent_id
    ▼
script-agent: consumeCommands → Dispatcher.Dispatch → LogRunner.Run
    │
    ├─ loadFileState(LOG_STATE_DIR/<job_id>.json)
    │     └─ 없음 → hasState=false (파일 끝부터 시작)
    │     └─ 있음 → {offset, size, file_id}
    │
    ├─ decideReadFrom
    │     file_id 변경 → offset 0 (rotation)
    │     size < state.Offset → offset 0 (truncate)
    │     그 외 → state.Offset
    │
    ├─ scanForPattern (bufio.Scanner + regex)
    │     matched++, samples(최대 10줄)
    │
    └─ saveFileState(새 {offset, size, file_id}) — atomic
    │
    ▼
script-agent: jobresult.Publisher (job_type=LOG_JOB 분기)
    →  Kafka: result-topic-log  (LOG_JOB 전용)
    │  LogResult{matched_lines_count, sample_lines}
script-agent: audit.Publisher  →  Kafka: audit-topic (JOB_EXECUTED)
    │
    ▼
hub: JobResultConsumer  (@KafkaListener topics={result-topic-job, result-topic-log})
    → JobResultRingBuffer(공용) → UI(/) job-results 패널
```

## 7. 검증 방법

> `데모 spec v0.2.1`은 **Phase 0 회귀 검증 기준**이며 도달 목표 규범이 아니다(규범 = 통합본 / ADR — §3).

- **e2e**: `e2e/results/20260614-164044.md` — PASS 64/0/0
  - §6-LOG: 임시 로그 파일 생성 → LOG_JOB 스케줄 등록(cron=0/5) → 첫 COMMAND 발행(파일 끝 offset 저장) → 매칭 라인 append → hub `JOB_RESULT received: execution_id=... agent_id=... job_type=LOG_JOB status=SUCCESS` 수신 실증 — LogRunner 동적 실행(log_path/pattern/offset 추적 사이클) 전체 경로 검증됨. hub 로그 스레드 `[ntainer#2-0-C-1]`에서 수신 확인.
  - §6-T4-A: 라이브 kafka 토픽 목록에 `result-topic-log` 존재(`result-topic-job result-topic-log` 함께 생성됨), 구명 `job-results` 미생성 확인.
  - §6-CMD: hub `/schedules` POST 성공 → `command-topic` 발행 확인. SCRIPT_JOB과 동일 발행·수신 경로 검증됨.
  - §8 R-B: `hub/KafkaConfig.Topics.RESULT_LOG = "result-topic-log"` / `hub/KafkaConfig.Topics.JOB_RESULTS 구명 상수 제거됨` / `script-agent config.go: KAFKA_TOPIC_RESULT_LOG default="result-topic-log"` 확인.
  - §7 x-source 가드 회귀: `JobResultConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인`.
- **단위 테스트**: `hub mvn test` PASS (Tests run: 103); `script-agent go test ./...` PASS — `internal/job` 패키지의 `LogRunner`, `FileState`, `decideReadFrom`, `scanForPattern` 단위 테스트 포함(`internal/job/log_test.go`, `internal/job/filestate_test.go`). `JobResultConsumerTest.java` R-C 분기 정확성(LOG_JOB→result-topic-log) 포함.

## 8. 미구현·잔여 사항

- **encoding UTF-8 전용**: 데모 단계에서 UTF-8 이외는 FAIL. 다중 인코딩 지원은 통합본 영역.
- **샘플 상한 하드코딩**: `logSampleLinesMax = 10`으로 고정. 설정화 미구현.
- **Quartz 스케줄 영속화**: SCRIPT_JOB과 동일 — RAMJobStore, 재시작 시 소멸.
- **LOG_STATE_DIR 미생성 시 실패**: state 저장 실패는 비치명적으로 처리되나, state 디렉토리가 생성되지 않아도 발행은 계속됨. 디렉토리 생성 실패 시 매 실행이 첫 실행으로 처리됨.
- **payload 평면화(후속 Track)**: 현재 `JobResult`는 SCRIPT_JOB·LOG_JOB 공통 구조(ADR #19, 현 단계 유지). 목표 스키마로의 필드 정렬은 후속 Track 작업이며 현재 미구현.

## 9. 최종 검증 기준 (필수)

- **기준 e2e 결과**: `e2e/results/20260614-164044.md` (PASS 64/0/0) — 형제 repo 코드가 실제 동작한 시점 증거. 동적 모드(`--dynamic`) 활성, Docker 데몬 v29.4.3.
- **spec 참조 시점**: §0 기준 meta commit `e7ca16c32b60da8886a0c9a1a8f6594390bcde4c` (master-design(통합본, ADR#19·T4-2 반영) / `adr/0005-topic-naming.md` / `adr/0019-result-payload-staging.md` / `docs/kafka-payloads.md` / `docs/envelope.md`)
- **Phase 0 회귀 기준(데모 spec v0.2.1 — 규범 아닌 회귀 근거)**: §6-LOG LOG_JOB executor 동적 실행 실증(log_path/pattern/offset 추적 사이클, JOB_RESULT status=SUCCESS); §6-CMD command-topic 경로 실증; §8 R-B 토픽 상수 신명 정합(result-topic-log, 구명 JOB_RESULTS 제거); §4 단위 테스트 PASS(LogRunner/FileState/decideReadFrom 포함).

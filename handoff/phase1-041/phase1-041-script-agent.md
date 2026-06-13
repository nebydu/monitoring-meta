# 작업 spec — phase1-041-script-agent (T4-2 result-topic 분리: script-agent)

> 이 handoff는 script-agent 세션이 받아 실행한다. 단일 `job-results` 발행을 **job_type 분기 발행**(SCRIPT_JOB→`result-topic-job`, LOG_JOB→`result-topic-log`)으로 바꾸는 T4-2의 **script-agent(producer) 몫**이다. **실행 순서 2순위** — infra(2토픽 생성) 후 hub와 **동시 컷오버**. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-041-script-agent` (T4-2) |
| 대상 repo | `script-agent` (Go) |
| 기준 monitoring-meta commit | 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인 |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted** / `docs/kafka-payloads.md` / 통합본 §6.9.2 항목1·§6.9.5 / 영향 분석 `handoff/phase1-041/phase1-041-000-impact.md` §2①·§4 |
| 작성일 | 2026-06-13 |
| 실행 순서 | **2순위** (infra 1순위 후, hub와 동시 컷오버) |

## 2. 분리 매핑 — producer 분기 발행

| job_type (현행 코드 enum `internal/model/types.go`) | 발행 토픽 (규칙 B) |
|---|---|
| `SCRIPT_JOB` (`model.JobTypeScript`) | `result-topic-job` |
| `LOG_JOB` (`model.JobTypeLog`) | `result-topic-log` |

> **현행 enum 사실 확정**: script-agent의 job_type은 `SCRIPT_JOB`/`LOG_JOB` **2종뿐**이다(`types.go:14-17`). SQL 작업 타입은 **현행 코드에 없다.** impact 표·통합본/kafka-payloads의 "SHELL/SQL"은 목표 spec(Phase 1+)의 job_type 명명이며, **§5.1=A(토픽만 분리, payload 현행 유지)에서는 분기 기준도 현행 enum(`SCRIPT_JOB`/`LOG_JOB`)을 그대로 쓴다.** job_type 값 enum 자체를 SHELL/SQL로 바꾸지 마라 — 그건 payload 정렬 후속 Track(ADR#10/#14/T3-7)이다.

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — 분기 발행)

**현행**(`internal/jobresult/publisher.go`): `Publisher{writer, topic}`가 단일 `topic`으로 무분기 발행. 생성자 `NewPublisher(writer, cfg.KafkaTopicJobResults)`(`cmd/agent/main.go:78`).

**변경**: `result.JobType`에 따라 발행 토픽을 골라야 한다.
- `JobTypeScript` → `KafkaTopicResultJob`
- `JobTypeLog` → `KafkaTopicResultLog`

**분기 위치 = 구현 선택(위임)** — impact §2① 후보 중 택1:
- (a) `Publisher` 내부에서 `result.JobType`으로 토픽 선택(생성자에 2토픽 주입). dispatcher 호출부 시그니처(`results.Publish(ctx, result)`) 불변 — **변경 표면 최소, 권장**.
- (b) `Publisher` 2개 인스턴스 + dispatcher 라우팅 — dispatcher fail-fast/발행순서 불변식을 건드릴 위험이 있어 (a) 대비 주의.
- (c) config map으로 토픽 선택.
- **단 어느 위치든 `Publish`가 `key=result.AgentID`·envelope `BuildHeaders` 발행을 현행과 동일하게 유지해야 한다**(`publisher.go:31-33`).

### 3.2 config — env 키 2키 신설 (§5.5 확정)

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `internal/config/config.go:57` | `KafkaTopicJobResults: getenv("KAFKA_TOPIC_JOB_RESULTS", "job-results")` | **삭제**(구 키 폐기) |
| (신설) | — | `KafkaTopicResultJob: getenv("KAFKA_TOPIC_RESULT_JOB", "result-topic-job")` |
| (신설) | — | `KafkaTopicResultLog: getenv("KAFKA_TOPIC_RESULT_LOG", "result-topic-log")` |

- `Config` 구조체 필드 `KafkaTopicJobResults`를 `KafkaTopicResultJob`/`KafkaTopicResultLog` 2개로 교체.
- 구 env 키 `KAFKA_TOPIC_JOB_RESULTS` **폐기**(§5.5 = 2키 신설·구 키 폐기). 외부 override 호환을 위한 잔존 불요(폐쇄망 클린 컷오버).
- `cmd/agent/main.go:78` `NewPublisher(...)` 생성을 분기 위치(3.1) 선택에 맞춰 2토픽 주입으로 갱신.

### 3.3 payload — 현행 `JobResult` 구조 유지 (§5.1=A)

- `internal/model/result.go`의 `JobResult`(`script *ScriptResult`/`log *LogResult` 중첩, `status: SUCCESS|FAIL|TIMEOUT`)를 **그대로** 둔다. 같은 struct를 두 토픽에 실어 보낸다.
- payload 필드 정렬(평면 exit_code/stdout/metrics, occurred_at=ADR#10, file_state=ADR#14, status 소문자, stdout_ref)은 **T4-2 범위 밖 — 후속 Track.** 이번에 손대지 마라.

### 3.4 dispatcher 불변식 보존 (변경 아님 — 보존 확인)

- `internal/job/dispatcher.go:134-148`의 **"results 먼저 → audit 나중 / results 실패 시 audit skip" fail-fast 순서**(데모 spec §5.2 회귀 앵커)는 분기 발행 후에도 **동일**해야 한다. 분기는 "어느 results 토픽인가"만 바꾸고 "results→audit 순서"는 불변.
- `d.results.Publish(ctx, result)` 호출 자체는 (a) 방식이면 시그니처 불변. (b) 방식이면 dispatcher가 라우팅하되 이 순서를 깨면 안 됨.

### 3.5 테스트/문서 동기화 (이번 handoff 포함)

- `internal/job/dispatcher_test.go`(160·185·204·206행 등)의 `job-results` 문자열(주석/로그)은 토픽 단언이 아니나 drift 방지로 `result-topic-job`/`result-topic-log`로 정리.
- `internal/jobresult/publisher.go:1-2,14` 패키지 godoc("job-results 토픽으로 …") 갱신.
- `internal/model/types.go:10`·`result.go:5` 등 godoc의 `job-results` → 신규 2토픽 표기.
- `README.md`·`.claude/` 주석의 `job-results`/`KAFKA_TOPIC_JOB_RESULTS` → 신규 토픽/2키로 동기화.
- repo 전체 `job-results`·`KAFKA_TOPIC_JOB_RESULTS` 문자열 잔존 0(R-B 완전성).
- **분기 정확성 단위 테스트(R-C 근거)**: SCRIPT_JOB 결과가 `result-topic-job`으로, LOG_JOB 결과가 `result-topic-log`으로 발행되는지(오분류 0) 검증하는 테스트를 권장(분기 위치에 맞춰 publisher 또는 dispatcher 레벨).

## 4. 적용 결정 (사람 확정 2026-06-13 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| payload 경계 (§5.1) | **옵션 A — 토픽만 분리.** payload class(`model.JobResult`) 현행 유지, 필드 정렬은 후속 Track. |
| 분기 발행 (§5.2) | producer가 job_type(`SCRIPT_JOB`/`LOG_JOB`)으로 토픽 선택. 분기 위치는 구현 선택(위임). |
| env 키 (§5.5) | **2키 신설**(`KAFKA_TOPIC_RESULT_JOB`/`KAFKA_TOPIC_RESULT_LOG`), 구 `KAFKA_TOPIC_JOB_RESULTS` 폐기. |
| 컷오버 방식 (§5.3) | **동시 컷오버** — infra 토픽 생성 후 hub/script-agent 같은 윈도우. 이중 발행 없음. |
| 구 토픽 처리 (§5.4) | 구 `job-results` 제거(infra). script-agent는 그 토픽으로 발행 안 함. |
| 회귀 0 정의 (§5.6) | R-A(동작 등가)+R-B(분리 완전성)+R-C(분기 정확성) 병행. |

## 5. DoD / 검증 (완료 조건)

- [ ] producer가 `SCRIPT_JOB`→`result-topic-job` / `LOG_JOB`→`result-topic-log` 분기 발행. `job-results`로 발행 없음.
- [ ] `key=result.AgentID`·envelope `BuildHeaders` 발행 현행과 동일(분리 무관 불변).
- [ ] `config.go`에 `KAFKA_TOPIC_RESULT_JOB`(default `result-topic-job`)·`KAFKA_TOPIC_RESULT_LOG`(default `result-topic-log`) 2키. 구 `KAFKA_TOPIC_JOB_RESULTS` 폐기.
- [ ] `JobResult` payload 구조 현행 유지(필드·중첩·status enum 무변경).
- [ ] dispatcher results→audit fail-fast 순서 불변(데모 §5.2).
- [ ] `go build ./...` / `go test ./...` 그린. 분기 정확성 테스트(R-C) 통과.
- [ ] README·주석 `job-results`/`KAFKA_TOPIC_JOB_RESULTS` 잔존 0.
- [ ] 동결 데모 spec·무관 파일 변경 없음. heartbeats·commands·audit 발행 경로 무변경.

## 6. 가드 (공통 — impact §6.2)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.**
- dispatcher의 results 먼저→audit 나중 / results 실패 시 audit skip fail-fast 순서 불변식 보존.
- key=`agent_id`·envelope 4종은 분리와 무관하게 동일 — 건드리지 말 것.
- payload는 §5.1=A로 현행 `JobResult` 유지 — 필드 정렬/status 소문자/occurred_at/file_state/metrics/stdout_ref는 후속 Track(이번 금지).
- 분리는 Phase 1 **forward 변경**(Phase 0 회귀 아님).
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행** — script-agent 세션이 직접 e2e 돌리지 않는다(단 `go test`는 script-agent가 돌린다).

## 7. 실패 시 롤백 경로 (동시 컷오버 실패 대비)

동시 컷오버(infra+hub+script-agent 같은 윈도우)가 실패하면:
- script-agent 단독 롤백: `Publisher`를 단일 토픽 무분기 발행으로 되돌리고, `config.go`를 `KafkaTopicJobResults: getenv("KAFKA_TOPIC_JOB_RESULTS", "job-results")` 단일 키로 복귀, `main.go:78` `NewPublisher(writer, cfg.KafkaTopicJobResults)` 복원 → 구 `job-results`로 재발행.
- **infra(구 `job-results` 재생성)·hub(구 토픽 재구독)도 같은 윈도우에서 함께 롤백해야 단절 해소.** script-agent만 단독 롤백하면 안 됨.
- 폐쇄망 클린 재기동이라 잔류 offset 정리 불요.

## 8. 미결정 사안

- 없음. §5 결정 4건 사람 확정 완료(2026-06-13). 통합본 13장 Open question·미결 ADR 저촉 없음(`adr/0005` Accepted, D-4(1)/D-4(2)/D-5 RESOLVED).

## 9. meta 복귀 게이트 (이 handoff 단독으로 작업을 닫지 않는다)

script-agent 구현 완료 후 형제 repo 3곳 구현 + meta e2e 60/0/0(R-A+R-B+R-C, §6-LOG 보존) 통과 후 **monitoring-meta 세션으로 복귀**한다. meta가 닫을 계약 문서(형제 repo는 닫지 않음):
- (i) `docs/kafka-payloads.md` 매핑표 상태("T4-2 잔여"→"일치") + result-topic-job/log 절 "현행 물리명" 갱신
- (ii) 통합본 §6.9.5·§6.9.2 항목1·§4.4.1 상태 반영
- (iii) ROADMAP §13 T4-2=DONE·T4-5=DONE·acceptance_evidence 기록
- (iv) spec-sync 재검사
- (v) features 2문서(script-job-execution.md·log-job-collection.md) 보완(feature-doc-writer)

## 10. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["분기 발행 위치 / config 2키 / payload 유지 / dispatcher 순서 보존 / 분기 정확성 테스트 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

# 작업 spec — phase1-041-hub (T4-2 result-topic 분리: hub)

> 이 handoff는 hub 세션이 받아 실행한다. 단일 `job-results` 구독을 **2토픽 구독**(`result-topic-job` + `result-topic-log`)으로 바꾸는 T4-2의 **hub(consumer) 몫**이다. **실행 순서 2순위** — infra(2토픽 생성) 후 script-agent와 **동시 컷오버**. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-041-hub` (T4-2) |
| 대상 repo | `hub` (Java/Spring) |
| 기준 monitoring-meta commit | 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인 |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted** / `docs/kafka-payloads.md` / 통합본 §6.9.2 항목1·§6.9.5 / 영향 분석 `handoff/phase1-041/phase1-041-000-impact.md` §2③·§2④·§4 |
| 작성일 | 2026-06-13 |
| 실행 순서 | **2순위** (infra 1순위 후, script-agent와 동시 컷오버) |

## 2. 분리 매핑 — consumer 2토픽 구독

| 발행 토픽 (script-agent 측) | hub 처리 |
|---|---|
| `result-topic-job` (SCRIPT_JOB 결과) | 단일 멀티토픽 listener가 구독 |
| `result-topic-log` (LOG_JOB 결과) | 동일 listener가 구독 |

> **§5.1=A(토픽만 분리)라 payload class가 두 토픽 공통**(현행 `domain.job.JobResult`) → **단일 멀티토픽 listener가 자연**(impact §2③(a) 권장). 토픽별 factory/listener 분리(b)는 payload가 토픽별로 다를 때 필요한데, A에서는 불필요 — 단일 listener로 변경 표면 최소화.

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — 토픽 상수)

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `config/KafkaConfig.java:53` | `public static final String JOB_RESULTS = "job-results";` | **삭제**(구 상수 폐기) |
| (신설) | — | `public static final String RESULT_JOB = "result-topic-job";` |
| (신설) | — | `public static final String RESULT_LOG = "result-topic-log";` |

- 구 `Topics.JOB_RESULTS` 상수를 **폐기**하고 `RESULT_JOB`/`RESULT_LOG` 2개 신설. T4-1 상수(`COMMANDS`/`AUDIT_EVENTS`/`HEARTBEATS`)는 무변경.
- godoc(`:52` "Agent → BE Job 실행 결과")도 2토픽 표기로 갱신.

### 3.2 필수 (런타임 — consumer 멀티토픽 구독)

`ingest/jobresult/JobResultConsumer.java:42-46` 단일 listener를 2토픽 구독으로 변경:

```
@KafkaListener(
        topics = {KafkaConfig.Topics.RESULT_JOB, KafkaConfig.Topics.RESULT_LOG},
        containerFactory = "jobResultListenerFactory",
        groupId = "hub-job-result-consumer"
)
```

- payload class는 현행 `domain.job.JobResult` **공통 유지**(§5.1=A) → factory(`jobResultConsumerFactory`/`jobResultListenerFactory`, `KafkaConfig.java:120-147`)는 **1쌍 그대로 재사용**(payload 타입 동일). factory 2쌍 분리 불요.
- ring buffer(`store.JobResultRingBuffer`) **단일 유지** — 두 토픽 결과를 같은 buffer에 적재(현행 동작 등가, R-A).
- `:50` `EnvelopeHeaders.inspectSource(record.headers(), ...)` 가드 — 토픽 상수 인자가 단일이었으나, 멀티토픽이면 `record.topic()`을 넘기거나 가드 의미를 유지하는 선에서 조정(envelope x-source 가드 동작 불변이 목표). **inspectSource의 동작·로깅 의미를 바꾸지 말 것.**

### 3.3 필수 — `JOB_RESULT received` 로그 포맷 보존 (e2e §6-LOG 의존)

- `JobResultConsumer.consume`의 `log.info("JOB_RESULT received: execution_id={} agent_id={} job_type={} status={}", ...)`(`:59-61`) **포맷 문자열을 그대로 유지**한다. e2e §6-LOG 동적 판정(`run-e2e.sh:949`)이 `JOB_RESULT received...job_type=LOG_JOB...status=SUCCESS`에 의존하므로, consumer가 `result-topic-log`를 구독하고 동일 로그를 찍기만 하면 판정 라인이 보존된다.
- job_type/status는 payload(`result.jobType()`/`result.status()`)에서 그대로 나오므로 분리와 무관(payload 현행 유지). **로그 메시지 문자열을 바꾸지 마라.**

### 3.4 테스트 픽스처 (변경 필요)

| 파일:라인 | 변경 |
|---|---|
| `config/KafkaTopicConstantsRegressionTest.java:54-61` | `jobResultsTopic_remainsJobResults()` 테스트는 **`JOB_RESULTS="job-results"` 유지를 PASS 조건으로 단언** → T4-2로 폐기/교체. `RESULT_JOB`=`result-topic-job`·`RESULT_LOG`=`result-topic-log` 단언으로 **교체**. `:18`·`:21`·`:56` 주석("T4-2 미변경"/"D-5 Open")도 갱신. |
| `config/KafkaTopicConstantsRegressionTest.java:66-73` | `allFourTopicConstantsAreNonNull()` — `JOB_RESULTS` 참조를 `RESULT_JOB`/`RESULT_LOG`로 교체(상수 개수 변경 반영). |
| `config/KafkaConfigDeserializerTest.java:109-136` | `jobResultConsumerFactoryMapsSnakeCasePayloadFully()` — `KafkaConfig.Topics.JOB_RESULTS` 참조(`:136`)를 신규 상수로 교체. **payload 매핑 자체(snake_case→JobResult)는 §5.1=A로 현행 유지**이므로 토픽 상수 참조만 갱신. |
| `ingest/jobresult/JobResultConsumerTest.java:39` | `TOPIC = "job-results"` → 신규 토픽명. **분기 정확성(R-C) 보강 권장**: LOG_JOB payload를 `result-topic-log`로, SCRIPT_JOB payload를 `result-topic-job`로 수신해 ring buffer 적재 + `JOB_RESULT received` 로그가 동일하게 나오는지 검증. |

**오탐 주의 — 변경하지 마라**: `web/UiController.java:26`·`HubApplication.java`·`api/CommandHistoryController.java`·`store/JobResultRingBuffer.java`·`AppProperties.java`·`application.yml:71` 등의 `job-results`는 **godoc/주석/ring buffer 설명**이다(토픽 단언 아님). 3.5에서 문서 동기화로만 정리.

### 3.5 문서/주석 동기화 (이번 handoff 포함)

- `README.md`·`pom.xml`·`application.yml` 주석·Java doc의 `job-results` → `result-topic-job`/`result-topic-log` 동기화.
- `web/index.html` 등 UI 라벨이 "job-results"를 사용자 표시 문자열로 쓰면 토픽명과 무관하므로 표시 의도대로 둘지 hub 재량.
- repo 전체 `job-results`·`JOB_RESULTS` 잔존 0(R-B 완전성, 단 위 오탐 주석은 문서 동기화 대상이지 코드 단언 아님).

### 3.6 group.id / offset (변경 아님 — 인지)

- `groupId="hub-job-result-consumer"` 고정. 동일 group이 신규 2토픽을 구독하며, 새 토픽엔 committed offset이 없어 `auto-offset-reset`(earliest)로 처음부터 읽는다. 폐쇄망 클린 컷오버라 무영향.
- hub에 `NewTopic` 빈 없음 — 토픽 물리 생성은 infra 단독. hub는 토픽 생성 코드 변경 불요.

## 4. 적용 결정 (사람 확정 2026-06-13 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| payload 경계 (§5.1) | **옵션 A — 토픽만 분리.** payload class `domain.job.JobResult` 공통 유지 → 단일 멀티토픽 listener + factory 1쌍 재사용. |
| 소비 구조 (§5.2) | 단일 `@KafkaListener` 2토픽 구독, ring buffer 단일. |
| 컷오버 방식 (§5.3) | **동시 컷오버** — infra 토픽 생성 후 hub/script-agent 같은 윈도우. 이중 구독 없음. |
| 구 토픽 처리 (§5.4) | 구 `JOB_RESULTS` 상수·구독 폐기. infra가 `job-results` 제거. |
| 회귀 0 정의 (§5.6) | R-A(동작 등가)+R-B(분리 완전성)+R-C(분기 정확성) 병행. §6-LOG 로그 포맷 보존. |

## 5. DoD / 검증 (완료 조건)

- [ ] `Topics.RESULT_JOB`=`result-topic-job`·`Topics.RESULT_LOG`=`result-topic-log` 신설, 구 `JOB_RESULTS` 폐기.
- [ ] `JobResultConsumer`가 `{RESULT_JOB, RESULT_LOG}` 2토픽 구독, payload class `JobResult` 공통, ring buffer 단일.
- [ ] `JOB_RESULT received: ... job_type=... status=...` 로그 포맷 **불변**(e2e §6-LOG 의존).
- [ ] `KafkaTopicConstantsRegressionTest`가 신규 2상수를 단언(구 `jobResultsTopic_remainsJobResults` 폐기/교체), `KafkaConfigDeserializerTest`·`JobResultConsumerTest` 신규 토픽 참조로 통과.
- [ ] 분기 정확성(R-C): LOG_JOB→`result-topic-log` 수신, SCRIPT_JOB→`result-topic-job` 수신, 오분류 0 확인(테스트 또는 e2e).
- [ ] `mvn test` 그린. 오탐(UI 라벨/모델 키/godoc) 미변경.
- [ ] README·주석 `job-results` 잔존 0. 동결 데모 spec·무관 파일 변경 없음.

## 6. 가드 (공통 — impact §6.2)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.**
- payload는 §5.1=A로 현행 `domain.job.JobResult` 유지 — 필드 정렬/status 소문자/occurred_at/file_state는 후속 Track(이번 금지).
- `JOB_RESULT received` 로그 포맷 보존(e2e §6-LOG 판정 의존, `run-e2e.sh:949`).
- key=`agent_id`·envelope 4종·`inspectSource` x-source 가드는 분리와 무관하게 동일 — 동작/로깅 의미 바꾸지 말 것.
- 분리는 Phase 1 **forward 변경**(Phase 0 회귀 아님).
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행** — hub 세션이 직접 e2e 돌리지 않는다(단 `mvn test` 단위테스트는 hub가 돌린다).

## 7. 실패 시 롤백 경로 (동시 컷오버 실패 대비)

동시 컷오버(infra+hub+script-agent 같은 윈도우)가 실패하면:
- hub 단독 롤백: `Topics.JOB_RESULTS="job-results"` 상수 복원, `JobResultConsumer`를 단일 `topics=Topics.JOB_RESULTS` 구독으로 되돌리고, 테스트 픽스처(`KafkaTopicConstantsRegressionTest`·`KafkaConfigDeserializerTest`·`JobResultConsumerTest`)를 구 토픽 단언으로 복귀 → 구 `job-results` 재구독.
- **infra(구 `job-results` 재생성)·script-agent(구 토픽 재발행)도 같은 윈도우에서 함께 롤백해야 단절 해소.** hub만 단독 롤백하면 안 됨.
- 폐쇄망 클린 재기동이라 잔류 offset 정리 불요(group이 빈 토픽 earliest로 재시작).

## 8. 미결정 사안

- 없음. §5 결정 4건 사람 확정 완료(2026-06-13). 통합본 13장 Open question·미결 ADR 저촉 없음(`adr/0005` Accepted, D-4(1)/D-4(2)/D-5 RESOLVED).

## 9. meta 복귀 게이트 (이 handoff 단독으로 작업을 닫지 않는다)

hub 구현 완료 후 형제 repo 3곳 구현 + meta e2e 60/0/0(R-A+R-B+R-C, §6-LOG 보존) 통과 후 **monitoring-meta 세션으로 복귀**한다. meta가 닫을 계약 문서(형제 repo는 닫지 않음):
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
  "findings": ["Topics 상수 2신설/구 폐기 / 멀티토픽 listener / 로그 포맷 보존 / 테스트 픽스처 갱신 / 분기 정확성 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

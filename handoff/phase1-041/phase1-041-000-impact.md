# T4-2 result-topic 분리 구현 영향 분석 (phase1-041-000-impact)

> 작성: analyzer (monitoring-meta) / 2026-06-13
> 작업 단위: **result-topic 분리(T4-2) 구현 영향 분석** (Phase 1, Track 4)
> 근거: 통합본 `docs/master-design.md` §6.9.2 항목1(분리=Phase 1 확정)·§6.9.5·§8.3 ADR#5/#6 / `docs/kafka-payloads.md`(result-topic-job·result-topic-log 절·토픽 명명 규칙) / `docs/envelope.md` §4.1 / ROADMAP `docs/phase1/ROADMAP_PHASE1_v0_3.md` §3.1 항목1·§13 T4-2·§17 D-5(RESOLVED 2026-06-07) / 동결 데모 spec v0.2.1 §5.2 / 선례 `handoff/phase1-040/phase1-040-000-impact.md`
> 성격: **분석/후보안 정리만 — 결정은 하지 않는다.** 형제 repo(`../hub`·`../script-agent`·`../infra`)와 `e2e/`는 Read 전용으로만 색출했고 어떤 파일도 수정하지 않았다.
> 선행 결정 상태: 명명 D-4(1) RESOLVED(2026-06-06) / 실행 순서 D-4(2) RESOLVED(2026-06-04) / ADR 소속 D-5 RESOLVED(2026-06-07, ADR#5 간접). **방향·계약 잔여 결정 0 — 단 §2 payload 매핑에서 "기여 계약" 한 건이 추가로 떠올랐다(§5.1 참조).**

---

## 0. 범위 선언 (T4-2 = job-results 1→2 분리)

T4-2는 현행 단일 토픽 `job-results`를 `result-topic-job`(SHELL/SQL 결과) + `result-topic-log`(LOG 결과) 둘로 **분리**하는 작업이다. T4-1(3토픽 단순 재명명, 완료)과 달리 producer 분기 발행 / consumer 분기 소비 / payload 라우팅까지 동반한다.

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) | 분기 기준 |
|---|---|---|
| `job-results` (단일, job_type 분기 없음) | `result-topic-job` | job_type = SHELL_JOB / SQL_JOB (목표 spec: `SHELL`/`SQL`) |
| `job-results` (동일) | `result-topic-log` | job_type = LOG_JOB |

- **분리 자체 = Phase 1 확정**(통합본 §6.9.2 항목1, ROADMAP §3.1 항목1, §13 T4-2 TODO). 선행 결정 전부 RESOLVED.
- **포함**: producer 토픽 분기 발행, consumer 분기 소비, infra 토픽 생성, e2e baseline 재검증, 계약 문서(meta) 갱신.
- **제외(인접 작업이지만 T4-2 밖)**: result payload **필드 구조 자체의 목표 spec 정렬**(occurred_at=ADR#10/T3-7, file_state=ADR#14, stdout 1MB 상한+ref 등) — 별 Track. 단 §2에서 이 인접 작업과 T4-2의 경계가 어디인지가 결정 포인트로 떠오르므로 §5.1에서 명시 정리한다.

> **T4-1 대비 본질적 차이**: T4-1은 "상수 값/​env default 값만 교체"로 끝났다(라우팅 불변). T4-2는 단일 producer가 **job_type으로 토픽을 골라 발행**하고, 단일 consumer가 **2토픽을 구독**하도록 *구조*가 바뀐다. 따라서 T4-1의 핸드오프를 그대로 복제할 수 없고, 분기·매핑·소비 구조는 신규 분석이다(아래 §2·§3).

---

## 1. 현황 (Phase 0 동작) vs 목표 spec

### 1.1 현황 — 단일 토픽, job_type 분기 없음 (전수 색출 결과)

- **script-agent producer**: `internal/jobresult/publisher.go` `Publisher{writer, topic}` — 생성자 `NewPublisher(writer, cfg.KafkaTopicJobResults)`(`cmd/agent/main.go:78`)로 **단일 토픽**을 주입받아, `Publish(ctx, result model.JobResult)`가 job_type 분기 **없이** 모든 결과를 그 토픽으로 발행한다(key=`result.AgentID`, envelope 헤더 `BuildHeaders`).
- **script-agent payload**: `internal/model/result.go` `JobResult`는 **단일 구조**다 — `execution_id`/`schedule_id`/`job_id`/`agent_id`/`job_type`/`status`/`started_at`/`finished_at` + `script *ScriptResult`(nil이면 null) + `log *LogResult`(nil이면 null). job_type별로 둘 중 하나만 채운다. dispatcher(`internal/job/dispatcher.go:135`)가 `results.Publish(ctx, result)`를 호출.
- **script-agent config**: `internal/config/config.go:57` `KafkaTopicJobResults: getenv("KAFKA_TOPIC_JOB_RESULTS", "job-results")` — 단일 env 키/default.
- **hub consumer**: `ingest/jobresult/JobResultConsumer.java` 단일 `@KafkaListener(topics=KafkaConfig.Topics.JOB_RESULTS, containerFactory="jobResultListenerFactory", groupId="hub-job-result-consumer")`. payload class = `domain/job/JobResult`(중첩 record `script`/`log`), ring buffer 적재 + `INFO JOB_RESULT received: ... job_type=... status=...` 로깅.
- **hub config**: `config/KafkaConfig.java:53` `Topics.JOB_RESULTS = "job-results"` 단일 상수 + `jobResultConsumerFactory`/`jobResultListenerFactory` 1쌍.
- **infra**: `docker-compose.yml:64` `for t in command-topic job-results audit-topic heartbeats-topic` — 단일 `job-results` 생성.

> **단일 진실**: script-agent는 토픽이 env 외부화(default `job-results`), hub는 `Topics.JOB_RESULTS` 상수 1개. 분기가 **현재 어디에도 없다**(가설과 일치).

### 1.2 목표 spec (Phase 1 도달 목표)

- `docs/kafka-payloads.md`: `result-topic-job`(평면 `exit_code`/`stdout`(1MB 상한)/`stdout_ref`/`stderr`/`metrics`, job_type=`SHELL|SQL`) + `result-topic-log`(`log_source`/`source_path`/`file_state`/`sample_lines[].{line, occurred_at}`/`line_count`)로 **2토픽 payload를 다르게** 정의.
- 통합본 §6.9.5: `job-results` → `result-topic-job` + `result-topic-log` = (나) 정정 대상, T4-2 잔여. §4.4.1 8토픽 매트릭스·§6.2/§6.3 본문 흐름도 모두 2토픽 전제로 이미 갱신됨.
- `docs/envelope.md` §4.1: `result-topic-job`/`result-topic-log` 둘 다 **envelope 4종 적용 공통 토픽군**, key=`agent_id`. envelope은 토픽명 독립(§4.1 주, D-4(2) 근거) → **분리는 envelope 헤더 규약에 영향 없음**(확인 완료).
- ROADMAP §6 ADR#6 매트릭스: 두 토픽 key=`agent_id` 확정.

> **핵심 위상**: spec/문서 레이어는 이미 2토픽으로 정렬돼 있다(envelope/kafka-payloads/통합본/ROADMAP). T4-2가 남긴 것은 **코드·infra·e2e의 단일 토픽을 spec의 2토픽으로 맞추는 forward 변경**이다. 단 §2에서 보듯 *payload 필드 구조*는 spec(목표)과 코드(현행)가 어긋나 있어, "토픽만 가르면 되는가 vs payload도 spec으로 정렬하는가"의 경계 결정이 필요하다.

---

## 2. 분리 고유 리스크 분석 (T4-1 단순 재명명과 다른 부분)

### ① 분기 발행 — producer가 job_type으로 토픽을 골라야 한다

- **현행**: `jobresult.Publisher`가 단일 `topic` 필드로 무분기 발행.
- **변경 필요**: SHELL/SQL → `result-topic-job` / LOG → `result-topic-log`로 발행 토픽을 골라야 한다.
- **분기 위치 후보**(구현 선택 — 형제 repo 위임 가능, §5.2):
  - (a) `Publisher` 내부에서 `result.JobType`으로 토픽 선택(생성자에 2토픽 주입). dispatcher 호출부(`results.Publish(ctx, result)`) 시그니처 불변 — 변경 표면 최소.
  - (b) `Publisher`를 2개 인스턴스로 분리하고 dispatcher가 job_type으로 라우팅. dispatcher의 fail-fast/​발행 순서 불변식(results 먼저→audit 나중, `dispatcher.go:134-148`)을 건드릴 위험.
  - (c) config에 토픽 2개(`KAFKA_TOPIC_RESULT_JOB`/`KAFKA_TOPIC_RESULT_LOG`) 외부화 + Publisher가 map 선택.
- **불변식 보존 주의**: dispatcher의 "results 먼저, audit 나중 / results 실패 시 audit skip" fail-fast 순서(데모 spec §5.2 회귀 앵커)는 분기 발행 후에도 동일해야 한다. 분기는 "어느 results 토픽인가"만 바꾸고 "results→audit 순서"는 불변.

### ② payload 매핑 — **2분할 정리 (가장 중요한 쟁점)**

현재 단일 `JobResult`(script-agent `model.JobResult` / hub `domain.job.JobResult`)를 2토픽에 어떻게 매핑하나. 프롬프트 지시대로 ⓐ(계약 변경 필요 여부=meta/사람 결정) / ⓑ(계약 내 구현 선택=형제 repo 위임)로 가른다.

**색출로 확인한 사실**: 현행 payload 필드 구조가 kafka-payloads.md 목표 spec과 **이미 다르다**(분리 이전에). 비교:

| 토픽 | kafka-payloads.md 목표 필드 | 현행 코드 `JobResult` 필드 |
|---|---|---|
| `result-topic-job` | `exit_code`/`stdout`(1MB)/`stdout_ref`/`stderr`/`metrics`, `mode`, `status: success\|failed\|timeout\|killed` (평면) | `script: {exit_code, stdout_cap, stderr_cap, truncated}` (중첩), `status: SUCCESS\|FAIL\|TIMEOUT`, `mode` 없음, `metrics`/`stdout_ref` 없음 |
| `result-topic-log` | `log_source`/`source_path`/`file_state`/`sample_lines[].{line, occurred_at}`/`line_count` | `log: {matched_lines_count, sample_lines: []string}` (중첩), `file_state`/`log_source`/`source_path`/`occurred_at` 없음 |

→ ⓐ **계약 변경 필요 여부 (meta/사람 결정 — §5.1)**: "토픽을 2개로 가르되 **payload는 현행 단일 `JobResult` 구조를 두 토픽에 그대로 실어 보내는가**(=토픽만 분리, payload 정렬은 후속 Track) vs **분리하면서 payload도 kafka-payloads.md 목표 필드 구조로 정렬하는가**". 후자는 ADR#10(`occurred_at`, T3-7)·ADR#14(`file_state`)·stdout 1MB+ref·`metrics`·status enum 소문자화 등 **별 Track 작업을 T4-2로 끌어들이는** 큰 계약 변경이다. 이건 `docs/kafka-payloads.md` 계약 해석/​경계 설정이라 analyzer가 결정하지 않고 사람에게 올린다.
  - 참고 정합성: ROADMAP은 T3-7(occurred_at)·payload 정렬을 **별도 Track 항목**으로 추적한다(§12 T3-7). 따라서 "T4-2 = 토픽 분리만 / payload 필드 정렬 = 후속"이 Track 구조상 자연스러우나, **확정은 사람 몫**(추측 금지).

→ ⓑ **계약 내 구현 선택 (형제 repo 위임 — §5.2)**: ⓐ가 "현행 payload 유지하고 토픽만 분리"로 확정될 경우, 같은 `JobResult` 구조를 두 토픽에 어떻게 직렬화/​역직렬화 매핑할지(예: hub가 토픽별 별도 record로 받을지 동일 record로 받을지, script-agent가 동일 struct를 두 토픽에 쓸지)는 코드 구현 선택이라 handoff로 위임 가능.

### ③ 소비 분기 — hub가 2토픽 구독

- **현행**: 단일 `@KafkaListener(topics=JOB_RESULTS, groupId="hub-job-result-consumer")` + factory 1쌍.
- **변경 후보**(구현 선택 — §5.2):
  - (a) **단일 consumer 멀티 토픽**: `topics={Topics.RESULT_JOB, Topics.RESULT_LOG}` 한 listener가 둘 구독. ring buffer 단일 유지, 로깅 동일. 변경 최소. payload class가 두 토픽 공통(현행 `JobResult`)이면 가장 단순.
  - (b) **토픽별 listener/factory 분리**: payload class가 토픽별로 달라지면(ⓐ 계약 변경 채택 시) factory 2쌍 + listener 2개. ring buffer를 분리할지(`result index`/`log index` 대응) 여부도 동반 결정.
- **②ⓐ 결정에 종속**: payload를 토픽별로 다르게 가져가면 (b), 단일 구조 유지면 (a)가 자연. 즉 ③은 ②ⓐ의 함수다.
- **group.id / offset**: 현행 `hub-job-result-consumer` group이 `job-results` offset을 갖고 있다. 새 토픽 2개 구독 시 그 토픽엔 committed offset이 없어 `auto-offset-reset`(T4-1 분석 기준 `earliest`)에 따라 처음부터 읽는다. 클린 컷오버는 무영향, 운영 데이터 보존은 §4 참조.

### ④ e2e §6-LOG 및 baseline 보존 — **T4-1보다 강하게 영향받음**

- **§6-LOG 동적 판정**(`e2e/run-e2e.sh:949`)은 hub 로그 `JOB_RESULT received...job_type=LOG_JOB...status=SUCCESS`에 의존한다. 이 로그는 `JobResultConsumer.consume`이 찍는다 → consumer가 `result-topic-log`를 구독하고 같은 로그를 찍기만 하면 **판정 라인 자체는 보존 가능**(로그 포맷 불변 시).
- **그러나 정적 §8 검증이 `job-results` 문자열을 직접 단언한다** — T4-1과 다른 핵심 차이:
  - `:1214-1217` §8 R-B: `JOB_RESULTS = "job-results"` **유지**를 PASS 조건으로 박음 → 분리 후 **반드시 FAIL**. 신명 단언으로 교체 필요.
  - `:1325-1329` §8 R-A: script-agent `KAFKA_TOPIC_JOB_RESULTS default="job-results"` 유지를 PASS 조건으로 박음 → 동일하게 갱신 필요.
  - `:681,690` §6-T4-A: 라이브 kafka 토픽 목록에서 `job-results` 존재를 신명 4종 중 하나로 검사 → 분리 후 토픽 목록이 바뀜(`result-topic-job`/`result-topic-log` 등장, `job-results` 제거 여부는 §4).
  - `:1266-1277` §8 정적: infra compose 루프 `command-topic.*job-results.*audit-topic.*heartbeats-topic` 패턴 단언 → 신 루프로 갱신 필요.
- **결론**: T4-1은 e2e가 토픽명에 견고했으나(흐름 기반), T4-2는 **e2e 하네스 자체가 `job-results` 문자열을 회귀 앵커로 박아 둔 지점이 4곳** 있어 하네스 갱신 + baseline 재생성이 필수다(meta 소관, §6 3순위). baseline 현재 60/0/0(`e2e/results/20260611-095734.md`).

---

## 3. Phase 0 동결 spec 정합 처리

### 3.1 문제
동결 데모 spec v0.2.1은 §1에서 `job-results` 단일 토픽을, §5.2에서 단일 `JobResult`(script/log 중첩) payload를 **verbatim 동결**한다. 분리 후 코드는 2토픽을 쓴다. 충돌인가?

### 3.2 판단 — 충돌 아님 (forward 변경 vs 회귀 앵커)
- 동결 데모 spec은 "Phase 0 코드가 회귀 없이 지켜야 할 동작 spec(ground truth)"이다(CLAUDE.md §1). 분리는 **Phase 1 forward 변경**이며(통합본 §6.9.2 항목1로 명시된 정정 대상), Phase 0 회귀가 아니다. T4-1 선례(`phase1-040` §3.2)와 동일 논리.
- 따라서 **동결 데모 spec은 그대로 둔다**(수정 후보로 올리지 않음 — CLAUDE.md 강제). 분리 후 토픽/payload의 Phase 1 기준 문서는 `docs/kafka-payloads.md`다.
- 단 T4-1과 다른 점: T4-1은 토픽 *이름*만 바꿔 동작 등가가 자명했으나, T4-2는 데모 spec §5.2 payload 구조(단일 JobResult)가 §2ⓐ 결정에 따라 바뀔 수도 있다. payload까지 손대면 "Phase 0 동작 보존"의 의미가 더 미묘해진다 → §3.3 회귀 정의가 T4-1보다 중요.

### 3.3 회귀 0 기준 후보 (T4-1 R-A/R-B 템플릿을 분리에 맞게 확장)
- **후보 R-A (동작 등가 — 권장)**: 회귀 0 = "토픽 이름이 아니라 *메시지 흐름·payload 내용·envelope·키·발행순서*의 보존". 데모 spec §5.1~§5.2 흐름(command→실행→results→audit JOB_EXECUTED), key=`agent_id`, results 먼저→audit 나중 순서가 분리 후 동일하게 성립하면 회귀 0. §6-LOG(LOG 사이클 status=SUCCESS 수신)가 `result-topic-log` 위에서 동일 성립.
- **후보 R-B (분리 완전성 검사)**: 분리 전/후 매핑(§0 표)을 명시하고 "SHELL/SQL 결과가 `result-topic-job`에, LOG 결과가 `result-topic-log`에 각각 도달 + `job-results`로는 더 이상 발행/​수신 없음"을 검사. T4-1의 "신명 존재/구명 부재"를 분기 버전으로 확장.
- **후보 R-C (분기 정확성 — T4-2 신규)**: job_type 오분류 없음(LOG 결과가 result-topic-job으로 새지 않음, 반대도). §6-LOG가 `result-topic-log`에서 SUCCESS를 받고 `result-topic-job`에선 LOG 결과가 안 나오는지까지 검사하면 분기 정확성 실증.
- **권장**: R-A(회귀 0 정의) + R-B(완전성) + R-C(분기 정확성) 병행. 단 **채택은 사람 확정**(§5).

---

## 4. 마이그레이션 / 운영 쟁점 (분리 고유분 중심)

1. **토픽 물리 생성**: kafka-init이 `result-topic-job`/`result-topic-log`를 새로 생성. 구 `job-results`는 잔존(클린 재기동 무영향). 운영 데이터 보존 필요 시 구 토픽 드레인/​삭제 정책 필요(§5).

2. **동시 컷오버 필수성 (분리는 T4-1보다 단절 리스크가 큼)**: producer가 2토픽 발행으로 가는데 consumer가 아직 `job-results`만 구독하면 **모든 결과 단절**(반대도 동일). T4-1은 1:1 재명명이라 한 토픽만 맞추면 됐지만, T4-2는 producer 분기 + consumer 멀티 구독 + infra 2토픽 생성이 **같은 컷오버 윈도우**에 들어가야 한다. 폐쇄망 클린 재기동이면 동시 컷오버가 단순(권장 후보), 무중단이면 병행 기간(이중 발행/​구독) 필요.

3. **§6-LOG 경로 보존**: LOG 결과가 `result-topic-log`로 가도 hub consumer가 그 토픽을 구독하고 동일 `JOB_RESULT received` 로그를 찍어야 §6-LOG PASS 유지. consumer 분기(③)와 로그 포맷이 핵심 — 로그 메시지 문자열을 바꾸면 e2e 판정 라인(`:949`)도 동반 갱신 필요.

4. **payload 정렬과의 결합 위험(②ⓐ)**: 만약 §2ⓐ에서 "payload도 목표 spec 정렬"을 택하면, status enum(SUCCESS→success), occurred_at(ADR#10), file_state(ADR#14), stdout 1MB+ref 등 **여러 ADR/Track이 T4-2에 합류**해 작업 크기·리스크가 급증하고 데모 spec §5.2 회귀 의미가 흔들린다. "토픽만 분리"로 한정하면 T4-2는 라우팅 변경에 그쳐 리스크 작음. → 경계 결정이 작업 규모를 좌우(§5.1).

5. **실행 순서 (cross-repo)**: 토픽이 없으면 producer/consumer가 못 붙으므로 **infra(2토픽 생성) 먼저 → hub(consumer 분기)+script-agent(producer 분기) 동시 컷오버**가 안전. (auto-create 켜진 환경이면 순서 민감도 낮으나 운영 표준은 명시 생성.)

6. **env 키 정책(script-agent)**: 단일 `KAFKA_TOPIC_JOB_RESULTS`를 2키(`KAFKA_TOPIC_RESULT_JOB`/`..._RESULT_LOG`)로 늘릴지, 아니면 키 1개 유지하고 코드에서 subtype suffix 파생할지 = 정책 결정(§5). T4-1은 "default 값만 교체"였으나 T4-2는 키 개수 자체가 1→2로 늘 수 있어 T4-1보다 결정 폭이 큼.

---

## 5. 결정 필요 사안 (사람 입력 대기)

> **통합본 Open question / 미결 ADR 저촉 여부**: T4-2의 분리 자체·명명·실행 순서·ADR 소속은 모두 RESOLVED(D-4(1)/D-4(2)/D-5)이며 `adr/0005` Accepted다. **통합본 13장 §A~§J Open question이나 미결 ADR에 걸리는 항목은 없다**(blocker 없음). 아래는 계획/​실행/​계약경계 레이어 결정이다. 단 5.1은 계약 문서 해석이 걸려 있어 가장 신중히 사람 입력을 요한다.

### 5.1 payload 매핑 경계 (②ⓐ — 가장 중요, 계약 결정)
**T4-2를 "토픽 분리만"으로 한정하는가, "분리 + payload 목표 spec 정렬"까지 포함하는가.**
- 옵션 A (토픽만 분리, 권장 후보): 현행 단일 `JobResult` 구조를 두 토픽에 그대로 실어 보냄. payload 필드 정렬(occurred_at/file_state/status enum/stdout ref/metrics)은 ADR#10·#14·후속 Track(T3-7 등)으로 분리. T4-2 리스크 최소.
- 옵션 B (분리 + payload 정렬): kafka-payloads.md 목표 필드 구조까지 맞춤. 여러 ADR이 T4-2에 합류 → 대형 작업, 데모 §5.2 회귀 의미 재정의 필요.
- **analyzer는 결정하지 않음.** Track 구조상 A가 자연스러워 보이나(payload 정렬은 별 Track 추적), 계약 문서(`docs/kafka-payloads.md`) 해석이라 사람 확정 필요.

### 5.2 구현 매핑 선택 (②ⓑ·①·③ — 형제 repo 위임 가능)
5.1이 옵션 A로 확정되면 아래는 구현 선택이라 handoff로 위임 가능: producer 분기 위치(Publisher 내부 vs dispatcher vs 2-Publisher), hub 소비 구조(단일 멀티토픽 listener vs 토픽별 factory), ring buffer 단일/​분리. **단 5.1이 B면 ③·payload class가 모두 계약에 종속되므로 위임 전 재분석 필요.**

### 5.3 컷오버 방식
(a) 동시 컷오버(폐쇄망 클린 재기동, 단순, 권장 후보) vs (b) 병행 기간(이중 발행/​구독, 무중단). 분리는 단절 리스크가 T4-1보다 커 동시 컷오버 권장이나 운영 요건 확인 필요.

### 5.4 구 토픽(`job-results`) 처리
분리 후 즉시 삭제 vs 유예. 잔류 메시지 보존 필요 여부. e2e/​데모 클린 재기동은 무영향.

### 5.5 env 키 정책 (script-agent)
`KAFKA_TOPIC_JOB_RESULTS` 1키 유지(코드 파생) vs 2키(`KAFKA_TOPIC_RESULT_JOB`/`..._RESULT_LOG`) 신설. 외부 override 호환·명료성 트레이드오프.

### 5.6 회귀 0 정의 채택
§3.3 R-A 단독 vs R-A+R-B vs R-A+R-B+R-C(분기 정확성). 권장 = 3종 병행(분리 고유 정확성 검사 R-C 포함).

### 5.7 e2e 하네스 갱신 + baseline 재생성
§2-④의 `job-results` 문자열 단언 4곳(`:681/690`, `:1214-1217`, `:1266-1277`, `:1325-1329`) + §6-LOG 판정(`:949`)을 분리 버전으로 갱신하고 새 baseline을 `e2e/results/`에 남길지(권장 — forward 변경이므로 새 PASS 기록 필수). 과거 결과 파일은 불변 보존.

### 5.8 계약 문서 갱신 범위 (meta 복귀 시)
kafka-payloads.md 매핑표 상태컬럼(현재 "T4-2 잔여" → "일치"), 통합본 §6.9.5·§6.9.2 항목1·§4.4.1 상태, ROADMAP T4-2/T4-5=DONE, spec-sync 갱신. 본 작업으로 어디까지 닫을지.

### 5.9 features 문서 보완 시점 (§6 참조)
`docs/features/script-job-execution.md`·`log-job-collection.md`가 `job-results` 토픽 흐름을 서술 — 구현 완료 후 보완 대상. feature-doc-writer 투입 시점.

---

## 6. 핸드오프 분할 제안

> ROADMAP §13 T4-2 owner_repo = hub, script-agent, infra, monitoring-meta. 실행 순서: infra(토픽 생성 1순위) → hub+script-agent(동시 컷오버 2순위) → meta e2e 재검증(3순위).

### 6.1 분할안
| handoff 파일 | 대상 | 단위 | 실행 순서 |
|---|---|---|---|
| `handoff/phase1-041/phase1-041-infra.md` | infra | kafka-init 루프에 `result-topic-job`/`result-topic-log` 추가(구 `job-results` 유지/​삭제는 §5.4 결정) | **1순위** (토픽 존재 기반) |
| `handoff/phase1-041/phase1-041-script-agent.md` | script-agent | producer 분기 발행(①), env 키 정책(§5.5), payload 매핑(§5.1 결정 종속). dispatcher fail-fast/​발행순서 불변식 보존 | 2순위 (hub와 동시 컷오버) |
| `handoff/phase1-041/phase1-041-hub.md` | hub | consumer 분기 소비(③), `Topics` 상수, factory/​listener 구조(§5.1 결정 종속), 테스트 픽스처(KafkaTopicConstantsRegressionTest/​JobResultConsumerTest/​KafkaConfigDeserializerTest) | 2순위 (script-agent와 동시) |
| (meta) e2e 재검증 | monitoring-meta | 하네스 `job-results` 단언 4곳 갱신 + §6-LOG 보존 확인 + R-A/R-B/R-C로 e2e-tester 단독 실행, 결과 `e2e/results/<ts>.md` | **3순위** (전 repo 컷오버 후) |

- **§5.1(payload 경계) 결정이 hub/script-agent handoff의 payload·소비 구조를 좌우한다** — 5.1 미확정 시 두 repo handoff를 확정 작성할 수 없다(특히 ③·②ⓑ). 따라서 **5.1을 먼저 사람이 확정한 뒤** repo handoff를 쓴다(T4-1과 다른 핸드오프 작성 선후 의존).
- **meta 복귀 게이트(각 handoff에 명시 권고)**: 형제 repo 구현 + e2e 60/0/0(또는 새 baseline) 완료 후 monitoring-meta로 복귀해 (i) kafka-payloads.md 매핑표 상태 갱신, (ii) 통합본 §6.9.5·§6.9.2 항목1·§4.4.1 상태 반영, (iii) ROADMAP T4-2(/연동 T4-5) = DONE, (iv) spec-sync drift 재검사, (v) features 문서 보완(feature-doc-writer) — **계약 문서 소유 = meta**이므로 형제 repo 세션이 이를 닫지 않는다.
- **e2e는 CLAUDE.md §3.3에 따라** meta가 별도 e2e-tester로 수행하며 형제 repo 세션이 직접 돌리지 않는다.

### 6.2 각 handoff 공통 가드
- 동결 데모 spec v0.2.1은 수정 금지(회귀 앵커).
- dispatcher의 results 먼저→audit 나중 / results 실패 시 audit skip fail-fast 순서(데모 §5.2) 불변식 보존.
- key=`agent_id`·envelope 4종은 분리와 무관하게 동일(계약 확정 — 건드리지 말 것).
- "회귀 0" = 토픽명 문자열이 아니라 §3.3 동작 등가 + 분기 정확성.
- §5.1이 옵션 A(토픽만 분리)로 확정된 경우에 한해 payload class·소비 구조 구현 선택을 위임 — 옵션 B면 meta 재분석.

---

## ⑥ 영향받는 기능 문서 (docs/features/)

- **보완 대상**: `docs/features/script-job-execution.md` — hop 8(jobresult.Publisher → `job-results`), hop 10~12(JobResultConsumer/​RingBuffer/​Ui가 `job-results` 수신)이 `result-topic-job`로 바뀜. §3 흐름도·§5 hop 표·§7 미구현 노트("job-results 재명명(T4-2)")가 모두 갱신 대상.
- **보완 대상**: `docs/features/log-job-collection.md` — hop 8(LOG 결과 → `job-results`), hop 10~12(hub 수신)이 `result-topic-log`로 바뀜. §3·§5·§7 동일.
- **단, 보완 시점은 구현 완료 후**: 두 문서는 descriptive(구현된 현재 코드 흐름 서술)이며, 현재는 `job-results`가 실제 코드 상태다. T4-2 구현이 형제 repo에서 완료되어 코드가 2토픽을 실제로 쓰게 된 시점에 feature-doc-writer가 보완해야 한다(미구현 상태에서 미리 고치면 코드와 어긋남). 본 분석(spec/​핸드오프 단계)만으로는 아직 보완하지 않는다.
- 신규 작성 대상 없음(새 사용자 가시 시나리오 없음 — 기존 두 시나리오의 토픽 hop 변경).

---

```json
{
  "status": "ok",
  "outputs": ["handoff/phase1-041/phase1-041-000-impact.md"],
  "findings": [
    "형제 repo 실제 경로는 C:/workspace/monitoring/{hub,script-agent,infra} (meta repo=C:/workspace/monitoring/monitoring-meta 기준 ../) — 전수 색출 완료",
    "T4-2 방향/계약/명명/실행순서/ADR소속 잔여 결정 0(D-4(1)/D-4(2)/D-5 RESOLVED, adr/0005 Accepted) — 통합본 Open question·미결 ADR 저촉 없음(blocker 없음)",
    "분기 발행①: 현행 jobresult.Publisher는 단일 topic 무분기 발행(key=AgentID) — SHELL/SQL→result-topic-job / LOG→result-topic-log 분기 신설 필요. dispatcher fail-fast/발행순서 불변식(results 먼저→audit) 보존 필수",
    "payload 매핑②: 현행 단일 JobResult(script/log 중첩, status=SUCCESS/FAIL/TIMEOUT)가 kafka-payloads.md 목표 필드구조(평면 exit_code/stdout/metrics, occurred_at/file_state, status 소문자)와 이미 어긋남 — ⓐ '토픽만 분리 vs payload도 목표 정렬'이 계약 경계 결정(§5.1, 사람 몫)이고 ⓑ는 그에 종속된 구현 위임",
    "소비 분기③: hub 단일 @KafkaListener(JOB_RESULTS, group=hub-job-result-consumer)+factory 1쌍 — 단일 멀티토픽 listener vs 토픽별 factory 분리는 ②ⓐ 결정의 함수",
    "e2e④: §6-LOG 판정(run-e2e.sh:949)은 hub 로그 패턴 기반이라 보존 가능하나, §8 정적이 'job-results' 문자열을 회귀 앵커로 직접 단언한 곳이 4군데(:681/690, :1214-1217, :1266-1277, :1325-1329) — T4-1과 달리 하네스 갱신+baseline 재생성 필수(현 baseline 60/0/0)",
    "동결 데모 spec v0.2.1 §1·§5.2는 회귀 앵커로 보존(forward 변경이라 충돌 아님, 수정 후보 아님) — T4-1 선례와 동일",
    "envelope 4종·key=agent_id는 분리와 무관하게 동일(envelope.md §4.1 확인) — 건드리지 말 것",
    "핸드오프 작성 선후 의존: §5.1(payload 경계) 사람 확정 전에는 hub/script-agent handoff의 payload·소비 구조를 확정 작성 불가 — T4-1과 다른 점",
    "features 2문서(script-job-execution.md·log-job-collection.md) 모두 job-results 흐름 서술 — 구현 완료 후 보완 대상(descriptive라 코드 변경 후 갱신)"
  ],
  "blockers": [],
  "affected_feature_docs": "보완 대상 script-job-execution (hop 8·10~12: job-results→result-topic-job) | 보완 대상 log-job-collection (hop 8·10~12: job-results→result-topic-log) — 단 구현 완료 후 feature-doc-writer 투입",
  "next_action": "사람이 §5 결정(특히 5.1 payload 경계 = 토픽만 분리 vs payload 정렬 포함)을 먼저 확정 → analyzer가 phase1-041-{infra,script-agent,hub}.md 핸드오프 작성(5.1 옵션 A 전제 시), meta 복귀 게이트 명시"
}
```

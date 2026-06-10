# T4-1 토픽 재명명 구현 영향 분석 (phase1-040-000-impact)

> 작성: analyzer (monitoring-meta) / 2026-06-06
> 작업 단위: **T4-1 토픽 재명명 구현 영향 분석** (Phase 1, Track 4)
> 근거 ADR: `adr/0005-topic-naming.md` **Accepted** (D-4(1) RESOLVED 2026-06-06 / D-4(2) RESOLVED 2026-06-04)
> 성격: **분석/후보안 정리만 — 결정은 하지 않는다.** 형제 repo는 Read 전용으로만 색출했고 어떤 파일도 수정하지 않았다.
> 입력: 통합본 §4.4.1·§6.8·§8.3 ADR#5 / `adr/0005` / `docs/kafka-payloads.md` / `docs/envelope.md` / ROADMAP v0.3 §7·§9·§13·§17 / 동결 데모 spec v0.2.1 §1 / `../hub`·`../script-agent`·`../infra`·`e2e/` 코드 전수.

---

## 0. 범위 선언 (T4-1 = 3토픽만)

T4-1은 현행 Phase 0 물리 토픽명을 ADR#5 규칙 B 최종 논리명으로 **재명명**하는 작업이다. 본 분석 대상은 아래 3토픽으로 한정한다.

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) | 규칙 B 적용 근거 |
|---|---|---|
| `commands` | `command-topic` | `<domain=command>-topic`. **단일 물리 토픽**(D-4(1) (2) 승인), zone suffix 없음. 다중 zone 진입 시 `-{zone}` 전개=미래 트리거(§17 D-4(1)-future / `adr/0005` §4 Open) |
| `audit-events` | `audit-topic` | `<domain=audit>-topic` |
| `heartbeats` | `heartbeats-topic` | `<domain=heartbeats>-topic`. 복수형 domain = **명시 예외**(baseline 호환, `adr/0005` §2.2.1) |

- **제외**: `job-results` → `result-topic-job` / `result-topic-log` **분리**는 T4-2 소관이며, 분리의 ADR 소속이 D-5(미결)다. T4-1에서 건드리지 않는다.
- **job-results를 T4-1에서 단순 재명명조차 하지 않고 T4-2로 미루는 게 정합적인가? → 정합적이다.** 다른 3토픽은 1:1 단순 재명명이지만 job-results는 "분리(1→2)"가 동반되어 producer/consumer payload 라우팅 분기까지 바뀐다(서로 다른 작업 성격). 또 분리 자체는 §6.9.2 항목1로 Phase 1 확정이나 **ADR 소속이 D-5 미결**이라 같은 handoff에 묶으면 D-5 결정 대기가 T4-1 전체를 블로킹한다. 따라서 job-results는 현행명 `job-results`로 그대로 두고 T4-2로 분리하는 것이 리스크·의존 측면에서 맞다. (단 운영 시점에는 한동안 토픽 네이밍이 혼재 — 새 3개는 `*-topic`, job-results만 구명 — 한다는 점을 §4에 명시.)

---

## 1. 현황 (Phase 0 동작) vs 목표 spec

### 1.1 현황 (Phase 0 코드가 실제로 쓰는 물리 토픽명)
- 동결 데모 spec v0.2.1 §1: `commands` / `job-results` / `audit-events` / `heartbeats` (kebab-case, prefix 없음).
- hub `KafkaConfig.Topics` 상수 4종이 위 물리명을 그대로 박고 있고, producer/consumer/UI/ring buffer가 이를 참조.
- script-agent는 토픽명을 **env default**(`config.go` `getenv("KAFKA_TOPIC_*", "commands"...)`)로 외부화. 코드에 박힌 문자열은 없음.
- infra `docker-compose.yml` kafka-init 루프 + `otel-collector-config.yml`이 물리 토픽을 생성/발행.

### 1.2 목표 spec (Phase 1 도달 목표)
- `docs/kafka-payloads.md` "토픽 명명 규칙" 표 + 각 토픽 절: 위 3토픽의 최종 논리명을 박아둠(spec 측은 이미 갱신 완료).
- `docs/envelope.md` §4.1: envelope 4종은 토픽명·zone suffix와 **독립**. → **재명명은 envelope에 영향 없음**(확인 완료. envelope.md §4.1 주, `adr/0005` §2.1 근거).
- ROADMAP §7 8토픽 매트릭스가 최종 논리명으로 갱신됨.

> **핵심 위상**: spec/문서 레이어(kafka-payloads/envelope/ROADMAP/ADR)는 이미 최종 논리명으로 정렬돼 있다. T4-1이 남긴 것은 **코드·infra·e2e의 물리 토픽명을 spec에 맞추는 forward 변경**뿐이다.

---

## 2. repo별 영향 목록 (전수 색출)

### 2.1 hub (Java/Spring)

**필수 변경 (런타임 영향)**
| 파일:라인 | 현재 | 변경 내용 |
|---|---|---|
| `src/main/java/com/monitoring/hub/config/KafkaConfig.java:50` | `AUDIT_EVENTS = "audit-events"` | 값을 `"audit-topic"`으로. 상수 *이름*(`AUDIT_EVENTS`)은 유지 가능(코드 식별자라 무방), 값만 교체. |
| `:53` | `JOB_RESULTS = "job-results"` | **변경하지 않음** (T4-2 소관). |
| `:56` | `COMMANDS = "commands"` | 값을 `"command-topic"`으로. |
| `:59` | `HEARTBEATS = "heartbeats"` | 값을 `"heartbeats-topic"`으로. |

> 이 상수 4종이 **단일 진실**이다. 아래 참조처는 모두 상수를 통하므로 상수 값만 바꾸면 런타임 토픽이 바뀐다. 직접 리터럴을 쓰는 producer/consumer는 없음(확인 완료).
> - producer: `producer/CommandPublisher.java:68` → `KafkaConfig.Topics.COMMANDS` 참조.
> - consumer: `ingest/audit/AuditConsumer.java:47` `topics = KafkaConfig.Topics.AUDIT_EVENTS`, `ingest/jobresult/JobResultConsumer.java:43` `JOB_RESULTS`(미변경), `ingest/heartbeat/HeartbeatConsumer.java:52` `HEARTBEATS`.
> - consumer 가드: `AuditConsumer.java:53` / `JobResultConsumer.java:50`의 `EnvelopeHeaders.inspectSource(..., 토픽상수)` — 인자가 상수라 자동 추종(로그/관찰용 토픽명만 바뀜, 동작 불변).

**group.id 영향 (중요)**
- hub consumer group.id는 토픽명과 **무관**하게 고정: `application.yml:22` `hub-audit-consumer`, `JobResultConsumer.java:45` `hub-job-result-consumer`, `HeartbeatConsumer.java:54` `hub-heartbeat-consumer`.
- 재명명 후 같은 group.id가 **새 토픽**을 구독한다. 새 토픽에는 그 group의 committed offset이 없으므로 `auto-offset-reset: earliest`(application.yml:23)에 따라 **새 토픽을 처음부터 재구독**한다. → §4 마이그레이션 쟁점 참조.

**NewTopic 빈**
- hub에는 `NewTopic` 빈(자동 토픽 생성)이 **없음**(색출 결과 0건). 토픽 물리 생성은 infra kafka-init 단독 책임. → hub 쪽 토픽 생성 코드 변경 불요.

**테스트 픽스처 (변경 필요)**
| 파일:라인 | 내용 |
|---|---|
| `src/test/java/.../ingest/jobresult/JobResultConsumerTest.java:39` | `TOPIC = "job-results"` — **미변경**(T4-2). |
| `src/test/java/.../ingest/audit/AuditConsumerTest.java:49` | `TOPIC = "audit-events"` → `"audit-topic"`로. |
| `src/test/java/.../config/KafkaConfigDeserializerTest.java:28` | 주석상 audit-events/job-results 언급 — 토픽 값 단언이 있으면 갱신, 주석만이면 선택. |
| `src/test/java/.../web/UiControllerTest.java:69-70` | `"heartbeats"`,`"commands"` 등은 **모델 attribute 키**(UI 변수명)이지 Kafka 토픽명이 아님 → **변경 불요**(오탐 주의). |
| `src/test/java/.../domain/command/CommandJsonTest.java` / `.../heartbeat/HeartbeatConsumerTest.java` | 변수명 `heartbeats` 등은 토픽명 아님 → 변경 불요. |

**문서/주석 (선택 — 동작 무관)**
- `README.md`(13·15·16·18·27·31·56·91~93·124·167행 등), `pom.xml`(6·33·58·65·89행 주석), `application.yml:38·41·44`(ring buffer 주석), 다수 Java doc 주석에 물리명 등장. **회귀와 무관**하나, drift 방지 위해 새 이름 동기화 권장(필수 아님). UI 라벨 "최근 commands"(`templates/index.html`)는 사용자 표시 문자열이라 토픽명과 무관 — 변경 정책은 hub 세션 재량.

### 2.2 script-agent (Go)

**필수 변경 (런타임 영향)**
| 파일:라인 | 내용 |
|---|---|
| `internal/config/config.go:56` | `getenv("KAFKA_TOPIC_COMMANDS", "commands")` → default를 `"command-topic"`으로. |
| `internal/config/config.go:57` | `getenv("KAFKA_TOPIC_JOB_RESULTS", "job-results")` — **미변경**(T4-2). |
| `internal/config/config.go:58` | `getenv("KAFKA_TOPIC_AUDIT_EVENTS", "audit-events")` → default를 `"audit-topic"`으로. |

> script-agent는 토픽명이 전부 env 외부화돼 있어 **코드 default 값 2곳만** 바꾸면 된다. heartbeats는 script-agent가 Kafka로 직접 발행하지 않고 OTel(infra)이 재발행하므로 script-agent에 heartbeats 토픽 참조 없음(`internal/heartbeat/heartbeat.go` 주석상 확인). producer(`internal/jobresult/publisher.go`, `internal/audit/publisher.go`), reader(`internal/kafka/reader.go`)는 모두 cfg에서 토픽을 주입받음 → 자동 추종.

**env var 이름 정책 (결정 사안)**
- env 키 `KAFKA_TOPIC_COMMANDS` / `KAFKA_TOPIC_AUDIT_EVENTS` 자체를 바꿀지(예: `..._COMMAND_TOPIC`)는 별도 선택. **default 값만 바꾸고 env 키 이름은 유지**하는 것이 호환 안전(외부 override 깨지지 않음). → §5 결정 사안.

**테스트/문서**
- `internal/job/dispatcher_test.go`(160·185·204·206행) 등의 `job-results`/`audit-events`는 **주석/로그 문자열**이며 토픽명 단언이 아님(토픽은 cfg 주입). 동작 무관 → 선택.
- `README.md`(26·59~64·98~100·120~131행), `.claude/`(agents·CLAUDE.md) 다수 주석. 회귀 무관, drift 방지용 선택.

### 2.3 infra

**필수 변경 (토픽 물리 생성/발행)**
| 파일:라인 | 현재 | 변경 내용 |
|---|---|---|
| `docker-compose.yml:64` | `for t in commands job-results audit-events heartbeats` | 생성 루프를 새 이름으로. **`job-results`는 유지**(T4-2 전까지). 즉 `for t in command-topic job-results audit-topic heartbeats-topic`. |
| `otel-collector-config.yml:19` | `topic: heartbeats` | `topic: heartbeats-topic`으로. (kafka exporter 발행 토픽) |
| `docker-compose.yml:75`(주석) | "`heartbeats` 토픽으로 재발행" | 주석 동기화(선택). |

> infra docker-compose에는 hub/script-agent **앱 서비스 정의가 없다**(88줄, 인프라만 기동). 따라서 앱의 `KAFKA_TOPIC_*` env override를 docker-compose에서 주입하는 경로는 없음 → infra 변경은 kafka-init 루프 + otel exporter 토픽 2곳이 전부.

### 2.4 monitoring-meta e2e

| 파일:라인 | 내용 | 변경 필요성 |
|---|---|---|
| `e2e/run-e2e.sh:231-238`(§3 정적 검증) | `HeartbeatConsumer.java`에 envelope 헤더 검사 추가 여부를 grep — 토픽명 자체는 직접 비교 안 함 | 동작 무관(파일/패턴 기반). 단 주석의 `heartbeats` 표기는 동기화 권장 |
| `e2e/run-e2e.sh:523-580`(§6 동적) | heartbeat 수신 판정을 hub 로그 패턴(`ntainer#1-0-C-1 ... Received: N records`)으로 함. **토픽명 문자열에 의존하지 않음** | 컨테이너 스레드 인덱스(`#1`)는 listener 등록 순서 의존 — 토픽명만 바꿔도 순서 불변이면 유지. 단 재명명 후 실측 재확인 필요 |
| `e2e/run-e2e.sh` 주석/§7 리포트(48·741행 등) | `heartbeats-topic` 표기 다수 — 이미 논리명 사용 | 본문 동작 무관 |
| `e2e/results/*.md` | 과거 실행 결과 — 불변 기록 | **변경 금지**(과거 산출물) |

> e2e는 토픽명을 하드코딩 비교하지 않아 **재명명에 비교적 견고**하나, 재명명 후 baseline 재실행으로 PASS를 재확인해야 한다(§5 결정 사안 — baseline 재생성).

---

## 3. Phase 0 동결 spec 정합 처리

### 3.1 문제
동결 데모 spec v0.2.1 §1은 `commands`/`audit-events`/`heartbeats`(+`job-results`)를 **verbatim 동결**로 박고 있다. 재명명 후 코드/infra는 `command-topic` 등을 쓰는데 동결 spec은 여전히 구명을 적는다. 이 둘이 충돌하는가?

### 3.2 판단 — 충돌 아님 (forward 변경 vs 회귀 앵커)
- 동결 데모 spec은 "**Phase 0 코드가 회귀 없이 지켜야 할 동작 spec(ground truth)**"이다(CLAUDE.md §1, spec 헤더). 재명명은 **Phase 1 forward 변경**이며 Phase 0 회귀가 아니다(`adr/0005` §6 Compliance, ROADMAP §3 머리). 즉 동결 spec은 "Phase 0 시점의 동작"을 박은 사료(史料)이고, T4-1은 그 위로 쌓는 Phase 1 변경이라 같은 평면에서 충돌하지 않는다.
- 따라서 **동결 데모 spec은 그대로 둔다**(수정 후보로 올리지 않음 — CLAUDE.md 강제). 토픽명의 Phase 1 최종 기준 문서은 `docs/kafka-payloads.md`다.

### 3.3 회귀 검증 기준 후보 (Phase 0 회귀 0의 재정의)
재명명 후 "Phase 0 회귀 0"을 토픽명 문자열 일치로 정의하면 **반드시 실패**한다(이름이 의도적으로 바뀌므로). 따라서 회귀 기준을 **이름 무관 동작 보존**으로 재정의해야 한다. 후보:

- **후보 R-A (동작 등가 — 권장)**: 회귀 0 기준을 "토픽 *이름*이 아니라 *메시지 흐름·payload·envelope·키·발행순서*의 보존"으로 정의. 즉 데모 spec §1.1 흐름(audit→heartbeat→command→job-results→audit JOB_EXECUTED), §2.2 envelope 4종, §2.3 키 규칙, 발행순서(results→audit)가 새 이름 위에서 동일하게 성립하면 회귀 0. e2e가 이미 흐름·헤더 기반 검증이라 이 정의와 정합.
- **후보 R-B (이름 매핑 테이블 검증)**: 재명명 전/후 토픽명을 매핑 테이블(§0 표)로 명시하고, "코드가 참조하는 물리명이 매핑 테이블의 *목표열*과 일치"를 추가 검사. R-A에 더해 이름 변경 자체의 완전성(누락 없음)을 보증.
- **권장**: R-A를 회귀 0 정의로, R-B를 재명명 완전성 검사로 **병행**. (사람 확정 필요 — §5.)

---

## 4. 마이그레이션 / 운영 쟁점

1. **토픽 물리 생성·삭제**: kafka-init이 새 이름으로 토픽을 생성하면 구 토픽(`commands`/`audit-events`/`heartbeats`)은 **잔존**한다. 클린 환경(e2e/데모 재기동)은 무영향이나, 기존 데이터가 있는 Kafka에서는 구 토픽 삭제 정책이 필요(즉시 삭제 vs 유예 후 삭제). 데모/Phase 1 폐쇄망은 보통 클린 재기동이라 리스크 낮음.

2. **컨슈머 group 재구독**: hub group.id가 토픽 독립이라 새 토픽 구독 시 committed offset이 없어 `earliest`로 처음부터 읽는다. 구 토픽의 미소비 잔류 메시지는 **유실**(group이 더 이상 구독 안 함). 클린 컷오버에서는 무영향, 운영 데이터 보존이 필요하면 드레인 절차 필요.

3. **잔류 메시지 / 동시 전환**: producer와 consumer가 **동시에** 새 토픽으로 가지 않으면(예: agent만 새 토픽 발행 + hub는 구 토픽 구독) 메시지 단절. → producer/consumer/infra 생성을 **원자적 컷오버**로 묶거나, 호환 기간 동안 양쪽 토픽 병행(이중 발행/이중 구독) 중 택해야 함. 폐쇄망·단일 환경이면 **동시 컷오버**가 단순(권장 후보), 무중단 운영이 필요하면 병행 기간.

4. **heartbeats(OTLP·ADR#2 protobuf)와 audit/command의 차이**:
   - heartbeats는 발행자가 **OTel Collector(infra)**다(script-agent/hub 아님). 재명명 시 변경 지점이 infra `otel-collector-config.yml`(exporter topic) + hub consumer(HEARTBEATS 상수) **둘 다 동시** 바뀌어야 함. envelope 4종 미적용(OTLP 위임군)이라 envelope 검증은 무관하나, payload가 OTLP protobuf(ADR#2)라 토픽 단절 시 디코드 단계 이전에 수신 0으로 e2e §6이 timeout 실패한다 → infra/hub 동시 컷오버 필수.
   - audit/command는 발행자가 명확(agent/hub)하고 envelope 4종 적용군이라 consumer 가드(`inspectSource`)가 새 토픽에서도 동일 동작(관찰 전용, reject 없음).

5. **실행 순서 (cross-repo)**: 토픽이 없으면 producer/consumer가 붙지 못하므로 **infra(토픽 생성) 먼저 → producer/consumer(hub/script-agent) 동시**가 안전. 단 kafka auto-create가 켜진 환경(script-agent README는 `KAFKA_AUTO_CREATE_TOPICS_ENABLE=true` 언급)에서는 순서 민감도가 낮아짐. 운영 표준(docker-compose는 kafka-init 명시 생성, auto-create off)이면 infra 선행 필수.

---

## 5. 결정 필요 사안 (사람 입력 대기)

> 아래는 **추측 금지 대상이 아닌 계획/실행 레이어 결정**이다. 통합본 `[Open]`/`13_open`/미결 ADR에 걸리는 항목은 **없다**(T4-1 3토픽은 `adr/0005` Accepted로 모두 확정). 다중 zone 전개·zone 인스턴스명(§13_open §A / D-4(1)-future)은 T4-1 범위 밖이라 본 작업을 막지 않는다.

1. **컷오버 방식**: (a) 동시 컷오버(폐쇄망 클린 재기동, 단순) vs (b) 양쪽 토픽 병행 기간(이중 발행/구독, 무중단). — 데모/Phase 1 환경 성격상 (a) 권장이나 운영 요건 확인 필요.
2. **구 토픽 처리**: 재명명 후 구 토픽(`commands`/`audit-events`/`heartbeats`) 즉시 삭제 vs 유예. 잔류 메시지 보존 필요 여부.
3. **env 키 이름 정책 (script-agent)**: `KAFKA_TOPIC_COMMANDS`/`KAFKA_TOPIC_AUDIT_EVENTS` env 키 이름을 유지(default 값만 교체, 권장) vs 키 이름까지 개명.
4. **회귀 0 정의 채택**: §3.3 후보 R-A(동작 등가) 단독 vs R-A+R-B(완전성 검사 병행). 권장 = 병행.
5. **e2e baseline 재생성 여부**: 재명명 후 `e2e/results/`에 새 baseline 실행 결과를 남길지(권장 — forward 변경이므로 새 PASS 기록 필요). 과거 결과 파일은 불변 보존.
6. **문서/주석 동기화 범위**: hub/script-agent README·Javadoc·Go 주석의 구 토픽명을 이번 handoff에서 함께 정리할지(drift 방지) vs 별도 cleanup. 회귀와 무관하므로 분리 가능.

---

## 6. 핸드오프 분할 제안

> ROADMAP §13 T4-1 owner_repo = hub, script-agent, infra, monitoring-meta. 실행 순서 D-4(2) RESOLVED(envelope 먼저)는 이미 Track 0 완료(T0-4/T0-5 DONE)로 충족됨 → T4-1 즉시 착수 가능.

### 6.1 분할안 (repo별 3 + meta e2e 별도)
| handoff 파일 | 대상 | 단위 | 실행 순서 |
|---|---|---|---|
| `handoff/phase1-040/phase1-040-infra.md` | infra | kafka-init 루프(`command-topic`/`audit-topic`/`heartbeats-topic`, job-results 유지) + otel-collector exporter topic | **1순위** (토픽 생성·heartbeat 발행 기반) |
| `handoff/phase1-040/phase1-040-hub.md` | hub | `KafkaConfig.Topics` 상수 3개 값 교체 + 영향 테스트(AuditConsumerTest 등) | 2순위 (infra와 사실상 동시 컷오버) |
| `handoff/phase1-040/phase1-040-script-agent.md` | script-agent | `config.go` env default 2개(command/audit) 교체 + 주석 정리 | 2순위 (hub와 동시) |
| (meta) e2e 재검증 | monitoring-meta | §3.3 R-A/R-B 회귀 기준으로 e2e-tester 단독 실행, 결과 `e2e/results/<ts>.md` | **3순위** (전 repo 컷오버 후) |

- **실행 순서 요지**: infra(토픽 존재) → hub+script-agent(동시 컷오버) → meta e2e 종단 재검증. heartbeats는 infra(otel exporter)+hub(consumer)가 같은 컷오버 윈도우에 들어가야 단절 없음(§4-4).
- **e2e는 CLAUDE.md §3.3에 따라** meta가 별도 e2e-tester로 수행하며, hub/script-agent 세션이 직접 e2e를 돌리지 않는다.
- job-results 재명명/분리(T4-2)는 **이 handoff 묶음에 넣지 않는다**(D-5 미결 대기). T4-1 완료 후 별도.

### 6.2 각 handoff에 명시할 공통 가드
- 동결 데모 spec v0.2.1은 수정 금지(회귀 앵커).
- 토픽 상수/env default **값만** 교체, 코드 식별자(상수명/env 키)는 유지(호환).
- "회귀 0" = 토픽명 문자열이 아니라 §3.3 동작 등가(흐름/payload/envelope/키/발행순서) 기준.

---

```json
{
  "status": "ok",
  "outputs": ["handoff/phase1-040/phase1-040-000-impact.md"],
  "findings": [
    "T4-1 3토픽은 adr/0005 Accepted로 최종 논리명 확정 — 통합본 Open/미결 ADR에 걸리는 항목 없음(blocker 없음)",
    "hub: 변경 단일 진실 = KafkaConfig.Topics 상수 3개 값(command-topic/audit-topic/heartbeats-topic). producer/consumer/가드는 상수 참조라 자동 추종. NewTopic 빈 없음, group.id는 토픽 독립",
    "script-agent: 토픽명 전부 env 외부화 — config.go getenv default 2곳(command/audit)만 변경. heartbeats는 OTel(infra) 발행이라 script-agent 참조 없음",
    "infra: kafka-init 생성 루프 + otel-collector-config exporter topic 2곳이 물리 생성/발행 지점. 앱 서비스 정의 없음(인프라만 기동)",
    "e2e: 토픽명 하드코딩 비교 안 함(흐름/로그패턴 기반) — 재명명에 견고하나 baseline 재실행으로 PASS 재확인 필요",
    "job-results는 T4-2(분리+D-5 미결)로 미루는 것이 정합적 — T4-1에서 현행명 유지",
    "heartbeats 재명명은 infra(otel exporter)+hub(consumer) 동시 컷오버 필수(단절 시 e2e §6 timeout 실패)",
    "동결 데모 spec v0.2.1 §1은 회귀 앵커로 보존 — 재명명은 forward 변경이라 충돌 아님(수정 후보 아님)"
  ],
  "blockers": [],
  "next_action": "사람이 §5 결정 6건(컷오버 방식/구토픽 처리/env키 정책/회귀0 정의/baseline 재생성/문서동기화 범위) 입력 → analyzer가 phase1-040-{infra,hub,script-agent}.md 3개 핸드오프 작성"
}
```

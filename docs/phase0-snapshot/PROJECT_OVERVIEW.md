# monitoring — 프로젝트 단일 개요 (Project Overview)

> **이 한 장이 무엇인가.** 모니터링 솔루션 데모 워크스페이스(`monitoring/`)의 현재
> 상태를 빠짐없이 전달하기 위한 **단일 컨텍스트 문서**. 외부 LLM/리뷰어에게
> 이 파일 하나만 던져도 다음을 모두 파악할 수 있다:
>
> - 워크스페이스 구조 (hub + script-agent + infra — **각각 독립 Git 저장소**)
> - 모듈별 책임/기능/엔드포인트
> - 인프라 토폴로지(Kafka·OTel 포트, 토픽 부트스트랩)
> - 메시지 명세 v0.2.1 ground truth (토픽·envelope·페이로드 전체)
> - 데모 범위와 본개발 ADR 후보 경계
> - 종단 검증 시나리오 / 빌드·실행 명령
>
> **저장소 구성 변경.** 초기에는 단일 monorepo(`monitoring.git`)였으나, 현재는
> 모듈별로 **독립 멀티레포(multi-repo)** 로 분리되었다 (`hub` / `script-agent` /
> `infra` 각각 별도 GitHub 저장소). 워크스페이스 루트(`monitoring/`)는 세 저장소를
> 형제 디렉토리로 체크아웃해 두는 작업 공간이자 본 개요 문서의 위치다. 저장소 목록과
> 클론 방법은 §2 참조.
>
> 작성 기준일: **2026-05-27**, spec 버전 **v0.2.1**. 코드 변경 시 본 문서의
> 해당 절도 함께 갱신한다 (ground truth는 여전히 `hub/docs/monitoring-demo-message-spec-v0.2.1.md`).

---

## 1. 한 줄 요약

| 항목 | 값 |
|---|---|
| 프로젝트 | 모니터링 솔루션 데모 (walking skeleton 완성본) |
| 위상 | **데모(개발 v0) 단계**. 본개발 reference implementation을 의도 |
| 구성 | `hub`(Spring Boot BE) + `script-agent`(Go) + `infra`(Kafka/OTel) |
| 저장소 | **멀티레포** — 모듈별 독립 Git 저장소 3개 (monorepo에서 분리, §2.0) |
| 통신 | Kafka 토픽 4종(JSON) + OTel Collector(heartbeat OTLP HTTP→Kafka 재발행) |
| 저장소 | 없음 (BE in-memory ring buffer + latest map; 재기동 시 휘발) |
| 인증 | 없음 (본개발 Phase 1에서 JWT+Knox 도입 예정) |
| UI | Thymeleaf 단일 페이지 (`GET /`) |

---

## 2. 워크스페이스 구조

### 2.0 저장소 (멀티레포)

초기 monorepo(`monitoring.git`)에서 모듈별 독립 저장소로 분리됨. 각 모듈은
**자기 저장소가 single source of truth**이며 독립적으로 클론/빌드/배포된다.

| 모듈 | 저장소 | 런타임/빌드 | 역할 |
|---|---|---|---|
| `hub` | `github.com/nebydu/hub.git` | Java 21 / Maven | Spring Boot BE (Kafka 컨슈머·프로듀서, Quartz, Thymeleaf UI) |
| `script-agent` | `github.com/nebydu/script-agent.git` | Go 1.21+ | 스크립트/로그 Job 실행 에이전트 |
| `infra` | `github.com/nebydu/infra.git` | docker-compose | Kafka / Zookeeper / OTel Collector |

> **레거시 monorepo.** `github.com/nebydu/monitoring.git`(과거 단일 저장소)는
> 분리 이전 이력 보존용이며, 신규 개발은 위 세 저장소에서 진행한다. 워크스페이스
> 루트(`C:\workspace\monitoring\`)는 세 저장소를 형제 디렉토리로 체크아웃해 두는
> 작업 공간으로, 본 개요 문서를 함께 둔다.

**워크스페이스 클론 (형제 디렉토리 배치):**

```powershell
mkdir C:\workspace\monitoring; cd C:\workspace\monitoring
git clone https://github.com/nebydu/hub.git
git clone https://github.com/nebydu/script-agent.git
git clone https://github.com/nebydu/infra.git
```

### 2.1 디렉토리 레이아웃

```
C:\workspace\monitoring\               # 작업 공간 (세 저장소 + 본 문서)
├── PROJECT_OVERVIEW.md                # ← 본 문서
├── hub/                  [git: hub.git]            # Spring Boot BE (JDK 21 / Maven)
│   ├── README.md
│   ├── AGENTS.md                      # Claude/Codex 역할 분담
│   ├── CLAUDE.md
│   ├── pom.xml
│   ├── docs/
│   │   └── monitoring-demo-message-spec-v0.2.1.md   # ★ ground truth
│   └── src/main/{java,resources}
├── script-agent/         [git: script-agent.git]   # Go agent (Go 1.21+)
│   ├── README.md
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── go.mod
│   ├── cmd/agent/                     # 엔트리포인트
│   ├── internal/                      # audit / config / heartbeat / identity / job / jobresult / kafka / model
│   └── docs/
│       └── monitoring-demo-message-spec-v0.2.1.md   # hub의 사본
└── infra/                [git: infra.git]          # Kafka / OTel
    ├── docker-compose.yml             # Kafka + Zookeeper + kafka-init + OTel Collector
    ├── otel-collector-config.yml
    └── otelcol-contrib.exe            # (옵션) 로컬 바이너리
```

### git 진행 상태 (2026-05-27 기준, 저장소별)

각 저장소가 독립 이력을 가진다. 모듈 분리 전 공통 초기 커밋(monorepo 시절)에서
갈라져 나왔다.

```
hub          (hub.git)
  3722223 docs: 에이전트 작업 지침과 프로젝트 개요 추가 [codex]
  7ce215f Kafka 역직렬화 설정 검증 추가
  7e4ea89 feat(hub): 데모 BE walking skeleton 완성 — 양방향 통신 + Thymeleaf UI

script-agent (script-agent.git)
  c73aae7 docs: 에이전트 작업 지침과 프로젝트 개요 추가 [codex]
  d15c6ad fix(agent): commands 처리 at-least-once 보장 강화
  1b64894 feat: monitoring 데모 초기 커밋 — Script Agent v0.1 + 공유 인프라

infra        (infra.git)
  f3fe352 PROJECT_OVERVIEW.md 추가
  6a9af42 feat: monitoring 데모 초기 커밋 — Script Agent v0.1 + 공유 인프라
```

→ **데모 walking skeleton 완성 상태.** 다음 단계는 본개발 Phase 1 (ADR #1·#7·#12·#8 등).

---

## 3. 위상과 역할 분담

### 3.1 위상

- **데모 단계**: Schema Registry 미도입, 인증 없음, 영속 저장소 없음, in-memory.
  단 코드는 "한 번 시연하고 버리는 demo"가 아니라 **본개발 reference implementation**으로
  유지되며 spec v0.2.1과 정합성을 유지한다.
- **본개발 Phase 1**: 인증(JWT+Knox), 영속(PG/OpenSearch), Schema Registry,
  LEGO+WebSocket 화면, SQL_JOB, Heartbeat protobuf 전환 등.
- **본개발 Phase 2**: 시계열 메트릭(OS metric / Infra Agent + VictoriaMetrics),
  Alert / Incident.

### 3.2 협업 규칙 (`hub/AGENTS.md`)

- 답변·코드 주석·문서: **한국어**. 변수/함수명은 영어.
- Claude Code가 기본 구현·큰 기능 개발 주도. Codex는 검토·수정·테스트 병행.
  서로의 변경은 임의로 되돌리지 않고, 필요 시 근거 남기고 최소 범위로 수정.
- 변경 후 가능한 경우 테스트·lint 실행. 큰 수정 후 `git diff` 기준 변경 요약.
- 리뷰 결과는 심각도 높은 항목부터 짧고 명확하게.

---

## 4. 인프라 (`infra/`)

### 4.1 docker-compose 서비스

| 서비스 | 이미지 | 포트(host:container) | 역할 |
|---|---|---|---|
| `zookeeper` | confluentinc/cp-zookeeper:7.5.3 | (내부) 2181 | Kafka 메타데이터 |
| `kafka` | confluentinc/cp-kafka:7.5.3 | **9092**:9092 (HOST), 29092 (DOCKER 내부) | dual listener |
| `kafka-init` | confluentinc/cp-kafka:7.5.3 | one-shot | 토픽 4종 명시 사전 생성 |
| `otel-collector` | otel/opentelemetry-collector-contrib:0.110.0 | **14318**:4318 | heartbeat OTLP HTTP → Kafka 재발행 |

### 4.2 Kafka 리스너 정책

- `HOST://localhost:9092` — 호스트에서 직접 띄운 Agent/Hub용
- `DOCKER://kafka:29092` — compose network 내부 컨테이너용 (현재는 OTel Collector만 사용)
- `inter.broker.listener.name=DOCKER`
- `AUTO_CREATE_TOPICS_ENABLE=true` — 안전망. **표준은 `kafka-init`이 사전 생성** (`commands`, `job-results`, `audit-events`, `heartbeats`).

### 4.3 OTel Collector 파이프라인 (`otel-collector-config.yml`)

```
Agent (OTLP HTTP :14318→4318)
  → otlp receiver
  → kafka exporter (encoding: otlp_json, brokers: kafka:29092, topic: heartbeats)
```

> Windows에서 4318이 Hyper-V 예약 범위에 잡혀 호스트 측만 14318로 우회. 컨테이너 내부와 Collector 설정은 4318 그대로.

### 4.4 기동 명령

```powershell
docker compose -f infra/docker-compose.yml up -d
```

---

## 5. Hub (BE, Spring Boot / JDK 21 / Maven)

### 5.1 책임

spec v0.2.1의 데모 범위(§0 위상 / §1~§5 토픽·도메인·페이로드 / §4.2 단일
페이지 UI / ADR #16 #17)를 모두 코드로 풀어놓은 reference implementation.

**수신 측 (Agent → BE)** 세 토픽 처리:
- `audit-events` — `AGENT_STARTED` → AgentRegistry 등록, `AGENT_STOPPED` → OFFLINE 마킹,
  `JOB_EXECUTED` → audit ring buffer 적재
- `job-results` — JobResult(SCRIPT_JOB / LOG_JOB) ring buffer 적재
- `heartbeats` — OTLP JSON 트리 파싱(spec §5.4.2), HeartbeatLatestMap 갱신 + AgentRegistry.lastSeen 갱신

**송신 측 (BE → Agent)** Quartz 스케줄러 + `commands` producer:
- cron 트리거마다 `valid_until` = "다음 트리거 예정 시각의 90% 지점" 계산 (§5.1.3)
- Trigger misfire = `MISFIRE_INSTRUCTION_DO_NOTHING` (§5.1 + ADR #17)
- spec §2.2 envelope 헤더 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`) 첨부
- spec §2.3 메시지 키 = `target_agent_id`

**Thymeleaf 단일 페이지 UI** — `GET /` 한 페이지에 모든 in-memory state 노출:
- 등록 Agent 목록 (ONLINE/OFFLINE + last_seen + heartbeat last_seen)
- Schedule 등록 폼 (§4.2 단일 폼 — job_type 선택으로 SCRIPT_JOB/LOG_JOB 분기)
- 등록된 Schedule 목록
- 최근 commands / job-results / audit-events 3종 패널

**REST API** (외부 자동화용):

| 메서드 | 경로 | 설명 |
|---|---|---|
| `POST` | `/schedules` | Schedule 등록 (JSON) |
| `GET` | `/schedules` | 등록된 스케줄 목록 |
| `GET` | `/commands` | 최근 발행 commands 50개 |
| `POST` | `/ui/schedules` | UI 폼 submit (redirect → `/`) |
| `GET` | `/health` | `OK` |

### 5.2 패키지 구조

```
com.monitoring.hub
├── HubApplication            # 부팅 엔트리포인트
├── config                    # AppProperties, KafkaConfig
├── domain
│   ├── audit                 # AuditEvent + Actor/Target + enum
│   ├── job                   # JobResult + ScriptResult/LogResult + JobType/JobStatus
│   │                         # + JobDefinition + ScheduleDefinition
│   ├── command               # Command (commands 토픽 페이로드)
│   ├── heartbeat             # HeartbeatState
│   └── agent                 # AgentInfo + AgentState
├── store                     # AuditRingBuffer, JobResultRingBuffer, CommandRingBuffer,
│                             # HeartbeatLatestMap, AgentRegistry, JobRegistry,
│                             # ScheduleRegistry (in-memory)
├── ingest
│   ├── audit                 # AuditConsumer (@KafkaListener)
│   ├── jobresult             # JobResultConsumer
│   └── heartbeat             # HeartbeatConsumer (OTLP JSON 트리 파싱)
├── producer                  # CommandPublisher (KafkaTemplate + envelope 헤더)
├── scheduler                 # ScheduleService (Quartz 등록), ScheduleTriggerJob
├── api                       # HealthController, ScheduleController,
│                             # CommandHistoryController, ScheduleRegistrationRequest
└── web                       # UiController (Thymeleaf), ScheduleFormRequest

src/main/resources/templates/
└── index.html                # 데모 단일 페이지 — 모든 in-memory state 노출
```

### 5.3 환경변수 / 설정

| 변수 | 기본값 | 설명 |
|---|---|---|
| `HUB_KAFKA_BOOTSTRAP` | `localhost:9092` | Kafka brokers |
| `hub.audit.ring-buffer-size` | 200 | §4.3 audit-events ring |
| `hub.job.ring-buffer-size` | 100 | §4.3 job-results ring |
| `hub.command.ring-buffer-size` | 50 | §4.3 commands ring |
| `hub.agent.heartbeat-timeout-seconds` | 30 | §3.2 OFFLINE 판정 기준값 |

Spring relaxed binding 규칙: 환경변수 override 가능 (`HUB_AUDIT_RINGBUFFERSIZE` 등).

### 5.4 빌드 / 실행

```powershell
mvn -DskipTests package          # 빌드만
mvn package                      # 테스트 포함
mvn spring-boot:run              # 실행 (포트 8080)
# 동작 확인
curl http://localhost:8080/health     # → OK
# 브라우저
start http://localhost:8080/
```

> **빌드 도구 주의.** 글로벌 기본은 Gradle이지만 monitoring 워크스페이스의 JVM 모듈은 **Maven**으로 통일 (`pom.xml`).

---

## 6. Script Agent (Go 1.21+)

### 6.1 책임

호스트에서 스크립트 실행 / 로그 스캔을 수행하고 결과를 Kafka로 보고하는 경량 Go 에이전트.

| 흐름 | 토픽 | 발행/소비 |
|---|---|---|
| 시작 알림 + 등록 | `audit-events` (`AGENT_STARTED`) | 발행 |
| 명령 수신 | `commands` | consume (`script-agent-<agent_id>` 그룹) |
| Job 실행 결과 | `job-results` | 발행 |
| 감사 이벤트 | `audit-events` (`JOB_EXECUTED`) | 발행 |
| 종료 알림 | `audit-events` (`AGENT_STOPPED`) | 발행 |
| Liveness | `heartbeats` | OTel Collector가 OTLP→Kafka 재발행 |

### 6.2 Job 실행 정책 (사전 결정)

- **실행 모델**: 단일 consumer goroutine에서 명령을 순차 처리 (Nagios/Zabbix 표준 — agent worker 단위 serial). 동일 schedule 재진입은 구조적으로 불가능.
- **at-least-once 보장**: Dispatch가 결과/감사 발행을 완료한 뒤에만 Kafka offset commit. publish 실패 시 즉시 `exit 1`로 종료 → supervisor 재기동 → last committed offset부터 redeliver.
- **발행 순서**: `job-results` 먼저, 성공 시 `audit-events` (JOB_EXECUTED). results 실패 시 audit은 시도하지 않음 — "audit엔 JOB_EXECUTED 있는데 결과 데이터 없음" 비대칭 차단. 반대 케이스(results 성공 후 audit 실패 → 재기동 시 results 중복)는 가능하므로 **BE는 `execution_id`로 dedup** 해야 함.
- **만료된 명령**: `valid_until` 지난 명령은 silent skip (spec §5.1).
- **SCRIPT_JOB**: `timeout_seconds`로 강제 중단, `output_cap_bytes` 초과분은 truncate + `truncated=true`.
- **LOG_JOB 첫 실행**: 파일 끝부터 매칭 (tail -f 스타일). 이후 offset 추적.
- **로그 rotation**: `file_id`(POSIX inode / Windows file index) 변경 또는 `size shrink` 감지 시 새 파일 처음부터 재시작.

### 6.3 종료 코드 / supervisor 정책

| exit code | 의미 | supervisor 권장 동작 |
|---|---|---|
| `0` | 정상 signal 종료 | 재기동 안 함 |
| `1` | 부팅 실패 또는 `job-results`/`audit-events` publish 실패 (fail-fast) | **재기동 필수** — at-least-once 보장 |

- systemd: `Restart=on-failure`
- Kubernetes: `restartPolicy: OnFailure`
- supervisord: `autorestart=unexpected` + `exitcodes=0`

### 6.4 환경변수

| 이름 | 기본값 | 설명 |
|---|---|---|
| `AGENT_ID_PATH` | `./.agent_id` | 영구 식별자(agent_id) 저장 파일 (spec §3.1) |
| `AGENT_VERSION` | `0.1.0` | audit / heartbeat 페이로드의 Agent 버전 |
| `LOG_LEVEL` | `info` | slog 출력 최소 레벨 |
| `KAFKA_BROKERS` | `localhost:9092` | Kafka brokers |
| `KAFKA_TOPIC_COMMANDS` | `commands` | BE→Agent 명령 토픽 |
| `KAFKA_TOPIC_JOB_RESULTS` | `job-results` | Agent→BE Job 결과 토픽 |
| `KAFKA_TOPIC_AUDIT_EVENTS` | `audit-events` | Agent→BE 감사 이벤트 토픽 |
| `LOG_STATE_DIR` | `./.agent_state` | LOG_JOB file_state JSON 저장 디렉토리 |
| `OTLP_ENDPOINT` | `http://localhost:4318` | OTel Collector OTLP HTTP. **Windows docker compose는 `http://localhost:14318`** |
| `HEARTBEAT_INTERVAL_SECONDS` | `10` | `agent.heartbeat` 메트릭 송신 주기 (spec §5.4.1) |

### 6.5 디렉토리 구조

```
script-agent/
├── cmd/agent/             # 엔트리포인트
├── internal/
│   ├── audit/             # AGENT_STARTED/STOPPED/JOB_EXECUTED 발행
│   ├── config/            # 환경 변수 로드
│   ├── heartbeat/         # OTel agent.heartbeat (OTLP HTTP)
│   ├── identity/          # agent_id 생성 / 로드
│   ├── job/               # Dispatcher + SCRIPT_JOB / LOG_JOB executor
│   ├── jobresult/         # JobResult 발행
│   ├── kafka/             # kafka-go 래퍼 (Writer/Reader + envelope 헤더)
│   └── model/             # 메시지 스키마 (spec §5)
├── .agent_id              # 런타임 생성 (gitignore)
└── .agent_state/          # LOG_JOB file_state (gitignore)
```

### 6.6 빌드 / 실행

```sh
go build ./...
go test ./...               # 모델/유틸 단위 테스트만 자동화 (Kafka 통합 테스트 없음)
go run ./cmd/agent
```

---

## 7. 메시지 명세 v0.2.1 (Ground Truth)

> 원본: `hub/docs/monitoring-demo-message-spec-v0.2.1.md` (및 동일 사본 `script-agent/docs/`).
> 본 절은 외부 LLM 단독 컨텍스트를 위해 spec 본문을 그대로 통합한 것이다.
> **충돌 시 원본 spec이 우선**이며, 양쪽이 함께 갱신되어야 한다.

### 7.0 위상

데모(개발 v0) 단계의 Kafka 메시지 스키마와 토픽 규약. Schema Registry 미도입
상태에서 이 spec이 ground truth. 변경 시 문서 버전 bump + 양쪽(Agent/BE)
코드 동시 갱신 원칙.

본개발 Phase 1 진입 시 Schema Registry 도입 여부, Heartbeat 마샬링
(`otlp_json` → protobuf), 인증, 영속 저장소, SQL_JOB 등이 추가 검토된다.

### 7.1 토픽 목록

| 토픽 | 방향 | 발행자 | 소비자 | 내용 |
|---|---|---|---|---|
| `commands` | BE → Agent | BE Quartz | Script Agent | Job 실행 명령 |
| `job-results` | Agent → BE | Script Agent | BE Consumer | Job 실행 결과 |
| `audit-events` | Agent → BE | Script Agent | BE Consumer | 감사 이벤트 (Agent 시작/종료, Job 실행) |
| `heartbeats` | OTel Collector → BE | OTel Collector | BE Consumer | Agent heartbeat (OTLP JSON) |

토픽 명명 규칙: `kebab-case`, 환경/도메인 prefix 없음.

#### 7.1.1 메시지 흐름

```
Agent 시작
  → audit-events: AGENT_STARTED   ─┐
  → heartbeats: agent.heartbeat   ─┤
                                   │
BE Quartz 트리거                   │
  → commands                       │  ────► BE Ring Buffer
        ▼                          │        + Agent 목록 (in-memory)
      Agent 실행                   │
        ▼                          │
  → job-results                    │
  → audit-events: JOB_EXECUTED    ─┘

Agent 종료
  → audit-events: AGENT_STOPPED
```

### 7.2 공통 규약

**7.2.1 직렬화.** JSON (UTF-8). Heartbeat 토픽만 OTLP JSON (OTel Collector exporter 표준).

**7.2.2 Kafka 메시지 헤더 (envelope).** 도메인 데이터가 아닌 메타데이터는
Kafka 헤더로 분리. payload는 도메인 데이터만.

| 헤더 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `x-message-id` | UUID string | ● | 메시지 식별자. 중복 감지용 (데모는 발행만, 검사 없음) |
| `x-message-version` | string | ● | payload 스키마 버전. 데모는 `1` 고정 |
| `x-source` | string | ● | 발행자: `script-agent` \| `monitoring-be` \| `otel-collector` |
| `x-trace-id` | string | ○ | OTel trace propagation 대비. 데모는 발행만, 검사 없음 |

`heartbeats` 토픽은 OTel Collector가 발행 — 위 헤더 규약 미적용 (OTLP 표준 헤더 그대로).

**7.2.3 메시지 키.**

| 토픽 | 키 |
|---|---|
| `commands` | `target_agent_id` |
| `job-results` | `agent_id` |
| `audit-events` | `agent_id` |
| `heartbeats` | OTel Collector 기본 (Agent 단위 분배 불보장) |

키 정책: Agent 단위 ordering 보장. 본개발에서도 동일 유지.

**7.2.4 ID 컨벤션.**

| ID | 발급 시점 | 발급자 | 비고 |
|---|---|---|---|
| `agent_id` | Agent 첫 실행 시 | Agent | UUIDv4. 로컬 파일에 저장 (§7.3.1) |
| `job_id` | Job 정의 등록 시 | BE | UUIDv4. Job = "무엇을 실행할지" 정의 |
| `schedule_id` | Schedule 등록 시 | BE | UUIDv4. Schedule = "어떤 Job을 언제, 어떤 Agent에서" |
| `execution_id` | Schedule 트리거 시 | BE Quartz | UUIDv4. 1회 실행 식별. commands/result/audit 상관 키 |

**7.2.5 Timestamp.** 모든 도메인 timestamp는 RFC3339 (예: `2026-05-19T14:00:00Z`). Heartbeat 영역만 OTLP 표준(UnixNano). 각 timestamp의 의미는 토픽별로 명시.

### 7.3 Agent 등록 메커니즘

**7.3.1 agent_id 생성.** Agent 첫 실행 시 작업 디렉토리의 `.agent_id` 확인 → 없으면 UUIDv4 생성 후 저장. agent_id는 영구 식별자이며 hostname/OS 변경과 무관.
(본개발: `/var/lib/monitoring-agent/agent_id` 검토 예정)

**7.3.2 등록 흐름.** 데모 단계에선 별도 등록 endpoint 없이 `audit-events` 토픽의 `AGENT_STARTED` 이벤트가 등록 역할 겸함. payload에 hostname/os/agent_version/started_at 포함. BE는 in-memory `Map<AgentId, AgentInfo>`에 등록/갱신.

이후 heartbeat은 등록 정보 재전송 없음 — agent_id attribute만으로 BE가 매칭해 last_seen 갱신. `AGENT_STOPPED` 수신 시 OFFLINE 마킹 (목록에서 제거하지 않음).

본개발 Phase 1에서 `/agents/register` endpoint + 사전 발급 토큰 + 관리자 승인 게이트로 진화 예정 (ADR #11).

### 7.4 Job 도메인 모델

**7.4.1 세 객체의 분리.**

- **Job (정의)**: "무엇을 어떻게 실행할지". 시간/대상과 무관.
  - SCRIPT_JOB: 스크립트 경로/인자/timeout/출력 cap
  - LOG_JOB: 로그 파일 경로/패턴/인코딩
- **Schedule**: "어떤 Job을 언제, 어떤 Agent에서" — `(job_id, target_agent_id, cron_expression, enabled)`
- **Execution**: Schedule이 트리거되어 실제로 실행된 사건 — `(execution_id, schedule_id, started_at, finished_at, status, output)`

**7.4.2 데모 UI 단순화.** 데모 UI는 schedule 중심으로만 노출. "스케줄 등록" 폼 하나에서 job_type, 실행 대상, 옵션, cron, target_agent_id를 모두 받고 BE가 내부적으로 Job + Schedule 두 객체 생성. job_id는 화면에 노출되지 않음. 본개발에서 Job 등록과 Schedule 등록 화면 분리.

**7.4.3 BE in-memory 상태.**

| 구조 | 형태 | 크기 |
|---|---|---|
| commands | Ring buffer | 최근 50개 |
| job-results | Ring buffer | 최근 100개 |
| audit-events | Ring buffer | 최근 200개 |
| heartbeats | Latest map `Map<AgentId, HeartbeatState>` | Agent당 최신 1개 |
| Agent 목록 | Map `Map<AgentId, AgentInfo>` | 등록된 Agent 수 |
| Job 정의 | Map `Map<JobId, JobDefinition>` | 등록된 Job 수 |
| Schedule 정의 | Map `Map<ScheduleId, ScheduleDefinition>` | 등록된 Schedule 수 |

> Heartbeat이 ring buffer가 아닌 **latest map**인 이유: Agent별 "마지막 살아있음" 시각만 필요. Ring buffer로 두면 단일 Agent가 ring을 채워 다른 Agent를 밀어내는 문제.

BE 재시작 시 모두 휘발. 본개발에서 PG/OpenSearch 영속화.

동시성: 여러 Consumer 스레드가 동시에 ring buffer에 쓰고 Thymeleaf 요청이 동시에 읽으므로 thread-safe 구조 필수 (`Collections.synchronizedList` 또는 Apache Commons `CircularFifoQueue` synchronized wrap 등).

### 7.5 토픽별 페이로드 명세

#### 7.5.1 `commands`

BE Quartz가 스케줄 트리거 시 발행. Agent별 unique consumer group으로 consume하며 payload의 `target_agent_id`가 자기 것이 아니면 무시.

**오프라인 Agent 처리.** 명령 발행 시점에 `valid_until` 포함. Agent가 consume했을 때 현재 시각이 `valid_until`을 지났으면 즉시 silent skip. 누적 실행 회피의 모니터링 솔루션 표준 패턴. BE Quartz의 misfire는 `MISFIRE_INSTRUCTION_DO_NOTHING`.

**SCRIPT_JOB 예시:**

```json
{
  "execution_id": "8f4b1c9e-...",
  "schedule_id": "3a7d2b5f-...",
  "job_id": "9c1e8a4d-...",
  "target_agent_id": "agent-001",
  "job_type": "SCRIPT_JOB",
  "issued_at": "2026-05-19T14:00:00Z",
  "valid_until": "2026-05-19T14:04:30Z",
  "spec": {
    "script_path": "/opt/scripts/check_disk.sh",
    "args": ["--threshold", "80"],
    "timeout_seconds": 30,
    "output_cap_bytes": 65536
  }
}
```

**LOG_JOB 예시:**

```json
{
  "execution_id": "8f4b1c9e-...",
  "schedule_id": "3a7d2b5f-...",
  "job_id": "9c1e8a4d-...",
  "target_agent_id": "agent-001",
  "job_type": "LOG_JOB",
  "issued_at": "2026-05-19T14:00:00Z",
  "valid_until": "2026-05-19T14:04:30Z",
  "spec": {
    "log_path": "/var/log/app/error.log",
    "pattern": "ERROR|FATAL",
    "encoding": "UTF-8"
  }
}
```

**필드 정의:**

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `execution_id` | UUID | ● | 이 한 번 실행의 식별자. result/audit가 이걸로 상관 |
| `schedule_id` | UUID | ● | 트리거된 Schedule 식별자 |
| `job_id` | UUID | ● | Job 정의 식별자 |
| `target_agent_id` | string | ● | 매치 안 되면 Agent 무시 |
| `job_type` | enum | ● | `SCRIPT_JOB` \| `LOG_JOB` |
| `issued_at` | RFC3339 | ● | BE가 명령을 발행한 시각 |
| `valid_until` | RFC3339 | ● | 이 시각 이후 받은 Agent는 명령을 skip. "다음 트리거 예정 시각의 90% 지점"으로 계산 |
| `spec` | object | ● | job_type별 구조 상이 |

**`valid_until` 계산.** 5분 주기면 `issued_at + 4분 30초`. 일반화: "다음 트리거 예정 시각의 90% 지점". 일회성 트리거는 본개발 영역.

#### 7.5.2 `job-results`

Agent가 Job 실행 후 발행.

**SCRIPT_JOB 결과:**

```json
{
  "execution_id": "8f4b1c9e-...",
  "schedule_id": "3a7d2b5f-...",
  "job_id": "9c1e8a4d-...",
  "agent_id": "agent-001",
  "job_type": "SCRIPT_JOB",
  "status": "SUCCESS",
  "started_at": "2026-05-19T14:00:01Z",
  "finished_at": "2026-05-19T14:00:03Z",
  "script": {
    "exit_code": 0,
    "stdout_cap": "Disk usage: 42%",
    "stderr_cap": "",
    "truncated": false
  },
  "log": null
}
```

**LOG_JOB 결과:**

```json
{
  "execution_id": "8f4b1c9e-...",
  "schedule_id": "3a7d2b5f-...",
  "job_id": "9c1e8a4d-...",
  "agent_id": "agent-001",
  "job_type": "LOG_JOB",
  "status": "SUCCESS",
  "started_at": "2026-05-19T14:00:01Z",
  "finished_at": "2026-05-19T14:00:02Z",
  "script": null,
  "log": {
    "matched_lines_count": 3,
    "sample_lines": [
      "[2026-05-19 13:59:42] ERROR Failed to connect to DB",
      "[2026-05-19 13:59:55] ERROR Retry exceeded"
    ]
  }
}
```

**필드 정의:**

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `execution_id` | UUID | ● | command와 매치 |
| `agent_id` | string | ● | 발행 Agent |
| `job_type` | enum | ● | `SCRIPT_JOB` \| `LOG_JOB` |
| `status` | enum | ● | `SUCCESS` \| `FAIL` \| `TIMEOUT` |
| `started_at` | RFC3339 | ● | Agent가 작업을 시작한 시각 |
| `finished_at` | RFC3339 | ● | Agent가 작업을 종료한 시각 |
| `script` | object \| null | ○ | SCRIPT_JOB일 때 채움 |
| `log` | object \| null | ○ | LOG_JOB일 때 채움 |

> **Timestamp 주의.** `started_at`/`finished_at`은 **Agent의 작업 시간**.
> LOG_JOB의 경우 로그 라인 자체의 발생 시각과는 별개이며, 데모 단계에서는
> 로그 발생 시각을 추출하지 않는다. 본개발에서 추가 예정 (ADR #10).
>
> **LOG_JOB file_state**(offset, inode, size)는 **Agent local 상태**이며
> BE에 전송하지 않음. Agent 내부의 로컬 JSON 파일에 보관.

#### 7.5.3 `audit-events`

데모 단계 audit 액션은 다음 세 가지로 한정.

| action | 발생 시점 | result 값 |
|---|---|---|
| `AGENT_STARTED` | Agent 프로세스 시작 직후 | `SUCCESS` |
| `AGENT_STOPPED` | Agent 정상 종료 직전 | `SUCCESS` |
| `JOB_EXECUTED` | Job 실행 종료 시 | `SUCCESS` \| `FAIL` \| `TIMEOUT` |

> `JOB_EXECUTED`의 `occurred_at`은 **Job 실행 종료 시각** (= `job-results.finished_at`).

**AGENT_STARTED 예시:**

```json
{
  "event_id": "uuid",
  "actor": { "type": "AGENT", "id": "agent-001" },
  "action": "AGENT_STARTED",
  "target": { "type": "AGENT", "id": "agent-001" },
  "result": "SUCCESS",
  "occurred_at": "2026-05-19T13:55:00Z",
  "metadata": {
    "hostname": "demo-host-01",
    "os": "linux/amd64",
    "agent_version": "0.1.0",
    "started_at": "2026-05-19T13:55:00Z"
  }
}
```

**AGENT_STOPPED 예시:**

```json
{
  "event_id": "uuid",
  "actor": { "type": "AGENT", "id": "agent-001" },
  "action": "AGENT_STOPPED",
  "target": { "type": "AGENT", "id": "agent-001" },
  "result": "SUCCESS",
  "occurred_at": "2026-05-19T18:30:00Z",
  "metadata": { "reason": "SIGTERM" }
}
```

**JOB_EXECUTED 예시:**

```json
{
  "event_id": "uuid",
  "actor": { "type": "AGENT", "id": "agent-001" },
  "action": "JOB_EXECUTED",
  "target": { "type": "SCRIPT", "id": "/opt/scripts/check_disk.sh" },
  "result": "SUCCESS",
  "occurred_at": "2026-05-19T14:00:03Z",
  "metadata": {
    "execution_id": "8f4b1c9e-...",
    "schedule_id": "3a7d2b5f-...",
    "job_id": "9c1e8a4d-...",
    "job_type": "SCRIPT_JOB",
    "exit_code": 0
  }
}
```

`target.type`은 SCRIPT_JOB이면 `SCRIPT`, LOG_JOB이면 `LOG_FILE`. `target.id`는 실행 대상의 경로.

**필드 정의:**

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `event_id` | UUID | ● | 감사 이벤트 식별자 |
| `actor.type` | enum | ● | 데모는 `AGENT` 고정. 본개발에서 `USER`, `SYSTEM` 추가 |
| `actor.id` | string | ● | agent_id |
| `action` | enum | ● | `AGENT_STARTED` \| `AGENT_STOPPED` \| `JOB_EXECUTED` |
| `target.type` | enum | ● | `AGENT` \| `SCRIPT` \| `LOG_FILE` |
| `target.id` | string | ● | 대상 식별자 (agent_id 또는 경로) |
| `result` | enum | ● | `SUCCESS` \| `FAIL` \| `TIMEOUT` |
| `occurred_at` | RFC3339 | ● | 사건 발생 시각 (JOB_EXECUTED는 종료 시각) |
| `metadata` | object | ○ | action별 자유 형식 |

#### 7.5.4 `heartbeats`

OTel Collector가 `otlp_json` exporter로 발행. payload 구조는 OTLP JSON 표준.

**Agent 측 송신 규약:**

| 항목 | 값 |
|---|---|
| metric name | `agent.heartbeat` |
| metric type | Gauge (value: 1) |
| 송신 주기 | 10초 (데모 기본) |
| attribute `agent_id` | Agent UUID |

**BE 측 추출 규약:** `resourceMetrics[].scopeMetrics[].metrics[]` 경로에서
metric name이 `agent.heartbeat`인 항목을 찾고, dataPoints의 attribute에서
`agent_id`를 추출, dataPoint의 `timeUnixNano`를 해당 Agent의 last_seen으로
갱신. OTLP 표준 구조 참조: https://opentelemetry.io/docs/specs/otlp/

본개발에서 마샬링 `otlp_json` → protobuf 전환 예정 (ADR #2).

---

## 8. 데모 범위 / 본개발 ADR 후보

### 8.1 데모 범위 외 (Phase 1/2)

| 영역 | 단계 | 비고 |
|---|---|---|
| 인증/인가 (JWT, Knox 어댑터) | Phase 1 | Spring Security 도입 |
| 영속 저장소 (PG, OpenSearch) | Phase 1 | 기술 스택 선정 + 구축 |
| SQL_JOB | Phase 1 | Job 유형 추가 |
| LOG_JOB 로그 발생 시각 추출 | Phase 1 | sample_lines에 occurred_at 필드 추가 |
| Alert / Incident 도메인 | Phase 1 | |
| 시계열 메트릭 (OS metric) | Phase 2 | Infra Agent + VictoriaMetrics |
| 화면 LEGO + WebSocket 전환 | Phase 1 | 데모는 Thymeleaf 한 페이지 |

### 8.2 ADR 후보 리스트

| # | 주제 | 데모 결정 | 본개발 전환 |
|---|---|---|---|
| 1 | 메시지 스키마 관리 | 마크다운 + 수동 작성 | v0.6 8장 Schema Registry 결정 따름 |
| 2 | Heartbeat 마샬링 | `otlp_json` | protobuf |
| 3 | Audit 채널 | Kafka 직행 (OTel 미경유) | 동일 유지 |
| 4 | Consumer group | Agent별 unique group.id | 동일 유지 (Phase 1 규모 검토) |
| 5 | 토픽 명명 | 환경 prefix 없이 단순 | 환경/리전 prefix 검토 |
| 6 | 메시지 키 | `agent_id` | 동일 유지 |
| 7 | 인증/인가 | 없음 | JWT + Knox 어댑터 |
| 8 | 시각화 | Thymeleaf 한 페이지 | LEGO + WebSocket |
| 9 | SQL_JOB | 데모 범위 외 | Phase 1 포함 |
| 10 | LOG_JOB 로그 발생 시각 | 추출하지 않음 | sample_lines에 occurred_at 추가 |
| 11 | Agent 자가 등록 | audit `AGENT_STARTED`가 등록 겸함 | 별도 register endpoint + 사전 토큰 |
| 12 | 영속 저장소 | 없음 (in-memory) | PG + OpenSearch |
| 13 | OTel Collector 라우팅 | heartbeat 단일 경로 | metric/heartbeat 분리 (Phase 2) |
| 14 | LOG_JOB file_state | Agent local만 | 검토 (BE 보고 필요 여부) |
| 15 | `x-message-id` 중복 검사 | 발행만, 검사 없음 | 검사 도입 (at-least-once 대비) |
| 16 | 명령 만료 정책 | `valid_until` + 다음 트리거 90% 지점 | 정책 유지. 만료 시 audit 발행 추가 |
| 17 | Quartz misfire | `MISFIRE_INSTRUCTION_DO_NOTHING` | 동일 |
| 18 | 오프라인 Agent 발행 게이팅 | 없음 (`valid_until`로 자체 정리) | heartbeat 기반 발행 게이팅 + Alert 도입 검토 |

---

## 9. 종단 검증 시나리오

1. infra 기동:
   ```powershell
   docker compose -f infra/docker-compose.yml up -d
   ```
2. hub 실행:
   ```powershell
   cd hub
   mvn spring-boot:run
   ```
   - `curl http://localhost:8080/health` → `OK`
   - 브라우저 `http://localhost:8080/` 에 데모 콘솔 UI.

3. script-agent 기동:
   ```powershell
   cd ../script-agent
   go run ./cmd/agent
   ```
   hub 콘솔에 `AGENT_STARTED received: agent_id=<uuid> hostname=<host> os=<goos>/<goarch> agent_version=0.1.0` 로그.

4. Schedule 등록 (브라우저 권장 — `http://localhost:8080/` 폼에서 1분 간격 SCRIPT_JOB), 또는 REST:
   ```powershell
   curl -X POST http://localhost:8080/schedules `
        -H "Content-Type: application/json" `
        -d '{
          "job_type": "SCRIPT_JOB",
          "target_agent_id": "<위 AGENT_STARTED 로그의 agent_id>",
          "cron": "0 * * * * ?",
          "spec": {
            "script_path": "echo",
            "args": ["hello from hub"],
            "timeout_seconds": 5,
            "output_cap_bytes": 4096
          }
        }'
   ```

5. 매 분 hub 콘솔에:
   ```
   COMMAND sent: execution_id=<uuid> target_agent=<uuid> job_type=SCRIPT_JOB valid_until=<+54s> ...
   JOB_RESULT received: execution_id=<uuid> agent_id=<uuid> job_type=SCRIPT_JOB status=SUCCESS
   JOB_EXECUTED received: ...
   ```

6. script-agent 살아있는 동안 10초 간격(spec §7.5.4)으로 heartbeat이 silently 누적 — DEBUG 로그에서만 보이지만 `HeartbeatLatestMap`과 `AgentRegistry.lastSeen`이 갱신됨.

7. script-agent `Ctrl+C` → hub 콘솔에 `AGENT_STOPPED received: agent_id=<uuid> reason=interrupt`.

---

## 10. 외부 LLM/리뷰어에게 이 문서를 전달할 때

본 문서 한 장 + (선택) 다음을 함께 전달하면 100% 컨텍스트가 된다:

- 실제 코드 변경을 다룬다면: 해당 모듈 저장소 — `hub/src/`(hub.git), `script-agent/internal/`·`script-agent/cmd/agent/`(script-agent.git)
- 인프라 변경을 다룬다면: `infra/docker-compose.yml`, `infra/otel-collector-config.yml` (infra.git)
- ADR/spec 정밀 검토라면: `hub/docs/monitoring-demo-message-spec-v0.2.1.md` 원본
- 최신 진행 상태: 멀티레포이므로 **저장소별로** `git log --oneline -20` (hub / script-agent / infra 각각)

> **이 문서가 코드와 어긋나는 경우 원본 spec(`hub/docs/...v0.2.1.md`)과 실제 코드가 우선**한다. 본 문서는 합본·요약 + 외부 컨텍스트용이며, 운영 단일 진실(single source of truth)는 spec 문서 + 코드.

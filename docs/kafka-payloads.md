# Kafka Payload 스키마 — 8 토픽

이 파일은 **본 시스템 8 Kafka 토픽의 메시지 본문(payload) 구조**. envelope(헤더 메타데이터)는 별도 기준 문서 `docs/envelope.md`가 정의한다(상위 근거: `docs/master-design.md`(통합본) 6.8). 구현 분배(shared-libs/envelope)는 `docs/envelope.md` §7 참조.

JSON 직렬화 baseline. Phase 2/3에서 Schema Registry 도입 시 Avro 또는 Protobuf로 전환 — 그때 이 파일이 IDL 입력 (ADR #1).

## 토픽 명명 규칙 (ADR #5 / `adr/0005-topic-naming.md` — D-4(1) 2026-06-06 Accepted)

- **규칙(후보 B 승인)**: `<domain>-topic[-{subtype}][-{zone}]` — 의미 기반 일반 규칙. 환경 prefix 없음(통합본 §8.3 ADR#5). 아래 8토픽은 모두 이 규칙의 사례이며, 신규 토픽(Phase 2 metric ingest·rule-engine 계열 등)도 이 규칙으로 강제한다.
- **`command-topic`은 suffix 없는 단일 물리 토픽**으로 확정(D-4(1) (2) 승인). 현 단계 zone=1(단일 폐쇄망). **다중 zone 진입 시** `command-topic-{zone}` 전개는 미래 트리거이며, 통합본 §6.8(zone 전개=다중 zone 진입 시 미래 트리거) 조건 + 13장 §A(zone topology) 해소 후 도입한다 — 지금 고정/추측하지 않는다.
- **명시 예외**: `heartbeats-topic`의 복수형 domain은 baseline 호환을 위해 유지(규칙 예외로 기록).
- **물리명 → 최종 논리명 매핑**: **토픽 재명명(T4-1)은 2026-06-07 완료** — 3토픽(`commands`/`audit-events`/`heartbeats`)은 물리명=논리명 일치(e2e 회귀 0, `e2e/results/20260607-080703.md`). 잔여는 `job-results` → `result-topic-job`/`result-topic-log` 분리(result-topic 분리, T4-2)뿐이다.

| 현행 물리명 | 최종 논리명 (규칙 B) | 상태 |
|---|---|---|
| `command-topic` | `command-topic` | **일치 (T4-1 완료)** — 단일(다중 zone 진입 시 `-{zone}`) |
| `job-results` | `result-topic-job` / `result-topic-log` | **T4-2 잔여**(토픽명 분리 — §6.9.2 항목1, ADR 소속=D-5/ADR#5 간접). payload는 2단계(**ADR#19**): 현 단계 계약=공통 `JobResult`, 목표 계약=각 절 ② 평면 스키마(후속 Track). 토픽명 "일치" 전환은 infra/script-agent 컷오버+e2e 후 복귀 게이트 |
| `audit-topic` | `audit-topic` | **일치 (T4-1 완료)** |
| `heartbeats-topic` | `heartbeats-topic` | **일치 (T4-1 완료)** — 복수형 명시 예외 |
| (신규) | `alert-topic` / `notification-topic` | Phase 1 신설(§6.9.3·§6.9.5) |
| (Phase 2) | `metrics-topic` | Phase 2 |

## 공통 규약

- 모든 필드는 snake_case
- 시간: RFC3339 UTC (예: `"2026-05-19T14:00:00Z"`)
- ID: UUIDv4 string (예외: trace_id는 16-byte hex)
- 누락 허용 필드는 `optional` 명시

---

## `command-topic`

Job 실행 명령. hub-be Quartz → script-agent.

> 최종 논리명 = `command-topic` (단일 물리 토픽, 규칙 B `<domain=command>-topic`). 현행 물리명 `commands`. **다중 zone 진입 시** `command-topic-{zone}` 전개(미래, 통합본 13장 §A 해소 후 — ADR #5 §4 Open).

```json
{
  "execution_id": "uuid",          // BE Quartz 생성, 결과 chain 키
  "schedule_id": "uuid",
  "job_id": "uuid",
  "target_agent_id": "uuid",       // = 메시지 키
  "mode": "prod | validation",     // validation 시 sandbox
  "job_type": "SHELL | SQL | LOG", // ADR #9 SQL Phase 1
  "script_ref": {
    "storage": "minio",
    "bucket": "scripts",
    "object_key": "...",
    "sha256": "..."                // 무결성 검증
  },
  "parameters": {...},             // job_type별
  "timeout_seconds": 60,
  "valid_until": "RFC3339",        // ADR #16, 만료 시 실행 X + 만료 audit
  "scheduled_at": "RFC3339"
}
```

## `result-topic-job`

Shell/SQL Job 실행 결과. script-agent → script-result-service / rule-engine-script.

> 최종 논리명 = `result-topic-job` (규칙 B `<domain=result>-topic-<subtype=job>`). 현행 물리명 `job-results`(Phase 1 분리, §6.9.2 항목1).
>
> **payload 위상 = 2단계 (ADR#19, `adr/0019-result-payload-staging.md`)**: 토픽 분리(T4-2)와 payload 필드 정렬을 독립 단계로 둔다. 아래 **① 현 단계 계약**(공통 `JobResult`)이 Phase 1 현재 검증 기준이고, **② 목표 계약**(평면 스키마)은 후속 Track 도달 목표다. ②와 코드가 다른 것은 drift가 아니라 의도된 단계 차이.

**① 현 단계 (Phase 1) 계약 — 공통 `JobResult`** (= 동결 데모 spec v0.2.1 §5.2 구조, ADR#19). `result-topic-job`/`result-topic-log`가 같은 구조를 공유하고 `job_type`에 따라 `script`/`log` 중 하나만 채운다. envelope 4종 적용, key=`agent_id`. **hub/script-agent 코드의 현 단계 검증 기준은 이 블록이다.** 현 단계 `job_type` 도메인 = `SCRIPT_JOB | LOG_JOB`(데모 §5.2)이고, result-topic-job은 `SCRIPT_JOB` 결과가 `script`를 채운다. **`SQL_JOB`은 현 단계에 미존재**하며 ADR#9/T2-7로 Phase 1 추가 예정 — 추가 시 result-topic-job에 실린다(목표 enum의 `SQL`에 대응).

```json
{
  "execution_id": "uuid",
  "schedule_id": "uuid",
  "job_id": "uuid",
  "agent_id": "uuid",              // = 메시지 키
  "job_type": "SCRIPT_JOB | LOG_JOB",     // 현 단계 enum (목표는 SHELL|SQL|LOG)
  "status": "SUCCESS | FAIL | TIMEOUT",   // 현 단계 enum (목표는 소문자)
  "started_at": "RFC3339",
  "finished_at": "RFC3339",
  "script": {                      // SCRIPT_JOB일 때 채움, 아니면 null
    "exit_code": 0,
    "stdout_cap": "...",
    "stderr_cap": "...",
    "truncated": false
  },
  "log": null                      // LOG_JOB일 때 채움(result-topic-log 절 참조), 아니면 null
}
```

**② 목표 (target) 계약 — 후속 Track 도달 목표** (ADR#19: 분리 후 별 Track에서 아래로 정렬). 정렬 항목별 Track/ADR 추적은 ROADMAP(`docs/phase1/ROADMAP_PHASE1_v0_3.md`)이 단일 출처 — 이 절에서 미결 ADR/Track을 선결정하지 않는다.

```json
{
  "execution_id": "uuid",
  "agent_id": "uuid",              // = 메시지 키
  "job_id": "uuid",
  "mode": "prod | validation",
  "job_type": "SHELL | SQL",
  "started_at": "RFC3339",
  "finished_at": "RFC3339",
  "status": "success | failed | timeout | killed",
  "exit_code": 0,
  "stdout": "...",                 // 1MB 상한
  "stdout_ref": null,              // 1MB 초과 시 {bucket, object_key}, stdout은 null
  "stderr": "...",
  "metrics": {...}                 // job_type별 추출 메트릭 (옵션)
}
```

## `result-topic-log`

LOG Job raw 로그 라인. script-agent → script-result-service / rule-engine-log.

> 최종 논리명 = `result-topic-log` (규칙 B `<domain=result>-topic-<subtype=log>`). 현행 물리명 `job-results`(Phase 1 분리, §6.9.2 항목1).
>
> **payload 위상 = 2단계 (ADR#19)**: result-topic-job 절과 동일 원칙.

**① 현 단계 (Phase 1) 계약** — **result-topic-job 절 ①의 공통 `JobResult`와 동일 구조**(단일 앵커). LOG_JOB은 `log`(`{matched_lines_count, sample_lines: [string]}`)를 채우고 `script`=null. 현 단계 검증 기준은 그 공통 블록이다.

**② 목표 (target) 계약 — 후속 Track 도달 목표** (ADR#19). 항목별 추적: `occurred_at`=ADR#10/T3-7(TODO), `file_state`=ADR#14(동일 유지·NO-OP, T5-4), 평면화 등 = 후속 Track(ROADMAP 단일 출처).

```json
{
  "execution_id": "uuid",
  "agent_id": "uuid",              // = 메시지 키
  "job_id": "uuid",
  "log_source": "file | windows-event-log",
  "source_path": "/var/log/app.log",
  "file_state": {"offset": 12345, "inode": "..."},  // ADR #14, Agent local
  "started_at": "RFC3339",
  "finished_at": "RFC3339",
  "sample_lines": [
    {
      "line": "raw log line",
      "occurred_at": "RFC3339"      // ADR #10 Phase 1 추가, 추출 실패 시 finished_at
    }
  ],
  "line_count": 42
}
```

## `audit-topic`

사용자 액션 / 시스템 자동 처리 / Agent 액션 감사.

> 최종 논리명 = `audit-topic` (규칙 B `<domain=audit>-topic`). 현행 물리명 `audit-events`.

```json
{
  "audit_id": "uuid",
  "occurred_at": "RFC3339",
  "actor": {
    "type": "AGENT | USER | SYSTEM",
    "id": "agent_id | user_id | 'system'",
    "name": "..."                   // 표시용
  },
  "action": "AGENT_STARTED | AGENT_STOPPED | JOB_EXECUTED | POLICY_CREATED | USER_ROLE_CHANGED | INCIDENT_ACKED | ...",
  "subject": {                       // 액션의 대상
    "type": "agent | job | rule | user | incident | notification",
    "id": "uuid",
    "name": "..."
  },
  "context": {...},                  // action별
  "result": "success | failed",
  "site_id": "..."
}
```

키는 actor 단위 (`agent_id` / `user_id` / `system`).

## `heartbeats-topic` (envelope 예외 — OTLP 표준)

OTel Collector가 OTLP heartbeat 메시지를 그대로 재발행. metric name `agent.heartbeat` (Gauge, value=1) + attribute `agent_id`.

> 최종 논리명 = `heartbeats-topic` (규칙 B 사례, 단 복수형 domain은 **명시 예외** — baseline 호환). 현행 물리명 `heartbeats`.

페이로드는 OTLP MetricsData protobuf (Phase 1, ADR #2). 데모는 `otlp_json` → Phase 1 protobuf 전환.

```
파싱은 OTel Java SDK 사용. shared-libs/otel 모듈이 wrapper 제공.
```

## `alert-topic`

Rule Engine 평가 결과 + Agent State OFFLINE Alert.

> 최종 논리명 = `alert-topic` (규칙 B `<domain=alert>-topic`). Phase 1 신설(§6.9.3·§6.9.5).

```json
{
  "alert_id": "uuid",
  "rule_id": "uuid",                // null 가능 (Agent OFFLINE은 룰 기반 아님)
  "target_id": "agent_id | resource_id",
  "severity": "Critical | Major | Minor | Warning",
  "event_type": "triggered | resolved",
  "triggered_at": "RFC3339",
  "rule_domain": "script | log | metrics | agent-state",
  "context": {...},                 // domain별
  "execution_id": "uuid",           // 옵션 (Job 결과 평가 시)
  "trace_id": "hex"                 // 옵션 OTel
}
```

키는 `(rule_id, target_id)` 조합 (rule_id 없으면 `("agent-offline", target_id)`).

## `notification-topic`

Incident 상태 변경 → 통보 트리거. event-service → notification-service.

> 최종 논리명 = `notification-topic` (규칙 B `<domain=notification>-topic`). Phase 1 신설(§6.9.3·§6.9.5).

```json
{
  "notification_trigger_id": "uuid",
  "incident_id": "uuid",            // = 메시지 키
  "state_transition": "opened | severity_changed | resolved | closed",
  "previous_severity": "Major",     // 옵션
  "current_severity": "Critical",
  "incident_summary": {
    "rule_group_id": "uuid",
    "rule_ids": ["uuid", ...],
    "alert_ids": ["uuid", ...],
    "target_ids": ["uuid", ...],
    "first_alert_at": "RFC3339",
    "last_alert_at": "RFC3339",
    "alert_count": 12,
    "kdb_ref": null                 // KDB placeholder
  },
  "occurred_at": "RFC3339",
  "site_id": "..."
}
```

## `metrics-topic` (Phase 2, envelope 예외 — OTLP 표준)

OTel Collector → metric-ingest-service + rule-engine-metrics. OTLP MetricsData protobuf 표준. Phase 1에선 미사용.

> 최종 논리명 = `metrics-topic` (규칙 B 사례, 복수형 metric domain). Phase 2 신규 토픽도 규칙 B로 강제(D-4(1) (3) 승인).

---

## 변경 정책

- 본 spec 변경 = breaking change 가능성 → monitoring-docs PR + 영향 모듈 협의
- 호환 변경 (필드 추가, optional) → minor bump
- 호환 깨짐 (필드 제거/타입 변경) → major bump + `x-message-version` 증가
- Schema Registry 도입 시 (Phase 2/3 ADR #1) — 이 파일이 IDL 입력

## 데모 일관성

데모 spec v0.2.1과의 일관성은 `docs/master-design.md`(통합본) §6.9 데모 일관성 매트릭스 참조. Phase 0 → Phase 1 전환 시 정정 항목 11개.

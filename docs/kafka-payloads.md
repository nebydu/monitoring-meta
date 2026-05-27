# Kafka Payload 스키마 — 8 토픽

이 파일은 **본 시스템 8 Kafka 토픽의 메시지 본문(payload) 구조**. envelope는 별도(`v0_9/04_데이터흐름.md` 6.8 + shared-libs/envelope).

JSON 직렬화 baseline. Phase 2/3에서 Schema Registry 도입 시 Avro 또는 Protobuf로 전환 — 그때 이 파일이 IDL 입력 (ADR #1).

## 공통 규약

- 모든 필드는 snake_case
- 시간: RFC3339 UTC (예: `"2026-05-19T14:00:00Z"`)
- ID: UUIDv4 string (예외: trace_id는 16-byte hex)
- 누락 허용 필드는 `optional` 명시

---

## `command-topic-{zone}`

Job 실행 명령. hub-be Quartz → script-agent.

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

페이로드는 OTLP MetricsData protobuf (Phase 1, ADR #2). 데모는 `otlp_json` → Phase 1 protobuf 전환.

```
파싱은 OTel Java SDK 사용. shared-libs/otel 모듈이 wrapper 제공.
```

## `alert-topic`

Rule Engine 평가 결과 + Agent State OFFLINE Alert.

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

---

## 변경 정책

- 본 spec 변경 = breaking change 가능성 → monitoring-docs PR + 영향 모듈 협의
- 호환 변경 (필드 추가, optional) → minor bump
- 호환 깨짐 (필드 제거/타입 변경) → major bump + `x-message-version` 증가
- Schema Registry 도입 시 (Phase 2/3 ADR #1) — 이 파일이 IDL 입력

## 데모 정합성

데모 spec v0.2.1과의 정합성은 `v0_9/04_데이터흐름.md` 6.9 매트릭스 참조. Phase 0 → Phase 1 전환 시 정정 항목 11개.

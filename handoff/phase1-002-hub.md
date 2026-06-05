# 작업 spec — phase1-002-hub (Track 0 — T0-3 산출물 → T0-4 구현 지시 — hub/Java)

> 이 handoff는 hub(Java/Spring) 세션이 받아 구현한다. envelope 적용 **범위**는 phase1-001에서 확정됐고(`handoff/phase1-001-envelope-scope.md`), 본 문서는 hub repo에서 **실제 구현할 것만** 한정한다. 코드 작업은 hub 세션에서 한다 — meta는 지시서만 쓴다.

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-002-hub` |
| 대상 repo | `hub` (Java/Spring) |
| 기준 monitoring-meta commit | `0d509a2aaf845264aed59597f7ad65ed90ed168b` (full 40자). **실행 전 `git rev-parse HEAD`로 monitoring-meta 최신 재확인** |
| 작성일 | 2026-06-05 |
| 근거 | `docs/envelope.md` §2.2·§2.3·§4.1·§6, phase1-001 §5.2, `adr/0005`(D-4(2) RESOLVED) |
| 선행 | phase1-001(범위 확정), envelope.md(정본) |

## 2. 문서 위상 (혼동 금지)

ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(Phase 1+ 목표)**.

- 데모 spec v0.2.1 §2.2 헤더 4종 발행/검사 동작은 **회귀 0**이어야 한다.
- envelope.md가 박혔다고 코드가 자동으로 따르는 게 아니다. 현재 hub 코드의 위상을 먼저 판단한 결과는 §4 배경에 정리돼 있다.

## 3. ground truth 참조 (상대 경로, 사본 두지 마라)

- `../monitoring-meta/docs/envelope.md` — envelope 4종 정본. 특히 **§2.2(헤더 정의)·§2.3(알 수 없는 x-source 가드)·§4.1(공통 토픽군)·§6(Phase 0 회귀)·§7(현재 구현 위치)**
- `../monitoring-meta/docs/kafka-payloads.md` — 8토픽 payload 정본(잠정 토픽명)
- `../monitoring-meta/docs/통합본_v0_9.md` §4.4.1 / §6.8
- `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` §2.2 — Phase 0 회귀 기준
- `../monitoring-meta/handoff/phase1-001-envelope-scope.md` — 범위/선후 확정
- `../monitoring-meta/handoff/phase1-002-000-impact.md` — 토픽별 현황 판정(왜 작업이 이것뿐인지)

## 4. 배경 — hub 현황 (분석 결과)

hub에서 envelope이 닿는 지점:

- **producer(`producer/CommandPublisher.java`)**: `command-topic`(코드명 `commands`)에 envelope 4종을 **이미 발행 완료**(`x-message-id` UUIDv4, `x-message-version="1"`, `x-source="monitoring-be"`, `x-trace-id`는 값 있을 때만). 헤더 키 상수는 publisher 내부 인라인(`HEADER_*`). → **신규 적용 작업 없음. 회귀만 보장.**
- **consumer 2종**:
  - `ingest/jobresult/JobResultConsumer.java` (`job-results` = `result-topic-job` consume)
  - `ingest/audit/AuditConsumer.java` (`audit-events` = `audit-topic` consume)
  - 둘 다 현재 `record.value()`(payload)만 처리하고 **envelope 헤더를 전혀 참조하지 않는다** → "우연히 안 깨지는" 상태. envelope §2.3의 "알 수 없는 `x-source`에 깨지지 않는다"는 **의도된 가드로 명시·고정**해야 한다.
- **heartbeats consumer**(`ingest/heartbeat/HeartbeatConsumer.java`): OTLP 위임군 — envelope 4종 미적용. **건드리지 마라**(제외 회귀 검증 대상).

### 이번 구현 대상 (실재 + 명시화 필요만)

| 대상 | 작업 | 근거 |
|---|---|---|
| `JobResultConsumer` / `AuditConsumer` | 알 수 없는 `x-source` 가드 **명시화** + 테스트 | envelope §2.3 |
| `CommandPublisher` | 헤더 발행 동작 회귀 0 확인(변경 없음 원칙) | envelope §6, 데모 §2.2 |

### 이번 범위 **밖** (이연 — 절대 지금 구현하지 마라)

| 항목 | 이연 사유 | 귀속 |
|---|---|---|
| `result-topic-log` 분리·해당 consumer | 토픽 분리(result job/log) 자체가 미수행 | 통합본 §6.9.2 항목1, 별도 Track |
| `alert-topic` producer/consumer | Alert Processor 미구현 | Track 2 |
| `notification-topic` producer/consumer | Notification/Incident Service 미구현 | Track 3 |
| `x-message-id` dedup(Redis) | baseline만 결정, 정확한 시점 Open | envelope §9 O1, ADR#15, T2-8 |
| `x-trace-id` trace context 복원 | consumer 측 Phase 1 별도 작업 | envelope §2.4·§6, 별도 |
| 토픽 **재명명**(`commands`→`command-topic` 등) | envelope은 토픽명 독립, D-4(1) 비준 대기 | Track 4-1 |

## 5. 작업 분해

### 5.1 consumer `x-source` 가드 명시화 (핵심 작업)

- `JobResultConsumer.consume` / `AuditConsumer.consume`에서, envelope §2.3을 만족하는 **명시적 가드**를 둔다:
  - `x-source` 헤더가 **알려진 값 목록(비규범)에 없어도** consume이 정상 진행되어야 한다(폐쇄 enum 아님).
  - 구현 형태는 hub 세션 재량이되, "헤더를 읽어 enum 강제 검증 → 미일치 시 reject/throw" 같은 동작을 **넣지 마라**(가드의 목적은 그 반대다).
  - 권장: `x-source`가 없거나 미지값이어도 처리 계속. 필요 시 미지값일 때 **debug 로깅만**(처리 흐름 영향 없음). payload 파싱·ring buffer 적재 동작은 불변.
  - 알려진 값 목록(envelope §2.3, 비규범): `script-agent`, `monitoring-be`, `otel-collector`, + Phase 1 신규(`infra-agent`/`rule-engine` 등). **이 목록을 코드에 폐쇄 enum으로 박지 마라** — drift/검증 대조 대상이 아니다(envelope §2.3 마지막 문단).
- **테스트(mvn test)**: 미지 `x-source`(예: `"unknown-future-service"`) 헤더가 달린 메시지를 consume해도 payload가 정상 적재됨을 검증하는 단위 테스트 추가. `x-source` 헤더 부재 케이스도 포함.

### 5.2 producer 회귀 보장 (변경 없음)

- `CommandPublisher`의 헤더 4종 발행 동작·키 문자열·`x-message-version="1"`·`x-source="monitoring-be"`·`x-trace-id` 옵셔널 생략 로직을 **변경하지 마라**. 기존 `CommandPublisherTest`가 그대로 통과해야 한다.

### 5.3 헤더 키 상수 정리 (선택, 가벼움)

- 현재 헤더 키 문자열이 `CommandPublisher`(producer)와 consumer 가드(신규)에 중복될 수 있다. 단일 상수 지점으로 모으는 리팩터는 **권장이되 강제 아님**. 모을 경우에도 **문자열 값은 데모 §2.2와 1바이트도 다르면 안 된다**(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`).

### 5.4 토픽명 외부화 점검 (D-4(1) 비준 대비)

- 토픽명은 `config/KafkaConfig.java` `Topics` 상수에 모여 있다(현 데모명 `commands`/`job-results`/`audit-events`/`heartbeats`). **이름을 바꾸지 마라**(재명명은 Track 4-1). 단일 상수 지점이 유지되는지만 확인. 새로 토픽 문자열을 다른 곳에 하드코딩하지 마라.

## 6. DoD / 검증

- [ ] `JobResultConsumer`/`AuditConsumer`가 **미지 `x-source` 값·헤더 부재**에도 payload를 정상 처리(단위 테스트로 고정).
- [ ] consumer가 `x-source`를 **폐쇄 enum으로 강제 검증하지 않음**(미지값 reject 동작 없음).
- [ ] **Phase 0 회귀 0**: 데모 spec §2.2 `command-topic` 헤더 4종 발행 동작·키 문자열·`x-message-version="1"`·`x-source="monitoring-be"`·`x-trace-id` 옵셔널 생략 불변. 기존 `CommandPublisherTest` PASS.
- [ ] heartbeats(OTLP 위임군)에 envelope 4종 미적용 유지 — `HeartbeatConsumer` 미변경.
- [ ] 토픽명 미변경(재명명은 본 작업 아님).
- [ ] `mvn test` 전체 PASS.
- [ ] **범위 밖 미착수**: result-log 분리/alert/notification/dedup/trace 복원에 손대지 않음.
- [ ] polyrepo 종단 검증은 meta `e2e-tester`가 별도 수행(본 세션 아님).

## 7. 미결정 사안 (있으면 실행 전 멈춤)

- **없음(block 아님).** 본 작업은 envelope.md §2.3·§6에 확정된 동작만 코드로 고정한다.
- D-4(1) 토픽 명명 컨벤션은 `adr/0005` 비준 대기지만 **본 작업과 독립**(토픽명 미변경). 막히지 않는다. 추측으로 토픽명을 동결하지 마라.

## 8. 결과 보고 스키마 (hub 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["x-source 가드 적용 결과 / 회귀 확인"],
  "blockers": ["사람 결정 필요 항목(없으면 빈 배열)"],
  "next_action": "다음에 할 일 한 줄"
}
```

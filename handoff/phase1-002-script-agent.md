# 작업 spec — phase1-002-script-agent (Track 0 T0-3: envelope 적용 구현 — script-agent/Go)

> 이 handoff는 script-agent(Go) 세션이 받아 구현한다. envelope 적용 **범위**는 phase1-001에서 확정됐고(`handoff/phase1-001-envelope-scope.md`), 본 문서는 script-agent repo에서 **실제 구현할 것만** 한정한다. 코드 작업은 script-agent 세션에서 한다 — meta는 지시서만 쓴다.

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-002-script-agent` |
| 대상 repo | `script-agent` (Go) |
| 기준 monitoring-meta commit | `0d509a2aaf845264aed59597f7ad65ed90ed168b` (full 40자). **실행 전 `git rev-parse HEAD`로 monitoring-meta 최신 재확인** |
| 작성일 | 2026-06-05 |
| 근거 | `docs/envelope.md` §2.2·§2.3·§4.1·§6·§7, phase1-001 §5.2, `adr/0005`(D-4(2) RESOLVED) |
| 선행 | phase1-001(범위 확정), envelope.md(정본) |

## 2. 문서 위상 (혼동 금지)

ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(Phase 1+ 목표)**.

- 데모 spec v0.2.1 §2.2 헤더 4종 발행 동작은 **회귀 0**이어야 한다.
- envelope.md §7이 현재 구현 위치를 `internal/model/envelope.go`(키 상수+고정값), `internal/kafka/envelope.go`(`BuildHeaders`, 옵셔널 trace 생략)로 명시한다 — 이미 정본과 정합.

## 3. ground truth 참조 (상대 경로, 사본 두지 마라)

- `../monitoring-meta/docs/envelope.md` — envelope 4종 정본. 특히 **§2.2(헤더 정의)·§2.3(알 수 없는 x-source 가드)·§4.1(공통 토픽군)·§6(Phase 0 회귀)·§7(현재 구현 위치)**
- `../monitoring-meta/docs/kafka-payloads.md` — 8토픽 payload 정본(잠정 토픽명)
- `../monitoring-meta/docs/통합본_v0_9.md` §4.4.1 / §6.8
- `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` §2.2 — Phase 0 회귀 기준
- `../monitoring-meta/handoff/phase1-001-envelope-scope.md` — 범위/선후 확정
- `../monitoring-meta/handoff/phase1-002-000-impact.md` — 토픽별 현황 판정(왜 작업이 이것뿐인지)

## 4. 배경 — script-agent 현황 (분석 결과)

script-agent에서 envelope이 닿는 지점:

- **producer 2종 — 이미 envelope 4종 발행 완료**:
  - `internal/audit/publisher.go` (`audit-events` = `audit-topic`): `publish`가 `kafka.BuildHeaders(NewMessageID(), "")` 사용(L132).
  - `internal/jobresult/publisher.go` (`job-results` = `result-topic-job`): `Publish`가 동일 패턴(L31).
  - 공통 빌더 `internal/kafka/envelope.go` `BuildHeaders`가 `x-message-id`/`x-message-version="1"`/`x-source="script-agent"` 발행, `traceID==""`면 `x-trace-id` 생략 — envelope §2.4·§6 정합. → **producer 신규 적용 작업 없음. 회귀만 보장.**
- **consumer(`cmd/agent/main.go` `consumeCommands`)**: `commands`(= `command-topic`)를 consume. 현재 `msg.Value`(payload)만 `json.Unmarshal`하고 **envelope 헤더를 전혀 참조하지 않는다** → "우연히 안 깨지는" 상태. envelope §2.3 "알 수 없는 `x-source`에 깨지지 않는다"를 **의도된 가드로 명시·고정**해야 한다.

### 이번 구현 대상 (실재 + 명시화 필요만)

| 대상 | 작업 | 근거 |
|---|---|---|
| `consumeCommands`(command consumer) | 알 수 없는 `x-source` 가드 **명시화** + 테스트 | envelope §2.3 |
| audit/jobresult producer | 발행 동작 회귀 0 확인(변경 없음) | envelope §6, 데모 §2.2 |

### 이번 범위 **밖** (이연 — 절대 지금 구현하지 마라)

| 항목 | 이연 사유 | 귀속 |
|---|---|---|
| `result-topic-log` 분리 발행 | 토픽 분리(result job/log) 자체가 미수행 | 통합본 §6.9.2 항목1, 별도 Track |
| `alert-topic`/`notification-topic` | 해당 서비스 미구현(hub/별도 컴포넌트) | Track 2/3 |
| `x-message-id` dedup | consumer 측 + baseline만 결정 | envelope §9 O1, ADR#15, T2-8 |
| `x-trace-id` 발행 값 채우기 / 복원 | 현재 `""` 발행은 정합(옵셔널 생략). 값 주입은 OTel 통합 별도 작업 | envelope §2.4, 별도 |
| 토픽 **재명명**(`commands`→`command-topic` 등) | envelope은 토픽명 독립, D-4(1) 비준 대기 | Track 4-1 |

## 5. 작업 분해

### 5.1 command consumer `x-source` 가드 명시화 (핵심 작업)

- `consumeCommands`에서 envelope §2.3을 만족하는 **명시적 가드**를 둔다:
  - `x-source` 헤더가 **알려진 값 목록(비규범)에 없어도** 명령 처리가 정상 진행되어야 한다(폐쇄 enum 아님).
  - "헤더를 읽어 source enum 강제 검증 → 미일치 시 skip/error" 같은 동작을 **넣지 마라**(가드의 목적은 그 반대다).
  - 권장: `msg.Headers`에서 `x-source`를 읽되, 없거나 미지값이어도 dispatch 계속. 미지값일 때 **debug 로깅만**(처리 흐름·commit 영향 없음). payload unmarshal·dispatch·commit 동작은 불변.
  - 알려진 값 목록(envelope §2.3, 비규범): `script-agent`, `monitoring-be`, `otel-collector`, + Phase 1 신규. **코드에 폐쇄 enum으로 박지 마라** — drift/검증 대조 대상이 아니다.
- **테스트(go test ./...)**: 미지 `x-source`(예: `"unknown-future-service"`) 헤더가 달린 command 메시지를 처리해도 dispatch가 정상 진행됨을 검증. `x-source` 부재 케이스도 포함. (consume 루프를 직접 테스트하기 어렵다면 가드 판정 함수를 분리해 단위 테스트.)

### 5.2 producer 회귀 보장 (변경 없음)

- `BuildHeaders`·`internal/model/envelope.go` 상수(`HeaderMessageID` 등, `MessageVersion="1"`, `SourceAgent="script-agent"`)·audit/jobresult publisher의 발행 동작을 **변경하지 마라**. 기존 `internal/kafka/envelope_test.go` 및 publisher 테스트가 그대로 통과해야 한다.

### 5.3 토픽명 외부화 점검 (D-4(1) 비준 대비)

- 토픽명은 이미 `internal/config/config.go`에서 env(`KAFKA_TOPIC_COMMANDS`/`_JOB_RESULTS`/`_AUDIT_EVENTS`)로 외부화됨(기본값 데모명). **추가 작업 없음.** 기본값(`commands` 등)을 **바꾸지 마라**(재명명은 Track 4-1). 새 토픽 문자열을 코드에 하드코딩하지 마라.

## 6. DoD / 검증

- [ ] `consumeCommands`가 **미지 `x-source` 값·헤더 부재**에도 command를 정상 dispatch(테스트로 고정).
- [ ] consumer가 `x-source`를 **폐쇄 enum으로 강제 검증하지 않음**(미지값 skip/error 동작 없음).
- [ ] **Phase 0 회귀 0**: 데모 spec §2.2 audit/jobresult 발행 헤더 4종·키 문자열·`x-message-version="1"`·`x-source="script-agent"`·`x-trace-id` 옵셔널 생략 불변. 기존 `envelope_test.go`/publisher 테스트 PASS.
- [ ] 토픽명·기본값 미변경(재명명은 본 작업 아님).
- [ ] `go test ./...` 전체 PASS.
- [ ] **범위 밖 미착수**: result-log 분리/alert/notification/dedup/trace 값 주입에 손대지 않음.
- [ ] polyrepo 종단 검증은 meta `e2e-tester`가 별도 수행(본 세션 아님).

## 7. 미결정 사안 (있으면 실행 전 멈춤)

- **없음(block 아님).** 본 작업은 envelope.md §2.3·§6에 확정된 동작만 코드로 고정한다.
- D-4(1) 토픽 명명 컨벤션은 `adr/0005` 비준 대기지만 **본 작업과 독립**(토픽명 미변경). 추측으로 토픽명을 동결하지 마라.

## 8. 결과 보고 스키마 (script-agent 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["x-source 가드 적용 결과 / 회귀 확인"],
  "blockers": ["사람 결정 필요 항목(없으면 빈 배열)"],
  "next_action": "다음에 할 일 한 줄"
}
```

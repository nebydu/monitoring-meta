# 작업 spec — phase1-040-script-agent (T4-1 토픽 재명명: script-agent)

> 이 handoff는 script-agent 세션이 받아 실행한다. Phase 0 물리 토픽명을 ADR#5 규칙 B 최종 논리명으로 재명명하는 T4-1의 **script-agent 몫**(env default 값 교체)이다. **실행 순서 2순위** — infra(토픽 생성) 후 hub와 동시 컷오버. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-040-script-agent` (T4-1) |
| 대상 repo | `script-agent` (Go) |
| 기준 monitoring-meta commit | `f28587ad7304fdd59ea35723e8ca2ca9319728ba` (실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted** / `docs/kafka-payloads.md` 토픽 명명 규칙 / 영향 분석 `handoff/phase1-040/phase1-040-000-impact.md` §2.2 |
| 작성일 | 2026-06-06 |
| 실행 순서 | **2순위** (infra 1순위 후, hub와 동시 컷오버) |

## 2. 재명명 매핑 (T4-1 = 3토픽 중 script-agent 발행 2종)

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) | script-agent 관여 |
|---|---|---|
| `commands` | `command-topic` | 구독(reader) |
| `audit-events` | `audit-topic` | 발행(publisher) |
| `heartbeats` | `heartbeats-topic` | **해당 없음** — heartbeats는 OTel(infra)이 발행, script-agent는 Kafka로 직접 발행 안 함 |

- **`job-results`는 그대로 둔다** — 분리는 T4-2(D-5 미결).

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — env default 값만)

토픽명이 전부 env로 외부화돼 있다. **코드 default 값 2곳만** 교체한다. env 키 *이름*은 유지(외부 override 호환).

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `internal/config/config.go:56` | `getenv("KAFKA_TOPIC_COMMANDS", "commands")` | default → `"command-topic"` |
| `internal/config/config.go:58` | `getenv("KAFKA_TOPIC_AUDIT_EVENTS", "audit-events")` | default → `"audit-topic"` |
| `internal/config/config.go:57` | `getenv("KAFKA_TOPIC_JOB_RESULTS", "job-results")` | **변경하지 않음** (T4-2) |

자동 추종(참고용 — 직접 손댈 필요 없음): producer `internal/jobresult/publisher.go`·`internal/audit/publisher.go`, reader `internal/kafka/reader.go`는 모두 cfg에서 토픽을 주입받음. heartbeats는 `internal/heartbeat/heartbeat.go`가 Kafka 직접 발행 아님(참조 없음).

### 3.2 env 키 이름 정책 (결정 3)

- env 키 `KAFKA_TOPIC_COMMANDS` / `KAFKA_TOPIC_AUDIT_EVENTS` **이름은 유지**한다(default 값만 교체). 외부에서 이 키로 override하는 환경이 깨지지 않도록.

### 3.3 테스트/문서 동기화 (이번 handoff 포함 — 결정 6)

- `internal/job/dispatcher_test.go`(160·185·204·206행 등)의 `job-results`/`audit-events`는 **주석/로그 문자열**(토픽 단언 아님, 토픽은 cfg 주입). 동작 무관 — 문서 동기화 차원에서 구 토픽명만 새 이름으로 정리(`job-results`는 유지).
- `README.md`(26·59~64·98~100·120~131행), `.claude/`(agents·CLAUDE.md) 주석의 구 토픽명 → 새 이름 동기화. 회귀 무관.
- (비기능 메모) `internal/heartbeat/heartbeat.go:3`의 `otlp_json` 주석은 ADR#2 관련 별건 — 이번 T4-1 범위 아님.

## 4. 적용 결정 (사람 확정 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| 컷오버 방식 | **동시 컷오버** — infra 토픽 생성 후 hub/script-agent 같은 윈도우. 이중 발행 없음. |
| 구 토픽 처리 | **클린 재기동 전제 — 별도 처리 불요.** |
| env 키 정책 | 키 이름 유지, **default 값만 교체.** |
| 회귀 0 정의 | 토픽명 문자열이 아니라 **동작 등가**(흐름·payload·envelope·키·발행순서) + 재명명 완전성. |
| 문서/주석 | 이번 handoff에 함께 정리. |

## 5. DoD / 검증

- [ ] `config.go` default 2개 = `command-topic` / `audit-topic`. `KAFKA_TOPIC_JOB_RESULTS` default=`job-results` 유지.
- [ ] env 키 이름 불변.
- [ ] `go build ./...` / `go test ./...` 그린(문서·default 변경이라 영향 적으나 1회 확인).
- [ ] README·주석 구 토픽명 잔존 0(job-results 제외).
- [ ] 동결 spec·무관 파일 변경 없음, heartbeats 관련 코드 무변경(해당 없음).

## 6. 가드 (공통)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.**
- env default **값만** 교체, 키 이름 유지.
- 재명명은 Phase 1 **forward 변경**(Phase 0 회귀 아님).
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행** — script-agent 세션이 직접 e2e 돌리지 않는다. (단 `go test`는 script-agent가 돌린다.)

## 7. 미결정 사안

- 없음. 3토픽은 `adr/0005` Accepted로 확정. 통합본 `[Open]`/`13_open`/미결 ADR에 걸리는 항목 없음.

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["config default 교체 / 테스트·문서 동기화 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

# 작업 spec — phase1-040-infra (T4-1 토픽 재명명: infra)

> 이 handoff는 infra 세션이 받아 실행한다. Phase 0 물리 토픽명을 ADR#5 규칙 B 최종 논리명으로 재명명하는 T4-1의 **infra 몫**(토픽 물리 생성 + OTel exporter 발행 토픽)이다. **실행 순서 1순위** — 토픽이 존재해야 hub/script-agent가 붙는다. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-040-infra` (T4-1) |
| 대상 repo | `infra` |
| 기준 monitoring-meta commit | `f28587ad7304fdd59ea35723e8ca2ca9319728ba` (실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted** / `docs/kafka-payloads.md` 토픽 명명 규칙 / 영향 분석 `handoff/phase1-040-000-impact.md` §2.3 |
| 작성일 | 2026-06-06 |
| 실행 순서 | **1순위** (hub/script-agent보다 먼저 — 토픽 생성·heartbeat 발행 기반) |

## 2. 재명명 매핑 (T4-1 = 3토픽)

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) |
|---|---|
| `commands` | `command-topic` |
| `audit-events` | `audit-topic` |
| `heartbeats` | `heartbeats-topic` |

- **`job-results`는 그대로 둔다** — 분리(→`result-topic-job`/`result-topic-log`)는 T4-2 소관이고 ADR 소속이 D-5(미결)다. 이번 작업에서 건드리지 않는다.

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — 토픽 물리 생성/발행)

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `docker-compose.yml:64` | `for t in commands job-results audit-events heartbeats` | `for t in command-topic job-results audit-topic heartbeats-topic` (job-results 유지) |
| `otel-collector-config.yml:19` | `topic: heartbeats` | `topic: heartbeats-topic` (kafka exporter 발행 토픽) |

> **heartbeats 동시 컷오버 주의**: `otel-collector-config.yml`의 exporter 토픽(`heartbeats-topic`)과 hub consumer(HEARTBEATS 상수)는 **같은 컷오버 윈도우**에 바뀌어야 한다. infra만 새 토픽으로 발행하고 hub가 구 토픽을 구독하면 e2e §6 heartbeat 수신이 timeout 실패한다(영향 분석 §4-4). 동시 컷오버(아래 §4) 전제로 진행.

### 3.2 문서/주석 동기화 (이번 handoff 포함 — 결정 6)

- `docker-compose.yml:75`(주석) "`heartbeats` 토픽으로 재발행" → `heartbeats-topic`으로 동기화.
- infra README 등에 구 토픽명(`commands`/`audit-events`/`heartbeats`)이 있으면 새 이름으로 동기화. `job-results`는 유지.

## 4. 적용 결정 (사람 확정 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| 컷오버 방식 | **동시 컷오버** — infra(토픽 생성) → hub/script-agent 같은 윈도우. 이중 발행 없음. |
| 구 토픽 처리 | **클린 재기동 전제 — 별도 삭제 절차 불요.** 클린 환경에선 구 토픽이 생성되지 않는다. (기존 데이터 있는 브로커면 수동 정리는 별건.) |
| 회귀 0 정의 | 토픽명 문자열이 아니라 **동작 등가**(메시지 흐름·payload·envelope·키·발행순서) + 재명명 완전성. e2e는 meta가 §3.3로 별도 검증. |

## 5. DoD / 검증

- [ ] `docker-compose.yml` kafka-init 루프가 `command-topic` / `audit-topic` / `heartbeats-topic` 생성(+`job-results` 유지). 구명 `commands`/`audit-events`/`heartbeats` 없음.
- [ ] `otel-collector-config.yml` exporter `topic: heartbeats-topic`.
- [ ] 인프라 기동 후 `kafka-topics --list`에 새 3토픽 + `job-results` 존재, 구 3토픽 미생성(클린 환경).
- [ ] 주석/README 구 토픽명 잔존 0(job-results 제외).
- [ ] 동결 데모 spec·코드 로직 외 무관 변경 없음.

## 6. 가드 (공통)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.** (infra repo엔 보통 없지만 사본 있으면 손대지 마라.)
- 재명명은 Phase 1 **forward 변경**이지 Phase 0 회귀가 아니다.
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행**한다 — infra 세션이 직접 e2e 돌리지 않는다.

## 7. 미결정 사안

- 없음. 3토픽은 `adr/0005` Accepted로 확정. 통합본 `[Open]`/`13_open`/미결 ADR에 걸리는 항목 없음. (다중 zone 전개·zone suffix는 T4-1 범위 밖 — 단일 `command-topic` 확정.)

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["kafka-init 토픽 / otel exporter 토픽 / 주석 동기화 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

## 9. 실행 결과 보고 (infra 세션 — 2026-06-06)

- 실행 시점 meta HEAD: `75047284858e56ce430485393857601cb2e4f7fd` (이 handoff를 추가한 커밋 — 기준 commit `f28587a` 직후이므로 drift 없음)
- infra 커밋: `d732de3`(T4-1 재명명), `a6946ec`(codex-gate profile — 별건) / origin/main push 완료

```json
{
  "status": "ok",
  "outputs": ["docker-compose.yml", "otel-collector-config.yml"],
  "findings": [
    "kafka-init: command-topic/audit-topic/heartbeats-topic 생성 + job-results 유지 — 클린 기동 후 kafka-topics --list로 신규 3토픽+job-results 존재, 구 3토픽 미생성 확인 (DoD 충족)",
    "otel exporter: topic heartbeats-topic 전환, collector 정상 기동(Everything is ready) 확인",
    "주석 2곳(docker-compose.yml:75, otel-collector-config.yml:3) 동기화 — repo 전체 구 토픽명 잔존 0 (README에는 원래 없음, job-results 제외)",
    "무관 변경 없음 (런타임 2곳 + 주석 2곳만 수정)"
  ],
  "blockers": [],
  "next_action": "같은 컷오버 윈도우에서 hub(HEARTBEATS 상수)·script-agent 재명명 적용 — 인프라는 새 토픽으로 기동 중이므로 hub가 구 토픽 구독 상태로 e2e를 돌리면 heartbeat 수신 실패(§3.1 주의 사항)"
}
```

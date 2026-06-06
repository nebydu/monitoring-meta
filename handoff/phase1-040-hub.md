# 작업 spec — phase1-040-hub (T4-1 토픽 재명명: hub)

> 이 handoff는 hub 세션이 받아 실행한다. Phase 0 물리 토픽명을 ADR#5 규칙 B 최종 논리명으로 재명명하는 T4-1의 **hub 몫**(Kafka 토픽 상수 값 교체 + 영향 테스트)이다. **실행 순서 2순위** — infra(토픽 생성) 후 script-agent와 동시 컷오버. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-040-hub` (T4-1) |
| 대상 repo | `hub` (Java/Spring) |
| 기준 monitoring-meta commit | `f28587ad7304fdd59ea35723e8ca2ca9319728ba` (실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted** / `docs/kafka-payloads.md` 토픽 명명 규칙 / 영향 분석 `handoff/phase1-040-000-impact.md` §2.1 |
| 작성일 | 2026-06-06 |
| 실행 순서 | **2순위** (infra 1순위 후, script-agent와 동시 컷오버) |

## 2. 재명명 매핑 (T4-1 = 3토픽)

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) |
|---|---|
| `commands` | `command-topic` |
| `audit-events` | `audit-topic` |
| `heartbeats` | `heartbeats-topic` |

- **`job-results`(JOB_RESULTS)는 그대로 둔다** — 분리는 T4-2(D-5 미결). 이번 작업에서 건드리지 않는다.

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — 단일 진실 = 상수 값)

`KafkaConfig.java`의 `Topics` 상수 **값만** 교체한다. 상수 *이름*(`COMMANDS`/`AUDIT_EVENTS`/`HEARTBEATS`)은 코드 식별자라 **유지**(호환). producer/consumer/가드는 모두 상수를 참조하므로 값만 바꾸면 런타임 토픽이 따라간다.

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `src/main/java/com/monitoring/hub/config/KafkaConfig.java:50` | `AUDIT_EVENTS = "audit-events"` | 값 → `"audit-topic"` |
| `:56` | `COMMANDS = "commands"` | 값 → `"command-topic"` |
| `:59` | `HEARTBEATS = "heartbeats"` | 값 → `"heartbeats-topic"` |
| `:53` | `JOB_RESULTS = "job-results"` | **변경하지 않음** (T4-2) |

자동 추종(확인 완료 — 직접 손댈 필요 없음, 참고용):
- producer `producer/CommandPublisher.java:68` → `Topics.COMMANDS`
- consumer `ingest/audit/AuditConsumer.java:47`(`AUDIT_EVENTS`), `ingest/heartbeat/HeartbeatConsumer.java:52`(`HEARTBEATS`), `ingest/jobresult/JobResultConsumer.java:43`(`JOB_RESULTS` 미변경)
- consumer 가드 `inspectSource(..., 토픽상수)` — 인자가 상수라 자동 추종(로그 토픽명만 바뀜, 동작 불변)

**group.id / NewTopic 주의**
- consumer group.id는 토픽과 무관하게 고정(`application.yml:22` 등). 재명명 후 같은 group이 **새 토픽**을 구독하며, committed offset이 없어 `auto-offset-reset: earliest`로 처음부터 읽는다(클린 컷오버에선 정상).
- hub에 `NewTopic` 빈 **없음** — 토픽 물리 생성은 infra 단독. hub는 토픽 생성 코드 변경 불요.

### 3.2 테스트 픽스처 (변경 필요)

| 파일:라인 | 변경 |
|---|---|
| `src/test/java/.../ingest/audit/AuditConsumerTest.java:49` | `TOPIC = "audit-events"` → `"audit-topic"` |
| `src/test/java/.../config/KafkaConfigDeserializerTest.java:28` | 토픽 **값 단언**이 있으면 갱신, 주석만이면 선택 |
| `src/test/java/.../ingest/jobresult/JobResultConsumerTest.java:39` | `TOPIC = "job-results"` — **미변경**(T4-2) |

**오탐 주의 — 변경하지 마라**: `web/UiControllerTest.java:69-70`의 `"heartbeats"`/`"commands"`, `domain/command/CommandJsonTest.java`·`heartbeat/HeartbeatConsumerTest.java`의 변수명 `heartbeats` 등은 **모델 attribute 키/변수명**이지 Kafka 토픽명이 아니다.

### 3.3 문서/주석 동기화 (이번 handoff 포함 — 결정 6)

회귀와 무관하나 drift 방지로 함께 정리한다(값/동작 무관):
- `README.md`(13·15·16·18·27·31·56·91~93·124·167행 등) 구 토픽명 → 새 이름. `job-results`는 유지.
- `pom.xml`(6·33·58·65·89행 주석), `application.yml:38·41·44`(ring buffer 주석), Java doc 주석의 구 토픽명 동기화.
- **변경 제외 판단**: `templates/index.html`의 UI 라벨 "최근 commands" 등 **사용자 표시 문자열**은 토픽명이 아니므로 표시 의도대로 둘지 hub 재량(토픽 재명명과 무관).

## 4. 적용 결정 (사람 확정 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| 컷오버 방식 | **동시 컷오버** — infra 토픽 생성 후 hub/script-agent 같은 윈도우 전환. 이중 발행/구독 없음. |
| 구 토픽 처리 | **클린 재기동 전제 — 별도 처리 불요.** |
| 상수/env 정책 | 상수 *이름* 유지, **값만 교체**(코드 식별자 보존). |
| 회귀 0 정의 | 토픽명 문자열이 아니라 **동작 등가**(흐름·payload·envelope·키·발행순서) + 재명명 완전성. |
| 문서/주석 | 이번 handoff에 함께 정리. |

## 5. DoD / 검증

- [ ] `KafkaConfig.Topics` 값 3개 = `command-topic` / `audit-topic` / `heartbeats-topic`. `JOB_RESULTS`=`job-results` 유지.
- [ ] 직접 토픽 리터럴을 쓰는 producer/consumer 없음(상수 경유) 재확인.
- [ ] `AuditConsumerTest` 등 영향 테스트 통과: `mvn test` 그린.
- [ ] 오탐(UI 모델 키/변수명) 미변경.
- [ ] README·주석 구 토픽명 잔존 0(job-results 제외).
- [ ] 코드 외 동결 spec·무관 파일 변경 없음.

## 6. 가드 (공통)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.**
- 토픽 상수 **값만** 교체, 식별자(상수명) 유지.
- 재명명은 Phase 1 **forward 변경**(Phase 0 회귀 아님).
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행** — hub 세션이 직접 e2e 돌리지 않는다. (단 `mvn test` 단위테스트는 hub가 돌린다.)

## 7. 미결정 사안

- 없음. 3토픽은 `adr/0005` Accepted로 확정. 통합본 `[Open]`/`13_open`/미결 ADR에 걸리는 항목 없음.

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["상수 값 교체 / 영향 테스트 / 문서 동기화 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

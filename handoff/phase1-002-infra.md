# 점검 노트 — phase1-002-infra (Track 0 — T0-3 산출물 → T0-4 구현 점검 — infra 영향)

> envelope은 **애플리케이션 Kafka 헤더** 규약이라 infra(Collector/broker) 직접 변경은 없다. 이 노트는 infra 세션이 "envelope 때문에 바꿀 게 있나"를 빠르게 확인하기 위한 가벼운 점검 항목이다. 결론: **이번 phase1-002에서 infra 변경 작업은 없다.**

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-002-infra` |
| 대상 repo | `infra` |
| 기준 monitoring-meta commit | `0d509a2aaf845264aed59597f7ad65ed90ed168b` (full 40자). **실행 전 `git rev-parse HEAD` 재확인** |
| 작성일 | 2026-06-05 |
| 근거 | `docs/envelope.md` §4.2(OTLP 위임군), phase1-001 §7 infra |

## 2. 결론 (먼저)

- **변경 없음.** envelope 4종은 hub/script-agent가 Kafka 헤더로 싣는 앱 레이어 규약이다. OTel Collector·broker 설정·`otel-collector-config.yml`은 envelope과 무관하다.
- heartbeats(OTLP 위임군)는 envelope 제외 — Collector 재발행 경로는 그대로 둔다(envelope §4.2). 본 작업으로 손대지 않는다.

## 3. 점검 항목 (확인만, 변경 아님)

### 3.1 토픽 사전 생성 범위

- 현재 `docker-compose.yml` init이 사전 생성하는 토픽: `commands`, `job-results`, `audit-events`, `heartbeats` 4종(+ `KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"` 안전망).
- 이번 envelope 적용 대상의 **실재 공통 토픽 3종(commands / job-results / audit-events)은 이미 사전 생성 목록에 포함**돼 있다. → **추가 작업 불필요.**
- `alert-topic` / `notification-topic` / `result-topic-log`(분리)는 **아직 컴포넌트 미존재**(Track 2/3 / 토픽 분리 미수행)라 본 작업 범위 밖. 해당 서비스/토픽이 생길 때 init 목록에 추가하면 된다(지금 추가하지 마라 — 잠정 토픽명·미정 시점).

### 3.2 토픽 ACL

- 현재 broker에 별도 ACL 설정 없음(단일 데모 broker). envelope은 헤더라 ACL과 무관. → 점검 결과 **대상 없음**.

### 3.3 토픽명 잠정 주의 (D-4(1) 비준 대비)

- init 스크립트의 토픽명(`commands` 등)은 데모명이며 kafka-payloads 잠정 논리명(`command-topic` 등)과 다르다. **이번에 바꾸지 마라** — 토픽 재명명은 D-4(1)(`adr/0005`) 비준 후 Track 4-1 소관이다. 앱(hub/script-agent)과 init 스크립트의 토픽명이 **일치 상태로 유지**되는지만 확인.

## 4. DoD

- [ ] (확인만) 실재 공통 토픽 3종이 init 사전 생성 목록에 있음을 확인 — 이미 충족.
- [ ] envelope 관련 Collector/broker 설정 변경 **없음** 확인.
- [ ] 토픽명 미변경(재명명은 본 작업 아님).

## 5. 미결정 사안

- 없음. D-4(1) 토픽 명명은 본 작업과 독립(토픽명 미변경).

## 6. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일(없으면 빈 배열)"],
  "findings": ["점검 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

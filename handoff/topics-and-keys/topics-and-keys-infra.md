# 작업 spec — topics-and-keys (infra)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `topics-and-keys` | T2-4 ∪ T4-4 합본 (신규 토픽 추가 + 신규 토픽 키 정의) |
| 대상 repo | `infra` | |
| **기준 monitoring-meta commit** | `81a5990eb456f0c6dadd6ab5feaa5969bf2dd47d` | 통합본/kafka-payloads 고정 시점 |
| 작성일 | 2026-06-24 | |
| 근거 ADR | `adr/0005-topic-naming.md`(Accepted) | |

### 1.1 기준 commit 이유
infra 세션도 기준 문서 spec을 상대 경로(`../monitoring-meta/docs/...`)로 참조만 한다. 작성↔실행 drift 방지용 고정 시점.

## 2. 문서 성격 상기
ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 + kafka-payloads(Phase 1+ 도달 목표)**.

## 3. ground truth 참조 경로
- `../monitoring-meta/docs/master-design.md` — §4.4.1 토픽 표(8토픽)
- `../monitoring-meta/docs/kafka-payloads.md` — `alert-topic`/`notification-topic` 토픽 명명·신설 근거
- `../monitoring-meta/adr/0005-topic-naming.md` — 토픽 명명 규칙(후보 B, Accepted) §2.2.1

## 4. 배경 / 목표

`alert-topic`/`notification-topic` 두 신규 토픽을 Kafka 브로커에 **사전 프로비저닝**한다. infra의 `kafka-init`은 운영 표준으로 토픽을 명시 사전 생성하는데(auto-create는 안전망), 현재 5토픽만 생성하므로 신규 2토픽을 추가한다.

끝났을 때 도달 상태: 브로커 기동 시 `alert-topic`/`notification-topic`이 기존 5토픽과 동일 baseline 옵션으로 사전 생성된다.

## 5. 작업 범위

### 해야 할 것
- `docker-compose.yml`의 `kafka-init` 서비스에서 토픽 사전 생성 목록에 `alert-topic`, `notification-topic` 2개 추가.
  - 현재 목록: `command-topic result-topic-job result-topic-log audit-topic heartbeats-topic` (5개).
  - 변경 후: 위 + `alert-topic notification-topic` (7개).
  - 생성 옵션(partition/replication 등)은 **기존 토픽과 동일 baseline**을 적용한다(현재 init은 토픽별 동일 옵션 루프 구조 — 신규 2토픽도 같은 옵션). 단일 broker 데모 환경이므로 replication=1 등 기존값 그대로.

### 하지 말 것 (out of scope)
- partition 수 튜닝(alert-topic hot partition 대응 등) — 통합본 §6.8.6 O3 Open 보존 사안. baseline partition으로만 생성, 튜닝은 별도 추적.
- 메시지 키 적용 로직(키는 producer 측 = hub 책임, infra는 토픽 존재만 보장).
- 새 broker/리스너/보안 설정 변경 — 토픽 추가만.
- 기존 5토픽 생성 옵션 변경.

### 영향받는 기능 문서 (`docs/features/`)
- **해당 없음.**
- 근거: features 레이어는 구현 완료된 사용자 가시 시나리오만 다룬다. 토픽 프로비저닝은 인프라 계약 레이어이며, 신규 토픽 위를 흐르는 사용자 가시 파이프라인은 미구현(scope 밖).

## 6. Phase 0 회귀 방지 기준

- 기존 5토픽(`command-topic`/`result-topic-job`/`result-topic-log`/`audit-topic`/`heartbeats-topic`) 사전 생성 동작 **불변**.
- `--if-not-exists` 플래그 유지(재기동 idempotent). auto-create 안전망(`KAFKA_AUTO_CREATE_TOPICS_ENABLE`) 불변.
- 신규 2토픽 추가가 기존 init 루프·healthcheck·기동 순서에 영향 없도록 한다(목록에 항목만 추가).
- Phase 0 e2e baseline(현행 64/0/0) 기존 토픽 흐름 회귀 0.

## 7. 미결정 사안 (있으면 실행 전 멈춤)

- **없음** (토픽 사전 생성 추가를 막는 통합본 `[Open question]`·미결정 ADR 없음).
- 참고(차단 아님): alert-topic hot partition은 §6.8.6 O3 Open이나 partition 튜닝 사안 — baseline으로 생성하면 무관.

## 8. 완료 기준 / 검증

- [ ] `kafka-init`이 `alert-topic`/`notification-topic`을 사전 생성(목록 7개).
- [ ] 브로커 기동 후 `kafka-topics --list`에 두 토픽 존재 확인.
- [ ] 기존 5토픽 생성·init exit0·healthcheck 회귀 없음.
- [ ] Phase 0 회귀 없음(§6 기준).
- [ ] (필요 시) polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

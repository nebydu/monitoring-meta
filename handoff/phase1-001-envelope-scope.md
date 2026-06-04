# 작업 spec — phase1-001-envelope-scope (Track 0: envelope 적용 범위 + 선후)

> 이 handoff는 ROADMAP §9 Track 0의 T0-1(envelope 적용 범위 + 제외 사유)·T0-2(envelope/재명명 선후)를 확정하는 **범위 결정 문서**다. owner_repo = monitoring-meta(spec/contract 소유). 실제 envelope 구현은 후속 `handoff/phase1-002-envelope-remaining-topics.md`(T0-3/T0-4)에서 hub/script-agent로 분배한다.

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `phase1-001-envelope-scope` | ROADMAP §16 슬라이스 1 |
| 대상 repo | monitoring-meta(범위 결정) → hub, script-agent, infra(후속 구현) | 본 문서는 범위/선후 확정 + repo별 작업 분해 |
| 기준 monitoring-meta commit | `bed89c4339371863c2db766cec5d684f3448d192` (이 handoff·`adr/0005`·ROADMAP v0.3 D-4 반영이 모두 포함된 커밋 — 완전 재현 가능) | 정본(통합본/envelope/kafka-payloads/ROADMAP v0.3/`adr/0005`) 고정 시점. **실행 전 `git rev-parse HEAD`로 최신 full 40자 재확인** |
| 작성일 | 2026-06-04 | |
| 근거 ADR | `adr/0005-topic-naming.md`(D-4(2) RESOLVED: envelope 먼저), ADR#2(heartbeats OTLP 예외) | |

## 2. 문서 위상 상기 (매 작업 고정)

ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(Phase 1+ 도달 목표)**.

- envelope.md가 박혔다고 코드가 자동으로 envelope을 따르는 게 아니다. 현재 코드(`producer/CommandPublisher.java` 인라인 헤더, `internal/kafka/envelope.go`)가 어느 위상에 있는지 먼저 판단한다(envelope.md §7 현재 구현 위치 참조).
- 데모 spec v0.2.1 §2.2 헤더 4종 발행 동작은 회귀 0이어야 한다.

## 3. ground truth 참조 경로 (상대 경로, 사본 두지 않음)

- `../monitoring-meta/docs/envelope.md` — envelope 4종 정본(§2 헤더 정의, §4 토픽별 적용, §6 Phase 0 하위호환)
- `../monitoring-meta/docs/kafka-payloads.md` — 8토픽 payload 정본(현행 잠정 토픽명)
- `../monitoring-meta/docs/통합본_v0_9.md` §4.4.1(토픽 표 envelope 컬럼) / §6.8(envelope·ID 컨벤션) / §6.9.3·§6.9.5(alert/notification Phase 1 확정·key)
- `../monitoring-meta/adr/0005-topic-naming.md` — D-4(2) RESOLVED 근거
- `../monitoring-meta/docs/phase1/ROADMAP_PHASE1_v0_3.md` §7(8토픽 계약 매트릭스)
- `docs/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준(각 repo 사본)

## 4. 배경 / 목표

Phase 0 데모는 `command-topic`(hub→script-agent)에 envelope 4종을 발행한다. Phase 1 목표는 envelope 4종을 **공통 토픽군 전체**로 확장 적용하는 것이다. D-4(2) 사람 결정(2026-06-04, `adr/0005`)으로 **envelope 적용을 토픽 재명명/재구조보다 먼저(envelope-first) 수행**한다. 본 문서는 envelope를 적용할 토픽군과 제외 토픽(+사유)을 확정하고 repo별 작업을 분해한다. 끝났을 때 도달 상태: 공통 토픽군 6개에 envelope 4종이 적용되고 OTLP 위임군 2개는 예외로 명시 보존된다.

## 5. T0-1 / T0-2 결정 내용

### 5.1 T0-2 envelope/재명명 선후 — **RESOLVED (2026-06-04, `adr/0005` §2.1)**

- **결정: envelope 먼저 (Track 0 → Track 4).**
- 근거: envelope은 Kafka **헤더**(transport 메타데이터)라 토픽 **이름**과 독립적이다(envelope.md §1·§4.1 주 — "envelope 4종 적용은 zone suffix와 무관하게 동일"). 따라서 토픽 최종 이름 미정(D-4(1) 비준 대기)에 막히지 않고 선적용 가능하며, 선적용 산출물은 재명명 후에도 그대로 유효하다(재작업 없음).

### 5.2 T0-1 envelope 적용 대상 토픽 + 제외 사유

근거: ROADMAP §7 8토픽 계약 매트릭스 + envelope.md §4 + 통합본 §4.4.1 envelope 컬럼(●/×).

| 토픽 | envelope 4종 적용 | 분류 | 근거 |
|---|:-:|---|---|
| `command-topic`(zone 단위) | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §4.4.1(●), §6.8.1·6.8.2 |
| `result-topic-job` | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §4.4.1(●), §6.9.2 항목1(분리 Phase 1 확정) |
| `result-topic-log` | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §4.4.1(●), §6.9.2 항목1 |
| `audit-topic` | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §4.4.1(●), §6.6.3 |
| `alert-topic` | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §6.9.3·§6.9.5(Phase 1 확정·key) |
| `notification-topic` | ● 적용 | 공통 토픽군 | envelope §4.1, 통합본 §6.9.3·§6.9.5(Phase 1 확정·key) |
| `heartbeats-topic` | ✕ 제외 | OTLP 위임군 | **제외 사유**: OTel Collector 발행, OTLP 표준 헤더 사용. envelope 4종 미적용(통합본 §6.8.1 예외문·§4.4.1 ×, envelope §4.2). ADR#2 protobuf 전환 대상이나 envelope 헤더와 무관 |
| `metrics-topic` | ✕ 제외 | OTLP 위임군 | **제외 사유**: Phase 2 신규·Phase 1 미사용. OTLP 표준 헤더(통합본 §6.9.5, envelope §4.2) |

- envelope 4종 = `x-message-id`(● 필수, UUIDv4) / `x-message-version`(● 필수, string `"1"`, major 호환성 버전) / `x-source`(● 필수, kebab-case 모듈명) / `x-trace-id`(○ 선택, 값 없으면 헤더 생략). 정의는 envelope.md §2.
- OTLP 위임군 제외는 "OTLP가 envelope 4종을 동등 대체 보장한다는 의미가 아니다" — 식별·버전은 OTLP/Collector 표준 위임, 1:1 대응 아님(envelope §4.2).

## 6. 중요 주석 — 토픽 이름 잠정 (ADR#5 비준 대기)

- 본 handoff의 토픽 *이름*은 모두 `docs/kafka-payloads.md` 기준 **잠정**이다. 최종 명명 규칙은 `adr/0005-topic-naming.md` D-4(1)로 **비준 대기 중**이다(명명 *원칙* "zone 단위 + 의미 기반"은 통합본 §4.4.1·§8.3 ADR#5 확정, 구체 컨벤션만 미정).
- envelope은 헤더라 토픽명과 독립 → **선적용 안전**. 구현 세션은 잠정 토픽명을 쓰되 토픽명을 상수/설정으로 외부화해 ADR#5 비준 후 재명명에 대비한다.
- `command-topic`은 논리명, 물리 실현은 `command-topic-{zone}`(zone suffix). envelope 4종은 zone suffix와 무관하게 동일 적용한다(envelope §4.1 주).

## 7. repo별 작업 분해 (후속 phase1-002에서 실제 실행)

> 본 문서는 범위 확정 문서다. 아래는 후속 `handoff/phase1-002-envelope-remaining-topics.md`로 넘길 repo별 작업 윤곽이며, 각 repo 세션이 그 handoff를 받아 구현한다.

### hub (Java)
- producer: `command-topic` 외 신규/기존 공통 토픽 발행 경로에 envelope 4종 주입. 현재 `producer/CommandPublisher.java`에 인라인된 헤더 빌드 로직을 공통 토픽 producer 전반으로 확장(envelope.md §7 — envelope 모듈 추출 후보).
- consumer: 공통 토픽군 consume 시 envelope 파싱. **알 수 없는 `x-source` 값에 깨지지 않는 가드**(envelope §2.3) 적용. (`x-message-id` dedup·`x-trace-id` 복원은 T2-8·별도 작업 — 본 범위 아님.)
- `result-topic-job`/`result-topic-log`/`alert-topic`/`notification-topic` producer/consumer는 해당 서비스 구현(Track 2/3)과 함께 envelope 적용.

### script-agent (Go)
- producer: `result-topic-job`/`result-topic-log` 발행 경로에 envelope 4종 주입(`internal/kafka/envelope.go` `BuildHeaders` 재사용, 옵셔널 trace 생략 로직 유지).
- 헤더 키 상수·고정값은 `internal/model/envelope.go` 기준 — 데모 spec §2.2와 동일 키 문자열 유지(Phase 0 회귀 0).

### infra
- envelope는 애플리케이션 헤더라 Collector/infra 직접 변경은 없음(heartbeats/metrics는 제외군). 단 토픽 ACL/생성 스크립트가 공통 토픽군을 포함하는지 확인(토픽명 잠정 — ADR#5 비준 후 재확인).

### monitoring-meta
- 본 문서(범위 확정) + 후속 phase1-002 생성 + spec-sync drift 검사(정본 envelope.md ↔ 양쪽 repo 구현). ROADMAP §9 T0-1/T0-2 status·evidence 갱신.

## 8. DoD / 검증

- [ ] 공통 토픽군 6개 발행 메시지에 envelope 4종 헤더 존재(`x-trace-id`는 값 있을 때만) — e2e 헤더 검증.
- [ ] `x-message-id` UUIDv4 형식, 메시지마다 고유.
- [ ] consumer가 알 수 없는 `x-source` 값에 깨지지 않음(envelope §2.3 가드 테스트).
- [ ] OTLP 위임군(heartbeats/metrics)에는 envelope 4종 미적용 유지(제외 회귀 검증).
- [ ] Phase 0 회귀 0: 데모 spec §2.2 `command-topic` 헤더 4종 발행 동작·키 문자열·`x-message-version="1"` 불변(envelope §6).
- [ ] 테스트: hub `mvn test` / script-agent `go test ./...` / polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 미결정 사안 (있으면 실행 전 멈춤)

- **D-4(1) 토픽 구체 명명 컨벤션** = `adr/0005-topic-naming.md` 비준 대기(`[결정 필요]`). **단 envelope 적용(본 작업)은 토픽명과 독립이므로 이 미결정에 막히지 않는다**(D-4(2) RESOLVED). 토픽 *재명명* 작업(T4-1)만 비준 대기.
- `x-message-id` dedup 정확한 시점(envelope §9 O1, ADR#15) — 본 작업 범위 밖(T2-8).
- 그 외 envelope §9 Open(O2 SR 연동 / O3 alert 키 partition)은 본 작업과 무관.

## 10. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

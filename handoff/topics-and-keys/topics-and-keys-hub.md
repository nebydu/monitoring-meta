# 작업 spec — topics-and-keys (hub)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `topics-and-keys` | T2-4 ∪ T4-4 합본 (신규 토픽 추가 + 신규 토픽 키 정의) |
| 대상 repo | `hub` | |
| **기준 monitoring-meta commit** | `666a16e9a60d0df328e463417eed0a77a4e5e2e3` | 통합본/kafka-payloads/envelope 고정 시점 (alert key wire 인코딩 반영분 포함) |
| 작성일 | 2026-06-24 | |
| 근거 ADR | `adr/0005-topic-naming.md`(Accepted), ADR#6(통합본 §8.3 메시지 키 결정) | |

### 1.1 기준 commit 이유
hub 세션은 기준 문서 spec을 상대 경로(`../monitoring-meta/docs/...`)로 참조만 한다. 작성↔실행 시점 drift를 막기 위해 기준 commit을 못 박는다. 필요 시 `git -C ../monitoring-meta log 666a16e..HEAD -- docs/`로 그 사이 spec 변경을 점검한다.

## 2. 문서 성격 상기

ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 + kafka-payloads + envelope(Phase 1+ 도달 목표)**. 데모 spec과 도달 목표 spec을 같은 기준으로 다루지 않는다.

## 3. ground truth 참조 경로 (상대 경로, 사본 두지 않음)
- `../monitoring-meta/docs/master-design.md` — 통합본 §4.4.1(토픽 표)·§6.8.2(메시지 키)·§6.9.3·§6.9.5
- `../monitoring-meta/docs/kafka-payloads.md` — `alert-topic`/`notification-topic` payload + 키 절
- `../monitoring-meta/docs/envelope.md` — §4.1 공통 토픽군(6) envelope 4종 적용
- `../monitoring-meta/adr/0005-topic-naming.md` — 토픽 명명 규칙(후보 B, Accepted)
- `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 기준

## 4. 배경 / 목표

`alert-topic`/`notification-topic` 두 신규 토픽을 hub에 도입하고, 두 토픽의 **메시지 키 규약**을 코드 계약으로 박는다. 토픽 신설(T2-4)과 신규 토픽 키 정의(T4-4)가 같은 두 토픽을 대상으로 하므로 한 작업으로 묶는다.

끝났을 때 도달 상태: hub가 두 토픽을 토픽 상수로 인지하고, (만들 경우) 두 토픽 producer가 envelope 4종 + 확정된 메시지 키 규약대로 발행한다. **도메인 로직(rule 평가/dedup/incident 그룹핑/통보)은 이 작업 밖**이다.

## 5. 작업 범위

### 5.1 확정 계약 (변경·추측 금지 — 기준 문서에서 도출)

| 토픽 | 최종 논리명 | envelope | 메시지 키 |
|---|---|---|---|
| alert-topic | `alert-topic` | 4종 적용 | `(rule_id, target_id)` 조합. **`rule_id`가 null이면 `("agent-offline", target_id)`** |
| notification-topic | `notification-topic` | 4종 적용 | `incident_id` |

- 출처: 통합본 §4.4.1·§6.8.2 키 표·§6.9.5, kafka-payloads `alert-topic`/`notification-topic` 절, envelope §4.1, ADR#5 §2.2.1.
- payload 필드 구조는 `kafka-payloads.md` 두 절을 그대로 따른다(producer를 만들 경우의 도메인 객체 매핑 기준).

#### 5.1.1 alert-topic key wire 인코딩 — **규범 출처=spec** (kafka-payloads `alert-topic` 키 절 + 통합본 §6.8.2)

통합본의 `(rule_id, target_id)`는 **ordering 의미** 계약이다. Kafka key는 단일 문자열이므로 그 의미를 **canonical wire 표현**으로 직렬화한다. 이 wire 인코딩은 meta가 2026-06-25 결정해 **`docs/kafka-payloads.md` `alert-topic` 키 절 + 통합본 §6.8.2에 반영**했다 — 즉 **규범 출처는 spec이며 본 절은 그 참조 요약**이다(handoff가 spec보다 먼저 규범화하는 것이 아님). 아래 표·전제는 kafka-payloads와 동일 내용이고, 충돌 시 kafka-payloads가 우선한다.

- **결정 출처**: 2026-06-25 meta 오케스트레이션 세션 사용자 승인(버전 접두 포맷). 근거 기록 = `proposal-review-topics-and-keys-r2.json`(approve). spec 반영 커밋 = 기준 commit §1(`666a16e`, kafka-payloads·통합본 §6.8.2 포함).

| 토픽 | canonical key (string) | rule_id null(예: Agent OFFLINE) |
|---|---|---|
| alert-topic | `alert-key:v1:{rule_id}:{target_id}` | `alert-key:v1:agent-offline:{target_id}` |
| notification-topic | `incident_id` 원문 문자열(UUID 등) 그대로 | — |

- 구분자 `:` **고정**, 버전 토큰 `v1`로 향후 포맷 진화 여지 확보.
- **전제**: `rule_id`/`target_id`에 `:`가 포함되지 않는다. 코드 세션은 착수 시 두 식별자의 charset을 확인하고, `:`가 들어올 수 있으면 **즉시 멈추고 escaping 규칙을 meta에 문의**한다(추측 금지). 현재 식별자 형식상 `:` 없음을 전제로 v1을 확정.
- ordering 단위는 `(rule_id, target_id)` 그대로 — 같은 Rule×대상의 모든 severity가 한 partition으로 모인다(§6.8.2).

### 해야 할 것
- `KafkaConfig.Topics`에 토픽 상수 2개 추가: `ALERT = "alert-topic"`, `NOTIFICATION = "notification-topic"`(명명은 기존 상수 컨벤션 따름).
- **작업 깊이 = (b) 골격 포함으로 확정**(§5.3): 위 상수 추가 + 두 토픽 producer 골격(`AlertPublisher`/`NotificationPublisher` 류)을 추가한다. 골격은 envelope 4종 헤더(기존 `messaging.EnvelopeHeaders` 재사용) + §5.1 키 규약 지정까지만 책임지고, 도메인 데이터 채움은 호출 측(미구현 서비스)에 맡긴다.
- producer 메시지 키 적용 (§5.1.1 canonical 인코딩 **그대로** — baseline/임의 변형 금지):
  - alert: key = `alert-key:v1:{rule_id}:{target_id}`, `rule_id` null이면 `alert-key:v1:agent-offline:{target_id}`. 이 직렬화를 **key builder 함수**로 분리하고 단위 테스트로 두 분기(정상/agent-offline)를 고정한다.
  - notification: key = `incident_id`(원문 문자열 그대로).
- `x-source` 처리 (envelope 기존 필수 요건의 구현 규칙 — **신규 spec 제약 아님**):
  - **`x-source`는 envelope §2.4상 이미 "● 필수" 헤더**다(본 합본이 새로 제약을 만드는 게 아니라 기존 요건을 구현으로 지키는 것). 골격 producer가 실제 발행 가능한 코드이므로 그 필수 헤더를 placeholder 값으로 채워 런타임으로 내보내면 안 된다. **`AlertPublisher`/`NotificationPublisher` 생성자(또는 발행 메서드)가 `source`를 필수 파라미터로 받게** 하라 — 호출 측(미구현 서비스)이 실제 발행 모듈명을 주입한다.
  - 실제 서비스 식별자는 D-2(모놀리스 vs MSA) 이후 모듈명이 바뀔 수 있으므로 publisher가 상수로 박지 않고 주입받는 구조가 맞다. (참고 매핑: alert는 Rule Engine/Agent State, notification은 Incident Service — 호출 측 책임.)
  - 골격 단계 단위 테스트는 명시적 테스트용 source 값을 주입해 키·헤더를 검증한다. envelope §2.3 알려진 값 목록은 비규범이므로 새 발행자 식별자 추가는 spec bump 불필요.

### 하지 말 것 (out of scope)
- Rule Engine(T2-1), Alert Processor + Dedup(T2-2), Incident Service(T2-3), Notification Service + 채널 어댑터(T3-1) **서비스 도메인 로직** — T1-1(Redis/PG) 등에 의존하는 영역. 이 작업은 그 의존을 타지 않는다.
- Agent OFFLINE → Alert 발화 로직(T2-6).
- alert/notification consumer의 도메인 처리(dedup·그룹핑·상태 전환·통보 발송).
- 두 토픽 payload를 채우는 rule 평가/incident 생성 데이터 로직.
- 기존 토픽 키 변경(command=`target_agent_id`, result=`agent_id`는 기구현 — 건드리지 않는다).

### 5.3 작업 깊이 결정 — **확정: (b) producer 골격까지** (2026-06-25, 사람 결정)
- §5의 (a) vs (b)는 **계획 레이어 선택**이었다(통합본 Open 아님). **(b) 골격까지로 확정**한다 — 두 토픽 producer 골격(`AlertPublisher`/`NotificationPublisher` 류)을 추가해 키·envelope 적용을 실제 코드로 검증한다. 단 도메인 로직(rule 평가/dedup/incident 그룹핑/통보 데이터 채움)은 제외(§5 "하지 말 것").
- (참고) (a) 계약-only는 기각. 골격 단계의 `x-source`는 placeholder 식별자 + 주석으로 향후 서비스 식별자를 명시한다.

### 영향받는 기능 문서 (`docs/features/`)
- **해당 없음.**
- 근거: features 레이어는 구현 완료된 사용자 가시 시나리오만 다룬다(`docs/features/README.md` §1). 본 작업은 토픽 추가 + 키 규약 정렬(인프라·계약 레이어)이며, Rule→Alert→Incident→Notification 사용자 가시 파이프라인은 미구현(T2-1~T3-1, scope 밖)이다.

## 6. Phase 0 회귀 방지 기준

- 기존 5토픽 상수(`command-topic`/`result-topic-job`/`result-topic-log`/`audit-topic`/`heartbeats-topic`)·consumer·CommandPublisher 키(`target_agent_id`) 동작 **불변**.
- envelope 4종 발행 로직(기존 토픽) 회귀 0 — 신규 producer는 기존 `EnvelopeHeaders`를 재사용하고 기존 발행 경로를 수정하지 않는다.
- 신규 토픽 상수·producer 추가는 기존 토픽 흐름과 격리(추가일 뿐). 데모 spec v0.2.1의 토픽 4종(commands/job-results/audit-events/heartbeats 흐름 — 현재 논리명) 동작에 영향 없음.

## 7. 미결정 사안 (있으면 실행 전 멈춤)

- **없음** (토픽 추가·키 정의 자체를 막는 통합본 `[Open question]`·미결정 ADR·AMS 가정 충돌 없음).
- 참고(차단 아님): alert-topic hot partition 튜닝은 통합본 §6.8.6 O3 Open이나, partition 수 튜닝 사안일 뿐 토픽 신설을 막지 않는다(baseline partition으로 생성). §5.3 작업 깊이는 계획 선택이지 통합본 Open 아님.

## 8. 완료 기준 / 검증

- [ ] `KafkaConfig.Topics`에 `alert-topic`/`notification-topic` 상수 2개 추가.
- [ ] 두 토픽 producer 골격(`AlertPublisher`/`NotificationPublisher` 류)이 envelope 4종 + §5.1.1 canonical 키대로 발행. (깊이 (b) 확정)
- [ ] alert key builder 단위 테스트로 두 분기 고정: 정상=`alert-key:v1:{rule_id}:{target_id}`, rule_id null=`alert-key:v1:agent-offline:{target_id}`. notification key=`incident_id`.
- [ ] `x-source`가 주입 파라미터로 채워짐 — placeholder/상수 하드코딩 없음(테스트는 명시 source 주입으로 검증).
- [ ] 착수 시 `rule_id`/`target_id` charset에 구분자 `:` 없음 확인(있으면 멈추고 meta 문의).
- [ ] 기존 토픽 상수·키·envelope 동작 불변(회귀).
- [ ] 테스트: hub `mvn test`.
- [ ] Phase 0 회귀 없음(§6 기준).
- [ ] (필요 시) polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

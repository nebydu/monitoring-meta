# Phase 1 ROADMAP — draft v0.2 (보완 적용)

> **위상**: 이 문서는 `monitoring-meta/docs/통합본_v0_9.md`를 최상위 기준으로 삼아 작성한 **입력 draft**다. 이 문서 자체는 정본이 아니다. Claude Code(analyzer)가 통합본·HANDOFF·실제 main 코드와 대조해 검증한 결과물(`ROADMAP_PHASE1_v0_3.md`)이 **정본 후보**가 된다.
> **입력 정본**: `monitoring-meta/docs/통합본_v0_9.md`
> **보조 입력**: `monitoring-meta/HANDOFF.md`
> **작성 기준일**: 2026-06-02
> **원칙**: 임의 결정 금지. 확정되지 않은 항목은 `[결정 필요]`로 남기고 source_ref와 판단 근거를 함께 기록한다.
> **이 보완본에서 v0.2 대비 고친 것**: ① source_ref `§05`/`§7.2` 분리 표기 → `05 §7.2`로 정규화(β/γ=`05 §7.2.6`, 경계↔데모=`05 §7.2.4`). ② status에 `PARTIAL` 추가 + Phase 걸치는 ADR 처리 명시. ③ 재귀 위험이 있던 "Claude Code 지시문" 섹션을 본문에서 제거(실행 지시문은 문서 밖에서 전달). ④ owner_repo=monitoring-meta의 의미 주석 추가. ⑤ 변경 이력에 보완 기록 추가.

---

## 0. 문서의 목적

이 문서는 Phase 0 완료 이후 Phase 1 완료까지 필요한 작업을 한 곳에서 추적하기 위한 기준 ROADMAP이다.

단, 이 문서는 실제 repo 작업 지시서가 아니다. 실제 구현은 이 ROADMAP을 기준으로 잘라낸 별도 HANDOFF 문서를 통해 수행한다.

```text
통합본_v0_9.md
  ↓ derive
docs/phase1/ROADMAP_PHASE1_draft_v0_2.md   (입력 draft, 이 문서)
  ↓ verify (analyzer + codex-gate)
docs/phase1/ROADMAP_PHASE1_v0_3.md         (정본 후보)
  ↓ slice
handoff/phase1-xxx/phase1-xxx-*.md
  ↓ execute
hub / script-agent / infra / monitoring-meta
  ↓ verify
monitoring-meta e2e + ROADMAP status update
```

**owner_repo 표기 주의**: 표의 `owner_repo`에 `monitoring-meta`가 들어가면 그것은 *코드 구현* 소유가 아니라 *spec/contract 문서*(`kafka-payloads.md`, `envelope.md`) 갱신 소유를 뜻한다. monitoring-meta는 런타임 repo가 아니라 공통 자산 보관소다.

---

## 1. Phase 1 범위 정의

Phase 1 완료는 `ADR 18개 완료`만으로 판단하지 않는다.

Phase 1 완료는 아래 묶음의 합집합을 닫는 것으로 본다.

| 묶음 | 설명 | primary source_ref | 비고 |
|---|---|---|---|
| ADR 18개 | Phase 1 결정 레이어 | `통합본 §8.3` | 일부 ADR은 구현 없음 / 동일 유지 / 미도입 / Phase 걸침일 수 있다. |
| 데모 정정 항목 | Phase 0 데모와 통합문서 사이의 정합성 정정 | `통합본 §6.9(나)` | ADR 명시 / ADR 간접 귀속 가능 / ADR 바깥 정정으로 재분류 필요. |
| Phase 1 신규 컴포넌트 | Rule Engine, Alert, Incident, Notification 등 | `통합본 §6.9(다)` | ADR 카탈로그 바깥의 실제 기능 빌드가 포함된다. |
| 모듈 구조 정리 | 모듈러 모놀리스 → 약 9 deployment 분리(β) | `통합본 05 §7.2`, `HANDOFF` | β 유지 / γ 전환 / 분리 시점은 결정 필요(`05 §7.2.6`). |
| 검증 증거 | repo별 테스트, e2e, source_ref drift 점검 | `HANDOFF`, `monitoring-meta e2e` | Phase 1 완료 증거로 남겨야 한다. |

### 1.1 데모 정정 항목 재분류 원칙

기존 v0.1의 "데모 정정 11개 중 7개만 ADR에 연결, 4개는 ADR 없음"이라는 단정은 쓰지 않는다.

| 분류 | 의미 | 처리 방식 |
|---|---|---|
| ADR 명시 항목 | 통합본 §8.3 표에서 ADR 번호가 직접 붙은 항목 | 해당 ADR의 acceptance evidence로 연결 |
| ADR 간접 귀속 가능 항목 | ADR 번호가 직접 없더라도 ADR#4/#5 등과 의미상 연결될 수 있는 항목 | `[결정 필요]`로 두고 analyzer/codex-gate에서 귀속 확정 |
| ADR 바깥 정정 항목 | Quartz JobStore, audit actor.type 확장처럼 ADR 카탈로그에 직접 들어가지 않는 구현 정정 | 별도 ROADMAP item으로 추적 |

특히 아래 항목은 재분류 확인이 필요하다.

| 항목 | 가능한 귀속 | 상태 |
|---|---|---|
| `job-results` 토픽 분리 | ADR#5 간접 귀속 가능 | `[결정 필요]` |
| `command-topic` zone routing | ADR#4 간접 귀속 가능 | `[결정 필요]` |
| Quartz JobStore DB-backed clustered | ADR 바깥 정정 가능성 높음 | `[결정 필요]` |
| audit actor.type 확장 | ADR 바깥 정정 가능성 높음 | `[결정 필요]` |

---

## 2. ROADMAP과 HANDOFF의 역할

### 2.1 ROADMAP

ROADMAP은 Phase 1 전체의 기준 문서이다. 다음을 정의한다: Phase 1 완료 범위, 의존 순서, source_ref, owner_repo 후보, blocker/gate, status, acceptance evidence, HANDOFF 분리 단위. ROADMAP은 직접 구현 지시서가 아니다.

### 2.2 HANDOFF

HANDOFF는 실제 작업 단위의 실행 문서이다. 다음을 정의한다: 어느 repo를 수정할지, 어떤 파일/모듈을 바꿀지, 어떤 테스트로 완료를 증명할지, 완료 후 ROADMAP의 어느 항목을 갱신할지, 다음 handoff로 무엇을 넘길지.

### 2.3 권장 운영 루프

```text
ROADMAP 항목 선택
  → handoff 생성
  → repo별 구현
  → 테스트 / e2e
  → codex-gate 검토
  → ROADMAP status 및 acceptance_evidence 갱신
```

---

## 3. Phase 1 Definition of Done

Phase 1 완료는 다음을 모두 만족해야 한다.

| ID | 완료 조건 | 확인 방법 | 상태 |
|---|---|---|---|
| DoD-1 | `통합본 §8.3` ADR 18개가 각각 `DONE` / `NO-OP` / `DEFERRED` / `PARTIAL` 중 하나로 판정되어 있다. | ADR별 status와 근거 확인 | TODO |
| DoD-2 | `통합본 §6.9(나)` 데모 정정 11개가 `DONE` / `DEFERRED` / `DECISION_REQUIRED`로 추적되어 있다. | demo-correction matrix 확인 | TODO |
| DoD-3 | `통합본 §6.9(다)` Phase 1 신규 컴포넌트가 구현 또는 명시 보류되어 있다. | component matrix 확인 | TODO |
| DoD-4 | `통합본 05 §7.2` 모듈 분리 기준이 β 유지인지 γ 전환인지 결정되어 있다(`05 §7.2.6`). | architecture decision record 또는 ROADMAP 결정 섹션 확인 | TODO |
| DoD-5 | hub / script-agent / infra / monitoring-meta 별 HANDOFF가 완료되고 repo별 테스트가 통과했다. | handoff completion log 확인 | TODO |
| DoD-6 | monitoring-meta 기준 e2e 검증 결과가 남아 있다. | e2e 결과 파일 또는 로그 확인 | TODO |
| DoD-7 | ROADMAP, ADR, HANDOFF, 통합본 간 source_ref drift가 없다. | codex-gate / analyzer 검토 결과 확인 | TODO |

**Phase 걸치는 ADR 처리**: ADR#4(consumer group: 기본=Phase 1, zone routing=후속), ADR#12(영속: PG/OS/Redis/MinIO=Phase 1, VictoriaMetrics=Phase 2), ADR#13(라우팅: heartbeat=기구현, metric=Phase 2)처럼 한 ADR이 Phase를 걸치면 `PARTIAL`로 판정하고 **Phase 1 범위 / Phase 2 잔여**를 함께 명시한다. 단일 status로 뭉개지 않는다.

---

## 4. 상태값 규칙

ROADMAP의 `status`는 아래 값만 사용한다.

| status | 의미 |
|---|---|
| TODO | 아직 착수 전 |
| IN_PROGRESS | 구현 또는 문서화 진행 중 |
| DONE | 구현과 검증 증거가 모두 완료 |
| NO-OP | 의도적으로 구현 작업 없음. 기존 유지 또는 1차 미도입 |
| PARTIAL | Phase 1 내 일부만 구현, 잔여는 다른 Phase로 분리. **잔여 범위를 반드시 명시** |
| DEFERRED | Phase 1 밖으로 명시 보류 |
| BLOCKED | 외부 결정 또는 선행 작업 때문에 진행 불가 |
| DECISION_REQUIRED | 사람/analyzer/codex-gate 결정 필요 |

---

## 5. 게이트 / 병행 검증 항목

이 섹션의 항목은 모두 "착수 전 일괄 차단 조건"이 아니다. 각 항목은 막는 범위가 다르므로 `gate_type`과 `blocks`를 명시한다.

| ID | 항목 | source_ref | gate_type | blocks | status | next_action |
|---|---|---|---|---|---|---|
| G-1 | AMS 분석 가정 검증 | `통합본 §11`, `통합본 §13_open §J` | local blocker | `[AMS 분석 가정 — 검증 필요]` 태그가 붙은 결정들의 확정 | BLOCKED | §13_open §J와 ADR/컴포넌트 항목을 대조해 실제 게이팅 대상 목록 작성 |
| G-2 | β vs γ 모듈 분리 협의 | `통합본 05 §7.2.6`, `통합본 §13_open §C` | local blocker | deployment 분리 시점, owner_repo 배치, 모듈 경계 확정 | DECISION_REQUIRED | β 유지 / γ 전환 / Phase 1 내 분리 범위 결정 |
| G-3 | 사이트별 운영 정보 입수 | `통합본 §13_open §A` | local blocker | 보안 정책, topology, 노드 추산, site별 배포/운영 결정 | IN_PROGRESS | site별 누락 정보 목록화 |
| G-4 | harness + plugin 검증 | dev-time 실행 인프라, `HANDOFF` | parallel validation | per-repo handoff 실행 루프와 codex-gate 검증 안정성 | IN_PROGRESS | ROADMAP 작성은 막지 않되, 실행 handoff 전 검증 상태 확인 |
| G-5 | source_ref drift 검증 | `통합본_v0_9.md`, `HANDOFF.md`, ROADMAP | parallel validation | 문서 간 불일치 | TODO | ROADMAP v0.3 생성 후 codex-gate 검토 |

---

## 6. Track 0 — 현재 이어받을 작업

현재 HANDOFF 흐름상 "나머지 토픽 envelope 적용"은 Tier 4 후반에 묻지 않고 별도 Track 0으로 분리한다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T0-1 | 나머지 토픽 envelope 적용 범위 확정 | `HANDOFF`, `통합본 §8.3 ADR#2`, `통합본 §8.3 ADR#5` | monitoring-meta | DECISION_REQUIRED | envelope 후속 handoff | ADR#5와의 선후 결정 | `handoff/phase1-001/phase1-001-envelope-scope.md` | 적용 대상 토픽 목록과 제외 사유 |
| T0-2 | ADR#5 토픽 재명명/분리와 envelope 적용 선후 결정 | `통합본 §8.3 ADR#5`, `통합본 §6.9(나)` | monitoring-meta | DECISION_REQUIRED | topic producer/consumer 변경 | analyzer/codex-gate 결정 | `handoff/phase1-001/phase1-001-envelope-scope.md` | "envelope 먼저" 또는 "ADR#5와 묶음" 결정 기록 |
| T0-3 | envelope 적용 handoff 생성 | `HANDOFF` | monitoring-meta | TODO | hub/script-agent 후속 작업 | T0-1, T0-2 | `handoff/phase1-002/phase1-002-envelope-remaining-topics.md` | repo별 수정 범위와 테스트 명시 |
| T0-4 | envelope 적용 구현 | `handoff/phase1-002/phase1-002-envelope-remaining-topics.md` | hub, script-agent | TODO | Phase 1 message contract 정합성 | T0-3 | repo별 handoff | unit/integration/e2e PASS |
| T0-5 | envelope 결과 ROADMAP 반영 | ROADMAP | monitoring-meta | TODO | Track 1~4 정확도 | T0-4 | `handoff/phase1-002/phase1-002-envelope-remaining-topics.md` | ROADMAP status와 evidence 갱신 |

---

## 7. Track 1 — 기반 레이어

거의 모든 Phase 1 기능이 의존하는 기반 작업이다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T1-1 | 영속 저장소: PostgreSQL + OpenSearch + Redis + MinIO (VM은 Phase 2) | `통합본 §8.3 ADR#12`, `통합본 §6.9(나)` | infra, hub, monitoring-meta | TODO | Alert, Incident, dedup, log, script storage | site 정보 일부, infra 결정 | `handoff/phase1-010/phase1-010-persistence-foundation.md` | docker/infra config, hub connection config, smoke/e2e |
| T1-2 | 인증/인가: JWT + OIDC + Knox 어댑터 | `통합본 §8.3 ADR#7`, `통합본 §6.9(나)` | hub | TODO | user-facing API, UI 권한, Knox 연동 | T1-1 중 PG user domain | `handoff/phase1-011/phase1-011-auth-oidc-knox.md` | auth flow test, role/permission test |
| T1-3 | 모듈러 모놀리스 → deployment 분리(β) | `통합본 05 §7.2` (β/γ=`05 §7.2.6`, 경계↔데모=`05 §7.2.4`), `HANDOFF` | hub, script-agent, infra | DECISION_REQUIRED | owner_repo 배치, 도메인 경계, 배포 단위 | G-2 | `handoff/phase1-012/phase1-012-module-split-decision.md` | β/γ 결정 기록, deployment map |
| T1-4 | Quartz JobStore DB-backed clustered | `통합본 §6.9(나)` | hub, infra | TODO | scheduler 신뢰성, job execution | T1-1 PG | `handoff/phase1-013/phase1-013-quartz-jobstore.md` | clustered JobStore 설정, failover/misfire test |
| T1-5 | 사이트별 운영 정보 정리 | `통합본 §13_open §A` | monitoring-meta, infra | IN_PROGRESS | topology/security/node sizing | 외부 정보 | `handoff/phase1-014/phase1-014-site-ops-inputs.md` | site별 운영정보 matrix |

---

## 8. Track 2 — 코어 도메인 / 파이프라인

기반 레이어 위에서 Phase 1 핵심 기능을 구현한다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T2-1 | Rule Engine: `rule-engine-script`, `rule-engine-log` | `통합본 §6.9(다)` | hub | TODO | Alert, validation, rule-based processing | T1-3 일부, job/log pipeline | `handoff/phase1-020/phase1-020-rule-engine.md` | rule execution test, sample rule e2e |
| T2-2 | Alert Processor + Dedup | `통합본 §6.9(다)`, `통합본 §8.3 ADR#15` | hub | TODO | Incident, Notification | T1-1 Redis/PG, T2-1 | `handoff/phase1-021/phase1-021-alert-processor.md` | duplicate suppression test, alert persistence |
| T2-3 | Incident Service + 그룹핑/상태 전환 | `통합본 §6.9(다)` | hub | TODO | UI incident view, notification context | T2-2 | `handoff/phase1-022/phase1-022-incident-service.md` | incident lifecycle test |
| T2-4 | `alert-topic` / `notification-topic` 추가 | `통합본 §6.9(다)` | hub, infra, monitoring-meta | TODO | Alert → Notification pipeline | topic strategy decision 일부 | `handoff/phase1-023/phase1-023-alert-notification-topics.md` | topic contract, producer/consumer test |
| T2-5 | Agent State Service 승격 | `통합본 §6.9(다)` | hub | TODO | Agent OFFLINE alert, UI state | heartbeat infra | `handoff/phase1-024/phase1-024-agent-state-service.md` | agent state transition test |
| T2-6 | Agent OFFLINE → Alert 발화 | `통합본 §6.9(다)`, `통합본 §8.3 ADR#18` | hub | TODO | 운영 알림 | T2-2, T2-5, T2-4 | `handoff/phase1-025/phase1-025-agent-offline-alert.md` | offline detection e2e |
| T2-7 | SQL_JOB 지원 | `통합본 §8.3 ADR#9` | hub, script-agent | TODO | DB query job execution | job pipeline, auth/security 정책 | `handoff/phase1-026/phase1-026-sql-job.md` | SQL_JOB execution test |
| T2-8 | `x-message-id` 중복 검사 | `통합본 §8.3 ADR#15`, `통합본 §6.9(나)` | hub, script-agent | TODO | idempotency | T1-1 Redis | `handoff/phase1-027/phase1-027-message-id-dedup.md` | Redis TTL 5분 dedup test |
| T2-9 | Agent 자가 등록 | `통합본 §8.3 ADR#11`, `통합본 §6.9(나)` | hub, script-agent | TODO | agent onboarding | T1-2 auth, 운영 정책 | `handoff/phase1-028/phase1-028-agent-self-registration.md` | pre-token/admin approval flow test |

---

## 9. Track 3 — 통보 / 검증 / 연동 / UI

코어 도메인 결과를 사용자·운영자·외부 시스템과 연결한다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T3-1 | Notification Service + 채널 어댑터 4종 | `통합본 §6.9(다)` | hub | TODO | 실제 알림 송신 | T2-3, T2-4 | `handoff/phase1-030/phase1-030-notification-service.md` | SMS/Email/Messenger/Teams adapter contract test |
| T3-2 | 통보 그룹: Knox 어댑터 + 자체 통합 | `통합본 §6.9(다)` | hub | TODO | recipient resolution | T1-2, T3-1 | `handoff/phase1-031/phase1-031-notification-groups.md` | group resolution test |
| T3-3 | Validation Service + sandbox mode | `통합본 §6.9(다)` | hub, script-agent | TODO | script/rule 검증 | T2-1, job pipeline | `handoff/phase1-032/phase1-032-validation-service.md` | sandbox execution test |
| T3-4 | 결재 어댑터: webhook 비동기 + HMAC | `통합본 §6.9(다)` | hub | TODO | approval integration | 외부 결재 시스템 정보 | `handoff/phase1-033/phase1-033-approval-adapter.md` | HMAC verification, async webhook test |
| T3-5 | Script 파일 보관 + Object Storage | `통합본 §6.9(다)`, `통합본 §8.3 ADR#12` | hub, infra | TODO | script lifecycle | T1-1 MinIO | `handoff/phase1-034/phase1-034-script-object-storage.md` | upload/download/versioning test |
| T3-6 | Frontend LEGO + WebSocket + Gateway + 권한 필터링 | `통합본 §8.3 ADR#8`, `통합본 §6.9(다)` | hub | TODO | UI/실시간 상태 | T1-2, T2/T3 domain APIs | `handoff/phase1-035/phase1-035-frontend-websocket.md` | permission-filtered websocket e2e |
| T3-7 | LOG_JOB `sample_lines[].occurred_at` | `통합본 §8.3 ADR#10`, `통합본 §6.9(나)` | hub, script-agent | TODO | log timeline accuracy | log pipeline | `handoff/phase1-036/phase1-036-logjob-occurred-at.md` | payload contract test |
| T3-8 | 명령 만료 audit | `통합본 §8.3 ADR#16` | hub, script-agent | TODO | audit completeness | command pipeline | `handoff/phase1-037/phase1-037-command-expiry-audit.md` | `valid_until` expiry audit test |
| T3-9 | audit actor.type 확장 | `통합본 §6.9(나)` | hub | DECISION_REQUIRED | audit normalization | ADR 귀속 결정 | `handoff/phase1-038/phase1-038-audit-actor-type.md` | AGENT/USER/SYSTEM audit event test |

---

## 10. Track 4 — 토픽 재구조 / 메시지 계약

Track 4는 cross-cutting 리스크가 높으므로 Track 0에서 선후 결정을 먼저 한다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T4-1 | 토픽 명명: zone 단위 + 의미 기반 | `통합본 §8.3 ADR#5` | hub, script-agent, infra, monitoring-meta | DECISION_REQUIRED | producer/consumer 전체 | T0-2 | `handoff/phase1-040/phase1-040-topic-naming.md` | topic contract matrix |
| T4-2 | `job-results` → `result-topic-job/log` 분리 | `통합본 §6.9(나)`, `통합본 §8.3 ADR#5 (간접 귀속 [결정 필요])` | hub, script-agent, infra | DECISION_REQUIRED | result pipeline | T4-1 또는 T0 선후 결정 | `handoff/phase1-041/phase1-041-result-topic-split.md` | job/log result e2e |
| T4-3 | zone 단위 topic routing / `command-topic` zone routing | `통합본 §8.3 ADR#4`, `통합본 §6.9(나)` | hub, script-agent, infra | DECISION_REQUIRED | multi-zone command routing | zone topology 정보 | `handoff/phase1-042/phase1-042-zone-topic-routing.md` | zone routing integration test |
| T4-4 | 메시지 키 토픽별 정의 | `통합본 §8.3 ADR#6` | hub, script-agent, monitoring-meta | TODO | ordering/partitioning semantics | topic contract decision | `handoff/phase1-043/phase1-043-message-key-policy.md` | topic별 key rule + test |
| T4-5 | envelope/topic contract 문서 갱신 | `monitoring-meta/docs/kafka-payloads.md`, `monitoring-meta/docs/envelope.md` | monitoring-meta | TODO | repo 구현 일관성 | T0/T4 decisions | `handoff/phase1-044/phase1-044-contract-doc-update.md` | docs updated + drift check |

---

## 11. Track 5 — 구현 없음 / 동일 유지 / Phase 1 미도입

아래 항목은 구현 작업이 없을 수 있다. 단, `NO-OP`도 근거와 검증 증거를 남겨야 한다.

| ID | ADR | 결정 | source_ref | status | acceptance_evidence |
|---|---|---|---|---|---|
| T5-1 | ADR#1 | 스키마 관리 1차 미도입. Phase 2/3 Apicurio 검토 | `통합본 §8.3 ADR#1` | NO-OP | ROADMAP에 Phase 1 미도입 근거 기록 |
| T5-2 | ADR#2 | Heartbeat protobuf 전환 완료 | `통합본 §8.3 ADR#2`, `HANDOFF` | DONE | 2026-06-02 PASS 기록 확인 |
| T5-3 | ADR#3 | Audit 채널 동일 유지 | `통합본 §8.3 ADR#3` | NO-OP | audit channel 유지 근거 기록 |
| T5-4 | ADR#14 | LOG_JOB `file_state` 동일 유지 | `통합본 §8.3 ADR#14` | NO-OP | payload contract 유지 근거 기록 |
| T5-5 | ADR#17 | Quartz misfire 동일 유지: `DO_NOTHING` | `통합본 §8.3 ADR#17` | NO-OP | scheduler 설정 확인 |
| T5-6 | ADR#13 | 라우팅: heartbeat=기구현, metric=Phase 2 | `통합본 §8.3 ADR#13` | PARTIAL | Phase 1 잔여 없음 / metric 라우팅 Phase 2 |

> ADR#4·#12도 Phase 걸침(`PARTIAL`)이나, Phase 1 작업분이 Track 1/4에 실재하므로 본 NO-OP 표가 아니라 해당 Track에서 추적한다(§3 DoD-1 주 참조).

---

## 12. Phase 1 범위 밖

아래 항목은 Phase 2 또는 그 이후로 분리한다.

| 항목 | source_ref | 처리 |
|---|---|---|
| ADR#13 metric routing 잔여 | `통합본 §8.3 ADR#13` | Phase 2 (heartbeat 분은 §11 T5-6 참조) |
| VictoriaMetrics (ADR#12 잔여) | `통합본 §6.9(다)` / Phase 2 | Phase 2 |
| Infra Agent | Phase 2 범위 | Phase 2 |
| Polling Service / Agentless | Phase 2 범위 | Phase 2 |
| `metrics-topic` | Phase 2 범위 | Phase 2 |
| Metric Ingest | Phase 2 범위 | Phase 2 |
| `rule-engine-metrics` | Phase 2 범위 | Phase 2 |
| self-monitoring 인스턴스 | Phase 2 범위 | Phase 2 |
| trace backend | Phase 2 범위 | Phase 2 |
| system log index 분리 | Phase 2 범위 | Phase 2 |
| KDB 구현 | Phase 1 UI 슬롯만 허용 | 구현 보류 |

---

## 13. 권장 HANDOFF 분리안

ROADMAP은 기준 문서로 두고, 아래와 같이 HANDOFF를 생성해 실행한다.

| 순서 | handoff 파일 후보 | 목적 | 대상 repo |
|---|---|---|---|
| 0 | `handoff/phase1-000/phase1-000-roadmap-normalization.md` | ROADMAP 검증, source_ref 보강, [결정 필요] 정리 | monitoring-meta |
| 1 | `handoff/phase1-001/phase1-001-envelope-scope.md` | 나머지 topic envelope 적용 범위와 ADR#5 선후 결정 | monitoring-meta |
| 2 | `handoff/phase1-002/phase1-002-envelope-remaining-topics.md` | envelope 미적용 topic 구현 | hub, script-agent |
| 3 | `handoff/phase1-010/phase1-010-persistence-foundation.md` | PG/OS/Redis/MinIO 기반 | infra, hub |
| 4 | `handoff/phase1-011/phase1-011-auth-oidc-knox.md` | JWT/OIDC/Knox | hub |
| 5 | `handoff/phase1-012/phase1-012-module-split-decision.md` | β/γ 및 deployment map 결정 | monitoring-meta, hub, infra |
| 6 | `handoff/phase1-020/phase1-020-rule-engine.md` | Rule Engine 1차 | hub |
| 7 | `handoff/phase1-021/phase1-021-alert-processor.md` | Alert + dedup | hub |
| 8 | `handoff/phase1-022/phase1-022-incident-service.md` | Incident lifecycle | hub |
| 9 | `handoff/phase1-030/phase1-030-notification-service.md` | Notification pipeline | hub |
| 10 | `handoff/phase1-040/phase1-040-topic-naming.md` | ADR#5 topic contract | monitoring-meta, hub, script-agent, infra |

각 HANDOFF는 아래 섹션을 반드시 포함한다. 또한 §1 헤더에 **기준 monitoring-meta commit full hash**를 박는다(작성↔실행 drift 방지).

```md
# HANDOFF 제목

## 1. 목적 (+ 기준 commit full hash)
## 2. source_ref
## 3. 대상 repo
## 4. 수정 대상 파일/모듈 후보
## 5. 구현 규칙 (+ out-of-scope)
## 6. 테스트 / 검증
## 7. 완료 시 ROADMAP 갱신 항목
## 8. 다음 HANDOFF
```

---

## 14. 미해결 / 결정 필요 목록

| ID | 결정 필요 항목 | 관련 source_ref | 막는 항목 | owner |
|---|---|---|---|---|
| D-1 | AMS 5단계 검증이 실제로 게이팅하는 ADR/컴포넌트 목록 | `통합본 §13_open §J` | G-1 관련 항목 | human/analyzer |
| D-2 | β 유지 vs γ 전환, Phase 1 내 deployment 분리 범위 | `통합본 05 §7.2.6`, `§13_open §C` | T1-3, owner_repo 배치 | human/analyzer |
| D-3 | 영속(#12)과 인증(#7)의 병렬/순차 실행 방식 | `통합본 §8.3 ADR#12`, `ADR#7` | T1-1, T1-2 | human/implementation lead |
| D-4 | envelope 나머지 토픽 적용과 ADR#5 토픽 재구조의 선후 | `HANDOFF`, `통합본 §8.3 ADR#5` | T0, T4 | human/analyzer |
| D-5 | §6.9(나) 데모 정정 항목의 ADR 명시/간접/바깥 분류 확정 | `통합본 §6.9(나)` | DoD-2 | analyzer/codex-gate |
| D-6 | 각 Track 항목의 최종 owner_repo 확정 | ROADMAP 전체 | repo별 HANDOFF | human/analyzer |
| D-7 | harness + plugin 검증 완료 기준 | `HANDOFF`, dev-time infra | 실행 루프 | implementation lead |
| D-8 | site별 운영 정보 중 Phase 1에 반드시 필요한 최소값 | `통합본 §13_open §A` | infra/security/topology | human/infra |

---

## 15. 변경 이력

| 버전 | 변경 |
|---|---|
| v0.1 | Claude 세션 derive 초안 — Tier 1~4 + 선행 게이트 + 작업 0 항목 + Phase 2 분리 |
| v0.2 | 게이트를 global/local/parallel로 세분, Track 0 분리(envelope), Phase 1 DoD 추가, 데모 정정 단정 제거→명시/간접/바깥 분류, 테이블 스키마 보강(source_ref/owner_repo/status/blocks/blocked_by/handoff/acceptance_evidence), ROADMAP/HANDOFF 역할 분리 |
| v0.2 (보완) | source_ref `§05`/`§7.2` → `05 §7.2` 정규화(β/γ=`§7.2.6`, 경계↔데모=`§7.2.4`); status에 `PARTIAL` 추가 + Phase 걸치는 ADR(#4/#12/#13) 처리 명시; 본문의 "Claude Code 지시문" 섹션 제거(재귀 방지, 실행 지시문은 문서 밖에서 전달); owner_repo=monitoring-meta 의미 주석; HANDOFF 템플릿에 기준 commit pin 명시 |

---

## 16. monitoring-meta 배치 권장

- 입력 draft 위치: `monitoring-meta/docs/phase1/ROADMAP_PHASE1_draft_v0_2.md` (이 문서)
- Claude Code 검증 후 생성할 정본 후보: `monitoring-meta/docs/phase1/ROADMAP_PHASE1_v0_3.md`
- normalization handoff: `monitoring-meta/handoff/phase1-000/phase1-000-roadmap-normalization.md`

> 실행 지시문(Claude Code 프롬프트)은 이 정본 문서에 포함하지 않는다. 문서 안에 다음 지시문을 넣으면 버전마다 자기 자신을 재생성하라는 재귀가 생긴다. 지시문은 채팅 또는 normalization handoff로 분리해 전달한다.

---

## 17. 최종 메모

이 ROADMAP은 "Phase 1을 ADR 18개 완료로 단순화하지 않기 위한 기준 문서"이다. Phase 1 완료 판정은 다음 식으로 본다.

```text
Phase 1 DONE
= ADR 18개 판정 완료 (DONE/NO-OP/DEFERRED/PARTIAL)
+ §6.9(나) 데모 정정 항목 정리
+ §6.9(다) 신규 컴포넌트 구현/보류 판정
+ 05 §7.2 모듈 분리 결정
+ repo별 HANDOFF 완료
+ monitoring-meta e2e 증거
+ source_ref drift 없음
```

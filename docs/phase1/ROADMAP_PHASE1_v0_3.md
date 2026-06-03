# Phase 1 ROADMAP — v0.3 (정본 후보)

> **위상**: 이 문서는 `monitoring-meta/docs/통합본_v0_9.md`를 최상위 기준으로 삼는 **Phase 1 정본 후보 ROADMAP**이다. 입력 draft(`ROADMAP_PHASE1_draft_v0_2.md`)를 Pass 1 normalization(`handoff/phase1-000-roadmap-normalization.md`) 검증 결과로 정정·반영해 생성했다. draft를 그대로 정본화한 것이 아니다.
>
> **문서 위상 우선순위** (HANDOFF.md §3): 코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(Phase 1+ 도달 목표). "통합본 우선"은 **사실 주장(범위·각 ADR 결정)** 에만 적용한다. tier 순서 / owner_repo / handoff 분리 같은 **계획 레이어**는 ROADMAP 고유 판단이므로 보존하되, 불확실하면 `DECISION_REQUIRED`로 둔다.
>
> **`[결정 필요]`는 멈춤 사유가 아니라 기록 대상**이다. §17 미해결 목록(D-목록)에 모은다. (§14는 Track 5다. 이전 v0.2에서 "§14에 모은다"고 한 자기참조 오류를 v0.3에서 §17로 정정.)

---

## 1. 헤더 / 기준 정보

| 항목 | 값 |
|---|---|
| 문서 버전 | v0.3 (정본 후보) |
| 입력 draft | `docs/phase1/ROADMAP_PHASE1_draft_v0_2.md` |
| Pass 1 검증 | `handoff/phase1-000-roadmap-normalization.md` |
| 최상위 기준(정본) | `docs/통합본_v0_9.md` |
| 보조 입력 | `HANDOFF.md`, `docs/kafka-payloads.md`, `docs/envelope.md` |
| 기준 monitoring-meta commit (full hash) | `4940e1a115b911e452f96f0083f1c4dc6ede879f` |
| 작성 기준일 | 2026-06-03 |

> **owner_repo 표기 주의**: `owner_repo`에 `monitoring-meta`가 들어가면 *코드 구현* 소유가 아니라 *spec/contract 문서*(`kafka-payloads.md`, `envelope.md`) 갱신 소유를 뜻한다. monitoring-meta는 런타임 repo가 아니라 공통 자산 보관소다(HANDOFF.md §2).
>
> **source_ref 표기 규칙 (Pass 1 drift-1~4 반영)**:
> - `05 §7.2.6` / `05 §7.2.4`는 §7.2 본문의 절 번호가 아니라 **§13_open §C의 cross-ref 라벨**이다. 단독 인용하지 말고 `통합본 §13_open §C (05 §7.2.6 cross-ref) / 본문 05 §7.2 "모듈 분리 정책" 단락`처럼 병기한다(drift-1/N-1).
> - 통합본에 `# 11` 최상위 토픽은 없다. AMS/마이그레이션은 `09 §11.x`, AMS 검증 가정은 §13_open §J가 집약한다. `통합본 §11` 단독 인용은 쓰지 않는다(drift-2/N-2).
> - `HANDOFF` 단독 인용 대신 `HANDOFF.md §5(작업 위상)` / `§7(미결정 사안)` 등 절을 지정한다(drift-3, 정밀화).
>
> **결정 필요 목록 위치**: 본 문서의 `[결정 필요]`(D-목록)는 **§17**에 모은다. **§14는 Track 5(구현 없음/동일 유지)** 이며 D-목록이 아니다. 본문·규칙에서 D-목록을 가리킬 때는 항상 §17로 인용한다.

---

## 2. 문서의 목적

이 문서는 Phase 0 완료 이후 Phase 1 완료까지 필요한 작업을 한 곳에서 추적하기 위한 기준 ROADMAP이다. 실제 repo 작업 지시서가 아니다. 실제 구현은 이 ROADMAP을 기준으로 잘라낸 별도 HANDOFF 문서를 통해 수행한다.

```text
통합본_v0_9.md
  ↓ derive
docs/phase1/ROADMAP_PHASE1_draft_v0_2.md   (입력 draft)
  ↓ verify (Pass 1: analyzer normalization + codex-gate)
handoff/phase1-000-roadmap-normalization.md (검증 결과)
  ↓ apply (Pass 2)
docs/phase1/ROADMAP_PHASE1_v0_3.md         (이 문서, 정본 후보)
  ↓ slice
handoff/phase1-xxx-*.md
  ↓ execute
hub / script-agent / infra / monitoring-meta
  ↓ verify
monitoring-meta e2e + ROADMAP status update
```

---

## 3. Phase 1 범위 정의

Phase 1 완료는 `ADR 18개 완료`만으로 판단하지 않는다. 아래 묶음의 합집합을 닫는 것으로 본다.

| 묶음 | 설명 | primary source_ref | 비고 |
|---|---|---|---|
| ADR 18개 | Phase 1 결정 레이어 | `통합본 §8.3` | 일부 ADR은 구현 없음 / 동일 유지 / 미도입 / Phase 걸침일 수 있다. 단순 "18개 완료"로 뭉개지 않는다(§5 DoD-1). |
| 데모 정정 항목 | Phase 0 데모와 통합문서 사이의 정합성 정정 | `통합본 §6.9(나)` (= 6.9.2) | 11개. ADR 명시 7 / ADR 간접 귀속 2 / ADR 바깥 2로 재분류(§3.1). 간접 1개(job-results→ADR#5)와 바깥 2개의 최종 귀속은 `DECISION_REQUIRED`(D-5). command routing→ADR#4는 §8.3 결정 컬럼이 직접 포함하므로 확정 귀속(§3.1 주). |
| Phase 1 신규 컴포넌트 | Rule Engine, Alert, Incident, Notification 등 | `통합본 §6.9(다)` (= 6.9.3) | ADR 카탈로그 바깥의 실제 기능 빌드 포함. **서비스 구현과 전용 Kafka 토픽(alert-topic/notification-topic) 신설은 둘 다 Phase 1 확정**이다(통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표). ADR#5는 토픽 **명명 규칙**만 결정(D-4) — 아래 경계 주석 참조. |
| 모듈 구조 정리 | 모듈러 모놀리스 → deployment 분리(β) | `본문 05 §7.2 "모듈 분리 정책" 단락`, `통합본 §13_open §C (05 §7.2.6 cross-ref)`, `HANDOFF.md §7` | β 유지 / γ 전환 / 분리 시점은 `DECISION_REQUIRED`(D-2). **통합본 미결 Open(§13_open §C) — 추측 금지.** |
| 검증 증거 | repo별 테스트, e2e, source_ref drift 점검 | `HANDOFF.md §5`, `monitoring-meta e2e` | Phase 1 완료 증거로 남긴다. |

> **서비스 구현 + 전용 Kafka 토픽 경계 주석 (D-9 결정 반영 2026-06-03)**: Alert/Incident/Notification **서비스**는 Phase 1 신규 컴포넌트로 **확정**이다(통합본 §6.9(다)/6.9.3). **그리고 전용 Kafka 토픽 `alert-topic`/`notification-topic` 추가도 Phase 1 확정이다** — 통합본 §6.9.3 (다) "Phase 1:" 표가 두 토픽을 "Kafka 토픽 추가"로 직접 명시하고(`alert-topic`=4.4.1·6.4, `notification-topic`=4.4.1·6.5), §6.9.5 토픽표가 둘을 "(다) v0.7 신규 (Phase 1)"로 박았다(확인된 사실). 따라서 "토픽이 Phase 1 topic set에 포함되는가"는 더 이상 Open이 아니다(과거 D-9는 2026-06-03 RESOLVED, §17). **ADR#5가 여는 것은 토픽 *명명 규칙*(zone 단위 + 의미 기반 prefix)과 토픽 재구조의 *실행 선후*뿐이며, 이는 D-4로 남는다. D-4(2) 실행 선후는 2026-06-04 RESOLVED(envelope 먼저, `adr/0005`); D-4(1) 구체 명명 규칙은 `adr/0005-topic-naming.md`로 승격되어 비준 대기다(§17).** §6.9.5 두 토픽의 key rule도 통합본이 확정한다: `alert-topic` = `(rule_id, target_id)` 조합 / `notification-topic` = `incident_id`. 따라서 §11~§12 Track 2/3의 서비스 항목(T2-2/T2-3/T3-1 등)과 전용 토픽 추가(T2-4)는 모두 Phase 1 TODO로 추적하며, 잔여 결정은 명명 규칙(D-4(1))뿐이다.

### 3.1 데모 정정 항목 재분류 (§6.9.2 11개 전수 — Pass 1 §4 반영)

§6.9.2 (나) 표 11개를 "ADR 명시 / ADR 간접 귀속 가능 / ADR 바깥 정정"으로 전수 재분류한다. 기존 v0.1의 "7개만 ADR 연결, 4개는 ADR 없음" 단정은 쓰지 않는다.

| # | §6.9(나) 항목 | 재분류 | 귀속 ADR / status |
|---|---|---|---|
| 1 | `job-results` 토픽 분리 | **ADR 간접 귀속 [결정 필요]** | ADR#5 의미 연결, §8.3 직접 번호 미부여 → D-5. 분리 자체=Phase 1 확정(§6.9.2 항목1) / 최종 명명 규칙만 D-4. T4-2 |
| 2 | Heartbeat 직렬화 | **ADR 명시** | ADR#2 → **DONE** (heartbeat 마샬링 한정 — envelope 전 토픽 적용 ≠ ADR#2, 비고는 §5.1 #2 / T5-2) |
| 3 | `x-message-id` 중복 검사 | **ADR 명시** | ADR#15 → TODO. T2-8 |
| 4 | 영속 저장소 | **ADR 명시** | ADR#12 → PARTIAL. T1-1 |
| 5 | 인증/인가 | **ADR 명시** | ADR#7 → TODO. T1-2 |
| 6 | Frontend | **ADR 명시** | ADR#8 → TODO. T3-6 |
| 7 | Agent 자가 등록 | **ADR 명시** | ADR#11 → TODO. T2-9 |
| 8 | Quartz JobStore DB-backed clustered | **ADR 바깥 (Phase 1 확정 정정, ADR 귀속만 미정)** | §8.3 직접 ADR 없음(ADR#17 misfire와 별개). 구현 필요성=Phase 1 확정 / ADR 귀속만 D-5. T1-4 |
| 9 | LOG_JOB `sample_lines[].occurred_at` | **ADR 명시** | ADR#10 → TODO. T3-7 |
| 10 | audit actor.type 범위(AGENT+USER+SYSTEM) | **ADR 바깥 (Phase 1 확정 정정, ADR 귀속만 미정)** | §8.3 직접 ADR 없음. 구현 필요성=Phase 1 확정 / ADR 귀속만 D-5. T3-9 |
| 11 | `command-topic` zone routing | **ADR#4 확정 귀속 (사실)** | 통합본 §8.3 ADR#4 결정 컬럼 = "동일 + **zone 단위 토픽 routing**"으로 zone routing을 직접 포함한다(확인된 사실). 따라서 ADR#4로 **확정 귀속**하며 D-5 범위에서 제외한다. T4-3 |

> **§3.1 status 단일값 주 (CRITICAL round-2)**: 위 표의 "귀속 ADR / status" 열에서 status 토큰은 §6 허용 8값 중 단일값(항목 2=`DONE`)이며, 범위 한정("heartbeat 마샬링 한정")은 status 토큰이 아니라 비고 문구다. ADR#2의 의미 한정 상세는 §5.1 #2 비고열 / §14 T5-2 비고열로 분리해 보존한다.

**재분류 집계**: ADR 명시 7 (항목 2·3·4·5·6·7·9) / 확정 귀속 1 (11→ADR#4, 통합본 §8.3 결정 컬럼이 직접 포함) / 간접 귀속 1 (1→ADR#5, §8.3 직접 번호 미부여 → D-5) / ADR 바깥 2 (8, 10 — 구현은 Phase 1 확정, ADR 귀속만 D-5). **D-5가 다루는 미결은 (job-results→ADR#5 간접 후보 1) + (ADR 바깥 2: Quartz JobStore, audit actor.type)뿐이다.** command routing(11)은 ADR#4 확정 귀속이므로 D-5에서 제외(§17 D-5 갱신).

---

## 4. ROADMAP과 HANDOFF의 역할

- **ROADMAP** — Phase 1 전체 기준 문서. Phase 1 완료 범위, 의존 순서, source_ref, owner_repo 후보, blocker/gate, status, acceptance evidence, HANDOFF 분리 단위를 정의한다. 직접 구현 지시서가 아니다.
- **HANDOFF** — 실제 작업 단위 실행 문서. 어느 repo를 수정할지, 어떤 파일/모듈을 바꿀지, 어떤 테스트로 완료를 증명할지, 완료 후 ROADMAP의 어느 항목을 갱신할지, 다음 handoff로 무엇을 넘길지 정의한다.

권장 운영 루프: `ROADMAP 항목 선택 → handoff 생성 → repo별 구현 → 테스트/e2e → codex-gate 검토 → ROADMAP status·acceptance_evidence 갱신`.

---

## 5. Phase 1 Definition of Done

Phase 1 완료는 다음을 모두 만족해야 한다.

> **DoD-1 ↔ §5.1 TODO ADR 관계 주 (gate 4차 — spec 5 해소)**: DoD-1 status=`IN_PROGRESS`는 "**ADR 판정이 진행 중**"이라는 뜻이다. §5.1 매트릭스의 TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 **최종 판정 전 진행 중 상태**이며, Phase 1 완료 시 각 Track 작업을 통해 `DONE`/`PARTIAL`/`NO-OP`/`DEFERRED` 중 하나의 **최종 판정으로 닫혀야 DoD-1이 충족**된다. 즉 `IN_PROGRESS` = "아직 TODO/DECISION_REQUIRED ADR이 남아 판정이 닫히지 않음"이다.

| ID | 완료 조건 | 확인 방법 | 상태 | 비고 |
|---|---|---|---|---|
| DoD-1 | **ADR 판정 완료 조건**: `통합본 §8.3` ADR 18개가 각각 **최종 판정** `DONE`/`NO-OP`/`DEFERRED`/`PARTIAL` 중 하나에 도달해 있다. | §5.1 ADR 판정 매트릭스 확인 | IN_PROGRESS | 현재 판정 상태에 TODO/DECISION_REQUIRED ADR이 다수 — 아직 최종 판정으로 닫히지 않음(판정 진행 중). TODO ADR은 §5.1 참조 |
| DoD-2 | `통합본 §6.9(나)` 데모 정정 11개가 §3.1 재분류대로 `DONE`/`DEFERRED`/`DECISION_REQUIRED` 중 하나로 추적되어 있다. | demo-correction matrix(§3.1) 확인 | IN_PROGRESS | — |
| DoD-3 | `통합본 §6.9(다)` Phase 1 신규 컴포넌트가 구현 또는 명시 보류되어 있다. | component matrix(Track 2/3) 확인 | TODO | — |
| DoD-4 | `본문 05 §7.2 "모듈 분리 정책" 단락` / `통합본 §13_open §C (05 §7.2.6 cross-ref)` 모듈 분리 기준이 β 유지인지 γ 전환인지 결정되어 있다. | ADR 또는 ROADMAP 결정 섹션 확인 | DECISION_REQUIRED | D-2, 통합본 미결 Open |
| DoD-5 | hub / script-agent / infra / monitoring-meta 별 HANDOFF가 완료되고 repo별 테스트가 통과했다. | handoff completion log 확인 | TODO | — |
| DoD-6 | monitoring-meta 기준 e2e 검증 결과가 남아 있다. | e2e 결과 파일/로그 확인 | TODO | ADR#2 한정 PASS 기록 존재 |
| DoD-7 | ROADMAP, ADR, HANDOFF, 통합본 간 source_ref drift가 없다. | codex-gate / analyzer 검토 결과 확인 | TODO | — |

> **DoD status 셀 단일값 주 (CRITICAL round-2)**: 위 DoD 표의 "상태" 열은 §6 허용 8값 중 **정확히 하나만** 담는다. 진행 상황·범위 설명은 "비고" 열로 분리했다(이전 v0.3에서 status 셀에 괄호 수식어가 섞여 있던 것을 정정).

> **DoD-1 정의 명확화 (S-2/N-5 재정정)**: DoD-1은 **Phase 1 "완료" 조건이 아니라 "ADR 18개 판정 완료" 조건**이다.
> - **DoD-1 = "18개 ADR이 각각 최종 판정(`DONE`/`NO-OP`/`DEFERRED`/`PARTIAL`) 중 하나에 도달"**.
> - `TODO` / `DECISION_REQUIRED`는 **진행 중 추적 상태**이지 최종 판정도, Phase 1 완료 상태도 아니다. 현재 §5.1 매트릭스에 TODO ADR(#5·#7·#8·#9·#10·#11·#15)과 DECISION_REQUIRED가 남아 있으므로 DoD-1은 아직 충족되지 않았다(IN_PROGRESS = 판정 진행 중, §5 머리 주 참조).
> - **Phase 1 *완료* 시점에는** TODO/DECISION_REQUIRED ADR이 모두 최종 판정(`DONE`/`NO-OP`/`DEFERRED`/`PARTIAL`)으로 닫혀 있어야 한다. 즉 "판정 추적 경로 연결"(TODO→Track 항목, DECISION_REQUIRED→§17 D-목록)은 *진행 관리*이고, Phase 1 완료의 필요조건은 그 추적이 최종 판정으로 *닫히는 것*이다. 두 단계를 분리해 본다.

**Phase 걸치는 ADR 처리**: 한 ADR이 Phase를 걸치면 `PARTIAL`로 판정하고 **Phase 1 범위 / Phase 2 잔여**를 함께 명시한다(단일 status로 뭉개지 않는다).
- ADR#4: group.id 정책 유지=Phase 1 기구현 / zone 단위 command-topic routing=후속(잔여, T4-3).
- ADR#12: PG/OS/Redis/MinIO=Phase 1 / VictoriaMetrics=Phase 2.
- ADR#13: **heartbeat 수집 경로=기구현(Phase 1 잔여 없음) / metric routing·self 별도=Phase 2** (drift-4/N-3 반영 — "heartbeat=기구현"은 라우팅 분리가 아니라 수집 경로 기구현을 뜻함).

### 5.1 ADR 18개 판정 매트릭스 (DoD-1 임베드 — Pass 1 §3 / S-2)

판정 기준: 통합본 §8.3 결정(목표 spec) + 데모 §6.9 위상 + 실제 main 코드(`../hub`, `../script-agent`, `../infra`) + `HANDOFF.md §5`.

> **TODO ADR ↔ DoD-1 관계 (gate 4차 — spec 5)**: 아래 TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 **최종 판정 전 진행 중 상태**다. Phase 1 완료 시 각 Track 작업을 통해 `DONE`/`PARTIAL` 등 최종 판정으로 닫혀야 DoD-1(=ADR 판정 완료)이 충족된다(§5 DoD-1 머리 주 참조).

> **status 렌즈 구분 주석 (필독)**: 이 §5.1의 status는 **ADR *전체* 의 판정 렌즈**(ADR이 정의하는 결정 전체가 어느 단계인가)다. 이와 별개로 §9~§14 Track 표의 status는 **Phase 1 *작업* 의 진행 렌즈**(Phase 1에 실재하는 작업 단위가 어디까지 갔나)다. 또한 §7 8토픽 계약 매트릭스의 셀은 **계약 *spec* 렌즈**(토픽 계약이 무엇으로 정의되나)다. 세 렌즈는 서로 다르다.
> 예: **ADR#13은 §5.1에서 PARTIAL**(ADR 전체: heartbeat 수집 경로 완료 / metric routing·self는 Phase 2)이지만, **Phase 1에 남은 *작업분*은 없다**. Phase 1 무작업이므로 Track 1~4의 작업 항목으로 잡히지 않고 §14 Track 5(T5-6)에 "Phase 1 무작업 + Phase 2 잔여 분리" 근거로 들어간다. 즉 §5.1=PARTIAL이라도 Phase 1 작업이 없으면 Track 5에 위치한다.

| ADR | 주제 | 통합본 §8.3 결정 | status | Phase 1 범위 / Phase 2 잔여 / 추적 |
|---|---|---|---|---|
| #1 | 스키마 관리 | 1차 미도입, Phase 2/3 Apicurio | **NO-OP** | Phase 1 미도입 근거 기록. T5-1 |
| #2 | Heartbeat 마샬링 | Phase 1 protobuf | **DONE** | heartbeat 마샬링 한정. 잔여 없음. e2e PASS 16/0/0(2026-06-02). **envelope 전 토픽 적용 ≠ ADR#2**(envelope 나머지 토픽은 Track 0) — T5-2/C-3 |
| #3 | Audit 채널 | Kafka 직행 동일 유지 | **NO-OP** | T5-3 |
| #4 | Consumer group | 동일 + zone 단위 토픽 routing | **PARTIAL** | Phase 1: group.id 유지(기구현). 잔여: zone 단위 command-topic routing → T4-3 |
| #5 | 토픽 명명 | zone 단위 + 의미 기반 | **TODO** | Phase 1 전체. 토픽 *명명 규칙*(D-4(1) — `adr/0005` 비준 대기) + 토픽 재구조 *실행 선후*(D-4(2) — 2026-06-04 RESOLVED, envelope 먼저). alert/notification 토픽 신설 자체는 Phase 1 확정(§6.9.3·§6.9.5). T4-1 |
| #6 | 메시지 키 | 토픽별 정의 | **PARTIAL** | 기존 토픽 키 기구현(command=target_agent_id). 잔여: 신규 토픽 key 정의(alert=`(rule_id,target_id)`/notification=`incident_id` — 통합본 §6.9.5 확정) → T4-4 (N-4) |
| #7 | 인증/인가 | JWT+OIDC+Knox (Phase 1) | **TODO** | Phase 1 전체. T1-2 |
| #8 | 시각화 | LEGO + WebSocket | **TODO** | Phase 1 전체. T3-6 |
| #9 | SQL_JOB | Phase 1 포함 | **TODO** | Phase 1 전체. T2-7 |
| #10 | LOG_JOB occurred_at | Phase 1 추가 | **TODO** | Phase 1 전체. T3-7 |
| #11 | Agent 자가 등록 | Phase 1 사전 토큰/승인 | **TODO** | Phase 1 전체. T2-9 |
| #12 | 영속 저장소 | PG+OS+Redis+MinIO+VM(Phase 2) | **PARTIAL** | Phase 1: PG/OS/Redis/MinIO(T1-1). 잔여: VictoriaMetrics=Phase 2 |
| #13 | OTel Collector 라우팅 | metric/heartbeat 분리 + self 별도 | **PARTIAL** | Phase 1: heartbeat 수집 경로 기구현(잔여 없음). 잔여: metric routing + self 별도=Phase 2 (drift-4/N-3). **Phase 1 작업분 없음 → Track 5(T5-6)에 위치(렌즈 구분 주석 참조)** |
| #14 | LOG_JOB file_state | Agent local 동일 유지 | **NO-OP** | T5-4 |
| #15 | x-message-id 중복 검사 | Phase 1 Redis TTL | **TODO** | Phase 1 전체. T1-1(Redis) 선행 → T2-8 |
| #16 | 명령 만료 valid_until | 정책 유지 + 만료 audit | **PARTIAL** | 정책(computeValidUntil 0.9) 기구현. 잔여: 만료 audit → T3-8 (N-4) |
| #17 | Quartz misfire | DO_NOTHING 동일 유지 | **NO-OP** | T5-5 |
| #18 | 오프라인 Agent 게이팅 | heartbeat 게이팅 + Agent OFFLINE Alert | **PARTIAL** | OFFLINE 판정/heartbeat 게이팅 기구현. 잔여: OFFLINE→Alert 발화 → T2-6 (N-4) |

> #6/#16/#18의 PARTIAL 판정은 "통합본 결정 사실 ∩ 코드 현황"의 교차로 도출된 **사실 정정**(N-4)이며 DECISION_REQUIRED가 아니다. draft가 TODO로 둔 것을 v0.3에서 정정했다.
> **TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 아직 최종 판정이 아니다**(진행 중 추적 상태). DoD-1 충족(=ADR 판정 완료)을 위해 Phase 1 완료 시점까지 각 Track 작업을 통해 `DONE`/`PARTIAL` 등 최종 판정으로 닫혀야 한다(§5 DoD-1 주 참조).
> **#2 status 셀 단일값 주 (CRITICAL round-2)**: ADR#2 status는 `DONE` 단일값이다. "heartbeat 마샬링 한정 / envelope 전 토픽 적용 ≠ ADR#2"라는 범위 한정은 status 셀이 아니라 "Phase 1 범위 / Phase 2 잔여 / 추적" 열의 비고로 분리했다.
> **#5 D-9 결정 반영 주 (2026-06-03)**: ADR#5 status는 `TODO` 단일값(Phase 1 전체). alert/notification 전용 토픽 신설 자체는 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 Phase 1 확정이므로 ADR#5에 종속되지 않는다. ADR#5가 여는 것은 토픽 *명명 규칙*(D-4(1) — `adr/0005` 비준 대기)과 토픽 재구조 *실행 선후*(D-4(2) — 2026-06-04 RESOLVED, envelope 먼저)뿐이다.

---

## 6. 상태값 규칙

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

> **status 단일 허용값 규칙**: 모든 status 셀에는 위 8개 허용값 중 **정확히 하나만** 적는다. "PARTIAL(잔여)/후속"처럼 두 값/수식어를 붙이지 않는다. 괄호 수식어("(heartbeat marshalling only)" 등)도 status 셀에 두지 않는다. 잔여·후속·범위 설명은 status 셀이 아니라 `Phase 1 범위 / Phase 2 잔여` 열, `acceptance_evidence`, 또는 비고/주석으로 분리한다.

---

## 7. 8토픽 계약 매트릭스 (C-1 해소 — 신규 섹션)

> **§7 렌즈 선언 (gate 4차 — critical 1 + spec 3·4 해소, 필독)**: **이 매트릭스는 *목표 계약 spec*이다.** 출처는 정본 `docs/kafka-payloads.md` + `docs/envelope.md`(= Phase 1+ 도달 목표 spec)다. 각 셀은 **"해당 토픽의 *계약*(envelope 적용 여부/방식, key rule, payload schema ref)이 무엇인가"** 를 기술하며, **Phase 1 *구현 시점·완료 상태가 아니다*.** 구현 상태/진행 시점(어느 Track에서 누가 언제 구현하는가)은 §9~§14 Track 표에서 별도로 추적한다. 즉 이 표의 "**적용**"·확정 key는 "계약이 그렇게 정의된다"는 뜻이지 "Phase 1에서 이미 구현 완료됐다"는 뜻이 아니다(§5.1=ADR 판정 렌즈 / Track=작업 진행 렌즈 / §7=계약 spec 렌즈의 3렌즈 구분 — §5.1 렌즈 주석 참조).
> **토픽 명명 규칙 종속 마커 (셀 단위 구분)**: 일부 토픽의 *계약 내용*(envelope 적용·key)은 확정이되, 토픽의 **최종 *이름*(name)** 은 ADR#5/D-4(1)(zone 단위 + 의미 기반 prefix 명명 규칙)에 종속된다. 해당 셀에는 마커 **"(토픽명/zone suffix 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정)"** 를 단다. **이 마커는 계약 내용(확정)이 아니라 최종 *이름*(미정)에만 걸린다.** §7 선언("미정 셀은 `[결정 필요]`")과의 정합: 본 표에서 미정인 것은 *명명 규칙*뿐이며(D-4(1)), 위 마커로 셀에 직접 표기해 계약 내용 확정분과 분리한다(임의 결정 금지). 실행 선후(D-4(2))는 2026-06-04 RESOLVED(envelope 먼저)이므로 더 이상 미정이 아니다.

8토픽 각각의 envelope 적용 여부/방식, 메시지 키 규칙, payload schema 참조, 근거를 한 표로 모은다. 출처: `docs/envelope.md`(§2·§4) + `docs/kafka-payloads.md` + 통합본 §8.3 ADR#2/#5/#6 + 통합본 6.8.1/6.8.2/4.4.1 + §6.9.3/§6.9.5(alert/notification Phase 1 확정·key rule). **미정 셀(= 최종 토픽 명명 규칙)은 위 명명 규칙 종속 마커로 셀에 직접 박는다(임의 결정 금지).** 보조 설명은 §7.1.

8토픽 = `command-topic-{zone}`, `result-topic-job`, `result-topic-log`, `audit-topic`, `heartbeats-topic`(OTLP 예외), `alert-topic`, `notification-topic`, `metrics-topic`(Phase 2·OTLP 예외). (위 토픽명은 현재 kafka-payloads.md 기준 잠정 이름이며, 최종 이름은 ADR#5(`adr/0005`) 명명 규칙 비준 대기에 종속된다 — 셀 마커 참조.)

| 토픽 | envelope 적용 여부/방식 | key rule | payload schema ref | 근거(ADR + 통합본 조항) |
|---|---|---|---|---|
| `command-topic-{zone}` | **적용** — envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). zone suffix와 무관하게 동일. (zone suffix 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정) | `target_agent_id` | kafka-payloads `command-topic-{zone}` | ADR#5(토픽 명명: zone 단위+의미 기반)·ADR#6 / 통합본 6.8.1·6.8.2·4.4.1, envelope §4.1 |
| `result-topic-job` | **적용** — envelope 4종 표준. **분리=Phase 1 확정**(통합본 §6.9.2 항목1), envelope·key 확정. (토픽명 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정) | `agent_id` | kafka-payloads `result-topic-job` | ADR#6·ADR#5(명명 규칙만 D-4(1)) / 통합본 6.9.2 항목1·6.8.2, envelope §4.1 |
| `result-topic-log` | **적용** — envelope 4종 표준. **분리=Phase 1 확정**(통합본 §6.9.2 항목1), envelope·key 확정. (토픽명 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정) | `agent_id` | kafka-payloads `result-topic-log` | ADR#6·ADR#10(occurred_at)·ADR#14(file_state)·ADR#5(명명 규칙만 D-4(1)) / 통합본 6.9.2 항목1·6.8.2, envelope §4.1 |
| `audit-topic` | **적용** — 4종 표준. `x-trace-id`는 audit 데모 적용 사실 있으나 정의상 여전히 선택(○), 전용 필수화는 envelope이 새로 정하지 않음 | `agent_id` / `user_id` / `system` (actor 단위) | kafka-payloads `audit-topic` | ADR#3(채널 동일 유지)·ADR#6 / 통합본 6.6.3·6.8.2, envelope §4.1 |
| `heartbeats-topic` | **미적용(OTLP 예외)** — envelope 4종 미적용, OTLP 표준 헤더. 식별·버전은 OTLP/Collector 표준 위임(1:1 대응 보장 아님) | (OTLP 위임 — envelope 키 정책 적용 안 함) | kafka-payloads `heartbeats-topic` (OTLP MetricsData protobuf, Phase 1) | ADR#2(Phase 1 protobuf, status `DONE`; heartbeat 마샬링 한정)·ADR#13(라우팅 PARTIAL) / 통합본 6.8.1 예외문·4.4.1, envelope §4.2 |
| `alert-topic` | **적용** — envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5). (토픽명 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정) | `(rule_id, target_id)` 조합. `rule_id`가 null이면 `("agent-offline", target_id)` | kafka-payloads `alert-topic` | 통합본 §6.9.3(Phase 1 확정)·§6.9.5(key rule)·6.8.2·6.8.3 / ADR#6 / envelope §4.1·§5 |
| `notification-topic` | **적용** — envelope 4종. 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5). (토픽명 명명 규칙 = ADR#5(`adr/0005`) 비준 대기, 현재 kafka-payloads 이름은 잠정) | `incident_id` | kafka-payloads `notification-topic` | 통합본 §6.9.3(Phase 1 확정)·§6.9.5(key rule)·6.8.2 / ADR#6 / envelope §4.1 |
| `metrics-topic` | **미적용(OTLP 예외)** — Phase 2 신규, **Phase 1 미사용**. OTLP 표준 헤더 | (OTLP 위임 — envelope 키 정책 적용 안 함) | kafka-payloads `metrics-topic` (OTLP MetricsData protobuf, Phase 2) | ADR#13(metric routing=Phase 2)·ADR#2(Phase 1 protobuf 대상은 heartbeats뿐, metrics 비포함) / 통합본 6.9.5, envelope §4.2 |

> **alert/notification 셀 확정 근거 (D-9 결정 반영 2026-06-03)**: 위 두 토픽의 매트릭스 셀의 *계약 내용*(envelope 4종·key rule)은 확정이다. 통합본 §6.9.3 (다) "Phase 1:" 표가 두 토픽을 Phase 1 Kafka 토픽 추가로 명시하고, §6.9.5 토픽표가 둘을 "(다) v0.7 신규 (Phase 1)"로 확정하며 key rule(alert=`(rule_id, target_id)` 조합 / notification=`incident_id`)까지 박았다(확인된 사실). envelope 적용은 envelope §4.1 공통 토픽군 4종 표준이다. **단, 토픽의 최종 *이름*은 ADR#5(`adr/0005`) 명명 규칙 비준 대기에 종속(셀 마커)** 이며, *토픽이 Phase 1 topic set에 포함되는가*는 결정 완료다. (계약 내용 확정 / 최종 이름 미정의 분리 — §7 렌즈 선언 참조.)

### 7.1 매트릭스 셀 보조 설명 (잔여 결정은 D-4)

표 셀의 결정 종속 관계를 풀어 설명한다(보조 설명, 잔여 결정은 §17 D-목록). **아래 모든 항목에서 *계약 내용*(envelope 적용·key)은 확정이며, 미정인 것은 토픽의 최종 *이름*(명명 규칙, D-4(1))뿐이다(§7 렌즈 선언). 실행 선후(D-4(2))는 2026-06-04 RESOLVED(envelope 먼저, `adr/0005`).**

- **`alert-topic` / `notification-topic` 토픽의 Phase 1 확정 추가**: 두 토픽을 Phase 1 확정 구현으로 신설하는 것은 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **확정**이다(과거 D-9는 2026-06-03 RESOLVED, §17). 매트릭스 셀에 envelope 4종·key rule을 확정값으로 담는다.
  - `alert-topic` envelope: envelope 4종 표준(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). payload `trace_id`는 헤더 `x-trace-id`의 도메인 사본(불변식 envelope §5).
  - `alert-topic` key: `(rule_id, target_id)` 조합, `rule_id`가 null이면 `("agent-offline", target_id)`(통합본 §6.9.5 확정).
  - `notification-topic` envelope: envelope 4종 표준.
  - `notification-topic` key: `incident_id`(통합본 §6.9.5 확정).
  - 잔여 결정은 두 토픽의 *최종 명명 규칙*(zone 단위 + 의미 기반 prefix)이며 ADR#5(`adr/0005`) 비준 대기(D-4(1))다(셀 마커). *신설 자체의 Phase 1 확정*과 *계약 내용*은 닫혔다.
- **`result-topic-job` / `result-topic-log` 분리**: `job-results` → 2개 분리(§6.9.2 항목 1)는 **분리 자체=Phase 1 확정**이고, envelope 적용·key(`agent_id`)도 확정이다. 잔여는 *최종 토픽 명명 규칙*(`result-topic-job`/`result-topic-log` 이름, D-4(1))과 토픽 재구조 *실행 선후*(D-4(2) — 2026-06-04 RESOLVED, envelope 먼저)이며 ADR#5(`adr/0005`)에 종속이다(ADR 귀속 미결은 D-5). 표 토픽명 셀은 분리 전제가 아니라 Phase 1 확정 분리분으로 두되, 최종 이름은 셀 마커로 D-4(1) 비준 대기를 표기한다.
- **`command-topic-{zone}` zone suffix 물리 실현**: envelope.md §4 주는 `command-topic`을 논리명으로, `command-topic-{zone}`을 zone 단위 물리 실현으로 본다(통합본 4.4.1 "zone 단위"). envelope 4종 적용은 zone suffix와 무관하게 동일하다(계약 확정). 단 zone suffix의 *명명 규칙*은 ADR#5(`adr/0005`) 비준 대기(D-4(1), 셀 마커)이고, zone 단위 routing 물리 실현(ADR#4 잔여 — **ADR#4 확정 귀속**, §3.1 항목 11)은 T4-3, zone topology 정보 입수(§13_open §A)에 종속한다.

> 위 셀들에서 alert/notification·result 분리의 *계약 내용*은 Phase 1 확정 spec이며, 남는 결정은 토픽의 *최종 명명 규칙*(D-4(1), `adr/0005` 비준 대기)과 result 분리 ADR 귀속(D-5)뿐이다(실행 선후 D-4(2)는 RESOLVED). **토픽 추가/분리 자체는 통합본 정본에 박힌 사실이다.** 본 §7 표는 계약 spec 렌즈이며 Phase 1 구현 완료 상태를 뜻하지 않는다(§7 렌즈 선언).

---

## 8. 게이트 / 병행 검증 항목

각 항목은 막는 범위가 다르므로 `gate_type`과 `blocks`를 명시한다(일괄 차단 조건 아님).

| ID | 항목 | source_ref | gate_type | blocks | status | next_action |
|---|---|---|---|---|---|---|
| G-1 | AMS 분석 가정 검증 | `통합본 §13_open §J` (필요 시 `09 §11.8`) | local blocker | `[AMS 분석 가정 — 검증 필요]` 태그 결정들의 확정 | BLOCKED | §13_open §J ↔ ADR/컴포넌트 대조해 실제 게이팅 대상 목록 작성. **§11 단독 인용 폐기(drift-2/N-2)** |
| G-2 | β vs γ 모듈 분리 협의 | `통합본 §13_open §C (05 §7.2.6 cross-ref)`, `본문 05 §7.2 "모듈 분리 정책" 단락` | local blocker | deployment 분리 시점, owner_repo 배치, 모듈 경계 확정 | DECISION_REQUIRED | β/γ/Phase 1 분리 범위 결정. **통합본 미결 Open — 추측 금지(D-2)** |
| G-3 | 사이트별 운영 정보 입수 | `통합본 §13_open §A` | local blocker | 보안 정책, topology, 노드 추산, site별 배포/운영 결정 | IN_PROGRESS | site별 누락 정보 목록화 |
| G-4 | harness + plugin 검증 | dev-time 실행 인프라, `HANDOFF.md §7` | parallel validation | per-repo handoff 실행 루프와 codex-gate 검증 안정성 | IN_PROGRESS | ROADMAP 작성은 막지 않되, 실행 handoff 전 검증 상태 확인 |
| G-5 | source_ref drift 검증 | `통합본_v0_9.md`, `HANDOFF.md`, ROADMAP | parallel validation | 문서 간 불일치 | TODO | v0.3 생성 후 codex-gate 검토 |

---

## 9. Track 0 — envelope 나머지 토픽 적용

"나머지 토픽 envelope 적용"은 Tier 4 후반에 묻지 않고 별도 Track 0으로 분리한다. **Track 0(envelope 적용)과 Track 4(ADR#5 토픽 명명/토픽 재구조) 선후는 D-4(2)로 2026-06-04 RESOLVED — envelope 먼저(Track 0 → Track 4)다(`adr/0005` §2.1). envelope은 Kafka 헤더라 토픽명·zone suffix와 독립이므로 토픽 명명 규칙 비준(D-4(1)) 전에 선적용해도 안전하다.** (alert/notification·result 토픽이 Phase 1 topic set에 포함되는지는 통합본 §6.9.3·§6.9.5로 확정 — Open 아님.)

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T0-1 | 나머지 토픽 envelope 적용 범위 확정 | `HANDOFF.md §7`, `통합본 §8.3 ADR#2`, `통합본 §8.3 ADR#5`, `envelope §4` | monitoring-meta | DONE | envelope 후속 handoff | (해소 — T0-2 RESOLVED) | `handoff/phase1-001-envelope-scope.md` | 적용 대상 토픽 목록과 제외 사유(공통 토픽군 6 ●, OTLP 위임군 2 ✕ — phase1-001 §5.2) |
| T0-2 | envelope 적용과 ADR#5 토픽 재명명/재구조의 실행 선후 결정 | `통합본 §8.3 ADR#5`, `통합본 §6.9(나)`, `adr/0005-topic-naming.md` | monitoring-meta | DONE | topic producer/consumer 변경 | (RESOLVED 2026-06-04, D-4(2)) | `handoff/phase1-001-envelope-scope.md` | **결정: envelope 먼저(Track 0 → Track 4)** — envelope은 헤더라 토픽명 독립(`adr/0005` §2.1) |
| T0-3 | envelope 적용 handoff 생성 | `HANDOFF.md §5` | monitoring-meta | TODO | hub/script-agent 후속 작업 | T0-1, T0-2 (둘 다 해소) | `handoff/phase1-002-envelope-remaining-topics.md` | repo별 수정 범위와 테스트 명시 |
| T0-4 | envelope 적용 구현 | `handoff/phase1-002-envelope-remaining-topics.md` | hub, script-agent | TODO | Phase 1 message contract 정합성 | T0-3 | repo별 handoff | unit/integration/e2e PASS |
| T0-5 | envelope 결과 ROADMAP 반영 | ROADMAP | monitoring-meta | TODO | Track 1~4 정확도 | T0-4 | `handoff/phase1-002-envelope-remaining-topics.md` | ROADMAP status·evidence 갱신 |

---

## 10. Track 1 — 기반 레이어

거의 모든 Phase 1 기능이 의존하는 기반 작업이다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T1-1 | 영속 저장소: PG + OpenSearch + Redis + MinIO (VM은 Phase 2) | `통합본 §8.3 ADR#12`, `통합본 §6.9(나)` | infra, hub, monitoring-meta | TODO | Alert, Incident, dedup, log, script storage | site 정보 일부(G-3), infra 결정 | `handoff/phase1-010-persistence-foundation.md` | docker/infra config, hub connection config, smoke/e2e |
| T1-2 | 인증/인가: JWT + OIDC + Knox 어댑터 | `통합본 §8.3 ADR#7`, `통합본 §6.9(나)` | hub | TODO | user-facing API, UI 권한, Knox 연동 | T1-1 중 PG user domain | `handoff/phase1-011-auth-oidc-knox.md` | auth flow test, role/permission test |
| T1-3 | 모듈러 모놀리스 → deployment 분리(β) | `본문 05 §7.2 "모듈 분리 정책" 단락`, `통합본 §13_open §C (05 §7.2.6 cross-ref / 경계↔데모 05 §7.2.4 cross-ref)`, `HANDOFF.md §7` | hub, script-agent, infra (provisional — β/γ 미결, blocked_by D-2) | DECISION_REQUIRED | owner_repo 배치, 도메인 경계, 배포 단위 | G-2 / D-2 | `handoff/phase1-012-module-split-decision.md` | β/γ 결정 기록, deployment map |
| T1-4 | Quartz JobStore DB-backed clustered | `통합본 §6.9(나)` (ADR 바깥 정정 — §6.9(나) Phase 1 확정 정정, ADR 귀속만 미정 D-5) | hub, infra | **TODO** | scheduler 신뢰성, job execution | T1-1 PG. **ADR 귀속 미정(D-5)** | `handoff/phase1-013-quartz-jobstore.md` | clustered JobStore 설정, failover/misfire test. 비고: 구현 필요성은 Phase 1 확정(§6.9(나)), ADR 귀속만 D-5로 추적 |
| T1-5 | 사이트별 운영 정보 정리 | `통합본 §13_open §A` | monitoring-meta, infra | IN_PROGRESS | topology/security/node sizing | 외부 정보(G-3) | `handoff/phase1-014-site-ops-inputs.md` | site별 운영정보 matrix |

> **β/γ 의존 owner_repo provisional 표기 (룰 2b)**: T1-3 owner_repo는 β(모듈러 모놀리스+메시지 처리 분리) vs γ(풀 MSA) 결정(D-2)에 종속되므로 `provisional`이며 blocked_by에 D-2를 명시한다. 임의 확정하지 않는다. 다른 Track 항목의 owner_repo도 D-2 결과에 따라 배치가 바뀔 수 있으면 D-6으로 추적한다.
>
> **T1-4 위상 (7/8 일관화)**: T1-4(Quartz JobStore)와 T3-9(audit actor.type)는 **같은 위상**이다 — 둘 다 §6.9(나) Phase 1 **확정 정정**(구현 필요성은 결정 불요)이고, **ADR 귀속만 미정(D-5)** 이다. 따라서 status는 둘 다 **`TODO`**(구현은 결정 불요이므로 DECISION_REQUIRED 아님)이고, ADR 귀속 미정은 비고/blocked_by에 "ADR 귀속 미정(D-5)"로만 단다.

---

## 11. Track 2 — 코어 도메인 / 파이프라인

> **서비스 구현 + 전용 토픽 주 (D-9 결정 반영 2026-06-03)**: Alert/Incident/Notification **서비스**(T2-2/T2-3 등)는 Phase 1 신규 컴포넌트 **확정**(통합본 §6.9(다)/6.9.3)이며, 전용 **Kafka 토픽 `alert-topic`/`notification-topic` 추가**(T2-4)도 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **Phase 1 확정**이다(과거 D-9는 2026-06-03 RESOLVED, §17). 따라서 T2-2/T2-3은 서비스 구현 단위 TODO로, T2-4(토픽 추가)도 Phase 1 확정 구현 TODO로 추적한다. 잔여 결정은 토픽 *명명 규칙*(ADR#5/D-4(1), `adr/0005` 비준 대기)뿐이다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T2-1 | Rule Engine: `rule-engine-script`, `rule-engine-log` | `통합본 §6.9(다)` | hub | TODO | Alert, validation, rule-based processing | T1-3 일부(D-2), job/log pipeline | `handoff/phase1-020-rule-engine.md` | rule execution test, sample rule e2e |
| T2-2 | Alert Processor + Dedup | `통합본 §6.9(다)`, `통합본 §8.3 ADR#15` | hub | TODO | Incident, Notification | T1-1 Redis/PG, T2-1 | `handoff/phase1-021-alert-processor.md` | duplicate suppression test, alert persistence |
| T2-3 | Incident Service + 그룹핑/상태 전환 | `통합본 §6.9(다)` | hub | TODO | UI incident view, notification context | T2-2 | `handoff/phase1-022-incident-service.md` | incident lifecycle test |
| T2-4 | `alert-topic` / `notification-topic` 추가 | `통합본 §6.9(다)`/§6.9.3, `통합본 §6.9.5`, `통합본 §8.3 ADR#5`, `envelope §4.1` | hub, infra, monitoring-meta | **TODO** | Alert → Notification pipeline | T1-1 등 선행 인프라 | `handoff/phase1-023-alert-notification-topics.md` | topic contract, producer/consumer test. 비고: 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5), key rule(alert=`(rule_id,target_id)`/notification=`incident_id`) 확정. 잔여=최종 명명 규칙(ADR#5/D-4(1), `adr/0005` 비준 대기) |
| T2-5 | Agent State Service 승격 | `통합본 §6.9(다)` | hub | TODO | Agent OFFLINE alert, UI state | heartbeat infra | `handoff/phase1-024-agent-state-service.md` | agent state transition test |
| T2-6 | Agent OFFLINE → Alert 발화 (ADR#18 잔여) | `통합본 §6.9(다)`, `통합본 §8.3 ADR#18` | hub | TODO | 운영 알림 | T2-2, T2-5, T2-4 | `handoff/phase1-025-agent-offline-alert.md` | offline detection e2e (OFFLINE 판정 자체는 기구현, Alert 발화만 잔여 — §5.1 #18). 비고: T2-4(alert-topic 전용 경로) 선행 |
| T2-7 | SQL_JOB 지원 | `통합본 §8.3 ADR#9` | hub, script-agent | TODO | DB query job execution | job pipeline, auth/security 정책 | `handoff/phase1-026-sql-job.md` | SQL_JOB execution test |
| T2-8 | `x-message-id` 중복 검사 | `통합본 §8.3 ADR#15`, `통합본 §6.9(나)`, `envelope §2.1` | hub, script-agent | TODO | idempotency | T1-1 Redis | `handoff/phase1-027-message-id-dedup.md` | Redis TTL 5분 dedup test |
| T2-9 | Agent 자가 등록 | `통합본 §8.3 ADR#11`, `통합본 §6.9(나)` | hub, script-agent | TODO | agent onboarding | T1-2 auth, 운영 정책 | `handoff/phase1-028-agent-self-registration.md` | pre-token/admin approval flow test |

> **T2-4 위상 정정 (D-9 결정 반영 2026-06-03)**: draft는 T2-4를 독립 Phase 1 TODO로, v0.3 이전 차수는 C-2 지적에 따라 DECISION_REQUIRED로 강등했었다. 그러나 사람이 D-9를 "A) Phase 1 확정"으로 결정했고, 이는 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표(정본)와 정합한다. 따라서 **DECISION_REQUIRED → TODO(Phase 1 확정 구현)로 정상화**한다. blocked_by에서 "topic set 확장 Open(D-9)"을 제거하고, 선행 인프라(T1-1 등)만 남긴다. 잔여 결정은 ADR#5 명명 규칙(D-4(1))뿐이며 이는 토픽 신설을 막지 않는다.

---

## 12. Track 3 — 통보 / 검증 / 연동 / UI

> **서비스 구현 + 전용 토픽 주 (D-9 결정 반영 2026-06-03)**: Notification Service(T3-1 등) **서비스** 구현은 Phase 1 신규 컴포넌트 확정(§6.9(다))이며, `notification-topic` **전용 토픽 추가**도 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **Phase 1 확정**이다(T2-4로 추적, 과거 D-9는 2026-06-03 RESOLVED). 잔여 결정은 토픽 명명 규칙(ADR#5/D-4(1), `adr/0005` 비준 대기)뿐이다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T3-1 | Notification Service + 채널 어댑터 4종 | `통합본 §6.9(다)` | hub | TODO | 실제 알림 송신 | T2-3, T2-4 | `handoff/phase1-030-notification-service.md` | SMS/Email/Messenger/Teams adapter contract test. 비고: T2-4(notification-topic 전용 경로) 선행 |
| T3-2 | 통보 그룹: Knox 어댑터 + 자체 통합 | `통합본 §6.9(다)` | hub | TODO | recipient resolution | T1-2, T3-1 | `handoff/phase1-031-notification-groups.md` | group resolution test |
| T3-3 | Validation Service + sandbox mode | `통합본 §6.9(다)` | hub, script-agent | TODO | script/rule 검증 | T2-1, job pipeline | `handoff/phase1-032-validation-service.md` | sandbox execution test |
| T3-4 | 결재 어댑터: webhook 비동기 + HMAC | `통합본 §6.9(다)` | hub | TODO | approval integration | 외부 결재 시스템 정보 | `handoff/phase1-033-approval-adapter.md` | HMAC verification, async webhook test |
| T3-5 | Script 파일 보관 + Object Storage | `통합본 §6.9(다)`, `통합본 §8.3 ADR#12` | hub, infra | TODO | script lifecycle | T1-1 MinIO | `handoff/phase1-034-script-object-storage.md` | upload/download/versioning test |
| T3-6 | Frontend LEGO + WebSocket + Gateway + 권한 필터링 | `통합본 §8.3 ADR#8`, `통합본 §6.9(다)` | hub | TODO | UI/실시간 상태 | T1-2, T2/T3 domain APIs | `handoff/phase1-035-frontend-websocket.md` | permission-filtered websocket e2e |
| T3-7 | LOG_JOB `sample_lines[].occurred_at` | `통합본 §8.3 ADR#10`, `통합본 §6.9(나)` | hub, script-agent | TODO | log timeline accuracy | log pipeline | `handoff/phase1-036-logjob-occurred-at.md` | payload contract test |
| T3-8 | 명령 만료 audit (ADR#16 잔여) | `통합본 §8.3 ADR#16` | hub, script-agent | TODO | audit completeness | command pipeline | `handoff/phase1-037-command-expiry-audit.md` | `valid_until` expiry audit test (정책 자체는 기구현, 만료 audit만 잔여 — §5.1 #16) |
| T3-9 | audit actor.type 확장 | `통합본 §6.9(나)` (ADR 바깥 정정 — §6.9(나) Phase 1 확정 정정, ADR 귀속만 미정 D-5) | hub | **TODO** | audit normalization | **ADR 귀속 미정(D-5)** | `handoff/phase1-038-audit-actor-type.md` | AGENT/USER/SYSTEM audit event test. 비고: 구현 필요성은 Phase 1 확정(§6.9(나)), ADR 귀속만 D-5로 추적 |

> **T3-9 정정 (7/8 일관화)**: draft/v0.2는 T3-9를 DECISION_REQUIRED로 두었으나, T3-9는 **T1-4(Quartz JobStore)와 같은 위상**이다(둘 다 §6.9(나) Phase 1 확정 정정 + ADR 귀속만 미정 D-5). 구현 자체는 결정 불요이므로 **DECISION_REQUIRED → TODO로 정정**하고, ADR 귀속 미정만 blocked_by/비고에 "ADR 귀속 미정(D-5)"로 표기한다. T1-4·T3-9 둘 다 동일하게 TODO + D-5 귀속 주석을 단다.

---

## 13. Track 4 — 토픽 재구조 / 메시지 계약

Track 4는 cross-cutting 리스크가 높으므로 Track 0에서 선후 결정을 먼저 한다. **Track 0↔Track 4 선후는 D-4(2)로 2026-06-04 RESOLVED — envelope 먼저(Track 0 → Track 4)다(`adr/0005` §2.1).** (alert/notification·result 토픽이 Phase 1 topic set에 포함되는지는 통합본 §6.9.3·§6.9.5로 확정 — Open 아님. result 분리 자체도 §6.9.2 항목1로 Phase 1 확정. ADR#5/D-4가 여는 것은 토픽 *명명 규칙*(D-4(1) — `adr/0005` 비준 대기)뿐이며, *실행 선후*(D-4(2))는 RESOLVED.)

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T4-1 | 토픽 명명: zone 단위 + 의미 기반 | `통합본 §8.3 ADR#5`, `통합본 §4.4.1`, `adr/0005-topic-naming.md` | hub, script-agent, infra, monitoring-meta | BLOCKED | producer/consumer 전체 | `adr/0005` 비준(D-4(1)). 실행 선후는 D-4(2) RESOLVED(envelope 먼저) — Track 0 이후 착수 | `handoff/phase1-040-topic-naming.md` | topic contract matrix(§7 연계). 비고: 명명 *원칙*("zone 단위 + 의미 기반")은 통합본 §4.4.1·§8.3 ADR#5 확정, 구체 컨벤션만 `adr/0005` D-4(1) 비준 대기 |
| T4-2 | `job-results` → `result-topic-job/log` 분리 | `통합본 §6.9(나)`/§6.9.2 항목1, `통합본 §8.3 ADR#5` (간접 귀속, D-5) | hub, script-agent, infra | **TODO** | result pipeline | T4-1(`adr/0005` 비준) 후 재명명 — 단 선후는 D-4(2) RESOLVED(envelope 먼저)이므로 Track 0 이후. 분리 자체=Phase 1 확정(§6.9.2 항목1) | `handoff/phase1-041-result-topic-split.md` | job/log result e2e. 비고: 분리=Phase 1 확정, 최종 명명 규칙=D-4(1)(`adr/0005` 비준 대기)·실행 선후=D-4(2) RESOLVED / ADR 귀속만 D-5 |
| T4-3 | zone 단위 topic routing / `command-topic` zone routing (ADR#4 잔여) | `통합본 §8.3 ADR#4` (**ADR#4 확정 귀속** — §8.3 결정 컬럼 "동일 + zone 단위 토픽 routing" 직접 포함), `통합본 §6.9(나)` | hub, script-agent, infra | **DEFERRED** | multi-zone command routing | zone topology 정보(§13_open §A / G-3) | `handoff/phase1-042-zone-topic-routing.md` | zone routing integration test. 비고: ADR#4 PARTIAL의 후속/잔여분(group.id 유지는 Phase 1 기구현, zone routing은 Phase 1 밖 명시 보류) |
| T4-4 | 메시지 키 토픽별 정의 (ADR#6 잔여: 신규 토픽 key) | `통합본 §8.3 ADR#6`, `통합본 6.8.2`, `통합본 §6.9.5` | hub, script-agent, monitoring-meta | TODO | ordering/partitioning semantics | topic naming decision(T4-1) | `handoff/phase1-043-message-key-policy.md` | topic별 key rule + test (기존 토픽 키 기구현 — §5.1 #6 / 신규: alert=`(rule_id,target_id)`·notification=`incident_id`는 §6.9.5 확정) |
| T4-5 | envelope/topic contract 문서 갱신 | `통합본 §8.3 ADR#2`, `통합본 §8.3 ADR#5`, `통합본 §8.3 ADR#6`, `docs/kafka-payloads.md`, `docs/envelope.md` | monitoring-meta | TODO | repo 구현 일관성 | T0/T4 decisions | `handoff/phase1-044-contract-doc-update.md` | §7 8토픽 계약 매트릭스 갱신 + drift check |

> **T4-3 정정 (3 / C-4 / drift-4)**: draft는 T4-3 status를 `PARTIAL(잔여) / 후속`으로 두었으나, 이는 §6 허용값(단일 8값) 위반이다(두 값/수식어 혼용). v0.3에서 **단일 허용 status `DEFERRED`로 정규화**한다(zone routing은 Phase 1 밖으로 명시 보류). "후속/잔여" 설명은 비고로 분리했다. blocked_by에 zone topology(§13_open §A / G-3)는 유지한다.
>
> **T4-1 정정 (D-4 결정 반영 2026-06-04)**: T4-1(토픽 명명)은 D-4(1) 구체 명명 컨벤션이 `adr/0005-topic-naming.md`로 승격되어 **비준 대기**이므로 status를 `DECISION_REQUIRED` → **`BLOCKED`(blocked_by=`adr/0005` 비준)** 로 정규화한다(명명 *원칙*은 통합본 확정, 구체 컨벤션 비준이 막힘). 실행 선후(D-4(2))는 RESOLVED(envelope 먼저)이므로 Track 0 이후 착수로 명시한다.
>
> **T4-2 정정 (D-9 결정 반영 2026-06-03)**: draft/이전 차수는 T4-2를 DECISION_REQUIRED로 두었으나, `job-results` 분리 자체는 통합본 §6.9.2 항목1로 Phase 1 확정이다(분리=Phase 1). 따라서 **DECISION_REQUIRED → TODO로 정상화**하고, 잔여는 *최종 토픽 명명 규칙*(D-4(1), `adr/0005` 비준 대기)과 토픽 재구조 *실행 선후*(D-4(2) RESOLVED, envelope 먼저)와 ADR 귀속(D-5)뿐임을 비고로 분리한다.
>
> **T4-3 ADR 귀속 (9 / D-5↔T4-3 충돌 정리)**: command-topic zone routing은 통합본 §8.3 **ADR#4 결정 컬럼이 "동일 + zone 단위 토픽 routing"으로 zone routing을 직접 포함한다(확인된 사실)**. 따라서 ADR#4로 **확정 귀속**(사실, 추측 아님)하며, **D-5 범위에서 제외**한다. §17 D-5는 더 이상 command-topic routing을 다루지 않는다.
>
> **T4-5 source_ref 정정 (S-1)**: draft는 파일경로만 가리켰으나 ADR#2/#5/#6 + 통합본 조항을 병기했다.

---

## 14. Track 5 — 구현 없음 / 동일 유지 / Phase 1 미도입

> **status 렌즈 주석 (필독)**: 이 Track 5의 status는 §9~§13 Track과 동일하게 **Phase 1 *작업* 진행 렌즈**다. 단 Track 5는 "Phase 1에 실재하는 작업이 없는"(무작업) ADR을 모은다. §5.1의 ADR *전체* 판정 렌즈와 다르다. 예: **ADR#13은 §5.1=PARTIAL**(ADR 전체: heartbeat 완료 / metric Phase 2)이지만 **Phase 1 작업분이 없으므로**(Phase 1 무작업) 본 Track 5(T5-6)에 위치한다. 두 렌즈를 혼동하지 않는다.

`NO-OP`도 근거와 검증 증거를 남긴다.

| ID | ADR | 결정 | source_ref | status | acceptance_evidence |
|---|---|---|---|---|---|
| T5-1 | ADR#1 | 스키마 관리 1차 미도입. Phase 2/3 Apicurio 검토 | `통합본 §8.3 ADR#1` | NO-OP | Phase 1 미도입 근거 기록 |
| T5-2 | ADR#2 | Heartbeat protobuf 전환 완료 | `통합본 §8.3 ADR#2`, `HANDOFF.md §5` | **DONE** | heartbeat 마샬링 한정. 2026-06-02 PASS 16/0/0. **ADR#2 ≠ envelope 전 토픽 적용**(C-3): envelope 나머지 토픽은 Track 0 |
| T5-3 | ADR#3 | Audit 채널 동일 유지 | `통합본 §8.3 ADR#3` | NO-OP | audit channel 유지 근거 기록 |
| T5-4 | ADR#14 | LOG_JOB `file_state` 동일 유지 | `통합본 §8.3 ADR#14` | NO-OP | payload contract 유지 근거 기록 |
| T5-5 | ADR#17 | Quartz misfire 동일 유지: `DO_NOTHING` | `통합본 §8.3 ADR#17` | NO-OP | scheduler 설정 확인 |
| T5-6 | ADR#13 | 라우팅: heartbeat 수집 경로=기구현(잔여 없음) / metric routing·self 별도=Phase 2 | `통합본 §8.3 ADR#13` | PARTIAL | **Phase 1 무작업**(heartbeat 수집 경로 기구현 → Phase 1 잔여 없음) / metric routing + self 별도=Phase 2. ADR 전체는 §5.1=PARTIAL이나 Phase 1 작업분이 없어 본 Track에 위치(drift-4/N-3: "기구현"=수집 경로 기구현, 라우팅 분리 아님) |

> **T5-2 status 셀 단일값 주 (CRITICAL round-2)**: T5-2 status는 `DONE` 단일값이다. "(heartbeat marshalling only)" 범위 한정은 status 셀이 아니라 acceptance_evidence 열의 "heartbeat 마샬링 한정"으로 분리했다. ADR#2 = heartbeat 마샬링 한정이며 envelope 전 토픽 적용은 ADR#2가 아니다(envelope 나머지 토픽은 Track 0).
> ADR#4·#12도 Phase 걸침(PARTIAL)이나 Phase 1 **작업분이 Track 1/4에 실재**하므로 본 표가 아니라 해당 Track에서 추적한다(§5.1 매트릭스 참조). 반면 ADR#13은 §5.1=PARTIAL이라도 Phase 1 작업분이 없어(무작업) 본 Track 5에 둔다 — 렌즈 차이.

---

## 15. Phase 1 범위 밖

| 항목 | source_ref | 처리 |
|---|---|---|
| ADR#13 metric routing + self 별도 잔여 | `통합본 §8.3 ADR#13` | Phase 2 (heartbeat 수집 경로는 §14 Track 5 T5-6 참조) |
| VictoriaMetrics (ADR#12 잔여) | `통합본 §8.3 ADR#12`, `통합본 §6.9(다)` | Phase 2 |
| Infra Agent | Phase 2 범위 | Phase 2 |
| Polling Service / Agentless | Phase 2 범위 | Phase 2 |
| `metrics-topic` | `통합본 §6.9.5`, `kafka-payloads metrics-topic` | Phase 2 (envelope OTLP 예외 — §7) |
| Metric Ingest | Phase 2 범위 | Phase 2 |
| `rule-engine-metrics` | Phase 2 범위 | Phase 2 |
| self-monitoring 인스턴스 | Phase 2 범위 | Phase 2 |
| trace backend | Phase 2 범위 | Phase 2 |
| system log index 분리 | Phase 2 범위 | Phase 2 |
| KDB 구현 | Phase 1 UI 슬롯만 허용 | 구현 보류 |

---

## 16. 권장 HANDOFF 분리안

ROADMAP은 기준 문서로 두고 아래와 같이 HANDOFF를 생성해 실행한다. **본 표는 우선 슬라이스 후보이며, Track 표(§9~§14)가 *전체* handoff를 추적한다. §16은 대표 슬라이스만 나열한다** — 우선 슬라이스 외 항목(`013/014/024~028/031~038/042~044` 등)은 해당 Track 항목 착수 시 동일 규칙으로 생성한다(S-4: 생략 기준 = "우선 슬라이스 외 항목은 Track 착수 시점에 생성, 추적은 Track 표가 담당").

> **§16 ↔ Track 표 위상 주 (gate 4차 — spec 6 해소)**: D-9 해소로 위상이 올라간 토픽 handoff 두 건(T2-4 → `phase1-023-alert-notification-topics`, T4-2 → `phase1-041-result-topic-split`)을 아래 우선 슬라이스 목록에 **추가**한다. ADR#5(`adr/0005-topic-naming.md`)는 D-4(1) 구체 명명 규칙 비준용 신규 ADR로, T4-1(`phase1-040-topic-naming`)의 선행 결정 문서다. 그 밖의 모든 토픽/도메인 handoff는 §16이 아니라 **Track 표(§9~§14)에서 전체 추적**되며, §16은 대표 슬라이스만 담는다. 따라서 "§16에 없는 handoff = 누락"이 아니라 "Track 표에서 추적 중"이다(Track 표 ↔ §16 위상 충돌 해소).

| 순서 | handoff 파일 후보 | 목적 | 대상 repo |
|---|---|---|---|
| 0 | `handoff/phase1-000-roadmap-normalization.md` | ROADMAP 검증, source_ref 보강, [결정 필요] 정리 | monitoring-meta |
| 1 | `handoff/phase1-001-envelope-scope.md` (작성됨 2026-06-04) | 나머지 topic envelope 적용 범위 + 선후 결정 — D-4(2) RESOLVED(envelope 먼저), 적용 대상/제외 확정 | monitoring-meta |
| 2 | `handoff/phase1-002-envelope-remaining-topics.md` | envelope 미적용 topic 구현 | hub, script-agent |
| 3 | `handoff/phase1-010-persistence-foundation.md` | PG/OS/Redis/MinIO 기반 | infra, hub |
| 4 | `handoff/phase1-011-auth-oidc-knox.md` | JWT/OIDC/Knox | hub |
| 5 | `handoff/phase1-012-module-split-decision.md` | β/γ 및 deployment map 결정 (D-2) | monitoring-meta, hub, infra |
| 6 | `handoff/phase1-020-rule-engine.md` | Rule Engine 1차 | hub |
| 7 | `handoff/phase1-021-alert-processor.md` | Alert + dedup | hub |
| 8 | `handoff/phase1-022-incident-service.md` | Incident lifecycle | hub |
| 9 | `handoff/phase1-023-alert-notification-topics.md` | `alert-topic`/`notification-topic` 추가 (T2-4, Phase 1 확정, 명명 규칙만 D-4(1)) | hub, infra, monitoring-meta |
| 10 | `handoff/phase1-030-notification-service.md` | Notification pipeline | hub |
| 11 | `adr/0005-topic-naming.md` (작성됨 2026-06-04) → `handoff/phase1-040-topic-naming.md` | ADR#5 topic contract: 구체 명명 규칙 비준(D-4(1)) 후 재명명 handoff | monitoring-meta, hub, script-agent, infra |
| 12 | `handoff/phase1-041-result-topic-split.md` | `job-results` → `result-topic-job/log` 분리 (T4-2, Phase 1 확정, 명명 규칙만 D-4(1); 실행 선후 D-4(2) RESOLVED) | hub, script-agent, infra |

각 HANDOFF는 §1 헤더에 **기준 monitoring-meta commit full hash**를 박고, 다음 섹션을 포함한다: `1.목적(+기준 commit) / 2.source_ref / 3.대상 repo / 4.수정 대상 파일·모듈 후보 / 5.구현 규칙(+out-of-scope) / 6.테스트·검증 / 7.완료 시 ROADMAP 갱신 항목 / 8.다음 HANDOFF`.

---

## 17. 미해결 / 결정 필요 목록 (D-목록)

> 이 §17이 본 문서의 **D-목록(결정 필요 목록)** 이다. (이전 v0.2가 "§14 D-목록"으로 부르던 자기참조 오류를 v0.3에서 §17로 정정. §14는 Track 5다.)

| ID | 결정 필요 항목 | 관련 source_ref | 막는 항목 | 통합본 Open 연계 | owner |
|---|---|---|---|---|---|
| D-1 | AMS 5단계 검증이 실제로 게이팅하는 ADR/컴포넌트 목록 | `통합본 §13_open §J` | G-1 | **통합본 미결 Open(§J)** | human/analyzer |
| D-2 | β 유지 vs γ 전환, Phase 1 내 deployment 분리 범위 | `통합본 §13_open §C (05 §7.2.6 cross-ref)`, `본문 05 §7.2 모듈 분리 정책 단락` | T1-3, owner_repo 배치 | **통합본 미결 Open(§C, 협의 필요)** | human/analyzer |
| D-3 | 영속(#12)과 인증(#7)의 병렬/순차 실행 방식 | `통합본 §8.3 ADR#12`, `ADR#7` | T1-1, T1-2 | 계획 레이어(통합본 Open 아님) | human/implementation lead |
| D-4(2) | envelope 적용과 토픽 재구조의 *실행 선후* → **RESOLVED (2026-06-04)**: **envelope 먼저(Track 0 → Track 4)**. envelope은 Kafka 헤더라 토픽명·zone suffix와 독립이므로 명명 규칙 비준(D-4(1)) 전에 선적용 안전(`adr/0005-topic-naming.md` §2.1). | `통합본 §8.3 ADR#5`, `adr/0005-topic-naming.md` | (해소 — T0-2 DONE, T4-1/T4-2 선후 = Track 0 이후) | (D-4(2) 해소) | 결정: human, 2026-06-04 |
| D-4(1) | 토픽 **구체 명명 컨벤션**(zone 단위 + 의미 기반 prefix 원칙 하의 실제 이름·zone suffix 전개·신규 토픽 적용 범위) → **`adr/0005-topic-naming.md`로 승격, 비준 대기**. 명명 *원칙*("zone 단위 + 의미 기반")은 통합본 §4.4.1·§8.3 ADR#5에 **확정**이며, 구체 컨벤션만 결정 대기다(후보 A/B/C는 `adr/0005` §3). **토픽 최종 이름은 동결하지 않는다(추측 금지).** | `통합본 §8.3 ADR#5`, `통합본 §4.4.1`, `adr/0005-topic-naming.md` | T4-1(재명명), §7 매트릭스 토픽명 셀, kafka-payloads 잠정 토픽명 최종화 | HANDOFF §7 미결정과 일치 / **`adr/0005` 비준 대기** | human/analyzer |
| D-5 | §6.9(나) 데모 정정 중 ADR 귀속 미결 3건의 최종 ADR 귀속 확정 — (간접 1: job-results→ADR#5 후보) + (ADR 바깥 2: Quartz JobStore, audit actor.type)。 **command-topic routing(항목 11)은 §8.3 ADR#4 결정 컬럼에 직접 포함되어 ADR#4 확정 귀속이므로 D-5에서 제외(§3.1 / §13 T4-3 참조).** | `통합본 §6.9(나)` | DoD-2, T4-2(ADR#5 간접), T1-4·T3-9(ADR 바깥 — 구현은 Phase 1 확정, 귀속만 미정) | 재분류 [결정 필요] | analyzer/codex-gate |
| D-6 | 각 Track 항목의 최종 owner_repo 확정 (β/γ 결과에 종속되는 항목은 D-2 후) | ROADMAP 전체 | repo별 HANDOFF | 계획 레이어 | human/analyzer |
| D-7 | harness + plugin 검증 완료 기준 | `HANDOFF.md §7`, dev-time infra | 실행 루프(G-4) | dev-time infra | implementation lead |
| D-8 | site별 운영 정보 중 Phase 1에 반드시 필요한 최소값 | `통합본 §13_open §A` | T1-5, infra/security/topology(G-3) | **통합본 미결 Open(§A)** | human/infra |
| ~~D-9~~ (RESOLVED 2026-06-03) | ~~`alert-topic`/`notification-topic` 등 topic set 확장이 Phase 1 확정인지 ADR#5에 종속된 Open인지~~ → **해소(RESOLVED)**: alert/notification 토픽은 **Phase 1 확정**이다(통합본 §6.9.3 (다) Phase 1 표가 두 토픽을 "Kafka 토픽 추가"로 명시 + §6.9.5 토픽표가 "(다) v0.7 신규 (Phase 1)"로 확정, key rule까지 박음 — 확인된 사실). 따라서 "토픽이 Phase 1 topic set에 포함되는가"는 더 이상 Open이 아니다. 명명 규칙(zone 단위+의미 기반 prefix)은 **D-4(1)**(`adr/0005`)로, 토픽 재구조 실행 선후는 **D-4(2)**(RESOLVED 2026-06-04)로 남는다. result-topic 분리 자체도 §6.9.2 항목1로 Phase 1 확정. | `통합본 §6.9.3 (다) Phase 1 표`, `통합본 §6.9.5 토픽표`, `통합본 §6.9.2 항목1` | (해소 — T2-4/T4-2 TODO 정상화, §7 매트릭스 alert/notification 확정. 잔여는 D-4) | 결정: human, 2026-06-03 (A) Phase 1 확정 | human/analyzer |

> **추측 금지 대상 (CLAUDE.md §2 / 강제 룰 5)**: D-1(§J)·D-2(§C)·D-8(§A)은 통합본 §13 Open Questions 미결 항목과 직접 연결되므로 analyzer가 추측으로 메우지 않는다. D-5(정정 귀속 미결)·D-4(1)(구체 명명 컨벤션, `adr/0005` 비준 대기)도 임의 결정하지 않는다 — 토픽 최종 이름을 동결하지 않는다. 이 항목들은 계획 레이어 보존 규칙에 따라 ROADMAP에서 삭제하지 않고 보존한다. (D-9는 2026-06-03 사람 결정 "A) Phase 1 확정", D-4(2)는 2026-06-04 사람 결정 "envelope 먼저"로 해소 — 통합본 §6.9.3/§6.9.5 정본·`adr/0005`와 정합.)
>
> **D-4 분리 정정 (D-4 결정 반영 2026-06-04)**: D-4를 둘로 분리한다. **D-4(2) 실행 선후 = RESOLVED**(envelope 먼저, Track 0 → Track 4 — envelope은 헤더라 토픽명 독립, `adr/0005` §2.1). **D-4(1) 구체 명명 컨벤션 = `adr/0005-topic-naming.md`로 승격, 비준 대기**(명명 *원칙*은 통합본 §4.4.1·§8.3 ADR#5 확정 / 구체 컨벤션만 결정 대기, 후보 A/B/C는 `adr/0005` §3 — 토픽 최종 이름 동결 금지). `job-results` → `result-topic-job/log` **분리 자체는 통합본 §6.9.2 항목1로 Phase 1 확정**이고, alert/notification 추가도 §6.9.3·§6.9.5로 Phase 1 확정이다. 따라서 D-4(1)은 토픽 *명명 규칙*만 다룬다. *분리/추가 여부·Phase*는 확정이다. §13 T4-1(BLOCKED, blocked_by=`adr/0005` 비준)/T4-2·§7 매트릭스 셀 마커·§9 Track 0 머리 문구와 일치시켰다.
>
> **D-5 범위 정정 (9)**: command-topic zone routing은 통합본 §8.3 ADR#4 결정 컬럼이 직접 포함하는 확인된 사실이므로 ADR#4 확정 귀속이며 D-5에서 제외했다. D-5는 이제 (job-results→ADR#5 간접 후보) + (ADR 바깥 2: Quartz JobStore, audit actor.type)만 다룬다. ADR 바깥 2건은 *구현 필요성*은 Phase 1 확정(§6.9(나))이고 *ADR 귀속만* D-5로 추적한다(T1-4·T3-9는 status=TODO).
>
> **D-9 해소 경계 정정 (D-9 결정 반영 2026-06-03)**: D-9가 다루던 것은 *전용 Kafka 토픽이 Phase 1 topic set에 포함되는가*였고, 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표(정본)가 이를 직접 확정하므로 더 이상 Open이 아니다(2026-06-03 사람 결정 A). ADR#5/D-4가 여는 것은 토픽 *명명 규칙*(D-4(1), `adr/0005` 비준 대기)과 토픽 재구조 *실행 선후*(D-4(2) RESOLVED)뿐이다. 서비스 구현은 §6.9(다) Phase 1 확정이며 토픽 신설과 함께 모두 TODO로 추적한다.

---

## 18. 변경 이력

| 버전 | 변경 |
|---|---|
| v0.1 | Claude 세션 derive 초안 — Tier 1~4 + 선행 게이트 + 작업 0 + Phase 2 분리 |
| v0.2 | 게이트 global/local/parallel 세분, Track 0 분리(envelope), Phase 1 DoD 추가, 데모 정정 단정 제거→명시/간접/바깥 분류, 테이블 스키마 보강, ROADMAP/HANDOFF 역할 분리 |
| v0.2 (보완) | source_ref `05 §7.2` 정규화, status에 PARTIAL 추가 + Phase 걸침 ADR 처리, "Claude Code 지시문" 섹션 제거(재귀 방지), owner_repo=monitoring-meta 주석, HANDOFF 템플릿 commit pin |
| **v0.3 (정본 후보)** | **Pass 1 normalization 반영**: ① source_ref drift-1~4 정정(§7.2.6/§7.2.4=§13_open §C cross-ref, §11→§13_open §J, ADR#13 표현, HANDOFF 절 지정) ② ADR#6/#16/#18 TODO→PARTIAL(N-4) ③ ADR#2 DONE(heartbeat marshalling only) 명시(C-3) ④ T4-3 Phase 1 잔여/후속 분리(C-4) ⑤ T2-4 TODO→DECISION_REQUIRED 강등 + T4-1/T0-2 blocked_by 종속(C-2/D-9) ⑥ 8토픽 계약 매트릭스 §7 신설(C-1) ⑦ DoD-1에 18-ADR 판정 매트릭스 임베드(S-2/N-5) ⑧ source_ref ADR/통합본 조항 병기(S-1/S-3/S-4) ⑨ D-9 신규 + D-목록 갱신 |
| **v0.3 (codex-gate 1차 반영)** | **codex-gate FAIL 9건 정정 (내부 일관성/status 정규화/자기참조)**: ① §5 DoD-1을 "Phase 1 완료 조건"→"ADR 18개 **판정 완료** 조건"으로 명확화, TODO/DECISION_REQUIRED=진행 중 추적 상태로 분리 서술(S-2/N-5 재정정) ② §7 alert/notification 셀을 확정 표기→`[결정 필요](D-9)` 잠정화(ADR#5/D-9 선결정 흔적 제거) ③ §13 T4-3 status `PARTIAL(잔여)/후속`→단일 허용값 `DEFERRED` 정규화(§6 위반 해소) ④ §14↔§17 자기참조 정정(D-목록=§17, §14=Track 5) ⑤ §7 미정 셀에 `[결정 필요]` 직접 박음(선언↔표현 일치) ⑥ §5.1·§14에 ADR 전체 렌즈 vs Phase 1 작업 렌즈 구분 주석(ADR#13 Phase 1 무작업→Track 5 근거) ⑦+⑧ T1-4·T3-9 동일 위상 일관화(둘 다 §6.9(나) Phase 1 확정 정정 + ADR 귀속만 D-5 → status=TODO, T3-9 DECISION_REQUIRED→TODO) ⑨ §17 D-5↔§13 T4-3 충돌 정리(command routing은 §8.3 ADR#4 결정 컬럼 직접 포함→ADR#4 확정 귀속, D-5에서 제외) |
| **v0.3 (codex-gate 2차 반영)** | **codex-gate 2차 FAIL(critical 2 + spec 4) 정정 (내부 일관성/status 단일값/확정↔미정 분리)**: ① **CRITICAL 1+2** — §3.1 #2 / §5.1 #2 / §14 T5-2 status `DONE (heartbeat marshalling only)` → 단일값 `DONE`, 범위 한정은 비고/acceptance_evidence로 분리(§6 단일값 규칙 위반 해소, DoD-1 최종 판정 집합에 ADR#2 깔끔히 DONE) ② **status 전수 sweep** — §5 DoD 표에 "비고" 열 추가, DoD-1/DoD-4/DoD-6 status 셀의 괄호 수식어를 비고로 분리(status 셀=단일 허용값) ③ **SPEC 3** — §7 result-topic-job/log 행을 "(분리 전제 — 확정=D-4/D-5)" 라벨로 명확화 ④ **SPEC 4** — §7 alert/notification 매트릭스 셀을 `[결정 필요] (D-9)`만 남기고 잠정 규칙(envelope 4종·key 잠정값)을 §7.1로 이동("아직 결정 아님" 라벨) ⑤ **SPEC 5** — §3·§11·§12·§17 D-9에 "서비스 구현(Phase 1 확정) ↔ 전용 Kafka 토픽 신설(D-9 미결)은 별개 결정" 경계 주석 추가. D-9·D-4·통합본 Open(§A/§C/§J) 보존, §1 commit pin 유지 |
| **v0.3 (D-9 결정 반영 + gate 3차)** | **D-9=A(Phase 1 확정) 사람 결정(2026-06-03) 반영 + codex-gate 잔여 지적(D-9 계열 4건) 해소**: ① **§17 D-9를 RESOLVED 처리** — alert/notification 토픽은 Phase 1 확정(통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표), 명명 규칙·result 분리 시점은 D-4. 결정 근거·날짜(2026-06-03) 명시, 미결 목록에서 닫음 ② **§7 매트릭스 alert/notification 행 확정 spec화** — `[결정 필요](D-9)` 제거, envelope 4종 적용 + key rule(alert=`(rule_id,target_id)`/notification=`incident_id`, §6.9.5 확정) 박음. §7.1 "신설 확정 시 잠정 규칙 — 아직 결정 아님" 항목 제거 ③ **§7 result-topic 행 정정(gate spec #3)** — "분리 전제" → "분리=Phase 1 확정(§6.9.2 항목1), envelope/key 확정, 최종 명명 규칙만 D-4"로 확정분/D-4 종속분 경계 명확화 ④ **Track 의존 정상화** — T2-4(alert/notification 토픽 추가) DECISION_REQUIRED→TODO, T4-2(result 분리) DECISION_REQUIRED→TODO, blocked_by에서 D-9 제거(T2-6/T3-1 의존은 전용 토픽 경로 선행으로 유지) ⑤ **§3/§11/§12 경계 주석 갱신** — "전용 토픽 신설 D-9 미결" → "alert/notification 토픽은 Phase 1 확정(§6.9.3); ADR#5는 명명 규칙만 결정(D-4)". D-1/D-2/D-4/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |
| **v0.3 (gate 4차 — §7 계약렌즈/D-4 정정)** | **codex-gate 4차 FAIL(critical 2 + spec 4) 정정 — 지적이 "§7 매트릭스가 *목표 계약 spec*인지 *Phase 1 구현 상태*인지 분리 안 됨" 하나의 뿌리로 수렴**: ① **critical 1 + spec 3·4** — §7 머리에 **렌즈 선언** 추가("이 매트릭스는 *목표 계약 spec*(출처: kafka-payloads.md + envelope.md). 각 셀은 토픽 *계약*을 기술하며 Phase 1 구현 시점·완료 상태가 아님 — 구현 상태는 Track 표가 추적"). 3렌즈(§5.1 ADR 판정 / Track 작업 진행 / §7 계약 spec) 구분 명시 ② **토픽 명명 종속 셀 마커** — `command-topic-{zone}` zone suffix / `result-topic-job`·`result-topic-log`·`alert-topic`·`notification-topic`의 토픽 *이름*에 "(토픽명/zone suffix 명명 규칙 = ADR#5/D-4 종속, 현재 kafka-payloads 이름은 잠정)" 마커. 계약 내용(envelope·key=확정) ↔ 최종 이름(D-4 종속)을 셀 단위 분리. §7 선언과 표 정합(미정=명명 규칙뿐) ③ **critical 2 — §17 D-4 문구 정정** — D-4에서 "result 분리 *시점*" 제거(분리 자체=§6.9.2 항목1 Phase 1 확정), D-4를 "토픽 *명명 규칙* + 토픽 재구조 *실행 선후*"로 좁힘. §13 T4-1/T4-2·§7 result 행 문구 일치 ④ **spec 5 — DoD-1↔§5.1 관계 명확화** — §5/§5.1 머리에 "TODO ADR(#5/#7/#8/#9/#10/#11/#15)=최종 판정 전 진행 중 상태, Phase 1 완료 시 최종 판정으로 닫혀야 DoD-1 충족. IN_PROGRESS=판정 진행 중" 한 줄 고정 ⑤ **spec 6 — §16↔Track 표 위상** — 토픽 handoff 2건(T2-4→`phase1-023`, T4-2→`phase1-041`)을 §16 우선 슬라이스 목록에 추가 + "Track 표가 전체 handoff 추적, §16은 대표 슬라이스" 생략 기준 보강. status 전수 sweep 유지(§6 8값 단일). D-1/D-2/D-4/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |
| **v0.3 (D-4 결정 반영 2026-06-04)** | **D-4 결정 반영(D-4(2) RESOLVED envelope-first / D-4(1) ADR#5 `adr/0005`로 승격, 이름 잠정 유지)**: ① **§17 D-4를 둘로 분리** — D-4(2) 실행 선후 = RESOLVED(2026-06-04, envelope 먼저 Track 0 → Track 4, 근거 `adr/0005` §2.1: envelope은 헤더라 토픽명 독립) / D-4(1) 구체 명명 컨벤션 = `adr/0005-topic-naming.md`로 승격, 비준 대기(명명 *원칙*은 통합본 §4.4.1·§8.3 ADR#5 확정, 구체 컨벤션만 결정 대기 — 토픽 최종 이름 동결 금지) ② **§9 Track 0 머리** — "선후 DECISION_REQUIRED" → "D-4(2) RESOLVED envelope 먼저" ③ **§13 T0-1/T0-2** status DECISION_REQUIRED → DONE(T0-2 결정=envelope 먼저), handoff `phase1-001-envelope-scope.md` 작성됨 ④ **§13 T4-1** status DECISION_REQUIRED → BLOCKED(blocked_by=`adr/0005` 비준), envelope-first 선후 반영. T4-2 blocked_by/비고 D-4(1)/(2) 분리 ⑤ **§7 매트릭스 셀 마커** — "ADR#5/D-4 종속, 잠정" → "ADR#5(`adr/0005`) 비준 대기, 잠정"으로 전수 일관화(command zone suffix/result-job/result-log/alert/notification + §7 머리·8토픽 줄·§7.1) ⑥ **§3/§5.1/§11/§12 경계 주석** D-4를 D-4(1)/D-4(2)로 분기 표기 ⑦ **§16** phase1-001 "작성됨", `adr/0005` 신설 반영(순서 11). D-1/D-2/D-4(1)/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |

---

## 19. v0.2 → v0.3 변경 요약 (codex-gate 검토용)

Pass 1 normalization의 N-1~N-5 / C-1~C-4 / S-1~S-4 (총 13개) 적용 매핑 + codex-gate 1차 반영 9건 + codex-gate 2차 반영(round-2) 5건 + D-9 결정 반영(gate 3차) + gate 4차 정정(§7 계약렌즈/D-4) + D-4 결정 반영(2026-06-04).

| ID | 적용 위치 | 적용 방식 | 남은 결정 필요 |
|---|---|---|---|
| N-1 | §1 헤더 source_ref 규칙, T1-3, DoD-4, G-2, D-2 | `05 §7.2.6`/`§7.2.4`를 `통합본 §13_open §C cross-ref` + 본문 05 §7.2 단락으로 병기 | 없음(표기 정정) |
| N-2 | G-1, D-1 | `통합본 §11` 단독 인용 폐기 → `통합본 §13_open §J`(+`09 §11.8`)로 교체 | 없음(표기 정정) |
| N-3 | §5 Phase 걸침 설명, §5.1 #13, T5-6, §15 | ADR#13 "heartbeat=기구현"을 "heartbeat 수집 경로=기구현 / metric routing·self=Phase 2"로 정정 | 없음(표현 정정) |
| N-4 | §5.1 #6/#16/#18, T4-4/T3-8/T2-6 | TODO→PARTIAL + 잔여 범위 명시(기존 키/정책/판정 기구현, 신규분만 잔여) | 없음(사실 정정) |
| N-5 | DoD-1, §5 DoD-1 정의 명확화 주 | DoD-1=ADR 판정 완료 조건으로 명확화, TODO/DECISION_REQUIRED=진행 중 추적 상태로 분리 | 없음 |
| C-1 | §7 (신규 섹션) | 8토픽 × envelope적용 × key rule × payload ref × 근거 매트릭스 작성, 미정 셀(명명 규칙)에 종속 마커 박음 | §7 result/alert/notification·zone 최종 *이름* = D-4(1) / ADR 귀속 = D-5 |
| C-2 | T2-4, §11 강등 근거 주 → **D-9 결정으로 정상화** | (과거) T2-4 TODO→DECISION_REQUIRED 강등. **D-9 결정(2026-06-03)으로 TODO로 정상화** | 없음(D-9 해소) |
| C-3 | §5.1 #2, T5-2 | ADR#2를 `DONE` 단일값으로 명시(범위 한정은 비고), envelope 전 토픽 적용과 분리(Track 0) | 없음(범위 명시) |
| C-4 | T4-3, §13 정정 주 | zone routing을 Phase 1 밖 명시 보류(`DEFERRED`)로 정규화(ADR#4 PARTIAL과 정합) | zone topology 입수 = G-3/D-8 종속 |
| S-1 | T4-5 source_ref | 파일경로만 → ADR#2/#5/#6 + 통합본 조항 병기 | 없음 |
| S-2 | §5.1 (매트릭스 임베드), DoD-1 정의 | 18-ADR 판정 매트릭스를 DoD-1에 임베드 + DoD-1=판정 완료 조건 명확화 | TODO ADR들이 최종 판정으로 닫혀야 Phase 1 완료(각 Track) |
| S-3 | §15 VictoriaMetrics 행 | source_ref에 `통합본 §8.3 ADR#12` 병기(`§6.9(다)/Phase 2` 단독 보완) | 없음 |
| S-4 | §16 HANDOFF 분리안 주 | 우선 슬라이스 외 handoff 생성 규칙(Track 착수 시점 생성, Track 표가 전체 추적) 명시 | 없음 |
| **gate-1** | §5 DoD-1, DoD-1 정의 주 | DoD-1을 "Phase 1 완료"→"ADR 18개 **판정 완료**" 조건으로 명확화, TODO/DECISION_REQUIRED를 진행 중 추적 상태로 분리(Phase 1 완료 시 최종 판정으로 닫힘) | 없음(문구 명확화) |
| **gate-2** | §7 alert-topic·notification-topic 셀, §7.1, §7 주 → **D-9 결정으로 확정** | (과거) 확정 표기 제거 → `[결정 필요](D-9)`. **D-9 결정(2026-06-03)으로 확정 spec화** | 없음(D-9 해소) |
| **gate-3** | §13 T4-3 status, §6 단일값 규칙 주 | `PARTIAL(잔여)/후속`→단일 허용값 `DEFERRED`. 후속/잔여는 비고로 분리. blocked_by zone topology(§A/G-3) 유지 | 없음(정규화) |
| **gate-4** | §0 머리주석, §1 헤더 주, §7·§11·§17 등 본문 참조 | "§14 D-목록"→"§17 D-목록" 전수 일치(§14=Track 5) | 없음(자기참조 정정) |
| **gate-5** | §7 매트릭스 result/alert/notification 셀, §7.1 | 선언("미정 셀은 [결정 필요]")과 표현 일치 — 미정 셀(명명 규칙)에 종속 마커 직접 박고 §7.1은 보조 설명으로 유지 | D-4(1)/D-5 |
| **gate-6** | §5.1 머리 렌즈 주석, §14 머리 렌즈 주석, §5.1 #13, T5-6 | ADR 전체 status 렌즈 vs Phase 1 작업 status 렌즈 구분 명시. ADR#13=§5.1 PARTIAL이나 Phase 1 무작업→Track 5(T5-6) 근거 | 없음(렌즈 구분) |
| **gate-7/8** | §3.1 항목 8·10, T1-4, T3-9, §10/§12 위상 주 | T1-4(Quartz)·T3-9(audit actor.type) 동일 위상 일관화 — 둘 다 §6.9(나) Phase 1 확정 정정 + ADR 귀속만 D-5 → status=TODO. T3-9 DECISION_REQUIRED→TODO | ADR 귀속 = D-5 |
| **gate-9** | §3.1 항목 11, §13 T4-3, §17 D-5 | command-topic routing을 ADR#4 확정 귀속(§8.3 결정 컬럼 직접 포함, 사실)으로 표기, D-5에서 제외. D-5는 job-results(ADR#5 간접)+ADR 바깥 2건만 | 없음(확정 귀속, 추측 아님) |
| **round-2 CRITICAL 1+2** | §3.1 #2, §5.1 #2, §14 T5-2, §6 규칙 주 | status `DONE (heartbeat marshalling only)` → 단일값 `DONE`(§6 단일값 규칙 준수). "heartbeat 마샬링 한정" 범위는 비고/acceptance_evidence로 분리. DoD-1 최종 판정 집합(DONE/NO-OP/DEFERRED/PARTIAL)에 ADR#2가 괄호 예외 없이 DONE으로 포함 | 없음(status 정규화) |
| **round-2 sweep** | §5 DoD 표(비고 열 신설), DoD-1/DoD-4/DoD-6 | 모든 status 셀 전수 점검 → 허용 8값 외 텍스트(괄호 수식어) 제거, 부가 설명은 "비고" 열로 이동. DoD 표에 비고 열 추가 | 없음(status 정규화) |
| **round-2 SPEC 3** | §7 result-topic-job/log 행, §7.1 → **gate 3차/4차로 재정정** | (과거) "(분리 전제 — 확정=D-4/D-5)" 라벨. gate 3차로 "분리=Phase 1 확정(§6.9.2 항목1), envelope/key 확정". **gate 4차로 최종 *이름*만 D-4 종속 마커로 셀 표기(계약 내용↔이름 분리)** | 최종 명명 규칙(이름) = D-4(1) / ADR 귀속 = D-5 |
| **round-2 SPEC 4** | §7 alert/notification 매트릭스 셀, §7.1 → **gate 3차/4차로 확정** | (과거) 매트릭스 셀에 `[결정 필요] (D-9)`만. gate 3차로 확정 spec화(envelope 4종·key rule §6.9.5 확정). **gate 4차로 계약 내용=확정 / 최종 이름=D-4 종속 마커 분리** | 최종 이름 = D-4(1)(D-9 해소) |
| **round-2 SPEC 5** | §3 경계 주석, §11·§12 분리 주, §17 D-9 → **gate 3차로 갱신** | (과거) "서비스 Phase 1 확정 ↔ 전용 토픽 신설 D-9 미결" 경계. **gate 3차(D-9 반영)로 "alert/notification 토픽은 Phase 1 확정(§6.9.3); ADR#5는 명명 규칙만 결정(D-4)"로 갱신** | 명명 규칙 = D-4(1) |
| **D-9 결정 / gate 3차** | §3 경계 주석·신규 컴포넌트 행, §5.1 #5/#6, §7 매트릭스 alert/notification/result 행·§7.1, §9·§13 머리 설명, §11 T2-4·주, §12 머리 주·T3-1, §13 T4-2·T4-4·주, §17 D-4·D-9·주 | D-9=A(Phase 1 확정) 사람 결정(2026-06-03) 반영: D-9 RESOLVED, alert/notification·result 분리 토픽을 Phase 1 확정 spec으로, T2-4·T4-2 DECISION_REQUIRED→TODO, 잔여는 명명 규칙(D-4)뿐 | 명명 규칙 = D-4(1) / 실행 선후 = D-4(2) / ADR 귀속 = D-5 |
| **gate-4차 critical 1 / spec 3·4** | §7 머리 렌즈 선언, §7 표 셀 명명 마커, §7.1, §5.1 렌즈 주석 | §7을 "목표 계약 spec"으로 선언(출처 kafka-payloads+envelope, Phase 1 구현 상태 아님), 3렌즈 구분. command zone suffix/result/alert/notification 토픽 *이름*에 ADR#5/D-4 종속 마커. 계약 내용(확정)↔최종 이름(미정) 셀 단위 분리 | 최종 토픽 이름(명명 규칙) = D-4(1) |
| **gate-4차 critical 2** | §17 D-4, §13 T4-1/T4-2, §7 result 행 | D-4에서 "result 분리 *시점*" 제거(분리 자체=§6.9.2 항목1 Phase 1 확정). D-4를 "토픽 *명명 규칙* + 토픽 재구조 *실행 선후*"로 좁힘. T4-2 비고·§7 result 셀 문구 일치 | 명명 규칙·실행 선후 = D-4 |
| **gate-4차 spec 5** | §5 머리 주, §5.1 머리 주, DoD-1 비고 | DoD-1 IN_PROGRESS=판정 진행 중. TODO ADR(#5/#7/#8/#9/#10/#11/#15)=최종 판정 전 진행 중 상태 → Phase 1 완료 시 최종 판정으로 닫혀야 DoD-1 충족, 한 줄 고정 | 없음(관계 명확화) |
| **gate-4차 spec 6** | §16 우선 슬라이스 목록, §16 위상 주 | 토픽 handoff 2건(`phase1-023`/`phase1-041`) §16 목록 추가 + "Track 표가 전체 handoff 추적, §16=대표 슬라이스" 생략 기준 보강 → Track 표↔§16 위상 충돌 해소 | 없음(위상 정합) |
| **D-4 결정 / 2026-06-04** | §17 D-4(둘로 분리: D-4(2) RESOLVED / D-4(1) `adr/0005` 비준 대기), §9 Track 0 머리, §13 T0-1/T0-2·T4-1·T4-2, §7 셀 마커·머리·§7.1, §3/§5.1/§11/§12 경계 주석, §16(phase1-001 작성됨·`adr/0005` 신설) | D-4(2) 실행 선후=RESOLVED(envelope 먼저, `adr/0005` §2.1: envelope은 헤더라 토픽명 독립). D-4(1) 구체 명명 컨벤션=`adr/0005-topic-naming.md`로 승격, 비준 대기(명명 원칙은 통합본 확정, 토픽 최종 이름 동결 금지). T0-1/T0-2 DONE, T4-1 BLOCKED(blocked_by=`adr/0005` 비준). 셀 마커 "ADR#5/D-4 종속" → "ADR#5(`adr/0005`) 비준 대기" 전수 일관화 | D-4(1) 구체 명명 컨벤션 = `adr/0005` 비준 대기 |

> 모든 사실 정정(N-1~N-4, C-3, C-4, S-1·S-3·S-4) 및 codex-gate 1차 반영(gate-1~9), 2차 반영(round-2 CRITICAL 1+2 / sweep / SPEC 3~5), D-9 결정 반영(gate 3차), gate 4차 정정(§7 계약렌즈/D-4/DoD-1 관계/§16 위상), D-4 결정 반영(2026-06-04)은 v0.3에 적용 완료. 남은 결정 필요는 §17 D-1~D-8(D-4(2)·D-9는 RESOLVED, D-4(1)은 `adr/0005` 비준 대기)로 집약했으며, 통합본 미결 Open(§A/§C/§J) 및 정정 귀속(D-5)·구체 명명 컨벤션(D-4(1))은 추측 금지 대상으로 보존한다(토픽 최종 이름 동결 금지). §1 기준 commit pin(`4940e1a`)은 유지한다.

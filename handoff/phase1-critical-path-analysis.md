# Phase 1 critical-path + 결정 레버리지 분석

> **성격**: 이 문서는 결정을 내리지 않는다. `docs/phase1/ROADMAP_PHASE1_v0_3.md` 원본(§3·§5·§5.1·§7·§8·§9~§17)을 source of truth로 Phase 1 의존 그래프를 재구성하고, "무엇이 막혀 무엇을 막는가"와 "어떤 결정이 가장 많은 작업을 여는가"를 드러낸다. 통합본 `[Open]`·미결 ADR은 *해소하지 않고* "BLOCKED, 외부 정보 필요"로 표기한다.
>
> **입력 source of truth**: `docs/phase1/ROADMAP_PHASE1_v0_3.md`(맨 위 액티브 큐 블록은 *사본*이므로 근거로 쓰지 않고 §7 drift 검증 대상으로만 사용) / `adr/0005-topic-naming.md`(Accepted) / `docs/통합본_v0_9.md` §13 Open Questions(§A·§C·§J 미결).
>
> **작성 기준일**: 2026-06-07. 반영 상태: T4-1 DONE(e2e PASS 58/0/0), Track 0(T0-1~T0-5) DONE, envelope/phase1-002 완료, D-4(1)·D-4(2)·D-9 RESOLVED, `adr/0005` Accepted.

---

## 1. Phase 1 목표 / exit criteria

**한 문단**: Phase 1 완료는 "ADR 18개 완료"만으로 판단하지 않는다(ROADMAP §3). ① 통합본 §8.3 ADR 18개가 각각 최종 판정(`DONE`/`NO-OP`/`DEFERRED`/`PARTIAL`)으로 닫히고(§5 DoD-1), ② 데모 정정 11개(§6.9.2)가 §3.1 재분류대로 추적·해소되며(DoD-2), ③ Phase 1 신규 컴포넌트(Rule Engine/Alert/Incident/Notification + 전용 토픽)가 구현 또는 명시 보류되고(DoD-3), ④ 모듈 분리 β/γ가 결정되고(DoD-4), ⑤ repo별 HANDOFF·테스트·e2e·source_ref drift 검증이 남는 것(DoD-5~7)의 합집합을 닫는 것이다.

**체크 가능한 exit criteria** (§5 DoD 표 그대로):

- [ ] **DoD-1** — ADR 18개 전부 최종 판정 도달. 현재 IN_PROGRESS. 잔여 TODO ADR = #5·#7·#8·#9·#10·#11·#15 (§5.1).
- [ ] **DoD-2** — 데모 정정 11개 추적 완료. 현재 IN_PROGRESS (§3.1).
- [ ] **DoD-3** — Phase 1 신규 컴포넌트 구현/보류. 현재 TODO (Track 2/3).
- [ ] **DoD-4** — 모듈 분리 β/γ 결정. 현재 **DECISION_REQUIRED (D-2, 통합본 §13_open §C 미결 Open)**.
- [ ] **DoD-5** — repo별 HANDOFF 완료 + repo 테스트 통과. 현재 TODO.
- [ ] **DoD-6** — e2e 검증 결과 보존. 현재 TODO (T4-1 PASS 58/0/0 기록 존재).
- [ ] **DoD-7** — ROADMAP/ADR/HANDOFF/통합본 source_ref drift 0. 현재 TODO.

> exit criteria의 **하드 게이트는 DoD-4(=D-2, 통합본 미결 Open)** 다. 나머지는 작업·판정 진행으로 닫히지만 DoD-4는 외부 협의 입력(§13_open §C 8개 협의 입력) 없이는 추측으로 닫을 수 없다.

---

## 2. 의존 그래프

노드 = Track 작업(T*) + 결정(D-*) + 게이트(G-*) + ADR. 엣지는 `blocked_by`(← 막힘) 기준으로 도출했고, 각 줄 끝에 출처 §를 명시한다. `=>` 는 "blocks"(여는 것).

### 2.1 결정/게이트 → 작업 (blocked_by 역추적)

```
[통합본 §13_open §A] (운영환경: topology/보안/노드) — 미결 Open
   => D-8 (Phase 1 필수 최소값)         [§17 D-8]
   => D-4(1)-future (다중 zone 전개·zone 인스턴스명)  [§17 D-4(1)-future, adr/0005 §4]
   => G-3 (사이트 운영정보 입수)         [§8 G-3]
        => T1-5 (사이트 운영정보 정리)    [§10 T1-5 blocked_by 외부정보 G-3]
        => T1-1 (영속저장소, site 정보 일부) [§10 T1-1 blocked_by "site 정보 일부(G-3)"]
        => T4-3 (zone routing, zone topology) [§13 T4-3 blocked_by §13_open §A/G-3] (DEFERRED)

[통합본 §13_open §C] (BE 모듈 분리 β vs γ) — 미결 Open
   => D-2 (β유지/γ전환/Phase1 분리범위)   [§17 D-2]
        => G-2 (β vs γ 협의)             [§8 G-2]
        => T1-3 (deployment 분리, status=DECISION_REQUIRED) [§10 T1-3 blocked_by G-2/D-2]
        => D-6 (owner_repo 확정, β/γ 의존분) [§17 D-6, §10 T1-3 주]
        => T2-1 (Rule Engine, T1-3 일부 의존)  [§11 T2-1 blocked_by "T1-3 일부(D-2)"]

[통합본 §13_open §J] (AMS 분석 가정 검증) — 미결 Open
   => D-1 (AMS가 게이팅하는 ADR/컴포넌트 목록) [§17 D-1]
        => G-1 (AMS 분석 가정 검증)        [§8 G-1, blocks "[AMS 분석 가정] 태그 결정 확정"]

[D-3] 영속(#12)·인증(#7) 실행순서 (계획레이어, 통합본 Open 아님) [§17 D-3]
   => T1-1, T1-2 실행 방식(병렬/순차)        [§17 D-3 "막는 항목"]

[D-5] 데모 정정 ADR 소속 미결 3건 (job-results→ADR#5 / Quartz JobStore / audit actor.type) [§17 D-5]
   => DoD-2 닫힘                          [§17 D-5 "막는 항목"]
   => T4-2 (job-results 분리 — ADR 소속분만) [§17 D-5, §13 T4-2]
   => T1-4 (Quartz JobStore — ADR 소속분만)  [§17 D-5, §10 T1-4]
   => T3-9 (audit actor.type — ADR 소속분만)  [§17 D-5, §12 T3-9]
   ※ 위 3개 작업의 *구현 자체*는 Phase 1 확정(§3.1) — D-5는 ADR 소속 라벨만 막는다.

[D-7] harness+plugin 검증 완료 기준 (dev-time infra) [§17 D-7]
   => G-4 (실행 루프 안정성)               [§8 G-4]
```

### 2.2 작업 → 작업 (Track 내부 선행, §10~§13 blocked_by)

```
T1-1 (영속: PG/OS/Redis/MinIO)  [§10]
   => T1-2 (auth, PG user domain)          [§10 T1-2]
   => T1-4 (Quartz JobStore, PG)           [§10 T1-4]
   => T2-2 (Alert+Dedup, Redis/PG)         [§11 T2-2]
   => T2-8 (x-message-id dedup, Redis)      [§11 T2-8 / §5.1 #15 "T1-1(Redis) 선행"]
   => T3-5 (Script Object Storage, MinIO)   [§12 T3-5]

T2-1 (Rule Engine)  [§11]
   => T2-2 (Alert Processor)               [§11 T2-2 blocked_by T2-1]
   => T3-3 (Validation Service)             [§12 T3-3]

T2-2 (Alert Processor + Dedup)  [§11]
   => T2-3 (Incident Service)              [§11 T2-3]
   => T2-6 (Agent OFFLINE → Alert)         [§11 T2-6]

T2-3 (Incident Service)  [§11]
   => T3-1 (Notification Service)          [§12 T3-1]

T2-4 (alert-topic/notification-topic 추가)  [§11]
   => T2-6 (OFFLINE alert, 전용경로)        [§11 T2-6 blocked_by T2-4]
   => T3-1 (Notification, 전용경로)         [§12 T3-1 blocked_by T2-4]

T2-5 (Agent State Service) => T2-6          [§11 T2-6]

T1-2 (auth) => T2-9 (Agent 자가등록), T3-2(통보그룹), T3-6(Frontend) [§11/§12]

T4-1 (토픽 재명명, DONE) => T4-2 (result 분리)  [§13 T4-2 blocked_by "T4-1 재명명 후"]
T4-1 => T4-4 (메시지 키 정책)               [§13 T4-4 blocked_by "topic naming(T4-1)"]
T0/T4 decisions => T4-5 (contract 문서 갱신)  [§13 T4-5]
```

### 2.3 ADR 판정 ↔ Track 닫힘 (§5.1)

```
ADR#5 (TODO)  --닫힘 by--> T4-1(DONE) + T4-2(잔여)   [§5.1 #5]
ADR#7 (TODO)  --닫힘 by--> T1-2                       [§5.1 #7]
ADR#8 (TODO)  --닫힘 by--> T3-6                       [§5.1 #8]
ADR#9 (TODO)  --닫힘 by--> T2-7                       [§5.1 #9]
ADR#10 (TODO) --닫힘 by--> T3-7                       [§5.1 #10]
ADR#11 (TODO) --닫힘 by--> T2-9                       [§5.1 #11]
ADR#15 (TODO) --닫힘 by--> T1-1(Redis) → T2-8         [§5.1 #15]
ADR#12 (PARTIAL) --Phase1분--> T1-1                   [§5.1 #12]
ADR#4 (PARTIAL) --잔여--> T4-3(DEFERRED)             [§5.1 #4]
ADR#6 (PARTIAL) --잔여--> T4-4                        [§5.1 #6]
ADR#16 (PARTIAL) --잔여--> T3-8                       [§5.1 #16]
ADR#18 (PARTIAL) --잔여--> T2-6                       [§5.1 #18]
ADR#1/#3/#13/#14/#17 (NO-OP/PARTIAL-무작업) --> Track5 (근거기록만) [§14]
ADR#2 (DONE) --완료--> T5-2                           [§5.1 #2]
```

---

## 3. 현재 상태 분류

### 3.1 DONE (근거 §)

| 항목 | 근거 § | 증거 |
|---|---|---|
| Track 0 전체 T0-1~T0-5 | §9 | envelope 적용, consumer x-source 가드, e2e PASS 28/0/0 |
| T4-1 토픽 재명명 | §13 | 3토픽 `*-topic` 재명명, **e2e PASS 58/0/0** (`e2e/results/20260607-080703.md`) |
| T5-2 (ADR#2 heartbeat protobuf) | §14 / §5.1 #2 | PASS 16/0/0 |
| 결정: D-4(2), D-4(1), D-9 | §17 | 모두 RESOLVED. `adr/0005` Accepted |
| ADR 판정 DONE: #2 / NO-OP: #1·#3·#14·#17 | §5.1 / §14 | 근거 기록 완료 |

### 3.2 READY (blocked_by 비어 지금 착수 가능)

| 항목 | 근거 § | 비고 |
|---|---|---|
| **T1-1** 영속 저장소(PG/OS/Redis/MinIO) | §10 | blocked_by = "site 정보 일부(G-3), infra 결정". **부분 의존** — site 정보 *일부*만 필요하므로 PG/Redis 등 site-중립 부분은 즉시 착수 가능. fan-out 최대(아래 §4). |
| **T4-2** job-results → result-topic-job/log 분리 | §13 | blocked_by = T4-1(DONE). 분리 자체=Phase 1 확정(§6.9.2 항목1). **단 ADR 소속이 D-5 미결** → 라벨은 D-5와 함께 닫아야 완결. |
| **T4-4** 메시지 키 정책(신규 토픽 key) | §13 | blocked_by = T4-1(DONE). 신규 key는 §6.9.5 확정. 착수 가능. |
| **T1-5** 사이트 운영정보 정리 | §10 | status IN_PROGRESS. 외부정보(G-3) 입수가 본체지만 "정리" 작업 자체는 진행 중. |
| **T4-5** contract 문서 갱신 | §13 | blocked_by = T0/T4 decisions(대부분 RESOLVED) → 사실상 착수 가능. |

### 3.3 BLOCKED (무엇에 막힘, 근거 §)

| 항목 | 막은 것 | 근거 § |
|---|---|---|
| T1-2 auth | T1-1 PG user domain | §10 |
| T1-4 Quartz JobStore | T1-1 PG (+ D-5 ADR 소속 라벨) | §10 |
| T2-1 Rule Engine | T1-3 일부(**D-2**), job/log pipeline | §11 |
| T2-2 Alert Processor | T1-1 Redis/PG, T2-1 | §11 |
| T2-3 Incident | T2-2 | §11 |
| T2-4 alert/notification 토픽 | T1-1 등 선행 인프라 | §11 |
| T2-5 Agent State Service | heartbeat infra | §11 |
| T2-6 OFFLINE→Alert | T2-2, T2-5, T2-4 | §11 |
| T2-7 SQL_JOB | job pipeline, auth 정책 | §11 |
| T2-8 x-message-id dedup | T1-1 Redis | §11 |
| T2-9 Agent 자가등록 | T1-2 auth, 운영정책 | §11 |
| T3-1 Notification | T2-3, T2-4 | §12 |
| T3-2 통보그룹 | T1-2, T3-1 | §12 |
| T3-3 Validation | T2-1, job pipeline | §12 |
| T3-4 결재 어댑터 | 외부 결재 시스템 정보(외부) | §12 |
| T3-5 Script Object Storage | T1-1 MinIO | §12 |
| T3-6 Frontend | T1-2, T2/T3 domain APIs | §12 |
| T3-7 LOG_JOB occurred_at | log pipeline | §12 |
| T3-8 명령 만료 audit | command pipeline | §12 |
| T3-9 audit actor.type | T1-1 무관, but D-5 ADR 소속 라벨 | §12 |
| G-1(AMS) | §13_open §J (외부) | §8 |
| G-3(site) | §13_open §A (외부) | §8 |

### 3.4 DECISION-NEEDED (근거 §)

| 항목 | 부류 | 근거 § |
|---|---|---|
| **D-2** β vs γ 모듈 분리 | (b) 통합본 §C 미결 Open — 추측 금지 | §17 D-2 / §13_open §C |
| **D-1** AMS 게이팅 목록 | (b) 통합본 §J 미결 Open — 추측 금지 | §17 D-1 / §13_open §J |
| **D-8** site 필수 최소값 | (b) 통합본 §A 미결 Open — 추측 금지 | §17 D-8 / §13_open §A |
| **D-4(1)-future** 다중 zone 전개·zone 인스턴스명 | (b) 통합본 §A 미결 Open — 미래 트리거, 추측 금지 | §17 D-4(1)-future / `adr/0005` §4 |
| **D-5** 데모 정정 ADR 소속 3건 | (a) 통합본 Open 아님 — analyzer/codex-gate 분류 가능 | §17 D-5 |
| **D-3** 영속·인증 실행순서 | (a) 계획 레이어 — 사람(implementation lead) 결정 | §17 D-3 |
| **D-6** owner_repo 확정 | (a) 계획 레이어, 단 β/γ 의존분은 D-2 후 | §17 D-6 |
| **D-7** harness 완료 기준 | (a) dev-time infra | §17 D-7 |
| **T1-3** deployment 분리 (status=DECISION_REQUIRED) | (b) D-2에 종속 | §10 T1-3 |

---

## 4. Critical path

Phase 1 완료(DoD 전부 충족)까지의 최장 의존 사슬을 두 갈래로 본다.

### CP-1 (코어 도메인 사슬 — 가장 김, 실행 레인의 척추)

```
T1-1(영속) → T2-1(Rule Engine) → T2-2(Alert+Dedup) → T2-3(Incident)
           → T3-1(Notification) → T3-2(통보그룹)
           (+ T2-4 토픽이 T2-6/T3-1로 합류)
           → T3-6(Frontend, T2/T3 domain API 의존)
```

출처: §10 T1-1 / §11 T2-1·T2-2·T2-3 / §12 T3-1·T3-2·T3-6. 사슬 길이 ≥ 6단. **T1-1이 이 사슬의 뿌리**이며, T1-1 없이는 코어 도메인 전부가 시작되지 않는다(§11 T2-2 blocked_by Redis/PG, §12 다수).

> **CP-1의 숨은 의존**: T2-1(Rule Engine)이 `T1-3 일부(D-2)`에 걸려 있다(§11). 즉 CP-1은 **D-2(β/γ, 통합본 §C 미결 Open)에 간접 종속**한다. D-2가 안 풀리면 T2-1 착수 범위가 모호해지고 CP-1 전체가 지연될 수 있다.

### CP-2 (모듈 분리 게이트 사슬 — DoD-4 하드 게이트)

```
[통합본 §13_open §C] → D-2 → G-2 → T1-3(deployment 분리) → D-6(owner_repo) → 각 Track 실제 repo 배치
                                                          → DoD-4 충족
```

출처: §13_open §C / §17 D-2·D-6 / §8 G-2 / §10 T1-3 / §5 DoD-4. **이 사슬의 뿌리는 통합본 미결 Open(§C)** 이라 analyzer가 못 푼다. **CP-2가 사실상 Phase 1 완료의 임계 사슬**이다 — DoD-4는 외부 협의 없이 닫히지 않고, owner_repo 확정(D-6)이 늦으면 모든 Track의 repo 배치가 잠정 상태로 남는다.

### 최우선 판단

- **실행 레인 최우선 = T1-1**. CP-1의 뿌리이자 T1-2/T1-4/T2-2/T2-8/T3-5의 공통 선행(아래 §5 fan-out 1위). site-중립 부분(PG/Redis/MinIO core)은 G-3과 무관하게 즉시 착수 가능(§10 blocked_by="site 정보 *일부*").
- **결정 레인 최우선 = D-2**. CP-2의 게이트이자 CP-1(T2-1)에도 간접 영향. 단 통합본 §C 미결 Open이라 **사람/외부 협의 escalation 대상**(추측 금지).

---

## 5. 결정 레버리지 순위 (하류 fan-out)

각 미결정이 풀리면 열리는 작업 수 기준. 출처: §10~§13 blocked_by + §17.

### (a) 지금 답 가능 — 통합본 Open 아님 (analyzer/사람 결정으로 닫힘)

| 순위 | 결정 | fan-out (여는 것) | 근거 § | 비고 |
|---|---|---|---|---|
| a-1 | **D-5** (데모 정정 ADR 소속 3건) | DoD-2 + T4-2·T1-4·T3-9의 **ADR 소속 라벨** 확정 (작업 3 + DoD 1) | §17 D-5, §3.1 | 구현 자체는 Phase 1 확정이라 *작업 착수*는 안 막지만, **DoD-2를 닫는 유일 키**. analyzer/codex-gate가 §6.9.2 + §8.3 대조로 분류 가능 |
| a-2 | **D-3** (영속·인증 실행순서) | T1-1·T1-2 실행 방식(병렬/순차) 확정 | §17 D-3 | 계획 레이어. 사람(impl lead) 결정. T1-1 착수와 병행 가능 |
| a-3 | **D-6** (owner_repo 확정) | repo별 HANDOFF 생성 정확도(전 Track) | §17 D-6 | β/γ 비의존분은 지금 확정 가능, 의존분만 D-2 후 |
| a-4 | **D-7** (harness 완료 기준) | G-4(실행 루프 안정성) | §17 D-7 | dev-time infra. 실행 handoff 전 정리 |

> **a-1(D-5)가 (a) 부류 최고 레버리지**다 — DoD-2를 닫는 유일한 키이고, 통합본 Open이 아니라 §6.9.2 항목별 ADR 대조로 분류 가능(추측 아님). 단 CLAUDE.md §2에 따라 analyzer가 *최종 소속을 단정*하지 말고 후보 분류만 제시하고 사람 승인을 받는다(§17 owner = analyzer/codex-gate).

### (b) 외부 정보 필요 / 통합본 Open — 추측 금지 (사람 escalation 대상)

| 순위 | 결정 | fan-out (여는 것) | 통합본 Open | 근거 § |
|---|---|---|---|---|
| b-1 | **D-2** (β vs γ 모듈 분리) | T1-3 + D-6(의존분) + T2-1(CP-1) 착수 범위 + DoD-4 + owner_repo 전반 | **§13_open §C** (협의 입력 8개) | §17 D-2 / §8 G-2 / §5 DoD-4 |
| b-2 | **D-8** (site 필수 최소값) | T1-5 + T1-1의 site-의존분 + G-3 | **§13_open §A** | §17 D-8 |
| b-3 | **D-1** (AMS 게이팅 목록) | G-1 + `[AMS 분석 가정]` 태그 결정 확정 범위 | **§13_open §J** | §17 D-1 / §8 G-1 |
| b-4 | **D-4(1)-future** (다중 zone 전개) | T4-3(zone routing) + 다중 zone 재명명 | **§13_open §A** | §17 D-4(1)-future / `adr/0005` §4 |

> **b-1(D-2)가 전체 최고 레버리지**다 — DoD-4 하드 게이트이자 CP-1·CP-2 양쪽에 걸린다. 그러나 통합본 §C 미결 Open(협의 입력 8개: K8s 운영 인력/CI 성숙도/팀 구조/운영 규모/Phase 1 일정/독립 진화/장애 격리)이라 **analyzer가 추측으로 메우면 안 된다**. 사람/외부 의사결정자 협의 escalation이 필요하다.

---

## 6. 권장 순서 (2레인)

critical path(§4) + readiness(§3.2) + leverage(§5) 근거.

### 결정 레인 (push — 레버리지순, 사람 입력 대기)

1. **D-2 (β/γ)** — b-1, 최대 fan-out + DoD-4 하드 게이트 + CP-1/CP-2 양쪽. **통합본 §C 미결 Open → 외부 협의 escalation** (추측 금지). *가장 먼저 사람에게 올려야 할 결정*.
2. **D-5 (ADR 소속 3건)** — a-1, DoD-2를 닫는 유일 키. analyzer 후보 분류 + 사람 승인. *지금 진행 가능*.
3. **D-8 (site 최소값)** + **D-1 (AMS 목록)** — b-2/b-3, T1-1 site-의존분·G-1을 풀지만 통합본 §A/§J 미결 → escalation.
4. **D-3 (실행순서)** / **D-6 (owner_repo 비의존분)** — a-2/a-3, T1-1 착수와 병행해 즉시 확정 가능.
5. **D-4(1)-future / D-7** — 미래 트리거·dev-time, 낮은 우선순위.

### 실행 레인 (pull — readiness순, blocked_by 비어 있는 것부터)

1. **T1-1 영속 저장소 (site-중립분)** — CP-1 뿌리, fan-out 1위. G-3 무관 부분(PG/Redis/MinIO core) 즉시 착수. *실행 레인 1순위*.
2. **T4-2 result-topic 분리** + **T4-4 메시지 키** — T4-1(DONE) 후 착수 가능. T4-2는 D-5와 함께 닫아 ADR 소속 라벨까지 완결.
3. **T4-5 contract 문서 갱신** — T0/T4 decisions 대부분 RESOLVED → 착수 가능.
4. T1-1 완료 후 연쇄: **T1-2(auth) → T2-8(dedup) / T1-4(Quartz) / T3-5(storage)**.
5. CP-1 본체: **T2-1 → T2-2 → T2-3 → T3-1** (단 T2-1은 D-2 간접 종속 — D-2 결정 후 범위 확정).

> **권장 동시 진행**: 실행 레인 1순위(T1-1 site-중립분) 착수와 결정 레인 D-2 escalation을 **병행**한다. T1-1은 D-2와 독립(영속 저장소는 모듈 배치와 별개)이므로, D-2 협의가 도는 동안 critical path 뿌리를 미리 깐다.

---

## 7. 사본 drift (액티브 큐 ↔ 원본 §9~§17)

ROADMAP 맨 위 "📌 현재 액티브 큐" 블록(line 3~20, 갱신 2026-06-07)을 원본 Track 표·D-목록과 대조했다.

| 항목 | 액티브 큐(사본) | 원본 §9~§17 | 판정 |
|---|---|---|---|
| T4-1 | "최근 완료 — DONE(2026-06-07), e2e PASS 58/0/0" (line 14) | §13 T4-1 status="DONE (2026-06-07, e2e PASS 58/0/0)" | **일치** |
| T4-2 | "지금 가능 … 단 ADR 소속이 D-5(미결) — 같이 풀어야 착수" (line 6) | §13 T4-2 status=TODO, blocked_by=T4-1(DONE), D-5는 ADR 소속만 | **일치** (본 분석 §3.2 READY와도 일치) |
| D-1·D-2·D-8 | "막힘 — 통합본 Open(§J/§C/§A)" (line 10) | §17 D-1(§J)/D-2(§C)/D-8(§A) 미결 | **일치** |
| D-3·D-5 | "결정 — 지금 가능" (line 7) | §17 D-3(계획레이어)/D-5(analyzer 분류) | **일치** |
| §16-5(모듈분리)=D-2 후 / D-6=D-2 후 | line 11 | §10 T1-3 주 / §17 D-6 | **일치** |
| D-4(1)/D-4(2)/D-9 | "최근 완료 — RESOLVED" (line 15·18) | §17 모두 RESOLVED, `adr/0005` Accepted | **일치** |

**drift 결론**: 액티브 큐 사본과 원본 §9~§17 사이 **불일치 없음**. 다만 액티브 큐가 명시하지 않은 **READY 항목(T4-4, T4-5)** 이 원본 §13에 존재한다(blocked_by=T4-1 DONE / T0·T4 decisions RESOLVED). 이는 drift(모순)는 아니나, 사본이 "지금 가능" 목록을 T4-2·D-3·D-5로 한정해 **T4-4·T4-5를 누락 표기**한 *미세 불완전*이다. 액티브 큐 갱신 시 보강을 권고한다(원본은 정확).

---

## 8. 결정 필요 사안 (사람 입력 대기 — 요약)

- **즉시 escalation (통합본 미결 Open, 추측 금지)**: D-2(§C, 최고 레버리지·DoD-4 게이트), D-8(§A), D-1(§J), D-4(1)-future(§A).
- **analyzer 후보 분류 + 사람 승인 (Open 아님)**: D-5(DoD-2 키 — 후보 분류만 하고 단정 금지), D-3, D-6(비의존분), D-7.

> 본 분석은 위 어떤 결정도 내리지 않았다. D-1/D-2/D-8/D-4(1)-future는 통합본 §13_open §A/§C/§J 미결과 직접 연결되어 CLAUDE.md §2·강제 룰 5에 따라 보존했다. D-5도 임의 결정하지 않았다.

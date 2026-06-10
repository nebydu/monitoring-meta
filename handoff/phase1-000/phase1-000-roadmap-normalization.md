# HANDOFF phase1-000 — ROADMAP_PHASE1 정규화/검증 (Pass 1: 검증만)

## 1. 목적 (+ 기준 commit)

`docs/phase1/ROADMAP_PHASE1_draft_v0_2.md`를 통합본 v0.9 기준 문서 / `HANDOFF.md` / 실제 main 코드(`../hub`, `../script-agent`, `../infra`)와 대조해 검증한다. **이 Pass에서는 검증 결과만 기록한다. `ROADMAP_PHASE1_v0_3.md`는 만들지 않는다.**

- 기준 monitoring-meta commit (full hash): `8d7a07668eb7d1d7db375fe2342d90f174bdfc49`
- 작성 기준일: 2026-06-03
- 검증 대상 입력: `docs/phase1/ROADMAP_PHASE1_draft_v0_2.md`
- 입력 기준 문서(최상위 기준): `docs/통합본_v0_9.md`
- 보조 입력: `HANDOFF.md`, `docs/kafka-payloads.md`, `docs/envelope.md`, `adr/0002-heartbeat-otlp-proto.md`
- 코드 대조 대상: `../hub`, `../script-agent`, `../infra` (읽기 전용)

규칙: "통합본 우선"은 **사실 주장(범위·각 ADR 결정)** 에만 적용한다. tier 순서 / owner_repo / handoff 분리 같은 계획 레이어는 ROADMAP 고유 판단이므로 삭제하지 않고, 불확실하면 `[결정 필요]`로 둔다. `[결정 필요]`는 멈춤 사유가 아니라 기록 대상이다.

---

## 2. 검증 1 — source_ref 전체 검증

draft가 인용한 통합본 source_ref를 통합본 실제 위치로 resolve했다. 통합본은 단일 파일(`docs/통합본_v0_9.md`)이며, draft가 쓰는 `통합본 §8.3`, `§6.9(나)`, `05 §7.2.x`, `§13_open §X` 표기를 실제 헤더/줄 위치와 대조했다.

### 2.1 resolve 결과 — OK

| draft source_ref | 통합본 실제 위치 | 판정 |
|---|---|---|
| `통합본 §8.3` (ADR 18개 매핑표) | `## 8.3 ADR 18개와 v0.7 매핑` (L2280) | OK |
| `통합본 §6.9(나)` 데모 정정 | `#### 6.9.2 (나) 데모 정정 대상` (L1742) | OK |
| `통합본 §6.9(다)` v0.7 신규 | `#### 6.9.3 (다) v0.7 신규` (L1760) — Phase 1/Phase 2 표 분리됨 | OK |
| `통합본 §6.9(가)` (간접 참조) | `#### 6.9.1 (가) 데모 검증 완료` (L1720) | OK |
| `통합본 §13_open §A` 운영 정보 입수 | `## A. 운영 환경 정보 입수 사안` (L3123) | OK |
| `통합본 §13_open §C` 협의 필요 | `## C. 협의 필요 사안` (L3168) | OK |
| `통합본 §13_open §J` AMS 검증 | `## J. [AMS 분석 가정 — 검증 필요]` (L3258) | OK |
| `통합본 §11` (G-1) | 통합본 본문에 `# 11` 최상위 토픽 부재 — AMS/마이그레이션은 `09 §11.x` 표기로 존재. **[source_ref 확인 필요]** (아래 2.3) | 주의 |

### 2.2 모듈 분리 source_ref `05 §7.2` 정규화 — 부분 OK / 일부 [source_ref 확인 필요]

draft가 정규화했다고 선언한 표기(`05 §7.2`, β/γ=`05 §7.2.6`, 경계↔데모=`05 §7.2.4`)를 통합본 실제 구조와 대조했다.

- `05 §7.2`(논리 아키텍처) 자체는 실존: `## 7.2 논리 아키텍처 (Phase 1 baseline)` (L1886). 모듈 분리 정책 단락 "모듈 분리 정책 — 결정 보류, 협의 필요"(L1976~)도 실존. → **본문 위치 OK.**
- 단, **통합본 §7.2 본문에는 `7.2.4` / `7.2.6` 라는 명시적 하위 절 번호(헤더)가 존재하지 않는다.** §7.2는 소제목(`### 전체 그림`, `### 모듈 분리 정책`, `### 컴포넌트 책임`)으로만 구성된다.
- 그 `§7.2.6` / `§7.2.4` 라는 번호는 **`13_open.md`(통합본 §13) §C 항목이 사용하는 cross-ref 표기**다. 실제 통합본 §13 §C(L3172, L3174)에 다음이 있다:
  - `(05 §7.2.6)` = "BE 모듈 분리 정책 — (β) 모듈러 모놀리스 + 메시지 처리 분리 vs (γ) 풀 MSA" (협의 입력 8개)
  - `(05 §7.2.4)` = "데모 코드 패키지 경계가 모듈러 모놀리스 분해와 일치하는지"
- 즉 draft의 정규화(β/γ=§7.2.6, 경계↔데모=§7.2.4)는 **의미상 통합본 §13 §C의 cross-ref와 일치**한다. 다만 §7.2.6/§7.2.4가 §7.2 본문의 실제 절 번호가 아니라 §13 §C의 참조 라벨이라는 점은 문서에 명시되어야 한다.
- 권고: ROADMAP에서 `05 §7.2.6` 인용 시 `통합본 §13_open §C (05 §7.2.6 cross-ref) / 본문 05 §7.2 "모듈 분리 정책" 단락`처럼 병기. 단독 `05 §7.2.6`만 두면 본문에서 resolve 안 됨. → **[source_ref 확인 필요] (drift-1)**

### 2.3 [source_ref 확인 필요] 목록

| ID | draft 위치 | 인용 | 문제 | 제안 |
|---|---|---|---|---|
| drift-1 | §1 보완 헤더, T1-3, DoD-4, G-2, D-2 | `05 §7.2.6`, `05 §7.2.4` | §7.2 본문에 해당 절 번호 헤더 없음. 실제로는 §13_open §C의 cross-ref 라벨 | `통합본 §13_open §C` + `본문 05 §7.2 모듈 분리 정책 단락` 병기 |
| drift-2 | §5 G-1 | `통합본 §11` | 통합본에 `# 11` 최상위 토픽 없음. AMS/마이그레이션은 `09 §11.x`로 표기되며, AMS 검증 가정은 §13_open §J가 집약 | `통합본 §13_open §J` (+ 필요 시 `09 §11.8`)로 교체. `§11` 단독 인용 삭제 |
| drift-3 | T0-1, T0-3, T0-5, T1-x 등 다수 | `HANDOFF` (단독) | `HANDOFF.md`는 운영 인계 문서(루트)로 실존하나, ROADMAP source_ref로는 절 단위 지정이 없어 모호 | `HANDOFF.md §5(작업 상태)` / `§7(미결정)` 등 절 지정 권고 (사실 오류 아님, 정밀화) |
| drift-4 | §11 T5-6, §12 | ADR#13 "heartbeat=기구현" | 통합본 §8.3 ADR#13은 "OTel Collector 라우팅: metric/heartbeat 분리 + self 별도". heartbeat 라우팅 자체는 데모서 단일이며 §6.9(가)에 "heartbeats-topic + OTel Collector 재발행" 검증 완료로 잡힘. draft의 "heartbeat=기구현"은 라우팅 분리가 아니라 수집 경로 기구현을 뜻함 — 표현 정밀화 필요 | "heartbeat 수집 경로=기구현 / metric·self 라우팅 분리=Phase 2"로 문구 정정 |

> 그 외 ADR 번호 인용(`§8.3 ADR#N`), `§6.9(나)`, `§6.9(다)`, `§13_open §A/§C/§J` 표기는 모두 통합본 실제 위치로 resolve됨.

---

## 3. 검증 2 — ADR 18개 status 판정 (코드 + HANDOFF 대조)

판정 기준: 통합본 §8.3 결정(목표 spec) + 데모 §6.9 성격 + 실제 main 코드(`../hub`,`../script-agent`,`../infra`) + HANDOFF.md §5. status 값은 draft §4 규칙(TODO/IN_PROGRESS/DONE/NO-OP/PARTIAL/DEFERRED/BLOCKED/DECISION_REQUIRED) 사용.

코드 현황 요약(대조 근거):
- hub는 Phase 0 데모 구조. 토픽 물리명 `commands`/`job-results`/`audit-events`/`heartbeats`, in-memory ring buffer(`JobResultRingBuffer`, `HeartbeatLatestMap`), Thymeleaf UI(`index.html`). Alert/Incident/Notification/Rule Engine/영속 저장소/인증 코드 **없음**.
- `ActorType` enum = `AGENT` 단독 (USER/SYSTEM 주석상 "본개발 예정", 미추가).
- `JobType` enum = `SCRIPT_JOB`,`LOG_JOB` (SQL_JOB 없음).
- `CommandPublisher`에 `x-message-id` 발행 헤더 존재. consumer 측 dedup 윈도우 코드 **없음**.
- `ScheduleTriggerJob.computeValidUntil` = `issued + (next-issued)*0.9` 구현(spec §5.1.3). "만료 audit"는 미구현.
- ADR#2: `infra/otel-collector-config.yml` `encoding: otlp_proto`, hub `HeartbeatOtlpDecoder`+byte[] consumer(`KafkaConfig` heartbeats ConsumerFactory), `pom.xml` opentelemetry-proto. → 3 repo 반영.

| ADR | 주제 | 통합본 §8.3 결정 | 코드/HANDOFF 현황 | status 판정 | Phase 1 범위 / Phase 2 잔여 |
|---|---|---|---|---|---|
| #1 | 스키마 관리 | 1차 미도입, Phase 2/3 Apicurio | 미도입(코드 없음, 의도적) | **NO-OP** | Phase 1 미도입 근거 기록. (draft T5-1 일치) |
| #2 | Heartbeat 마샬링 | Phase 1 protobuf | infra otlp_proto + hub decoder + proto dep 반영, e2e PASS 16/0/0 (2026-06-02) | **DONE** | 잔여 없음. (draft T5-2 일치) |
| #3 | Audit 채널 | Kafka 직행 동일 유지 | audit-topic 단일 흐름 유지, 변경 없음 | **NO-OP** | (draft T5-3 일치) |
| #4 | Consumer group | 동일 + zone 단위 토픽 routing | Agent별 unique group.id는 데모 기구현(§6.9(가)). zone routing 코드 없음 | **PARTIAL** | Phase 1: group.id 정책 유지(기구현). 잔여(zone 단위 command-topic routing)는 T4-3 추적. draft 주석(§11 하단) 일치 |
| #5 | 토픽 명명 | zone 단위 + 의미 기반 | 데모 물리명 유지, 재명명/분리 없음 | **TODO** (draft DECISION_REQUIRED T4-1) | Phase 1 전체. [결정 필요] envelope 적용과 순서(T0-2) |
| #6 | 메시지 키 | 토픽별 정의 | command은 target_agent_id 키 기구현. 토픽별 key 정책 문서화 미완 | **PARTIAL** | Phase 1: 신규 토픽(alert/notification) key 정의 필요(T4-4). 기존 토픽 키는 기구현 |
| #7 | 인증/인가 | JWT+OIDC+Knox (Phase 1) | 코드 없음 | **TODO** | Phase 1 전체(T1-2) |
| #8 | 시각화 | LEGO + WebSocket | Thymeleaf 단일 페이지(데모) | **TODO** | Phase 1 전체(T3-6) |
| #9 | SQL_JOB | Phase 1 포함 | JobType에 SQL_JOB 없음 | **TODO** | Phase 1 전체(T2-7) |
| #10 | LOG_JOB occurred_at | Phase 1 추가 | sample_lines[].occurred_at 미추출 | **TODO** | Phase 1 전체(T3-7) |
| #11 | Agent 자가 등록 | Phase 1 사전 토큰/승인 | AGENT_STARTED가 등록 겸함(데모) | **TODO** | Phase 1 전체(T2-9) |
| #12 | 영속 저장소 | PG+OS+Redis+MinIO+VM(Phase 2) | in-memory(데모) | **PARTIAL** | Phase 1: PG/OS/Redis/MinIO(T1-1). 잔여: VictoriaMetrics=Phase 2. draft 주석 일치 |
| #13 | OTel Collector 라우팅 | metric/heartbeat 분리 + self 별도 | heartbeat 수집 경로 기구현(데모, §6.9(가)). metric·self 라우팅 분리 없음 | **PARTIAL** | Phase 1: heartbeat 경로 기구현(잔여 없음). 잔여: metric routing + self 별도=Phase 2. **(drift-4: "기구현" 표현 정밀화 필요)** |
| #14 | LOG_JOB file_state | Agent local 동일 유지 | 동일 유지 | **NO-OP** | (draft T5-4 일치) |
| #15 | x-message-id 중복 검사 | Phase 1 Redis TTL | 발행 헤더만 존재, consumer dedup 없음 | **TODO** | Phase 1 전체(T2-8). T1-1 Redis 선행 |
| #16 | 명령 만료 valid_until | 정책 유지 + 만료 audit | computeValidUntil 0.9 정책 기구현. 만료 audit 미구현 | **PARTIAL** | Phase 1: 만료 audit 추가(T3-8). 정책 자체는 기구현 |
| #17 | Quartz misfire | DO_NOTHING 동일 유지 | 데모 정책 유지 | **NO-OP** | (draft T5-5 일치) |
| #18 | 오프라인 Agent 게이팅 | heartbeat 게이팅 + Agent OFFLINE Alert | heartbeat timeout OFFLINE 판정은 데모 기구현(§6.9(가)). Alert 발화 없음(Alert 도메인 부재) | **PARTIAL** | Phase 1: OFFLINE→Alert 발화 추가(T2-6). OFFLINE 판정 자체는 기구현 |

### 3.1 draft와의 status 차이 (정정 제안)

draft는 §11 Track 5에서 #13만 PARTIAL로 명시하고 #4/#12는 "Track에서 추적"으로만 처리했다. 위 전체 판정에서 draft 대비 추가/정정해야 할 판정:

- **#6(메시지 키)**: draft T4-4 status=TODO. → 기존 토픽 키는 기구현이므로 **PARTIAL**(신규 토픽 key만 잔여)로 정정 권고. [결정 필요 아님, 사실 정정]
- **#16(valid_until)**: draft T3-8 status=TODO. → 정책 자체 기구현 + 만료 audit만 잔여이므로 **PARTIAL**로 정정 권고.
- **#18(오프라인 게이팅)**: draft T2-6 status=TODO. → heartbeat 게이팅/OFFLINE 판정 기구현 + Alert 발화만 잔여이므로 **PARTIAL**로 정정 권고.
- #4/#12/#13은 draft가 이미 PARTIAL로 인지(§3 DoD-1 주). 일치.

> 위 #6/#16/#18 정정은 "통합본 결정 사실"과 "코드 현황"의 교차로 도출된 사실 판정이므로 ROADMAP v0.3에서 반영 대상. (DECISION_REQUIRED 아님)

---

## 4. 검증 3 — §6.9(나) 데모 정정 11개 재분류

통합본 §6.9.2 (나) 표는 정확히 11개 행이다. draft §1.1 재분류 원칙(ADR 명시 / ADR 간접 소속 가능 / ADR 바깥)에 따라 전체 재분류했다. "정정 시점" 열에 ADR 번호가 직접 붙은 것은 ADR 명시로 확정한다.

| # | §6.9(나) 항목 | 통합본 "정정 시점" 표기 | 재분류 | 근거 / 비고 |
|---|---|---|---|---|
| 1 | `job-results` 토픽 분리 | Phase 1 (ADR 미표기) | **간접 소속 [결정 필요]** | 통합본 §6.9.5 토픽표가 `job-results`→2개를 "(나) 정정"으로 명시. ADR#5(토픽 명명)와 의미상 연결되나 §8.3에서 직접 번호 미부여. draft T4-2/D-5 일치 |
| 2 | Heartbeat 직렬화 | Phase 1 (ADR #2) | **ADR 명시 → DONE** | ADR#2. 코드 반영 완료(§3 #2) |
| 3 | `x-message-id` 중복 검사 | Phase 1 (ADR #15) | **ADR 명시** | ADR#15(TODO) |
| 4 | 영속 저장소 | Phase 1 (ADR #12) | **ADR 명시** | ADR#12(PARTIAL) |
| 5 | 인증/인가 | Phase 1 (ADR #7) | **ADR 명시** | ADR#7(TODO) |
| 6 | Frontend | Phase 1 (ADR #8) | **ADR 명시** | ADR#8(TODO) |
| 7 | Agent 자가 등록 | Phase 1 (ADR #11) | **ADR 명시** | ADR#11(TODO) |
| 8 | Quartz JobStore | Phase 1 (ADR 미표기) | **ADR 바깥 [결정 필요]** | DB-backed Clustered. §8.3에 직접 ADR 없음. ADR#17(misfire)과는 별개. draft T1-4/D-5 일치. ADR 바깥 정정 항목으로 추적 권고 |
| 9 | LOG_JOB `sample_lines[].occurred_at` | Phase 1 (ADR #10) | **ADR 명시** | ADR#10(TODO) |
| 10 | audit actor.type 범위 | Phase 1 (확장, ADR 미표기) | **ADR 바깥 [결정 필요]** | AGENT+USER+SYSTEM. 코드상 ActorType=AGENT 단독. §8.3에 직접 ADR 없음. draft T3-9/D-5 일치 |
| 11 | `command-topic` routing | Phase 1 (다중 zone 진입 시, ADR 미표기) | **간접 소속 [결정 필요]** | zone 단위 + hash partition. ADR#4(consumer group + zone routing)와 의미상 연결. §8.3 ADR#4 본문에 "zone 단위 토픽 routing" 포함되므로 ADR#4 간접 소속 후보. draft T4-3/D-5 일치 |

### 4.1 재분류 집계

- ADR 명시: **7개** (#2,#3,#4,#5,#6,#7,#9 항목 → 실제로는 항목 2,3,4,5,6,7,9 = heartbeat/x-message-id/영속/인증/FE/자가등록/occurred_at)
- ADR 간접 소속 가능 [결정 필요]: **2개** (job-results 분리 → ADR#5 / command-topic routing → ADR#4)
- ADR 바깥 정정 [결정 필요]: **2개** (Quartz JobStore / audit actor.type)

> draft §1.1이 "기존 v0.1의 7/4 단정을 쓰지 않는다"고 한 것과 일치. 결과적으로 7(명시)+2(간접)+2(바깥)이며, 간접·바깥 4개의 최종 소속은 [결정 필요](D-5)로 유지한다. **이 4개의 소속을 analyzer가 임의 확정하지 않는다.**

---

## 5. 검증 4 — [결정 필요] 전체 목록

draft 전체에서 status=`DECISION_REQUIRED` / `BLOCKED` / `[결정 필요]` / §14 D-목록을 수집하고, 본 검증에서 추가된 항목을 합쳐 확정한다.

### 5.1 draft가 이미 표기한 [결정 필요] (유지)

| ID | 항목 | source_ref | 통합본 Open 연계 |
|---|---|---|---|
| D-1 / G-1 | AMS 5단계 검증이 게이팅하는 ADR/컴포넌트 목록 | §13_open §J | §J (AMS 분석 가정 — 검증 필요) — **통합본 미결 Open** |
| D-2 / G-2 / T1-3 | β 유지 vs γ 전환, Phase 1 deployment 분리 범위 | §13_open §C (05 §7.2.6) | §C "BE 모듈 분리 정책" — **통합본 미결 Open(협의 필요)** |
| D-3 | 영속(#12)·인증(#7) 병렬/순차 실행 방식 | §8.3 ADR#12,#7 | 계획 레이어(통합본 Open 아님) |
| D-4 / T0-1 / T0-2 | envelope 나머지 토픽 적용과 ADR#5 재구조 순서 | HANDOFF, §8.3 ADR#5 | HANDOFF §7 미결정 사안과 일치 |
| D-5 / T3-9 / T4-2 / T4-3 | §6.9(나) 정정 4개 ADR 소속 확정(§4.1 간접 2 + 바깥 2) | §6.9(나) | 재분류 [결정 필요] |
| D-6 | 각 Track 항목 최종 owner_repo 확정 | ROADMAP 전체 | 계획 레이어 |
| D-7 / G-4 | harness + plugin 검증 완료 기준 | HANDOFF | dev-time infra |
| D-8 / T1-5 / G-3 | site별 Phase 1 필수 최소 운영 정보 | §13_open §A | §A "운영 환경 정보 입수" — **통합본 미결 Open** |

### 5.2 본 검증에서 추가된 [결정 필요] / 정정 제안

| ID | 항목 | 유형 | 처리 |
|---|---|---|---|
| N-1 | source_ref `05 §7.2.6`/`§7.2.4`를 §7.2 본문 절 번호로 오인 — §13_open §C cross-ref임을 ROADMAP에 명시 | source_ref 정정(drift-1) | v0.3에서 병기 표기로 수정 |
| N-2 | G-1 `통합본 §11` 인용 — 통합본에 `# 11` 최상위 토픽 없음 | source_ref 정정(drift-2) | `§13_open §J`(+`09 §11.8`)로 교체 |
| N-3 | ADR#13 "heartbeat=기구현" 표현이 라우팅 분리와 혼동 소지 | 표현 정정(drift-4) | "heartbeat 수집 경로=기구현 / metric·self 라우팅 분리=Phase 2"로 문구 정정 |
| N-4 | ADR#6/#16/#18 status를 TODO→PARTIAL로 정정(§3.1) | 사실 정정 | v0.3에서 PARTIAL + 잔여 명시 |
| N-5 | DoD-1 status 집합에 PARTIAL/TODO 누락 가능성 — draft DoD-1은 "DONE/NO-OP/DEFERRED/PARTIAL"만 열거하나 §3 판정상 TODO ADR이 다수(#5,#7,#8,#9,#10,#11,#15). DoD-1 완료 조건에 TODO→착수/완료 경로 명시 필요 | 일관성 | v0.3에서 DoD-1 문구 보강(판정 자체는 모두 완료됨) |

> N-1~N-5는 ROADMAP v0.3 작성 시 반영할 **변경 제안**이다. 이번 Pass에서는 draft를 수정하지 않는다.

### 5.3 통합본 Open question에 직접 묶인 [결정 필요] — 추측 금지 대상

다음은 통합본 §13 Open Questions에 미결로 존재하는 항목과 직접 연결되므로 **analyzer가 추측으로 메우지 않는다**(CLAUDE.md §2 / 강제 룰 5):

- **§13_open §C — BE 모듈 분리 β vs γ** (D-2/G-2/T1-3). 협의 입력 8개 미입수. → ROADMAP은 T1-3을 DECISION_REQUIRED로 유지. **분리 시점·owner_repo 배치를 임의 결정하지 않는다.**
- **§13_open §A — 사이트별 운영 정보** (D-8/G-3/T1-5). → 미입수 상태 유지.
- **§13_open §J — AMS 분석 가정 검증** (D-1/G-1). → AMS 실무자 피드백 전까지 게이팅 대상 목록 미확정.
- **§6.9(나) 정정 4개 ADR 소속** (D-5). → 간접/바깥 분류는 했으나 최종 ADR 번호 소속은 미결.

이 항목들은 **계획 레이어 보존 규칙**에 따라 ROADMAP에서 삭제하지 않고 `[결정 필요]`로 둔다.

---

## 6. 계획 레이어 보존 확인 (통합본 우선 적용 범위 점검)

"통합본 우선"을 사실 주장에만 적용하고, 계획 레이어는 ROADMAP 고유 판단으로 보존했는지 확인:

- **tier/Track 순서**(Track 0~5), **owner_repo 후보**, **handoff 분리안**(§13), **gate_type/blocks 구조**(§5)는 통합본에 근거가 없어도 ROADMAP 고유 계획이므로 **삭제하지 않았다.** owner_repo=monitoring-meta가 "spec/contract 문서 갱신 소유"라는 draft §0 주석도 유지.
- 통합본과 **충돌하는 사실 주장**은 발견되지 않음(토픽 개수 8개, Phase 1/2 컴포넌트 분류, ADR 18개 결정 모두 draft가 통합본을 정확히 반영). 단 §3.1 #6/#16/#18 status와 §2.3 source_ref 4건은 정밀화 대상.
- draft §11 T5-6의 ADR#13 "heartbeat=기구현"은 통합본 §6.9(가)(heartbeats-topic 검증 완료)와 일치하나 표현만 정정 필요(N-3).

---

## 7. 결론 / 다음 단계 (Pass 2 입력)

이번 Pass 1 검증 결과, draft v0.2(보완)는 통합본/HANDOFF/코드와 **큰 사실 충돌 없이 일치**하며, 정정 대상은 source_ref 4건(drift-1~4) + status 3건(#6/#16/#18) + DoD-1 문구(N-5) + 표현 1건(N-3)이다. [결정 필요] 항목(D-1~D-8 + 통합본 Open §A/§C/§J 연계)은 추측 금지 대상으로 모두 보존한다.

다음 단계(Pass 2, **별도 지시 시**):
1. 본 검증 결과(§2~§5 변경 제안 N-1~N-5 + status 정정)를 반영해 `docs/phase1/ROADMAP_PHASE1_v0_3.md` 생성.
2. v0.3 §1 헤더에 동일 기준 commit `8d7a07668eb7d1d7db375fe2342d90f174bdfc49` pin.
3. codex-gate Stop hook으로 통합본↔ROADMAP↔ADR source_ref drift 재검증(G-5).

> 이 Pass에서는 `ROADMAP_PHASE1_v0_3.md`를 만들지 않았다. 산출물은 이 파일 단일.

---

## 8. codex-gate Pass 1 보강 검출 (2026-06-03)

Stop hook의 codex-gate가 ROADMAP draft v0.2(`docs/phase1/ROADMAP_PHASE1_draft_v0_2.md`, docs/ 트리거)를 검토해 FAIL을 냈다. 지적 8건을 Pass 1 검증 결과에 통합한다. (이 핸드오프 자체는 게이트 트리거 대상이 아니며, 게이트는 ROADMAP draft 본문을 본다. 따라서 본 §8 기록만으로 게이트가 해소되지는 않는다 — ROADMAP v0.2 본문 정정/커밋은 사람 결정 사안.)

### 8.1 critical (4)

| ID | Codex 지적 | 본 검증 판정 | 처리 |
|---|---|---|---|
| C-1 | 8토픽 계약 일관성 핵심 표 부재 — 토픽별 envelope 적용/ key rule / payload schema ref가 없어 통합본·ADR#2/#5/#6 ↔ kafka-payloads/envelope 일치 판정 근거 부족 | 타당. 본 핸드오프 §3은 **ADR 18개 매트릭스**이지 **토픽 계약 매트릭스가 아니다**(별개 산출물). draft T4-5도 "docs updated + drift check" 수준 | **[보강 필요]** Pass 2 또는 별도 contract-audit에서 `8토픽 × envelope적용 × key rule × payload ref × 근거 ADR/통합본조항` 매트릭스 작성 |
| C-2 | T2-4 `alert-topic`/`notification-topic` 추가가 T4-1(토픽 명명)·T0-2(ADR#5 순서)보다 먼저 독립 Phase 1 TODO로 잡힘 → Open이어야 할 topic set 확장을 사실상 결정한 흔적 | 타당. topic set 확장은 ADR#5/topic contract 결정의 일부일 수 있음 | **[결정 필요 D-9]** T2-4를 T4-1/T0-2 결정에 `blocked_by`로 의존. 토픽 추가 자체가 Open인지 확정 전까지 독립 TODO 금지 |
| C-3 | T5-2가 ADR#2를 `DONE`으로 확정하나 T0-1/3/4는 envelope 적용을 DECISION_REQUIRED/TODO로 둠 — 범위 모순 | 본 §3 #2 판정과 일치(ADR#2 = heartbeat 마샬링 한정). 단 ROADMAP T5-2 문구가 범위를 안 밝혀 모순처럼 보임 | **[정정]** T5-2를 `DONE (heartbeat marshalling only)`로 명시. ADR#2 ≠ envelope 전 토픽 적용임을 병기 |
| C-4 | T4-3 zone routing을 ADR#4 DECISION_REQUIRED로 두나, §3 본문은 ADR#4를 "zone routing=후속"으로 해석 → 부일치 | 타당. 본 §3 ADR#4 판정(PARTIAL, zone routing=후속/잔여)과도 충돌. T4-3이 Phase 1 DECISION_REQUIRED인 건 부일치 | **[정정, drift-4 연계]** T4-3을 Phase 1 잔여(PARTIAL) 또는 Phase 후속으로 분리 |

### 8.2 spec (4)

| ID | Codex 지적 | 처리 |
|---|---|---|
| S-1 | T4-5 source_ref가 파일경로(`kafka-payloads.md`,`envelope.md`)만 가리키고 통합본/ADR 근거 미병기 | **[정정]** ADR#2/#5/#6 + 통합본 조항 병기 (drift류) |
| S-2 | DoD-1 허용값(DONE/NO-OP/DEFERRED/PARTIAL)과 본문 TODO/DECISION_REQUIRED 불일치 + ADR별 최종 판정 matrix 부재 | 본 §3이 18-ADR 판정 매트릭스 제공 → v0.3 DoD-1에 임베드 + 허용값에 TODO/DECISION_REQUIRED 추적경로 추가(N-5 연계) |
| S-3 | §12 VictoriaMetrics source_ref가 `§6.9(다)/Phase 2`만, ADR#12 직접 참조와 불일치 | **[정정]** 통합본 §8.3 ADR#12 병기 |
| S-4 | §13 권장 HANDOFF 10개 vs 본문 Track의 다수 handoff(013/014/023~028/031~038/041~044) 간 성격 차 | **[정정]** 생략 기준 또는 후속 handoff 생성 규칙 명시 |

### 8.3 [결정 필요] 추가

| ID | 결정 필요 항목 | 관련 | 통합본 Open 연계 |
|---|---|---|---|
| D-9 | alert-topic/notification-topic 등 **topic set 확장**이 Phase 1 확정 구현인지, ADR#5 topic contract 결정에 의존된 Open인지 | C-2, T2-4, T4-1, T0-2 | ADR#5(토픽 명명) — D-4와 묶임. **추측 금지** |

> §8 정정/보강의 대상은 ROADMAP draft v0.2 본문이다. Pass 1(검증만) 범성격 본 핸드오프는 draft를 수정하지 않으며, C-1~C-4 / S-1~S-4 / D-9는 Pass 2(v0.3) 또는 사람 정정 시 반영 대상으로 기록만 한다.

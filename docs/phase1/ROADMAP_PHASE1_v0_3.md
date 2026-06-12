# Phase 1 ROADMAP — v0.3 (기준 문서 후보)

> **📌 현재 액티브 큐** (§17 D-목록·§16/§9~§14의 **사본** — 갱신 2026-06-13 · 표기는 항상 **이름(ID)** 꼴, ID 읽는 법: `docs/phase1/ID-GLOSSARY.md`)
>
> **지금 바로 할 수 있는 작업** (우선순위 근거: `handoff/decisions/phase1-critical-path-analysis.md`)
> - **result-topic 분리**(T4-2) — `job-results` 토픽을 job/log 둘로 나눈다. 막던 결정이 전부 풀려(ADR 소속 확정 포함, D-5) 잔여 결정 0 — 구현만 남음. → §13
> - **메시지 키 정의**(T4-4) · **계약 문서 갱신**(T4-5) — 신규 토픽의 Kafka 키 규칙 구현 / envelope·topic 계약 문서 정리. 잔여 결정 0. → §13
> - **Rule Engine 등 임계 경로 후속**(T2-1 등) — 영속 저장소 기반(T1-1) 완료로 선행 인프라가 충족됐다. 단 일부는 모듈 분리 결정(D-2)에 걸림. → §11
>
> **사람이 정해야 풀리는 것**
> - **모듈을 어떻게 쪼갤지**(D-2) — 모듈러 모놀리스(β) 유지냐 풀 MSA(γ) 전환이냐. 가장 레버리지 큰 결정(§5 완료 조건 4의 게이트). **협의 입력 8개 수집은 지금, 결정 자체는 Rule Engine(T2-1) 착수 전까지 유보**(`handoff/decisions/d2-escalation-timing.md`). 통합본 §C Open — 추측 금지.
> - **영속·인증 작업의 실행 순서**(D-3) · **owner_repo 확정 중 D-2와 무관한 부분**(D-6) — 계획 레이어라 지금 병행 확정 가능.
>
> **외부 정보·선행 결정 대기**
> - **AMS 분석 가정 검증**(D-1) — **방식 전환(2026-06-13)**: 외부 채널 부재로 사용자 잠정 확정(pull)+팀 리뷰 재검증으로 진행. 지금 액티브 큐 무차단, 첫 묶음은 Rule Engine(T2-1) 착수 전 3개(J-04 Drools·J-05 복합 이벤트·J-14 표준 모니터링). 기록 `handoff/decisions/ams-assumption-decisions.md`. → §17 D-1
> - **site별 최소 운영 정보**(D-8) · **다중 zone 진입 시 토픽 전개**(D-4(1)-future) — 통합본 Open(§A)이라 외부 정보가 와야 풀린다. 추측 금지.
> - **모듈 분리 handoff**(§16 순서 5) · **owner_repo 확정 중 D-2 의존분**(D-6) — 모듈 분리 결정(D-2) 후.
>
> **최근 완료**
> - **Open 위상 정리**(open-alignment, 2026-06-13, 거버넌스 · Track 무관) — 통합본 v0.12(결정 0): 6장 Open 절의 기해소 항목 취소선+해소 출처 표시, 13장 §E에 §7.5 baseline 결정 재검토 카드 7건 등재(고아 6건+Agentless 재분류), 13장 도입 선언 현실화, stale 따옴표 인용 3곳(adr/0005·본 ROADMAP·kafka-payloads) 의미 인용 갱신. 사람 결정 D1~D4 = `handoff/open-alignment/open-alignment-000-decision-packet.md` §9. spec-backfill 잔존 항목 종결.
> - **통합본 stale 결정 backfill + 파일명 rename**(spec-backfill, 2026-06-12, 거버넌스 · Track 무관) — 통합본 v0.11(내용 변경 릴리스, 신규 결정 0): heartbeat protobuf 전환(ADR#2)·토픽 명명(ADR#5)·토픽 재명명(T4-1) 완료 반영, 분가 문서 anchor 추가, 인덱스 현행화, kafka-payloads 매핑 표 "T4-1 완료/T4-2 잔여" 정정. 파일명 `통합본_v0_9.md` → **`docs/master-design.md`**(버전 없는 영어 파일명 — v0.10 때 예고한 후속 결정 발동, 이후 버전은 내부 표기로만). 형제 repo 호칭·경로 재배선은 `handoff/spec-backfill/` 3건 발주. §7.2/D-2(β/γ) 절은 동료 자료 검토 중이라 범위 제외.
> - **식별자 체계 단순화 + 이름 우선 표기**(2026-06-11, 거버넌스 · Track 무관) — 운영 ID를 **작업(T)/결정(D)/결정 기록(ADR) 3종**으로 정리. 게이트(G)는 결정(D)에 흡수(G-1→D-1/G-2→D-2/G-3→D-8/G-4→D-7/G-5→§5 완료 조건 7), 완료 조건(DoD)은 "§5 완료 조건 N"으로 격하, 리뷰 잔재(N/C/S/drift/Pass 1)·일회성(P/X/M) 본문 제거. 본 액티브 큐는 **이름(ID) 표기**로 전환. 범례 신설 `docs/phase1/ID-GLOSSARY.md`(신구 매핑 부록). **Open 무결정·통합본 v0.9 무수정**(v0.10 표기 개선은 후속 분리). 형제 repo 변경 0(공지 `handoff/id-cleanup/`). 근거: `handoff/id-cleanup/id-cleanup-000-impact.md`.
> - **e2e baseline v15 = 60/0/0 + 기능 문서 전수 검증**(2026-06-11, 거버넌스 · Track 무관) — 하네스 v9→v15: 동적 검사 2종 추가(**§6-LOG** LOG_JOB 전체 사이클 `JOB_RESULT SUCCESS` 수신 / **§6-STOP** agent graceful shutdown → hub `AGENT_STOPPED received reason=interrupt` 수신) + setup·teardown 잔존 프로세스 위생 검사. **전체 PASS 60/0/0**(`e2e/results/20260611-095734.md`) — **이후 회귀 기준은 이 baseline**(구 58/0/0 표기는 당시 기록). 신호 교훈: Windows에서 CTRL_C(0,0) 콘솔 브로드캐스트 미배달 → **CTRL_BREAK_EVENT(1,0)** 사용(v10~v14 FAIL 원인, 격리 실험으로 확정). `docs/features/` 3건 신규(`script-job-execution`/`log-job-collection`/`agent-lifecycle-audit`)로 구현 완료 시나리오 4건 전부 문서화·미실증 주의 0. 커밋 `a162c76`·`4102ed0`·`b6a35ee`·`d3e41fd`(push됨).
> - **docs/features 기능 문서 레이어 신설 + 파이프라인**(2026-06-10, 거버넌스 · Track 무관) — 사용자 가시 시나리오의 cross-repo 흐름 안내(descriptive, 규범=통합본/adr와 분리). 산출: `docs/features/`(README 헌장+`_template.md`), `feature-doc-writer` sub-agent, analyzer `affected_feature_docs` 필수 필드, codex-gate descriptive 전용 프롬프트 분기(Step 4 결정 (c)). 파일럿 `docs/features/heartbeat-collection.md`(ADR#2 heartbeat 흐름, 검증기준 e2e `20260610-152424`). 커밋 `c967fad`·`b591f29`·`4fafa5b`. 후속 = script-agent 구 토픽명 주석 drift(`handoff/heartbeat-topic-comment-drift/heartbeat-topic-comment-drift-script-agent.md`).
> - **영속 저장소 기반 구축**(T1-1, D-2-무관 슬라이스) **DONE**(2026-06-10) — infra 4종(PG/OS/Redis/MinIO) self-host(infra `aae124f`)+hub 연결·smoke(hub `618cd83`). **실기동 검증 3종 PASS**: infra 헬스 green/yellow+init exit0(버킷·템플릿·ISM), hub `SMOKE_INFRA=1` 4종 왕복(mvn 0), **Phase 0 e2e 회귀 0=58/0/0**(`e2e/results/20260610-152424.md`). DONE 범위=인프라·연결·smoke 슬라이스; 도메인 영속(repository·DDL·트랜잭션)=D-2 후·VM=Phase 2 잔여. CP-1 뿌리 풀림. → §10
> - **데모 정정 3건의 ADR 소속 결정**(D-5) 승인(2026-06-07) — job-results 분리=**ADR#5 간접** / Quartz JobStore=**ADR 바깥** / audit actor.type=**ADR 바깥**. §5 완료 조건 2 추적 닫힘, T4-2 잠금 해제. `handoff/decisions/d5-classification-packet.md`. → §17
> - **토픽 재명명 구현**(T4-1) 완료(2026-06-07) — 3토픽 `commands`/`audit-events`/`heartbeats` → `*-topic`(infra `d732de3`·hub·script-agent). **e2e 종단 PASS 58/0/0**(`e2e/results/20260607-080703.md`, 하네스 v9): R-A 동작 등가(command-topic 발행 라이브·audit/heartbeat 라이브)+R-B 완전성(신명 3종/구명 0)+회귀 0. `job-results`는 T4-2. → §9
> - **토픽 구체 명명 컨벤션 승인**(D-4(1)) 완료(2026-06-06, 후보 B / 단일 command-topic / 신규까지 적용). `adr/0005-topic-naming.md` **Accepted** 전환 → T4-1 BLOCKED 해제. §A 의존 풀림(단일 토픽). → §17
> - **envelope 적용 구현**(T0-3~T0-5) 완료 — consumer `x-source` 가드 명시화(hub/script-agent), Phase 0 §2.2 회귀 0. **e2e PASS 28/0/0**(`e2e/results/20260605-214041.md`, 하네스 §7-D/§7-I 검사 결함 수정 후 재실행, 06-05)
> - **Phase 0 정리**(phase0-cleanup) — 데모 spec 단일화·HANDOFF archive·source_ref 재배선 (e2e PASS 16/0/0, 06-05)
> - **그 외 결정**: alert/notification 토픽 Phase 1 확정(D-9, 06-03) · 실행 순서=envelope 먼저(D-4(2), 06-04) · command-topic routing=ADR#4 소속 승인(06-05)
>
> *갱신 규칙: 기준 문서(§17 D-목록 / §9~§14 Track)을 **먼저** 갱신 → 본 블록은 그 사본. 완료 기준 — 결정 항목=사람 승인 즉시 / 작업 항목=e2e PASS 후. 표기 규칙 — 문장에서 ID 단독 인용 금지, 항상 이름(ID) 꼴.*

---

> **성격**: 이 문서는 `monitoring-meta/docs/master-design.md`(통합본)를 최상위 기준으로 삼는 **Phase 1 기준 문서 후보 ROADMAP**이다. 입력 draft(`ROADMAP_PHASE1_draft_v0_2.md`)를 normalization 검증(`handoff/phase1-000/phase1-000-roadmap-normalization.md`) 결과로 정정·반영해 생성했다. draft를 그대로 기준 문서화한 것이 아니다.
>
> **문서 성격 우선순위**: 코드 → 데모 spec v0.2.1(Phase 0 회귀 방지, 기준 문서 `docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`) → 통합본(`docs/master-design.md`) + kafka-payloads + envelope(Phase 1+ 도달 목표). "통합본 우선"은 **사실 주장(범위·각 ADR 결정)** 에만 적용한다. tier 순서 / owner_repo / handoff 분리 같은 **계획 레이어**는 ROADMAP 고유 판단이므로 보존하되, 불확실하면 `DECISION_REQUIRED`로 둔다.
>
> **`[결정 필요]`는 멈춤 사유가 아니라 기록 대상**이다. §17 미해결 목록(D-목록)에 모은다. (§14는 Track 5다. 이전 v0.2에서 "§14에 모은다"고 한 자기참조 오류를 v0.3에서 §17로 정정.)
>
> **식별자 읽는 법**: `docs/phase1/ID-GLOSSARY.md` — 운영 ID는 **T(작업)/D(결정)/ADR(결정 기록)** 3종. 옛 문서·스냅샷의 폐지 ID(G/DoD/N·C·S/drift/P·X·M) 해독표 포함.

---

## 1. 헤더 / 기준 정보

| 항목 | 값 |
|---|---|
| 문서 버전 | v0.3 (기준 문서 후보) |
| 입력 draft | `docs/phase1/ROADMAP_PHASE1_draft_v0_2.md` |
| normalization 검증 | `handoff/phase1-000/phase1-000-roadmap-normalization.md` |
| 최상위 기준 문서 | `docs/master-design.md` (통합본 — v0.11에서 rename, 구 `docs/통합본_v0_9.md`) |
| 보조 입력 | `docs/kafka-payloads.md`, `docs/envelope.md` (※ 셋업기 `HANDOFF.md`는 `archive/`로 격하 — 작업 상태·미결정의 현행 기준 문서는 본 ROADMAP §9~§14/§17) |
| 기준 monitoring-meta commit (full hash) | `4940e1a115b911e452f96f0083f1c4dc6ede879f` |
| 작성 기준일 | 2026-06-03 |

> **owner_repo 표기 주의**: `owner_repo`에 `monitoring-meta`가 들어가면 *코드 구현* 소유가 아니라 *spec/contract 문서*(`kafka-payloads.md`, `envelope.md`) 갱신 소유를 뜻한다. monitoring-meta는 런타임 repo가 아니라 공통 자산 보관소다.
>
> **source_ref 표기 규칙**:
> - `05 §7.2.6` / `05 §7.2.4`는 §7.2 본문의 절 번호가 아니라 **§13_open §C의 cross-ref 라벨**이다. 단독 인용하지 말고 `통합본 §13_open §C (05 §7.2.6 cross-ref) / 본문 05 §7.2 "모듈 분리 정책" 단락`처럼 병기한다.
> - 통합본에 `# 11` 최상위 토픽은 없다. AMS/마이그레이션은 `09 §11.x`, AMS 검증 가정은 §13_open §J가 집약한다. `통합본 §11` 단독 인용은 쓰지 않는다.
> - 셋업기 `HANDOFF.md`는 `archive/`로 격하됐다(phase0-cleanup). 종전 `HANDOFF.md §5(작업 상태)` / `§7(미결정 사안)` 인용은 본 ROADMAP의 **§9~§14 Track status**(작업 상태)·**§17 D-목록**(미결정)으로 대체하며, 1:1 대응이 없는 사실은 통합본 §8.3 / §13_open 기준 문서를 인용한다.
>
> **결정 필요 목록 위치**: 본 문서의 `[결정 필요]`(D-목록)는 **§17**에 모은다. **§14는 Track 5(구현 없음/동일 유지)** 이며 D-목록이 아니다. 본문·규칙에서 D-목록을 가리킬 때는 항상 §17로 인용한다.

---

## 2. 문서의 목적

이 문서는 Phase 0 완료 이후 Phase 1 완료까지 필요한 작업을 한 곳에서 추적하기 위한 기준 ROADMAP이다. 실제 repo 작업 지시서가 아니다. 실제 구현은 이 ROADMAP을 기준으로 잘라낸 별도 HANDOFF 문서를 통해 수행한다.

```text
master-design.md (통합본)
  ↓ derive
docs/phase1/ROADMAP_PHASE1_draft_v0_2.md   (입력 draft)
  ↓ verify (analyzer normalization + codex-gate)
handoff/phase1-000/phase1-000-roadmap-normalization.md (검증 결과)
  ↓ apply (Pass 2)
docs/phase1/ROADMAP_PHASE1_v0_3.md         (이 문서, 기준 문서 후보)
  ↓ slice
handoff/phase1-xxx/phase1-xxx-*.md
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
| ADR 18개 | Phase 1 결정 레이어 | `통합본 §8.3` | 일부 ADR은 구현 없음 / 동일 유지 / 미도입 / Phase 걸침일 수 있다. 단순 "18개 완료"로 뭉개지 않는다(§5 완료 조건 1). |
| 데모 정정 항목 | Phase 0 데모와 통합문서 사이의 일관성 정정 | `통합본 §6.9(나)` (= 6.9.2) | 11개. ADR 명시 7 / ADR 간접 소속 2 / ADR 바깥 2로 재분류(§3.1). 간접 1개(job-results→ADR#5)와 바깥 2개의 최종 소속은 D-5로 추적했고 **2026-06-07 RESOLVED**(간접=ADR#5 / 바깥 확정, §17). command routing→ADR#4는 §8.3 결정 컬럼이 직접 포함하므로 확정 소속(§3.1 주). |
| Phase 1 신규 컴포넌트 | Rule Engine, Alert, Incident, Notification 등 | `통합본 §6.9(다)` (= 6.9.3) | ADR 카탈로그 바깥의 실제 기능 빌드 포함. **서비스 구현과 전용 Kafka 토픽(alert-topic/notification-topic) 신설은 둘 다 Phase 1 확정**이다(통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표). ADR#5는 토픽 **명명 규칙**만 결정(D-4) — 아래 경계 주석 참조. |
| 모듈 구조 정리 | 모듈러 모놀리스 → deployment 분리(β) | `본문 05 §7.2 "모듈 분리 정책" 단락`, `통합본 §13_open §C (05 §7.2.6 cross-ref)`, `ROADMAP §17 D-2` | β(모듈러 모놀리스) 유지 / γ(풀 MSA) 전환 / 분리 시점은 `DECISION_REQUIRED`(D-2). **통합본 미결 Open(§13_open §C) — 추측 금지.** |
| 검증 증거 | repo별 테스트, e2e, source_ref drift 점검 | `ROADMAP §9~§14 Track status`, `monitoring-meta e2e` | Phase 1 완료 증거로 남긴다. |

> **서비스 구현 + 전용 Kafka 토픽 경계 주석 (D-9 결정 반영 2026-06-03)**: Alert/Incident/Notification **서비스**는 Phase 1 신규 컴포넌트로 **확정**이다(통합본 §6.9(다)/6.9.3). **그리고 전용 Kafka 토픽 `alert-topic`/`notification-topic` 추가도 Phase 1 확정이다** — 통합본 §6.9.3 (다) "Phase 1:" 표가 두 토픽을 "Kafka 토픽 추가"로 직접 명시하고(`alert-topic`=4.4.1·6.4, `notification-topic`=4.4.1·6.5), §6.9.5 토픽표가 둘을 "(다) v0.7 신규 (Phase 1)"로 박았다(확인된 사실). 따라서 "토픽이 Phase 1 topic set에 포함되는가"는 더 이상 Open이 아니다(과거 D-9는 2026-06-03 RESOLVED, §17). **ADR#5가 여는 것은 토픽 *명명 규칙*(zone 단위 + 의미 기반 prefix)과 토픽 재구조의 *실행 순서*뿐이며, 이는 D-4로 남았다. D-4(2) 실행 순서는 2026-06-04 RESOLVED(envelope 먼저, `adr/0005`); D-4(1) 구체 명명 규칙은 2026-06-06 RESOLVED(후보 B 승인, `adr/0005` Accepted).** §6.9.5 두 토픽의 key rule도 통합본이 확정한다: `alert-topic` = `(rule_id, target_id)` 조합 / `notification-topic` = `incident_id`. 따라서 §11~§12 Track 2/3의 서비스 항목(T2-2/T2-3/T3-1 등)과 전용 토픽 추가(T2-4)는 모두 Phase 1 TODO로 추적하며, D-4 잔여 결정은 모두 닫혔다.

### 3.1 데모 정정 항목 재분류 (§6.9.2 11개 전체)

§6.9.2 (나) 표 11개를 "ADR 명시 / ADR 간접 소속 가능 / ADR 바깥 정정"으로 전체 재분류한다. 기존 v0.1의 "7개만 ADR 연결, 4개는 ADR 없음" 단정은 쓰지 않는다.

| # | §6.9(나) 항목 | 재분류 | 소속 ADR / status |
|---|---|---|---|
| 1 | `job-results` 토픽 분리 | **ADR#5 간접 소속 (D-5 RESOLVED 2026-06-07)** | ADR#5 의미 연결, §8.3 직접 번호 미부여이나 간접 소속 확정. 분리 자체=Phase 1 확정(§6.9.2 항목1) / 명명 규칙 D-4(1) RESOLVED(2026-06-06) / 소속 D-5 RESOLVED. T4-2 |
| 2 | Heartbeat 직렬화 | **ADR 명시** | ADR#2 → **DONE** (heartbeat 마샬링 한정 — envelope 전 토픽 적용 ≠ ADR#2, 비고는 §5.1 #2 / T5-2) |
| 3 | `x-message-id` 중복 검사 | **ADR 명시** | ADR#15 → TODO. T2-8 |
| 4 | 영속 저장소 | **ADR 명시** | ADR#12 → PARTIAL. T1-1 |
| 5 | 인증/인가 | **ADR 명시** | ADR#7 → TODO. T1-2 |
| 6 | Frontend | **ADR 명시** | ADR#8 → TODO. T3-6 |
| 7 | Agent 자가 등록 | **ADR 명시** | ADR#11 → TODO. T2-9 |
| 8 | Quartz JobStore DB-backed clustered | **ADR 바깥 (D-5 RESOLVED 2026-06-07)** | §8.3 직접 ADR 없음(ADR#17 misfire "동일유지" 한정과 별개). 구현 필요성=Phase 1 확정 / ADR 바깥 확정. T1-4 |
| 9 | LOG_JOB `sample_lines[].occurred_at` | **ADR 명시** | ADR#10 → TODO. T3-7 |
| 10 | audit actor.type 범위(AGENT+USER+SYSTEM) | **ADR 바깥 (D-5 RESOLVED 2026-06-07)** | §8.3 직접 ADR 없음(#3 audit "채널" 한정과 별개). 구현 필요성=Phase 1 확정 / ADR 바깥 확정. T3-9 |
| 11 | `command-topic` zone routing | **ADR#4 확정 소속 (사실)** | 통합본 §8.3 ADR#4 결정 컬럼 = "동일 + **zone 단위 토픽 routing**"으로 zone routing을 직접 포함한다(확인된 사실). 따라서 ADR#4로 **확정 소속**하며 D-5 범위에서 제외한다. T4-3 |

> **§3.1 status 단일값 주 (CRITICAL round-2)**: 위 표의 "소속 ADR / status" 열에서 status 토큰은 §6 허용 8값 중 단일값(항목 2=`DONE`)이며, 범위 한정("heartbeat 마샬링 한정")은 status 토큰이 아니라 비고 문구다. ADR#2의 의미 한정 상세는 §5.1 #2 비고열 / §14 T5-2 비고열로 분리해 보존한다.

> **항목 11 command-topic routing 사람 승인 (2026-06-05)**: 통합본 §8.3 ADR#4 결정 컬럼이 "동일 + zone 단위 토픽 routing"을 직접 포함하므로 ADR#4 확정 소속으로 승인한다. D-5로 되돌리지 않음(추측 아닌 §8.3 직접 도출). (normalization 검증 `handoff/phase1-000/phase1-000-roadmap-normalization.md` line 122는 "ADR#4 간접 소속 후보 [결정 필요]"로 두었으나, §8.3 결정 컬럼이 zone routing을 명문으로 담고 있어 사실 소속으로 확정한다.)

**재분류 집계**: ADR 명시 7 (항목 2·3·4·5·6·7·9) / 확정 소속 1 (11→ADR#4, 통합본 §8.3 결정 컬럼이 직접 포함) / 간접 소속 1 (1→ADR#5) / ADR 바깥 2 (8, 10 — 구현은 Phase 1 확정). **D-5(job-results→ADR#5 간접 / Quartz JobStore·audit actor.type→ADR 바깥)는 2026-06-07 RESOLVED**(§17 D-5 / `handoff/decisions/d5-classification-packet.md`). command routing(11)은 ADR#4 확정 소속이므로 D-5에서 제외.

---

## 4. ROADMAP과 HANDOFF의 역할

- **ROADMAP** — Phase 1 전체 기준 문서. Phase 1 완료 범위, 의존 순서, source_ref, owner_repo 후보, blocker/gate, status, acceptance evidence, HANDOFF 분리 단위를 정의한다. 직접 구현 지시서가 아니다.
- **HANDOFF** — 실제 작업 단위 실행 문서. 어느 repo를 수정할지, 어떤 파일/모듈을 바꿀지, 어떤 테스트로 완료를 증명할지, 완료 후 ROADMAP의 어느 항목을 갱신할지, 다음 handoff로 무엇을 넘길지 정의한다.

권장 운영 루프: `ROADMAP 항목 선택 → handoff 생성 → repo별 구현 → 테스트/e2e → codex-gate 검토 → ROADMAP status·acceptance_evidence 갱신`.

---

## 5. Phase 1 Definition of Done

Phase 1 완료는 다음을 모두 만족해야 한다.

> **완료 조건 1 ↔ §5.1 TODO ADR 관계 주 (gate 4차 — spec 5 해소)**: 완료 조건 1의 상태=`IN_PROGRESS`는 "**ADR 판정이 진행 중**"이라는 뜻이다. §5.1 매트릭스의 TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 **최종 판정 전 진행 중 상태**이며, Phase 1 완료 시 각 Track 작업을 통해 `DONE`/`PARTIAL`/`NO-OP`/`DEFERRED` 중 하나의 **최종 판정으로 닫혀야 완료 조건 1이 충족**된다. 즉 `IN_PROGRESS` = "아직 TODO/DECISION_REQUIRED ADR이 남아 판정이 닫히지 않음"이다.

> 본 표의 번호는 본문에서 "**§5 완료 조건 N**"으로 인용한다(구 DoD-n — 번호 1~7 동일, 해독표 `docs/phase1/ID-GLOSSARY.md` 부록 B).

| 번호 | 완료 조건 | 확인 방법 | 상태 | 비고 |
|---|---|---|---|---|
| 1 | **ADR 판정 완료 조건**: `통합본 §8.3` ADR 18개가 각각 **최종 판정** `DONE`/`NO-OP`/`DEFERRED`/`PARTIAL` 중 하나에 도달해 있다. | §5.1 ADR 판정 매트릭스 확인 | IN_PROGRESS | 현재 판정 상태에 TODO/DECISION_REQUIRED ADR이 다수 — 아직 최종 판정으로 닫히지 않음(판정 진행 중). TODO ADR은 §5.1 참조 |
| 2 | `통합본 §6.9(나)` 데모 정정 11개가 §3.1 재분류대로 `DONE`/`DEFERRED`/`DECISION_REQUIRED` 중 하나로 추적되어 있다. | demo-correction matrix(§3.1) 확인 | IN_PROGRESS | — |
| 3 | `통합본 §6.9(다)` Phase 1 신규 컴포넌트가 구현 또는 명시 보류되어 있다. | component matrix(Track 2/3) 확인 | TODO | — |
| 4 | `본문 05 §7.2 "모듈 분리 정책" 단락` / `통합본 §13_open §C (05 §7.2.6 cross-ref)` 모듈 분리 기준이 β(모듈러 모놀리스) 유지인지 γ(풀 MSA) 전환인지 결정되어 있다. | ADR 또는 ROADMAP 결정 섹션 확인 | DECISION_REQUIRED | D-2, 통합본 미결 Open |
| 5 | hub / script-agent / infra / monitoring-meta 별 HANDOFF가 완료되고 repo별 테스트가 통과했다. | handoff completion log 확인 | TODO | — |
| 6 | monitoring-meta 기준 e2e 검증 결과가 남아 있다. | e2e 결과 파일/로그 확인 | TODO | ADR#2 한정 PASS 기록 존재 |
| 7 | ROADMAP, ADR, HANDOFF, 통합본 간 source_ref drift가 없다. | codex-gate / analyzer 검토 결과 확인 | TODO | 상시 검증 공정 — codex-gate/analyzer가 매 세션 확인(구 §8 G-5 흡수) |

> **완료 조건 status 셀 단일값 주 (CRITICAL round-2)**: 위 완료 조건 표의 "상태" 열은 §6 허용 8값 중 **정확히 하나만** 담는다. 진행 상황·범위 설명은 "비고" 열로 분리했다(이전 v0.3에서 status 셀에 괄호 수식어가 섞여 있던 것을 정정).

> **완료 조건 1 정의 명확화**: 완료 조건 1은 **Phase 1 "완료" 조건이 아니라 "ADR 18개 판정 완료" 조건**이다.
> - **완료 조건 1 = "18개 ADR이 각각 최종 판정(`DONE`/`NO-OP`/`DEFERRED`/`PARTIAL`) 중 하나에 도달"**.
> - `TODO` / `DECISION_REQUIRED`는 **진행 중 추적 상태**이지 최종 판정도, Phase 1 완료 상태도 아니다. 현재 §5.1 매트릭스에 TODO ADR(#5·#7·#8·#9·#10·#11·#15)과 DECISION_REQUIRED가 남아 있으므로 완료 조건 1은 아직 충족되지 않았다(IN_PROGRESS = 판정 진행 중, §5 머리 주 참조).
> - **Phase 1 *완료* 시점에는** TODO/DECISION_REQUIRED ADR이 모두 최종 판정(`DONE`/`NO-OP`/`DEFERRED`/`PARTIAL`)으로 닫혀 있어야 한다. 즉 "판정 추적 경로 연결"(TODO→Track 항목, DECISION_REQUIRED→§17 D-목록)은 *진행 관리*이고, Phase 1 완료의 필요조건은 그 추적이 최종 판정으로 *닫히는 것*이다. 두 단계를 분리해 본다.

**Phase 걸치는 ADR 처리**: 한 ADR이 Phase를 걸치면 `PARTIAL`로 판정하고 **Phase 1 범위 / Phase 2 잔여**를 함께 명시한다(단일 status로 뭉개지 않는다).
- ADR#4: group.id 정책 유지=Phase 1 기구현 / zone 단위 command-topic routing=미래 트리거(다중 zone 진입 시 §A 해소 후 — T4-3 DEFERRED, Phase 1 잔여 아님).
- ADR#12: PG/OS/Redis/MinIO=Phase 1 / VictoriaMetrics=Phase 2.
- ADR#13: **heartbeat 수집 경로=기구현(Phase 1 잔여 없음) / metric routing·self 별도=Phase 2** ("heartbeat=기구현"은 라우팅 분리가 아니라 수집 경로 기구현을 뜻함).

### 5.1 ADR 18개 판정 매트릭스 (완료 조건 1 임베드)

판정 기준: 통합본 §8.3 결정(목표 spec) + 데모 §6.9 성격 + 실제 main 코드(`../hub`, `../script-agent`, `../infra`) + `ROADMAP §9~§14 Track status`.

> **TODO ADR ↔ 완료 조건 1 관계 (gate 4차 — spec 5)**: 아래 TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 **최종 판정 전 진행 중 상태**다. Phase 1 완료 시 각 Track 작업을 통해 `DONE`/`PARTIAL` 등 최종 판정으로 닫혀야 §5 완료 조건 1(=ADR 판정 완료)이 충족된다(§5 머리 주 참조).

> **status 렌즈 구분 주석 (필독)**: 이 §5.1의 status는 **ADR *전체* 의 판정 렌즈**(ADR이 정의하는 결정 전체가 어느 단계인가)다. 이와 별개로 §9~§14 Track 표의 status는 **Phase 1 *작업* 의 진행 렌즈**(Phase 1에 실재하는 작업 단위가 어디까지 갔나)다. 또한 §7 8토픽 계약 매트릭스의 셀은 **계약 *spec* 렌즈**(토픽 계약이 무엇으로 정의되나)다. 세 렌즈는 서로 다르다.
> 예: **ADR#13은 §5.1에서 PARTIAL**(ADR 전체: heartbeat 수집 경로 완료 / metric routing·self는 Phase 2)이지만, **Phase 1에 남은 *작업분*은 없다**. Phase 1 무작업이므로 Track 1~4의 작업 항목으로 잡히지 않고 §14 Track 5(T5-6)에 "Phase 1 무작업 + Phase 2 잔여 분리" 근거로 들어간다. 즉 §5.1=PARTIAL이라도 Phase 1 작업이 없으면 Track 5에 위치한다.

| ADR | 주제 | 통합본 §8.3 결정 | status | Phase 1 범위 / Phase 2 잔여 / 추적 |
|---|---|---|---|---|
| #1 | 스키마 관리 | 1차 미도입, Phase 2/3 Apicurio | **NO-OP** | Phase 1 미도입 근거 기록. T5-1 |
| #2 | Heartbeat 마샬링 | Phase 1 protobuf | **DONE** | heartbeat 마샬링 한정. 잔여 없음. e2e PASS 16/0/0(2026-06-02). **envelope 전 토픽 적용 ≠ ADR#2**(envelope 나머지 토픽은 Track 0) — T5-2 |
| #3 | Audit 채널 | Kafka 직행 동일 유지 | **NO-OP** | T5-3 |
| #4 | Consumer group | 동일 + 단일 command-topic에서 target_agent_id routing(zone 전개=다중 zone 진입 시) | **PARTIAL** | Phase 1 범위(group.id 유지+단일 토픽 routing)는 기구현 완료. zone 단위 전개는 **Phase 1 잔여가 아니라 미래 트리거** — 다중 zone 진입 시 §A 해소 후 발동(D-4(1)-future), T4-3 **DEFERRED**(§13 비고 참조) |
| #5 | 토픽 명명 | 의미 기반 규칙 B(단일 command-topic, zone suffix=다중 zone 진입 시) | **PARTIAL** | 토픽 *명명 규칙*(D-4(1) — 2026-06-06 RESOLVED, 후보 B, `adr/0005` Accepted) + 토픽 재구조 *실행 순서*(D-4(2) — 2026-06-04 RESOLVED, envelope 먼저). **토픽 재명명(T4-1) 완료(2026-06-07, 3토픽 물리=논리, e2e 58/0/0)**. 잔여=result-topic 분리(T4-2) + alert/notification 토픽 신설(Phase 1 확정, §6.9.3·§6.9.5) |
| #6 | 메시지 키 | 토픽별 정의 | **PARTIAL** | 기존 토픽 키 기구현(command=target_agent_id). 잔여: 신규 토픽 key 정의(alert=`(rule_id,target_id)`/notification=`incident_id` — 통합본 §6.9.5 확정) → T4-4 |
| #7 | 인증/인가 | JWT+OIDC+Knox (Phase 1) | **TODO** | Phase 1 전체. T1-2 |
| #8 | 시각화 | LEGO + WebSocket | **TODO** | Phase 1 전체. T3-6 |
| #9 | SQL_JOB | Phase 1 포함 | **TODO** | Phase 1 전체. T2-7 |
| #10 | LOG_JOB occurred_at | Phase 1 추가 | **TODO** | Phase 1 전체. T3-7 |
| #11 | Agent 자가 등록 | Phase 1 사전 토큰/승인 | **TODO** | Phase 1 전체. T2-9 |
| #12 | 영속 저장소 | PG+OS+Redis+MinIO+VM(Phase 2) | **PARTIAL** | Phase 1: PG/OS/Redis/MinIO(T1-1). 잔여: VictoriaMetrics=Phase 2 |
| #13 | OTel Collector 라우팅 | metric/heartbeat 분리 + self 별도 | **PARTIAL** | Phase 1: heartbeat 수집 경로 기구현(잔여 없음). 잔여: metric routing + self 별도=Phase 2. **Phase 1 작업분 없음 → Track 5(T5-6)에 위치(렌즈 구분 주석 참조)** |
| #14 | LOG_JOB file_state | Agent local 동일 유지 | **NO-OP** | T5-4 |
| #15 | x-message-id 중복 검사 | Phase 1 Redis TTL | **TODO** | Phase 1 전체. T1-1(Redis) 선행 → T2-8 |
| #16 | 명령 만료 valid_until | 정책 유지 + 만료 audit | **PARTIAL** | 정책(computeValidUntil 0.9) 기구현. 잔여: 만료 audit → T3-8 |
| #17 | Quartz misfire | DO_NOTHING 동일 유지 | **NO-OP** | T5-5 |
| #18 | 오프라인 Agent 게이팅 | heartbeat 게이팅 + Agent OFFLINE Alert | **PARTIAL** | OFFLINE 판정/heartbeat 게이팅 기구현. 잔여: OFFLINE→Alert 발화 → T2-6 |

> #6/#16/#18의 PARTIAL 판정은 "통합본 결정 사실 ∩ 코드 현황"의 교차로 도출된 **사실 정정**이며 DECISION_REQUIRED가 아니다. draft가 TODO로 둔 것을 v0.3에서 정정했다.
> **TODO ADR(#5·#7·#8·#9·#10·#11·#15)은 아직 최종 판정이 아니다**(진행 중 추적 상태). §5 완료 조건 1 충족(=ADR 판정 완료)을 위해 Phase 1 완료 시점까지 각 Track 작업을 통해 `DONE`/`PARTIAL` 등 최종 판정으로 닫혀야 한다(§5 주 참조).
> **#2 status 셀 단일값 주 (CRITICAL round-2)**: ADR#2 status는 `DONE` 단일값이다. "heartbeat 마샬링 한정 / envelope 전 토픽 적용 ≠ ADR#2"라는 범위 한정은 status 셀이 아니라 "Phase 1 범위 / Phase 2 잔여 / 추적" 열의 비고로 분리했다.
> **#5 D-4 결정 반영 주 (2026-06-06)**: ADR#5 status는 `TODO` 단일값(Phase 1 전체). alert/notification 전용 토픽 신설 자체는 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 Phase 1 확정이므로 ADR#5에 의존되지 않는다. ADR#5가 여는 것은 토픽 *명명 규칙*(D-4(1) — 2026-06-06 RESOLVED, 후보 B 승인)과 토픽 재구조 *실행 순서*(D-4(2) — 2026-06-04 RESOLVED, envelope 먼저)뿐이며, 둘 다 닫혔다. 잔여 TODO는 명명 규칙을 코드에 반영하는 *재명명 구현*(T4-1, `adr/0005` Accepted로 BLOCKED 해제)이다.

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

## 7. 8토픽 계약 매트릭스

> **§7 렌즈 선언 (gate 4차 — critical 1 + spec 3·4 해소, 필독)**: **이 매트릭스는 *목표 계약 spec*이다.** 출처는 기준 문서 `docs/kafka-payloads.md` + `docs/envelope.md`(= Phase 1+ 도달 목표 spec)다. 각 셀은 **"해당 토픽의 *계약*(envelope 적용 여부/방식, key rule, payload schema ref)이 무엇인가"** 를 기술하며, **Phase 1 *구현 시점·완료 상태가 아니다*.** 구현 상태/진행 시점(어느 Track에서 누가 언제 구현하는가)은 §9~§14 Track 표에서 별도로 추적한다. 즉 이 표의 "**적용**"·확정 key는 "계약이 그렇게 정의된다"는 뜻이지 "Phase 1에서 이미 구현 완료됐다"는 뜻이 아니다(§5.1=ADR 판정 렌즈 / Track=작업 진행 렌즈 / §7=계약 spec 렌즈의 3렌즈 구분 — §5.1 렌즈 주석 참조).
> **토픽 최종 논리명 확정 (D-4(1) 2026-06-06 승인 반영)**: 토픽의 최종 *이름*(name)은 ADR#5(`adr/0005`) 명명 규칙 D-4(1)이 2026-06-06 후보 B로 승인되어 **확정**됐다. 규칙 B = `<domain>-topic[-{subtype}][-{zone}]`(환경 prefix 없음). 최종 논리명은 `command-topic`(단일, 다중 zone 진입 시 `-{zone}` 전개=미래 §17 D-4 Open), `result-topic-job`, `result-topic-log`, `audit-topic`, `heartbeats-topic`(복수형 명시 예외), `alert-topic`, `notification-topic`, `metrics-topic`이다. 종전 "(토픽명/zone suffix 명명 규칙 = ADR#5/D-4 의존, 현재 kafka-payloads 이름은 잠정)" 마커는 본 승인으로 **해소**됐고, 아래 셀은 최종 논리명·확정 규칙으로 갱신했다. 실행 순서(D-4(2))는 2026-06-04 RESOLVED(envelope 먼저). 실제 물리 재명명은 T4-1(BLOCKED 해제, handoff 분배 대기).

8토픽 각각의 envelope 적용 여부/방식, 메시지 키 규칙, payload schema 참조, 근거를 한 표로 모은다. 출처: `docs/envelope.md`(§2·§4) + `docs/kafka-payloads.md` + 통합본 §8.3 ADR#2/#5/#6 + 통합본 6.8.1/6.8.2/4.4.1 + §6.9.3/§6.9.5(alert/notification Phase 1 확정·key rule). **토픽 최종 논리명은 D-4(1)(2026-06-06 후보 B 승인)으로 확정** — 아래 셀에 최종명·확정 규칙을 박는다. 보조 설명은 §7.1.

8토픽 = `command-topic`(단일), `result-topic-job`, `result-topic-log`, `audit-topic`, `heartbeats-topic`(OTLP 예외, 복수형 명시 예외), `alert-topic`, `notification-topic`, `metrics-topic`(Phase 2·OTLP 예외). (위 토픽명은 D-4(1) 후보 B 승인으로 확정된 최종 논리명이며, 규칙 B `<domain>-topic[-{subtype}][-{zone}]`의 사례다. 현행 물리명→논리명 매핑은 `docs/kafka-payloads.md` 참조.)

| 토픽 | envelope 적용 여부/방식 | key rule | payload schema ref | 근거(ADR + 통합본 조항) |
|---|---|---|---|---|
| `command-topic` | **적용** — envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). 단일 물리 토픽(D-4(1) (2) 승인), 다중 zone 진입 시 `-{zone}` 전개=미래(§17 D-4 Open). zone suffix와 무관하게 동일 | `target_agent_id` | kafka-payloads `command-topic` | ADR#5(토픽 명명: zone 단위+의미 기반, D-4(1) Accepted)·ADR#6 / 통합본 6.8.1·6.8.2·4.4.1·6.8(routing 시점), envelope §4.1 |
| `result-topic-job` | **적용** — envelope 4종 표준. **분리=Phase 1 확정**(통합본 §6.9.2 항목1), envelope·key 확정. 최종 논리명 `result-topic-job`(규칙 B 확정) | `agent_id` | kafka-payloads `result-topic-job` | ADR#6·ADR#5(명명 규칙 D-4(1) Accepted) / 통합본 6.9.2 항목1·6.8.2, envelope §4.1 |
| `result-topic-log` | **적용** — envelope 4종 표준. **분리=Phase 1 확정**(통합본 §6.9.2 항목1), envelope·key 확정. 최종 논리명 `result-topic-log`(규칙 B 확정) | `agent_id` | kafka-payloads `result-topic-log` | ADR#6·ADR#10(occurred_at)·ADR#14(file_state)·ADR#5(명명 규칙 D-4(1) Accepted) / 통합본 6.9.2 항목1·6.8.2, envelope §4.1 |
| `audit-topic` | **적용** — 4종 표준. `x-trace-id`는 audit 데모 적용 사실 있으나 정의상 여전히 선택(○), 전용 필수화는 envelope이 새로 정하지 않음 | `agent_id` / `user_id` / `system` (actor 단위) | kafka-payloads `audit-topic` | ADR#3(채널 동일 유지)·ADR#6 / 통합본 6.6.3·6.8.2, envelope §4.1 |
| `heartbeats-topic` | **미적용(OTLP 예외)** — envelope 4종 미적용, OTLP 표준 헤더. 식별·버전은 OTLP/Collector 표준 위임(1:1 대응 보장 아님). 복수형 domain=규칙 B 명시 예외 | (OTLP 위임 — envelope 키 정책 적용 안 함) | kafka-payloads `heartbeats-topic` (OTLP MetricsData protobuf, Phase 1) | ADR#2(Phase 1 protobuf, status `DONE`; heartbeat 마샬링 한정)·ADR#13(라우팅 PARTIAL)·ADR#5(복수형 명시 예외) / 통합본 6.8.1 예외문·4.4.1, envelope §4.2 |
| `alert-topic` | **적용** — envelope 4종(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5). 최종 논리명 `alert-topic`(규칙 B 확정) | `(rule_id, target_id)` 조합. `rule_id`가 null이면 `("agent-offline", target_id)` | kafka-payloads `alert-topic` | 통합본 §6.9.3(Phase 1 확정)·§6.9.5(key rule)·6.8.2·6.8.3 / ADR#6·ADR#5(명명 D-4(1) Accepted) / envelope §4.1·§5 |
| `notification-topic` | **적용** — envelope 4종. 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5). 최종 논리명 `notification-topic`(규칙 B 확정) | `incident_id` | kafka-payloads `notification-topic` | 통합본 §6.9.3(Phase 1 확정)·§6.9.5(key rule)·6.8.2 / ADR#6·ADR#5(명명 D-4(1) Accepted) / envelope §4.1 |
| `metrics-topic` | **미적용(OTLP 예외)** — Phase 2 신규, **Phase 1 미사용**. OTLP 표준 헤더. 최종 논리명 `metrics-topic`(규칙 B 확정, 신규 토픽까지 규칙 적용=D-4(1) (3)) | (OTLP 위임 — envelope 키 정책 적용 안 함) | kafka-payloads `metrics-topic` (OTLP MetricsData protobuf, Phase 2) | ADR#13(metric routing=Phase 2)·ADR#2(Phase 1 protobuf 대상은 heartbeats뿐, metrics 비포함)·ADR#5(명명 D-4(1) (3)) / 통합본 6.9.5, envelope §4.2 |

> **alert/notification 셀 확정 근거 (D-9 결정 반영 2026-06-03)**: 위 두 토픽의 매트릭스 셀의 *계약 내용*(envelope 4종·key rule)은 확정이다. 통합본 §6.9.3 (다) "Phase 1:" 표가 두 토픽을 Phase 1 Kafka 토픽 추가로 명시하고, §6.9.5 토픽표가 둘을 "(다) v0.7 신규 (Phase 1)"로 확정하며 key rule(alert=`(rule_id, target_id)` 조합 / notification=`incident_id`)까지 박았다(확인된 사실). envelope 적용은 envelope §4.1 공통 토픽군 4종 표준이다. **토픽의 최종 *이름*도 ADR#5(`adr/0005`) 명명 규칙 D-4(1) 승인(2026-06-06 후보 B)으로 확정**됐고, *토픽이 Phase 1 topic set에 포함되는가*도 결정 완료다. (계약 내용 확정 / 최종 이름 확정 — §7 렌즈 선언 참조.)

### 7.1 매트릭스 셀 보조 설명 (D-4 잔여 결정 닫힘)

표 셀의 결정 의존 관계를 풀어 설명한다(보조 설명, 잔여 결정은 §17 D-목록). **아래 모든 항목에서 *계약 내용*(envelope 적용·key)과 토픽의 최종 *이름*(명명 규칙, D-4(1) 2026-06-06 후보 B 승인) 모두 확정이다. 실행 순서(D-4(2))는 2026-06-04 RESOLVED(envelope 먼저, `adr/0005`). result 분리 ADR 소속도 ADR#5 간접으로 확정(D-5 RESOLVED 2026-06-07). 남은 것은 다중 zone 진입 시 zone suffix 전개(§17 D-4(1)-future)뿐이다.**

- **`alert-topic` / `notification-topic` 토픽의 Phase 1 확정 추가**: 두 토픽을 Phase 1 확정 구현으로 신설하는 것은 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **확정**이다(과거 D-9는 2026-06-03 RESOLVED, §17). 매트릭스 셀에 envelope 4종·key rule을 확정값으로 담는다.
  - `alert-topic` envelope: envelope 4종 표준(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`). payload `trace_id`는 헤더 `x-trace-id`의 도메인 사본(불변식 envelope §5).
  - `alert-topic` key: `(rule_id, target_id)` 조합, `rule_id`가 null이면 `("agent-offline", target_id)`(통합본 §6.9.5 확정).
  - `notification-topic` envelope: envelope 4종 표준.
  - `notification-topic` key: `incident_id`(통합본 §6.9.5 확정).
  - 두 토픽의 *최종 명명*(`alert-topic`/`notification-topic`, 규칙 B)도 D-4(1) 승인으로 확정. *신설 자체의 Phase 1 확정*과 *계약 내용*도 닫혔다.
- **`result-topic-job` / `result-topic-log` 분리**: `job-results` → 2개 분리(§6.9.2 항목 1)는 **분리 자체=Phase 1 확정**이고, envelope 적용·key(`agent_id`)도 확정이다. 최종 명명(`result-topic-job`/`result-topic-log`, 규칙 B)도 D-4(1)로 확정. 토픽 재구조 *실행 순서*(D-4(2))도 2026-06-04 RESOLVED(envelope 먼저). ADR 소속도 ADR#5 간접으로 확정(D-5 RESOLVED 2026-06-07) — 잔여 결정 0, 구현만 남음. 표 토픽명 셀은 Phase 1 확정 분리분·최종 논리명으로 둔다.
- **`command-topic` zone suffix 물리 실현**: D-4(1) (2) 승인으로 `command-topic`은 **단일 물리 토픽**으로 확정됐다(현 단계 zone=1). envelope 4종 적용은 zone suffix와 무관하게 동일(계약 확정). **다중 zone 진입 시** `command-topic-{zone}` 전개는 미래 트리거이며(통합본 §6.8 "Phase 1 (다중 zone 진입 시)"), zone 단위 routing 물리 실현(ADR#4 잔여 — **ADR#4 확정 소속**, §3.1 항목 11)은 T4-3, zone topology 정보 입수(§13_open §A)에 의존한다(§17 D-4 Open).

> 위 셀들에서 alert/notification·result 분리의 *계약 내용*과 *최종 명명*은 모두 Phase 1 확정 spec이다(명명 규칙 D-4(1) 2026-06-06 승인). result 분리 ADR 소속도 ADR#5 간접 확정(D-5 RESOLVED 2026-06-07). 남는 결정은 다중 zone 진입 시 zone suffix 전개(§17 D-4(1)-future)뿐이다. **토픽 추가/분리/명명은 통합본 기준 문서 + `adr/0005` Accepted에 박힌 사실이다.** 본 §7 표는 계약 spec 렌즈이며 Phase 1 구현 완료 상태를 뜻하지 않는다(§7 렌즈 선언).

---

## 8. 게이트 / 병행 검증 항목 (→ §17로 흡수)

구 게이트 표(G-1~G-5)는 **2026-06-11 ID 체계 정리로 폐지**됐다 — 게이트는 결국 "사람/외부 입력이 정해야 풀리는 사안"이라 D-목록과 같은 사안의 이중 ID였다(식별자 읽는 법: `docs/phase1/ID-GLOSSARY.md`).

- 구 G-1→**D-1**, G-2→**D-2**, G-3→**D-8**, G-4→**D-7**: 게이트 운영 정보(gate_type / 막는 항목 / status / next_action)는 **§17 D-목록 표의 열**로 흡수됐다.
- 구 G-5(source_ref drift 검증)→**§5 완료 조건 7 비고**로 흡수(상시 검증 공정 — codex-gate/analyzer).

---

## 9. Track 0 — envelope 나머지 토픽 적용

"나머지 토픽 envelope 적용"은 Tier 4 후반에 묻지 않고 별도 Track 0으로 분리한다. **Track 0(envelope 적용)과 Track 4(ADR#5 토픽 명명/토픽 재구조) 순서는 D-4(2)로 2026-06-04 RESOLVED — envelope 먼저(Track 0 → Track 4)다(`adr/0005` §2.1). envelope은 Kafka 헤더라 토픽명·zone suffix와 독립이므로 토픽 명명 규칙(D-4(1) — 2026-06-06 RESOLVED)과 무관하게 선적용해도 안전하다.** (alert/notification·result 토픽이 Phase 1 topic set에 포함되는지는 통합본 §6.9.3·§6.9.5로 확정 — Open 아님.)

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T0-1 | 나머지 토픽 envelope 적용 범위 확정 | `ROADMAP §9 Track 0`, `통합본 §8.3 ADR#2`, `통합본 §8.3 ADR#5`, `envelope §4` | monitoring-meta | DONE | envelope 후속 handoff | (해소 — T0-2 RESOLVED) | `handoff/phase1-001/phase1-001-envelope-scope.md` | 적용 대상 토픽 목록과 제외 사유(공통 토픽군 6 ●, OTLP 위임군 2 ✕ — phase1-001 §5.2) |
| T0-2 | envelope 적용과 ADR#5 토픽 재명명/재구조의 실행 순서 결정 | `통합본 §8.3 ADR#5`, `통합본 §6.9(나)`, `adr/0005-topic-naming.md` | monitoring-meta | DONE | topic producer/consumer 변경 | (RESOLVED 2026-06-04, D-4(2)) | `handoff/phase1-001/phase1-001-envelope-scope.md` | **결정: envelope 먼저(Track 0 → Track 4)** — envelope은 헤더라 토픽명 독립(`adr/0005` §2.1) |
| T0-3 | envelope 적용 handoff 생성 | `ROADMAP §9 Track 0` | monitoring-meta | **DONE** | hub/script-agent 후속 작업(T0-4) | T0-1, T0-2 (둘 다 해소) | `handoff/phase1-002/phase1-002-{hub,script-agent,infra}.md` + `phase1-002-000-impact.md` | **분석: 실재 공통 토픽 3종(command/job-results/audit-events) producer는 Phase 0에서 이미 envelope 발행 완료 → 실잔여=consumer `x-source` 가드 명시화. result-log분리·alert·notification은 컴포넌트 미존재로 연기(Track 1/2/3)** |
| T0-4 | envelope 적용 구현(consumer 가드 명시화) | `handoff/phase1-002/phase1-002-{hub,script-agent}.md`, `envelope §2.3` | hub, script-agent | **DONE** | Phase 1 message contract 일관성 | T0-3 (해소) | repo별 handoff(분배 완료) | **PASS** — hub `EnvelopeHeaders.inspectSource()`(관찰 전용, throw/reject 없음)+`JobResultConsumer`/`AuditConsumer` 적용, script-agent `kafka.SourceFromHeaders()`(allowlist/reject 없음). consumer `x-source` 가드 테스트 + Phase 0 §2.2 회귀 0. e2e PASS 28/0/0(`e2e/results/20260605-214041.md` — §7-D/§7-I 검사 결함 수정 후 재실행분), hub mvn 85/0/0·script-agent go test 전체 PASS |
| T0-5 | envelope 결과 ROADMAP 반영 | ROADMAP | monitoring-meta | **DONE** | Track 1~4 정확도 | T0-4 (해소) | `handoff/phase1-002/phase1-002-*` | 본 절(§9 T0-3~T0-5 DONE)·액티브 큐 사본 갱신 완료(06-05). Track 1~3 연기 범위 불변 |

---

## 10. Track 1 — 기반 레이어

거의 모든 Phase 1 기능이 의존하는 기반 작업이다.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T1-1 | 영속 저장소: PG + OpenSearch + Redis + MinIO (VM은 Phase 2) | `통합본 §8.3 ADR#12`, `통합본 §6.9(나)` | infra, hub, monitoring-meta | DONE | Alert, Incident, dedup, log, script storage | site 정보 일부(D-8), infra 결정 | `handoff/phase1-050/phase1-050-t1-1-datastore-slice.md`(슬라이스 정의·승인), `phase1-050-infra.md`(완료보고 ok), `phase1-050-hub.md`(완료보고 ok) | **infra 기동·운영골격 슬라이스 config 단계 완료**(infra `aae124f`): PG/OS/Redis/MinIO 4종+init 2종(opensearch-init/minio-init) docker-compose 추가, 도메인-무관 운영골격(OS `app-*` 인덱스템플릿+ISM, MinIO `app-objects` 비공개 버킷), host port 127.0.0.1 바인딩·credential env `${VAR:?}` 강제. `docker compose config` 무오류(10서비스/3볼륨), 기존 kafka/otel 무영향. **hub 연결·smoke 슬라이스 코드·단위 완료**(hub `618cd83`, push됨): PG(jdbc/Hikari)·Redis(Lettuce)·OpenSearch(opensearch-java 2.25.0)·MinIO(8.5.17) 클라이언트 연결 설정+`DatastoreConnectionSmokeTest`(SMOKE_INFRA gate)+`DatastoreContextBootTest`(인프라 없이 빈 로드 PASS), mvn 100/0/0(smoke 4 skip)·기존 회귀 0. **OUT-OF-SCOPE 양 repo 미침범**(도메인 DDL·repository·@Entity·β/γ(모듈 분리)·PG 스키마 마이그레이션·site sizing·VM 없음, Phase 0 in-memory(Ring Buffer/AgentRegistry)·envelope 불변, grep 증거). **✅ 실기동 검증 PASS(2026-06-10, meta 직접 — 읽기전용 룰 이 검증 한해 완화·infra/.env 미작성 셸 env 주입)**: ① infra 4종 실기동 — PG/OS/Redis/kafka healthy(OS yellow=단일노드 정상)+init 3종 exit=0(버킷 `app-objects` private·템플릿 `app-general`·ISM `general-retention` 적용 확인) ② hub `SMOKE_INFRA=1` smoke 4종 실연결 왕복 PASS(PG temp-table·Redis set-get-del·OS index-get-del·MinIO put-stat-rm, mvn exit 0) ③ **Phase 0 e2e 회귀 0 = 58/0/0**(`e2e/results/20260610-152424.md`, baseline `20260607-080703` 동일 — 스토어 추가가 메시지 흐름/envelope/T4-1 재명명에 회귀 없음). **DONE 범위 = D-2-무관 슬라이스(인프라·연결·smoke).** 잔여(T1-1 항목 밖/후속, DONE에 불포함): 도메인 영속 슬라이스(repository·DDL·트랜잭션 경계·owner_repo)=D-2 후(D-6) / VictoriaMetrics=Phase 2(§5.1 ADR#12 PARTIAL 잔여). hub config↔infra .env(변수명/포트/버킷 `app-objects`) 1:1 의존=변경 시 동기화 필요. 보안 하드닝(OS transport TLS·PKI)=D-8/T1-2 트리거 시 승격, dev-local 한정 |
| T1-2 | 인증/인가: JWT + OIDC + Knox 어댑터 | `통합본 §8.3 ADR#7`, `통합본 §6.9(나)` | hub | TODO | user-facing API, UI 권한, Knox 연동 | T1-1 중 PG user domain | `handoff/phase1-011/phase1-011-auth-oidc-knox.md` | auth flow test, role/permission test |
| T1-3 | 모듈러 모놀리스 → deployment 분리(β) | `본문 05 §7.2 "모듈 분리 정책" 단락`, `통합본 §13_open §C (05 §7.2.6 cross-ref / 경계↔데모 05 §7.2.4 cross-ref)`, `ROADMAP §17 D-2` | hub, script-agent, infra (provisional — β/γ 미결, blocked_by D-2) | DECISION_REQUIRED | owner_repo 배치, 도메인 경계, 배포 단위 | D-2 | `handoff/phase1-012/phase1-012-module-split-decision.md` | β/γ 결정 기록, deployment map |
| T1-4 | Quartz JobStore DB-backed clustered | `통합본 §6.9(나)` (ADR 바깥 정정 — Phase 1 확정 정정, ADR 소속 = ADR 바깥 D-5 RESOLVED) | hub, infra | **TODO** | scheduler 신뢰성, job execution | T1-1 PG. ADR 소속 = **ADR 바깥(D-5 RESOLVED 2026-06-07)** | `handoff/phase1-013/phase1-013-quartz-jobstore.md` | clustered JobStore 설정, failover/misfire test. 비고: 구현 필요성은 Phase 1 확정(§6.9(나)), ADR 소속 ADR 바깥 확정 |
| T1-5 | 사이트별 운영 정보 정리 | `통합본 §13_open §A` | monitoring-meta, infra | IN_PROGRESS | topology/security/node sizing | 외부 정보(D-8) | `handoff/phase1-014/phase1-014-site-ops-inputs.md` | site별 운영정보 matrix |

> **β/γ 의존 owner_repo provisional 표기 (룰 2b)**: T1-3 owner_repo는 β(모듈러 모놀리스+메시지 처리 분리) vs γ(풀 MSA) 결정(D-2)에 의존되므로 `provisional`이며 blocked_by에 D-2를 명시한다. 임의 확정하지 않는다. 다른 Track 항목의 owner_repo도 D-2 결과에 따라 배치가 바뀔 수 있으면 D-6으로 추적한다.
>
> **T1-4 성격 (7/8 일관화)**: T1-4(Quartz JobStore)와 T3-9(audit actor.type)는 **같은 성격**이다 — 둘 다 §6.9(나) Phase 1 **확정 정정**(구현 필요성은 결정 불요)이고, ADR 소속은 **둘 다 ADR 바깥(D-5 RESOLVED 2026-06-07)**. 따라서 status는 둘 다 **`TODO`**(구현 잔여)이고, ADR 소속은 비고/blocked_by에 "ADR 바깥(D-5 RESOLVED)"로 단다.

---

## 11. Track 2 — 코어 도메인 / 파이프라인

> **서비스 구현 + 전용 토픽 주 (D-9 결정 반영 2026-06-03)**: Alert/Incident/Notification **서비스**(T2-2/T2-3 등)는 Phase 1 신규 컴포넌트 **확정**(통합본 §6.9(다)/6.9.3)이며, 전용 **Kafka 토픽 `alert-topic`/`notification-topic` 추가**(T2-4)도 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **Phase 1 확정**이다(과거 D-9는 2026-06-03 RESOLVED, §17). 따라서 T2-2/T2-3은 서비스 구현 단위 TODO로, T2-4(토픽 추가)도 Phase 1 확정 구현 TODO로 추적한다. 토픽 *명명 규칙*(ADR#5/D-4(1))은 2026-06-06 후보 B로 승인 완료(`adr/0005` Accepted) — 최종 논리명 확정.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T2-1 | Rule Engine: `rule-engine-script`, `rule-engine-log` | `통합본 §6.9(다)` | hub | TODO | Alert, validation, rule-based processing | T1-3 일부(D-2), job/log pipeline | `handoff/phase1-020/phase1-020-rule-engine.md` | rule execution test, sample rule e2e |
| T2-2 | Alert Processor + Dedup | `통합본 §6.9(다)`, `통합본 §8.3 ADR#15` | hub | TODO | Incident, Notification | T1-1 Redis/PG, T2-1 | `handoff/phase1-021/phase1-021-alert-processor.md` | duplicate suppression test, alert persistence |
| T2-3 | Incident Service + 그룹핑/상태 전환 | `통합본 §6.9(다)` | hub | TODO | UI incident view, notification context | T2-2 | `handoff/phase1-022/phase1-022-incident-service.md` | incident lifecycle test |
| T2-4 | `alert-topic` / `notification-topic` 추가 | `통합본 §6.9(다)`/§6.9.3, `통합본 §6.9.5`, `통합본 §8.3 ADR#5`, `envelope §4.1` | hub, infra, monitoring-meta | **TODO** | Alert → Notification pipeline | T1-1 등 선행 인프라 | `handoff/phase1-023/phase1-023-alert-notification-topics.md` | topic contract, producer/consumer test. 비고: 토픽 신설=Phase 1 확정(§6.9.3·§6.9.5), key rule(alert=`(rule_id,target_id)`/notification=`incident_id`) 확정, 최종 명명(`alert-topic`/`notification-topic`, 규칙 B)=D-4(1) 2026-06-06 승인 확정 |
| T2-5 | Agent State Service 격상 | `통합본 §6.9(다)` | hub | TODO | Agent OFFLINE alert, UI state | heartbeat infra | `handoff/phase1-024/phase1-024-agent-state-service.md` | agent state transition test |
| T2-6 | Agent OFFLINE → Alert 발화 (ADR#18 잔여) | `통합본 §6.9(다)`, `통합본 §8.3 ADR#18` | hub | TODO | 운영 알림 | T2-2, T2-5, T2-4 | `handoff/phase1-025/phase1-025-agent-offline-alert.md` | offline detection e2e (OFFLINE 판정 자체는 기구현, Alert 발화만 잔여 — §5.1 #18). 비고: T2-4(alert-topic 전용 경로) 선행 |
| T2-7 | SQL_JOB 지원 | `통합본 §8.3 ADR#9` | hub, script-agent | TODO | DB query job execution | job pipeline, auth/security 정책 | `handoff/phase1-026/phase1-026-sql-job.md` | SQL_JOB execution test |
| T2-8 | `x-message-id` 중복 검사 | `통합본 §8.3 ADR#15`, `통합본 §6.9(나)`, `envelope §2.1` | hub, script-agent | TODO | idempotency | T1-1 Redis | `handoff/phase1-027/phase1-027-message-id-dedup.md` | Redis TTL 5분 dedup test |
| T2-9 | Agent 자가 등록 | `통합본 §8.3 ADR#11`, `통합본 §6.9(나)` | hub, script-agent | TODO | agent onboarding | T1-2 auth, 운영 정책 | `handoff/phase1-028/phase1-028-agent-self-registration.md` | pre-token/admin approval flow test |

> **T2-4 성격 정정 (D-9 결정 반영 2026-06-03)**: draft는 T2-4를 독립 Phase 1 TODO로, v0.3 이전 차수는 리뷰 지적에 따라 DECISION_REQUIRED로 격하했었다. 그러나 사람이 D-9를 "A) Phase 1 확정"으로 결정했고, 이는 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표(기준 문서)와 일치한다. 따라서 **DECISION_REQUIRED → TODO(Phase 1 확정 구현)로 정상화**한다. blocked_by에서 "topic set 확장 Open(D-9)"을 제거하고, 선행 인프라(T1-1 등)만 남긴다. 토픽 명명 규칙(D-4(1))은 2026-06-06 후보 B 승인으로 확정됐으며 토픽 신설을 막지 않는다.

---

## 12. Track 3 — 통보 / 검증 / 연동 / UI

> **서비스 구현 + 전용 토픽 주 (D-9 결정 반영 2026-06-03)**: Notification Service(T3-1 등) **서비스** 구현은 Phase 1 신규 컴포넌트 확정(§6.9(다))이며, `notification-topic` **전용 토픽 추가**도 통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표로 **Phase 1 확정**이다(T2-4로 추적, 과거 D-9는 2026-06-03 RESOLVED). 토픽 명명 규칙(ADR#5/D-4(1))은 2026-06-06 후보 B로 승인 완료 — 최종 논리명 확정.

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T3-1 | Notification Service + 채널 어댑터 4종 | `통합본 §6.9(다)` | hub | TODO | 실제 알림 송신 | T2-3, T2-4 | `handoff/phase1-030/phase1-030-notification-service.md` | SMS/Email/Messenger/Teams adapter contract test. 비고: T2-4(notification-topic 전용 경로) 선행 |
| T3-2 | 통보 그룹: Knox 어댑터 + 자체 통합 | `통합본 §6.9(다)` | hub | TODO | recipient resolution | T1-2, T3-1 | `handoff/phase1-031/phase1-031-notification-groups.md` | group resolution test |
| T3-3 | Validation Service + sandbox mode | `통합본 §6.9(다)` | hub, script-agent | TODO | script/rule 검증 | T2-1, job pipeline | `handoff/phase1-032/phase1-032-validation-service.md` | sandbox execution test |
| T3-4 | 결재 어댑터: webhook 비동기 + HMAC | `통합본 §6.9(다)` | hub | TODO | approval integration | 외부 결재 시스템 정보 | `handoff/phase1-033/phase1-033-approval-adapter.md` | HMAC verification, async webhook test |
| T3-5 | Script 파일 보관 + Object Storage | `통합본 §6.9(다)`, `통합본 §8.3 ADR#12` | hub, infra | TODO | script lifecycle | T1-1 MinIO | `handoff/phase1-034/phase1-034-script-object-storage.md` | upload/download/versioning test |
| T3-6 | Frontend LEGO + WebSocket + Gateway + 권한 필터링 | `통합본 §8.3 ADR#8`, `통합본 §6.9(다)` | hub | TODO | UI/실시간 상태 | T1-2, T2/T3 domain APIs | `handoff/phase1-035/phase1-035-frontend-websocket.md` | permission-filtered websocket e2e |
| T3-7 | LOG_JOB `sample_lines[].occurred_at` | `통합본 §8.3 ADR#10`, `통합본 §6.9(나)` | hub, script-agent | TODO | log timeline accuracy | log pipeline | `handoff/phase1-036/phase1-036-logjob-occurred-at.md` | payload contract test |
| T3-8 | 명령 만료 audit (ADR#16 잔여) | `통합본 §8.3 ADR#16` | hub, script-agent | TODO | audit completeness | command pipeline | `handoff/phase1-037/phase1-037-command-expiry-audit.md` | `valid_until` expiry audit test (정책 자체는 기구현, 만료 audit만 잔여 — §5.1 #16) |
| T3-9 | audit actor.type 확장 | `통합본 §6.9(나)` (ADR 바깥 정정 — Phase 1 확정 정정, ADR 소속 = ADR 바깥 D-5 RESOLVED) | hub | **TODO** | audit normalization | ADR 소속 = **ADR 바깥(D-5 RESOLVED 2026-06-07)** | `handoff/phase1-038/phase1-038-audit-actor-type.md` | AGENT/USER/SYSTEM audit event test. 비고: 구현 필요성은 Phase 1 확정(§6.9(나)), ADR 소속 ADR 바깥 확정 |

> **T3-9 정정 (7/8 일관화)**: draft/v0.2는 T3-9를 DECISION_REQUIRED로 두었으나, T3-9는 **T1-4(Quartz JobStore)와 같은 성격**이다(둘 다 §6.9(나) Phase 1 확정 정정 + ADR 소속=ADR 바깥 D-5 RESOLVED). 구현 자체는 결정 불요이므로 **DECISION_REQUIRED → TODO로 정정**하고, ADR 소속은 blocked_by/비고에 "ADR 바깥(D-5 RESOLVED 2026-06-07)"로 표기한다. T1-4·T3-9 둘 다 동일하게 TODO + ADR 바깥 소속 주석을 단다.

---

## 13. Track 4 — 토픽 재구조 / 메시지 계약

Track 4는 cross-cutting 리스크가 높으므로 Track 0에서 순서 결정을 먼저 한다. **Track 0↔Track 4 순서는 D-4(2)로 2026-06-04 RESOLVED — envelope 먼저(Track 0 → Track 4)다(`adr/0005` §2.1). 토픽 구체 명명 규칙(D-4(1))은 2026-06-06 후보 B로 승인 완료(`adr/0005` Accepted) → T4-1 BLOCKED 해제.** (alert/notification·result 토픽이 Phase 1 topic set에 포함되는지는 통합본 §6.9.3·§6.9.5로 확정 — Open 아님. result 분리 자체도 §6.9.2 항목1로 Phase 1 확정. ADR#5/D-4가 열었던 토픽 *명명 규칙*(D-4(1))과 *실행 순서*(D-4(2))는 둘 다 RESOLVED.)

| ID | 항목 | source_ref | owner_repo | status | blocks | blocked_by | handoff | acceptance_evidence |
|---|---|---|---|---|---|---|---|---|
| T4-1 | 토픽 명명: zone 단위 + 의미 기반 (규칙 B 재명명 구현) | `통합본 §8.3 ADR#5`, `통합본 §4.4.1`, `adr/0005-topic-naming.md` | hub, script-agent, infra, monitoring-meta | **DONE (2026-06-07, e2e PASS 58/0/0)** | producer/consumer 전체 | 3토픽 재명명 완료(`commands`→`command-topic`/`audit-events`→`audit-topic`/`heartbeats`→`heartbeats-topic`), `job-results`는 T4-2. infra `d732de3`·hub `KafkaConfig.Topics`·script-agent `config.go` 적용. 결정 6건(동시 컷오버/클린 재기동/env키 유지/회귀0=R-A+R-B/baseline 재생성/문서 동기화) 반영 | `handoff/phase1-040/phase1-040-000-impact.md` + `handoff/phase1-040/phase1-040-{infra,hub,script-agent}.md` | **e2e 종단 검증 PASS 58/0/0**(`e2e/results/20260607-080703.md`, 하네스 v9): R-B 재명명 완전성(신명 3종/구명 0) + R-A 동작 등가(command-topic 발행 라이브 `COMMAND sent offset=0`, audit-topic AGENT_STARTED 수신, heartbeats-topic 라이브, envelope 독립) + 정적·단위(mvn90/go) 회귀 0. 직전 reuse-infra race(coordinator readiness)는 클린 부팅서 미재현 — 재명명 무관 확정 |
| T4-2 | `job-results` → `result-topic-job/log` 분리 | `통합본 §6.9(나)`/§6.9.2 항목1, `통합본 §8.3 ADR#5` (ADR#5 간접 소속, D-5 RESOLVED) | hub, script-agent, infra | **TODO (착수 가능 — 모든 선행 결정 해소)** | result pipeline | T4-1(DONE)·D-4(1)·D-4(2)·D-5 모두 RESOLVED. 분리 자체=Phase 1 확정(§6.9.2 항목1) | `handoff/phase1-041/phase1-041-result-topic-split.md` | job/log result e2e. 비고: 분리=Phase 1 확정, 명명=D-4(1) RESOLVED·순서=D-4(2) RESOLVED·**ADR 소속=ADR#5 간접 D-5 RESOLVED(2026-06-07)** → 잔여 결정 0, 구현만 |
| T4-3 | zone 단위 topic routing / `command-topic` zone routing (ADR#4 잔여) | `통합본 §8.3 ADR#4` (**ADR#4 확정 소속** — §8.3 결정 컬럼 "동일 + zone 단위 토픽 routing" 직접 포함), `통합본 §6.9(나)` | hub, script-agent, infra | **DEFERRED** | multi-zone command routing | zone topology 정보(§13_open §A / D-8) | `handoff/phase1-042/phase1-042-zone-topic-routing.md` | zone routing integration test. 비고: ADR#4 PARTIAL의 후속/잔여분(group.id 유지는 Phase 1 기구현, zone routing은 Phase 1 밖 명시 보류). command-topic 단일 토픽 확정(D-4(1) (2)) — zone suffix 전개는 다중 zone 진입 시 미래 트리거(§17 D-4 Open) |
| T4-4 | 메시지 키 토픽별 정의 (ADR#6 잔여: 신규 토픽 key) | `통합본 §8.3 ADR#6`, `통합본 6.8.2`, `통합본 §6.9.5` | hub, script-agent, monitoring-meta | TODO | ordering/partitioning semantics | topic naming decision(T4-1) | `handoff/phase1-043/phase1-043-message-key-policy.md` | topic별 key rule + test (기존 토픽 키 기구현 — §5.1 #6 / 신규: alert=`(rule_id,target_id)`·notification=`incident_id`는 §6.9.5 확정) |
| T4-5 | envelope/topic contract 문서 갱신 | `통합본 §8.3 ADR#2`, `통합본 §8.3 ADR#5`, `통합본 §8.3 ADR#6`, `docs/kafka-payloads.md`, `docs/envelope.md` | monitoring-meta | TODO | repo 구현 일관성 | T0/T4 decisions | `handoff/phase1-044/phase1-044-contract-doc-update.md` | §7 8토픽 계약 매트릭스 갱신 + drift check |

> **T4-3 정정**: draft는 T4-3 status를 `PARTIAL(잔여) / 후속`으로 두었으나, 이는 §6 허용값(단일 8값) 위반이다(두 값/수식어 혼용). v0.3에서 **단일 허용 status `DEFERRED`로 정규화**한다(zone routing은 Phase 1 밖으로 명시 보류). "후속/잔여" 설명은 비고로 분리했다. blocked_by에 zone topology(§13_open §A / D-8)는 유지한다.
>
> **T4-1 정정 (D-4(1) 승인 반영 2026-06-06)**: T4-1(토픽 명명)은 D-4(1) 구체 명명 컨벤션이 `adr/0005-topic-naming.md`로 격상되어 승인 대기였고 v0.3에서 한때 `BLOCKED`(blocked_by=`adr/0005` 승인)로 정규화돼 있었다. **2026-06-06 사람 승인(후보 B / 단일 command-topic / 신규까지 적용)으로 `adr/0005`가 Accepted 전환됨에 따라 BLOCKED를 해제하고 status를 `TODO`(handoff 분배 대기)로 정상화**한다. 실행 순서(D-4(2))는 RESOLVED(envelope 먼저)이므로 Track 0 이후 착수로 명시한다. 잔여는 명명 규칙을 코드/인프라에 반영하는 *재명명 구현*이며, 이는 별도 handoff(`phase1-040-topic-naming.md`)로 후속 분배한다(본 승인 작업 범위 밖).
>
> **T4-2 정정 (D-9 결정 반영 2026-06-03)**: draft/이전 차수는 T4-2를 DECISION_REQUIRED로 두었으나, `job-results` 분리 자체는 통합본 §6.9.2 항목1로 Phase 1 확정이다(분리=Phase 1). 따라서 **DECISION_REQUIRED → TODO로 정상화**하고, 선행 결정(명명 D-4(1) RESOLVED·실행 순서 D-4(2) RESOLVED·ADR 소속 D-5 RESOLVED 2026-06-07=ADR#5 간접)이 모두 닫혀 **잔여 결정 0, 구현만** 남음을 비고로 분리한다.
>
> **T4-3 ADR 소속 (9 / D-5↔T4-3 충돌 정리)**: command-topic zone routing은 통합본 §8.3 **ADR#4 결정 컬럼이 "동일 + zone 단위 토픽 routing"으로 zone routing을 직접 포함한다(확인된 사실)**. 따라서 ADR#4로 **확정 소속**(사실, 추측 아님)하며, **D-5 범위에서 제외**한다. §17 D-5는 더 이상 command-topic routing을 다루지 않는다.
>
> **T4-5 source_ref 정정**: draft는 파일경로만 가리켰으나 ADR#2/#5/#6 + 통합본 조항을 병기했다.

---

## 14. Track 5 — 구현 없음 / 동일 유지 / Phase 1 미도입

> **status 렌즈 주석 (필독)**: 이 Track 5의 status는 §9~§13 Track과 동일하게 **Phase 1 *작업* 진행 렌즈**다. 단 Track 5는 "Phase 1에 실재하는 작업이 없는"(무작업) ADR을 모은다. §5.1의 ADR *전체* 판정 렌즈와 다르다. 예: **ADR#13은 §5.1=PARTIAL**(ADR 전체: heartbeat 완료 / metric Phase 2)이지만 **Phase 1 작업분이 없으므로**(Phase 1 무작업) 본 Track 5(T5-6)에 위치한다. 두 렌즈를 혼동하지 않는다.

`NO-OP`도 근거와 검증 증거를 남긴다.

| ID | ADR | 결정 | source_ref | status | acceptance_evidence |
|---|---|---|---|---|---|
| T5-1 | ADR#1 | 스키마 관리 1차 미도입. Phase 2/3 Apicurio 검토 | `통합본 §8.3 ADR#1` | NO-OP | Phase 1 미도입 근거 기록 |
| T5-2 | ADR#2 | Heartbeat protobuf 전환 완료 | `통합본 §8.3 ADR#2`, `ROADMAP §5.1 ADR#2` | **DONE** | heartbeat 마샬링 한정. 2026-06-02 PASS 16/0/0. **ADR#2 ≠ envelope 전 토픽 적용**: envelope 나머지 토픽은 Track 0 |
| T5-3 | ADR#3 | Audit 채널 동일 유지 | `통합본 §8.3 ADR#3` | NO-OP | audit channel 유지 근거 기록 |
| T5-4 | ADR#14 | LOG_JOB `file_state` 동일 유지 | `통합본 §8.3 ADR#14` | NO-OP | payload contract 유지 근거 기록 |
| T5-5 | ADR#17 | Quartz misfire 동일 유지: `DO_NOTHING` | `통합본 §8.3 ADR#17` | NO-OP | scheduler 설정 확인 |
| T5-6 | ADR#13 | 라우팅: heartbeat 수집 경로=기구현(잔여 없음) / metric routing·self 별도=Phase 2 | `통합본 §8.3 ADR#13` | PARTIAL | **Phase 1 무작업**(heartbeat 수집 경로 기구현 → Phase 1 잔여 없음) / metric routing + self 별도=Phase 2. ADR 전체는 §5.1=PARTIAL이나 Phase 1 작업분이 없어 본 Track에 위치("기구현"=수집 경로 기구현, 라우팅 분리 아님) |

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
| 다중 zone 진입 시 `command-topic-{zone}` 전개 | `통합본 §6.8`(zone 전개=다중 zone 진입 시 미래 트리거 — 구 따옴표 인용은 v0.11 재서술로 의미 인용 갱신), `통합본 13장 §A`, `adr/0005` §4 | 미래 트리거 — 다중 zone 진입 + §A(zone topology) 해소 후 Track 4 재명명. 지금 고정/추측 금지(§17 D-4 Open) |

---

## 16. 권장 HANDOFF 분리안

ROADMAP은 기준 문서로 두고 아래와 같이 HANDOFF를 생성해 실행한다. **본 표는 우선 슬라이스 후보이며, Track 표(§9~§14)가 *전체* handoff를 추적한다. §16은 대표 슬라이스만 나열한다** — 우선 슬라이스 외 항목(`013/014/024~028/031~038/042~044` 등)은 해당 Track 항목 착수 시 동일 규칙으로 생성한다(생략 기준 = "우선 슬라이스 외 항목은 Track 착수 시점에 생성, 추적은 Track 표가 담당").

> **§16 ↔ Track 표 성격 주 (gate 4차 — spec 6 해소)**: D-9 해소로 성격이 올라간 토픽 handoff 두 건(T2-4 → `phase1-023-alert-notification-topics`, T4-2 → `phase1-041-result-topic-split`)을 아래 우선 슬라이스 목록에 **추가**한다. ADR#5(`adr/0005-topic-naming.md`)는 D-4(1) 구체 명명 규칙 승인용 신규 ADR로, 2026-06-06 후보 B로 승인 완료(Accepted)되어 T4-1(`phase1-040-topic-naming`) 재명명 handoff의 선행 결정이 닫혔다. 그 밖의 모든 토픽/도메인 handoff는 §16이 아니라 **Track 표(§9~§14)에서 전체 추적**되며, §16은 대표 슬라이스만 담는다. 따라서 "§16에 없는 handoff = 누락"이 아니라 "Track 표에서 추적 중"이다(Track 표 ↔ §16 성격 충돌 해소).

| 순서 | handoff 파일 후보 | 목적 | 대상 repo |
|---|---|---|---|
| 0 | `handoff/phase1-000/phase1-000-roadmap-normalization.md` | ROADMAP 검증, source_ref 보강, [결정 필요] 정리 | monitoring-meta |
| 1 | `handoff/phase1-001/phase1-001-envelope-scope.md` (작성됨 2026-06-04) | 나머지 topic envelope 적용 범위 + 순서 결정 — D-4(2) RESOLVED(envelope 먼저), 적용 대상/제외 확정 | monitoring-meta |
| 2 | `handoff/phase1-002/phase1-002-{hub,script-agent,infra}.md` (작성됨 2026-06-05, 구현 완료) | envelope 적용 구현 — consumer `x-source` 가드 명시화(T0-4 DONE) | hub, script-agent |
| 3 | `handoff/phase1-010/phase1-010-persistence-foundation.md` | PG/OS/Redis/MinIO 기반 | infra, hub |
| 4 | `handoff/phase1-011/phase1-011-auth-oidc-knox.md` | JWT/OIDC/Knox | hub |
| 5 | `handoff/phase1-012/phase1-012-module-split-decision.md` | β(모듈러 모놀리스)/γ(풀 MSA) 및 deployment map 결정 (D-2) | monitoring-meta, hub, infra |
| 6 | `handoff/phase1-020/phase1-020-rule-engine.md` | Rule Engine 1차 | hub |
| 7 | `handoff/phase1-021/phase1-021-alert-processor.md` | Alert + dedup | hub |
| 8 | `handoff/phase1-022/phase1-022-incident-service.md` | Incident lifecycle | hub |
| 9 | `handoff/phase1-023/phase1-023-alert-notification-topics.md` | `alert-topic`/`notification-topic` 추가 (T2-4, Phase 1 확정, 명명 규칙 D-4(1) 승인 완료) | hub, infra, monitoring-meta |
| 10 | `handoff/phase1-030/phase1-030-notification-service.md` | Notification pipeline | hub |
| 11 | `adr/0005-topic-naming.md` (Accepted 2026-06-06) → `handoff/phase1-040/phase1-040-topic-naming.md` | ADR#5 topic contract: 구체 명명 규칙 승인(D-4(1)) **완료** → 재명명 구현 handoff 분배 대기 | monitoring-meta, hub, script-agent, infra |
| 12 | `handoff/phase1-041/phase1-041-result-topic-split.md` | `job-results` → `result-topic-job/log` 분리 (T4-2, Phase 1 확정, 명명 규칙 D-4(1) RESOLVED; 실행 순서 D-4(2) RESOLVED) | hub, script-agent, infra |

각 HANDOFF는 §1 헤더에 **기준 monitoring-meta commit full hash**를 박고, 다음 섹션을 포함한다: `1.목적(+기준 commit) / 2.source_ref / 3.대상 repo / 4.수정 대상 파일·모듈 후보 / 5.구현 규칙(+out-of-scope) / 6.테스트·검증 / 7.완료 시 ROADMAP 갱신 항목 / 8.다음 HANDOFF`.

---

## 17. 미해결 / 결정 필요 목록 (D-목록)

> 이 §17이 본 문서의 **D-목록(결정 필요 목록)** 이다. (이전 v0.2가 "§14 D-목록"으로 부르던 자기참조 오류를 v0.3에서 §17로 정정. §14는 Track 5다.)
>
> **게이트 흡수 주 (2026-06-11)**: 구 §8 게이트 표(G-1~G-5)를 본 표로 흡수했다(G-1→D-1, G-2→D-2, G-3→D-8, G-4→D-7, G-5→§5 완료 조건 7 비고). `gate_type`/`status`/`next_action` 열이 그 게이트 운영 정보다 — **게이트 성격이 없거나 해소된 행은 `—`**(status 열에 값을 적을 때는 §6 허용 8값 중 하나만). 흡수는 표기 통합일 뿐 각 결정의 미결 상태·통합본 Open 연계는 무변경이다.

| ID | 결정 필요 항목 | 관련 source_ref | gate_type | 막는 항목 | status | 통합본 Open 연계 | owner | next_action |
|---|---|---|---|---|---|---|---|---|
| D-1 | AMS 분석 가정 검증 게이트 (구 G-1 흡수 — 구 "5단계 검증") | `통합본 13장 §J`, `09 §11.8`, `handoff/ams-assumption-baseline/ams-assumption-baseline-000-decision-packet.md` | local blocker | `[AMS 분석 가정 — 검증 필요]` 태그 결정들의 확정 | **IN_PROGRESS(pull — 검증 프로세스만. §J 14항목의 답은 전부 미결)** | 통합본 미결 Open(§J — 14항목 전부 미확정 유지. 전환된 것은 검증 방식이지 항목 해소가 아님) | human | **방식 전환(2026-06-13)**: 외부 채널 부재 → 사용자 잠정 확정(pull, 차단 시점별 묶음 — T2-1 전 3개/도메인 DDL 전 4개/T3 전 2개/마이그레이션 전/유보 5개) + **팀 리뷰 재검증 게이트(마이그레이션·ETL 설계 전, 늦어도 본개발 진입 전)**. 게이팅 대조표=패킷 §3~§4(작성 완료), 누적 기록=`handoff/decisions/ams-assumption-decisions.md` |
| D-2 | β(모듈러 모놀리스+메시지 처리 분리) 유지 vs γ(풀 MSA) 전환, Phase 1 내 deployment 분리 범위 (구 G-2 흡수) | `통합본 §13_open §C (05 §7.2.6 cross-ref)`, `본문 05 §7.2 모듈 분리 정책 단락` | local blocker | T1-3, owner_repo 배치, deployment 분리 시점·모듈 경계 확정 | DECISION_REQUIRED | **통합본 미결 Open(§C, 협의 필요)** | human/analyzer | β/γ/Phase 1 분리 범위 결정 — **추측 금지** |
| D-3 | 영속(#12)과 인증(#7)의 병렬/순차 실행 방식 | `통합본 §8.3 ADR#12`, `ADR#7` | — | T1-1, T1-2 | — | 계획 레이어(통합본 Open 아님) | human/implementation lead | — |
| D-4(2) | envelope 적용과 토픽 재구조의 *실행 순서* → **RESOLVED (2026-06-04)**: **envelope 먼저(Track 0 → Track 4)**. envelope은 Kafka 헤더라 토픽명·zone suffix와 독립이므로 명명 규칙 승인(D-4(1)) 전에 선적용 안전(`adr/0005-topic-naming.md` §2.1). | `통합본 §8.3 ADR#5`, `adr/0005-topic-naming.md` | — | (해소 — T0-2 DONE, T4-1/T4-2 순서 = Track 0 이후) | — | (D-4(2) 해소) | 결정: human, 2026-06-04 | — |
| D-4(1) | 토픽 **구체 명명 컨벤션** → **RESOLVED (2026-06-06)**: 후보 **B**(규칙 `<domain>-topic[-{subtype}][-{zone}]` 명시) / `command-topic` **단일 물리 토픽** / 신규 토픽까지 규칙 적용. `heartbeats-topic` 복수형은 명시 예외. `adr/0005-topic-naming.md` **Accepted** 전환 → T4-1 BLOCKED 해제. 명명 *원칙*("zone 단위 + 의미 기반")은 통합본 §4.4.1·§8.3 ADR#5 확정과 일치. | `통합본 §8.3 ADR#5`, `통합본 §4.4.1`, `통합본 §6.8`, `adr/0005-topic-naming.md` | — | (해소 — §7 매트릭스·kafka-payloads 최종명 갱신 완료 / T4-1 BLOCKED 해제) | — | (D-4(1) 해소) | 결정: human, 2026-06-06 | — |
| D-4(1)-future | **다중 zone 진입 시 zone suffix 전개** + **실제 zone 인스턴스명**: `command-topic-{zone}` 전개는 다중 zone 진입이라는 미래 트리거에 의존(통합본 §6.8 "Phase 1 (다중 zone 진입 시)"). 실제 zone 인스턴스명·topology는 통합본 §13_open §A 미결 — **추측 금지**. 단일 토픽 채택(D-4(1) (2))으로 현 단계 의존은 풀렸으나 다중 zone 전개 시점에 §A 해소 필요. | `통합본 §6.8`, `통합본 §13_open §A`, `adr/0005` §4 | — | T4-3(zone routing), 다중 zone 전개 시 재명명 | — | **통합본 미결 Open(§A)** | human/infra/analyzer | — |
| D-5 | §6.9(나) 데모 정정 ADR 소속 3건 → **RESOLVED (2026-06-07)**: **job-results 분리 = ADR#5 간접 소속** / **Quartz JobStore = ADR 바깥** / **audit actor.type = ADR 바깥**. 3건 모두 구현은 Phase 1 확정이고 ADR 소속 라벨만 확정한 것. command-topic routing(항목 11)은 ADR#4 확정 소속으로 D-5에서 제외(§3.1 / §13 T4-3). | `통합본 §6.9(나)` | — | (해소 — §5 완료 조건 2 닫힘 추적, T4-2=ADR#5 간접 라벨 확정, T1-4·T3-9=ADR 바깥 라벨 확정) | — | (D-5 해소) | 결정: human, 2026-06-07 | — |
| D-6 | 각 Track 항목의 최종 owner_repo 확정 (β/γ 결과에 의존되는 항목은 D-2 후) | ROADMAP 전체 | — | repo별 HANDOFF | — | 계획 레이어 | human/analyzer | — |
| D-7 | harness + plugin 검증 완료 기준 (구 G-4 흡수) | dev-time 실행 인프라 | parallel validation | per-repo handoff 실행 루프와 codex-gate 검증 안정성 | IN_PROGRESS | dev-time infra | implementation lead | ROADMAP 작성은 막지 않되, 실행 handoff 전 검증 상태 확인 |
| D-8 | site별 운영 정보 중 Phase 1에 반드시 필요한 최소값 (구 G-3 흡수) | `통합본 §13_open §A` | local blocker | T1-5, 보안 정책·topology·노드 추산·site별 배포/운영 결정 | IN_PROGRESS | **통합본 미결 Open(§A)** | human/infra | site별 누락 정보 목록화 |

> **D-9 해소 (2026-06-03)**: `alert-topic`/`notification-topic` 등 topic set 확장이 Phase 1 확정인지 ADR#5 의존 Open인지의 결정은 **RESOLVED**다 — alert/notification 토픽은 **Phase 1 확정**이다(통합본 §6.9.3 (다) Phase 1 표가 두 토픽을 "Kafka 토픽 추가"로 명시 + §6.9.5 토픽표가 "(다) v0.7 신규 (Phase 1)"로 확정, key rule까지 박음 — 확인된 사실). 명명 규칙(zone 단위+의미 기반 prefix)은 **D-4(1)**(`adr/0005`, 2026-06-06 후보 B 승인 RESOLVED)로, 토픽 재구조 실행 순서는 **D-4(2)**(RESOLVED 2026-06-04)로 닫혔다. result-topic 분리 자체도 §6.9.2 항목1로 Phase 1 확정. (결정: human, 2026-06-03 (A) Phase 1 확정.)

> **D-4(1) 해소 (2026-06-06)**: 토픽 구체 명명 컨벤션은 사람 승인으로 **RESOLVED**다 — (1) 후보 B(규칙 명시) / (2) `command-topic` 단일 물리 토픽 / (3) 신규 토픽까지 규칙 적용. `heartbeats-topic` 복수형은 명시 예외. 단일 토픽 채택으로 §A(zone topology) 의존이 현 단계에는 풀렸고 D-4(1) 세 항목 전부 closed → `adr/0005` Accepted 전환 → T4-1 BLOCKED 해제. **다중 zone 진입 시 zone suffix 전개·실제 zone 인스턴스명은 미래 트리거로 D-4(1)-future에 분리 보존(§A 미결, 추측 금지).**
>
> **D-5 해소 (2026-06-07)**: §6.9(나) 데모 정정 3건의 ADR 소속이 사람 승인으로 **RESOLVED**다 — **job-results 분리 = ADR#5 간접 소속**(§8.3 ADR#5=토픽 명명, 분리에 번호 직접 미부여이나 의미 연결) / **Quartz JobStore = ADR 바깥**(§8.3 #17 misfire "동일유지" 한정 — JobStore 전환은 별개) / **audit actor.type = ADR 바깥**(§8.3 #3 audit "채널" 한정 — actor 모델 확장은 별개). 3건 모두 *구현*은 Phase 1 확정이고 이번에 *ADR 소속 라벨*만 확정 → §5 완료 조건 2 추적 닫힘, T4-2(ADR#5 간접 라벨)·T1-4·T3-9(ADR 바깥 라벨) 소속 확정. 근거 패킷 `handoff/decisions/d5-classification-packet.md`. 통합본 Open 아님(§6.9(나)↔§8.3 대조로 도출, 추측 아님).

> **추측 금지 대상 (CLAUDE.md §2 / 강제 룰 5)**: D-1(§J)·D-2(§C)·D-8(§A)·D-4(1)-future(§A)은 통합본 §13 Open Questions 미결 항목과 직접 연결되므로 analyzer가 추측으로 메우지 않는다. 이 항목들은 계획 레이어 보존 규칙에 따라 ROADMAP에서 삭제하지 않고 보존한다. (D-9는 2026-06-03, D-4(2)는 2026-06-04, D-4(1)은 2026-06-06, **D-5는 2026-06-07** 사람 결정으로 해소 — 통합본 §6.9.3/§6.9.5/§6.8 기준 문서·`adr/0005`와 일치. 해소된 결정은 더 이상 blocker가 아니다.)
>
> **command-topic routing 승인 (2026-06-05)**: 통합본 §8.3 ADR#4 결정 컬럼이 "zone 단위 토픽 routing"을 직접 포함하므로 ADR#4 확정 소속으로 승인한다. D-5로 되돌리지 않음(추측 아닌 §8.3 직접 도출). 따라서 §17 D-5는 command-topic routing을 다루지 않으며, T4-3은 ADR#4 PARTIAL 잔여(DEFERRED)로만 추적한다(§3.1 항목11 / §13 T4-3).

---

## 18. 변경 이력

> **현재 상태 요약(v0.3)**: D-9·D-4(2)·D-4(1) 해소, D-4(1) `adr/0005` Accepted 전환(후보 B 승인 2026-06-06) → T4-1 BLOCKED 해제, 8토픽 계약 매트릭스(§7) 최종 논리명·확정 규칙 갱신, command-topic routing ADR#4 확정 소속 승인(2026-06-05). 상세 gate-round 이력(gate-1~9 / round-2 CRITICAL·sweep·SPEC / D-9·D-4 반영 매핑)은 `handoff/phase1-000/phase1-000b-consistency-checklist.md` 부록 참조.

| 버전 | 현재 상태 요약 |
|---|---|
| v0.1 | derive 초안 — Tier 1~4 + 선행 게이트 + 작업 0 + Phase 2 분리 |
| v0.2 | 게이트 세분, Track 0 분리(envelope), DoD 추가, 데모 정정 명시/간접/바깥 분류, 역할 분리. source_ref `05 §7.2` 정규화 + PARTIAL 추가(보완) |
| **v0.3 (기준 문서 후보, 현행)** | Pass 1 normalization + codex-gate 다회차 정정 + D-9·D-4 사람 결정 반영. **현재 상태**: D-9·D-4(2)·D-4(1)·D-5(2026-06-07) RESOLVED, D-4(1) `adr/0005` Accepted(후보 B 승인 2026-06-06) → T4-1 BLOCKED 해제 후 구현 완료(2026-06-07), §7 8토픽 계약 최종 논리명 갱신, command-topic routing ADR#4 확정 소속 승인(2026-06-05). 잔여 미결 = §17 D-1·D-2·D-4(1)-future·D-8(+ 통합본 Open §A/§C/§J). §1 기준 commit pin `4940e1a`·버전 v0.3 유지. 상세 차수별 정정 이력은 부록(`handoff/phase1-000/phase1-000b-consistency-checklist.md`)으로 이관. |

> **기준 commit pin 결정 이력**: Pass-1(`handoff/phase1-000/phase1-000-roadmap-normalization.md` §7)은 v0.3 헤더에 `8d7a07668eb7d1d7db375fe2342d90f174bdfc49` pin을 요구했으나, 사용자가 Pass-2에서 현 기준 문서 `4940e1a115b911e452f96f0083f1c4dc6ede879f`로 결정했다(`4940e1a`는 Pass-1 산출물을 포함해 더 정확). 의도적 변경이며 §1 헤더 pin은 `4940e1a`로 유지한다.

> **command-topic routing 소속 승인 이력 (2026-06-05)**: §3.1 항목11 command-topic routing은 사람 승인으로 ADR#4 확정 소속(통합본 §8.3 결정 컬럼 직접 도출, 사실)으로 닫았다. D-5로 되돌리지 않는다(§17 D-5 / §3.1 항목11 승인 주 참조).

> **D-4(1) 토픽 명명 컨벤션 승인 이력 (2026-06-06)**: D-4(1)은 사람 승인으로 후보 B(규칙 명시) / `command-topic` 단일 물리 토픽 / 신규 토픽까지 적용으로 확정됐다. `adr/0005-topic-naming.md` Proposed → Accepted 전환, §7 매트릭스 토픽명 셀·`docs/kafka-payloads.md` 잠정명 → 최종 논리명 정정, T4-1 BLOCKED → TODO(handoff 분배 대기). 다중 zone 전개·실제 zone 인스턴스명은 §A 미결로 D-4(1)-future에 분리 보존(추측 금지). 본 작업은 결정 기록(spec 저작)이며 실제 토픽 재명명 코드(T4-1 구현)는 별도 후속 handoff.

---

## 19. v0.2 → v0.3 변경 요약 (codex-gate 검토용)

> **요약**: Pass 1 normalization(N-1~N-5 / C-1~C-4 / S-1~S-4) + codex-gate 다회차 정정(1차 9건 / 2차 round-2 5건 / 3차 D-9 반영 / 4차 §7 계약렌즈·D-4·DoD-1·§16 성격) + D-4 사람 결정(D-4(2) 2026-06-04 / D-4(1) 2026-06-06) + command-topic routing 소속 승인(2026-06-05)을 v0.3에 모두 적용 완료.
>
> **상세 차수별 적용 매핑(N/C/S 13건, gate-1~9, round-2 CRITICAL·sweep·SPEC 3~5, D-9·gate 3차·4차, D-4 결정 매핑 표)는 본문에서 `handoff/phase1-000/phase1-000b-consistency-checklist.md` 부록으로 이관**했다(provenance 보존). 회고성 매핑은 부록에서 추적하고, v0.3 본문은 현재 상태만 담는다.
>
> **현재 잔여 결정 필요**(회고가 아닌 현 상태): §17 D-1·D-2·D-4(1)-future·D-8. (D-4(2)·D-4(1)·D-9·D-5(2026-06-07)는 RESOLVED, `adr/0005`는 Accepted.) 통합본 미결 Open(§A/§C/§J) 및 다중 zone 전개(D-4(1)-future)는 추측 금지 대상으로 보존한다(다중 zone 전개 시 zone 인스턴스명 고정 금지). §1 기준 commit pin(`4940e1a`)·버전 v0.3은 유지한다.

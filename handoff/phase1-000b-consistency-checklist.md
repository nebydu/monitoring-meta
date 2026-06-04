# handoff — phase1-000b: Phase 1 문서 정합성 체크리스트 (해소·이관본)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `phase1-000b` | `docs/phase1/checklist.md`(commit edd892c)의 해소·이관본 |
| target | `meta` | monitoring-meta 내부 정합성 처리(코드 repo 무관) |
| 기준 monitoring-meta commit | `5d20cf2178c08ec15970b28f766dbbe284725c69` | 본 handoff·`adr/0005` decision status 표·v0.3 해소 반영이 모두 포함된 커밋(완전 재현). v0.3 정본 base pin은 §1의 `4940e1a`로 별도 유지 |
| 작성일 | 2026-06-05 | |
| 근거 ADR | `adr/0005-topic-naming.md` | D-4 승격 ADR |

## 2. 근거 경로 (읽기 전용 참조)

- `docs/phase1/checklist.md` (commit edd892c) — 이 파일의 원본(이관 대상)
- `docs/phase1/ROADMAP_PHASE1_v0_3.md` — 해소 반영 대상(§3.1·§17·§18·§19)
- `adr/0005-topic-naming.md` — decision status 표 추가 대상
- `handoff/phase1-000-roadmap-normalization.md` — Pass 1(pin 8d7a076 요구 line 192 / command-topic 간접귀속 line 122)
- `docs/통합본_v0_9.md` §8.3 ADR#4(결정 컬럼 "동일 + zone 단위 토픽 routing")

## 3. 배경 / 목표

`docs/phase1/checklist.md`(문서 정합성 체크리스트)의 항목을 사람이 검토·결정했다(2026-06-05). 본 handoff는 그 해소 결과를 반영하고, 원 checklist를 정본 트리(`docs/phase1/`) 밖으로 이관해 grep 기반 codex-gate가 과거 회고 문구에 재반응하지 않게 한다. 또한 v0.3 §18/§19에서 축약된 상세 gate-round 이력을 부록으로 원문 보존(provenance)한다.

**사람 결정 (2026-06-05)**: checklist 1.2(command-topic routing의 ADR 귀속)는 D-5로 환원하지 않고 "확정 귀속(통합본 §8.3 ADR#4 결정 컬럼 직접 도출, 사실)"으로 비준한다.

---

## 4. 체크리스트 해소 결과

대상 문서(원본 §대상 문서 목록):
- `docs/phase1/ROADMAP_PHASE1_v0_3.md`
- `docs/phase1/ROADMAP_PHASE1_draft_v0_2.md`
- `handoff/phase1-000-roadmap-normalization.md`
- `handoff/phase1-001-envelope-scope.md`
- `adr/0005-topic-naming.md`
- `docs/통합본_v0_9.md`
- `docs/kafka-payloads.md`
- `docs/envelope.md`
- `HANDOFF.md`

### 4.1 우선 수정 항목

- [x] **1.1 `ROADMAP_PHASE1_v0_3.md` 기준 commit pin 정합화**
  - 현재: `4940e1a115b911e452f96f0083f1c4dc6ede879f` / Pass 1 요구: `8d7a07668eb7d1d7db375fe2342d90f174bdfc49`.
  - **처리 결과**: v0.3 §18에 pin 결정 이력 기록 — Pass-1이 `8d7a076`을 요구했으나 사용자가 Pass-2에서 현 정본 `4940e1a`로 결정(Pass-1 산출물 포함, 더 정확). 의도적 변경, §1 헤더 pin은 `4940e1a` 유지.

- [x] **1.2 `command-topic` zone routing의 ADR 귀속 확정**
  - 현재 v0.3: ADR#4 확정 귀속, D-5 제외 / Pass 1: ADR#4 간접 귀속 후보 `[결정 필요]`.
  - **처리 결과**: 사람 비준 2026-06-05 — 통합본 §8.3 ADR#4 결정 컬럼이 "동일 + zone 단위 토픽 routing"을 직접 포함하므로 ADR#4 **확정 귀속**으로 비준(추측 아닌 §8.3 직접 도출). D-5로 환원하지 않음. v0.3 §3.1 항목11 주·§17 D-5 정정 주에 비준 1줄 추가.

- [x] **1.3 `phase1-001-envelope-scope.md` 기준 commit과 참조 ADR 재현성 정리**
  - 현재 기준 commit: `f6697ac840d8f498974c5bb8d14038f93de7fbb3` / 문제: 같은 문서가 `adr/0005`를 근거 참조하나 ADR은 다음 커밋에서 추가됨.
  - **처리 결과**: phase1-001 기준 commit을 `adr/0005`가 포함된 `bed89c4`로 승급(meta 처리). 재현성 확보.

- [x] **1.4 `adr/0005-topic-naming.md` 부분 결정 구조 명확화**
  - 현재 ADR 상태: `Proposed` / 사용 방식: D-4(2)=RESOLVED, D-4(1)=비준 대기.
  - **처리 결과**: adr/0005 상단(상태줄 근처)에 decision status 표 추가 — D-4(2)=Accepted/Resolved(2026-06-04), D-4(1)=Proposed(비준 대기). 헤더 Status 줄을 "전체 Proposed / 부분 D-4(2)만 Resolved"로 정합 조정. §0~§6 본문 보존.

- [~] **1.5 D-9 해소 결정의 독립 근거 보강**
  - 현재 ROADMAP: D-9를 2026-06-03 사람 결정으로 RESOLVED 처리 / Pass 1: D-9는 추측 금지 결정 필요 항목.
  - **처리 결과(부분)**: D-9 해소 근거·결정자(human, 2026-06-03)·정본 근거(§6.9.3 (다) Phase 1 표 + §6.9.5 토픽표)는 v0.3 §17 D-9 항목 + adr/0005 §0에 이미 존재한다. 별도 decision-log 중앙화는 후속(우선순위 낮음).

### 4.2 문서 구조 개선 항목

- [x] **2.1 v0.3 변경 이력 축약**
  - **처리 결과**: v0.3 §18/§19를 "버전별 현재 상태 1줄 요약 + pin/비준 이력 주"로 축약. 과거 gate-round 상세(gate-1~9, round-2 CRITICAL·sweep·SPEC 3~5, D-9·gate 3차/4차·D-4 결정 매핑 표)는 삭제하지 않고 본 handoff §5 부록으로 이관(원문 보존). v0.3 본문에는 "상세는 `handoff/phase1-000b-consistency-checklist.md` 부록 참조" 포인터 1줄만 남김. 본문 stale grep-bait(과거 `[결정 필요](D-9)` 회고, 나열식 회고 매핑) 정리, 단 현재 유효한 미결(D-1/D-2/D-4(1)/D-5/D-8)·통합본 Open(§A/§C/§J) 표기는 보존. 원 `docs/phase1/checklist.md`는 정본 트리 밖(본 handoff)으로 이동(meta가 git rm 처리).

- [~] **2.2 D-목록 번호 정책 확인**
  - **처리 결과(확인)**: v0.3 §17 유지(D-목록=§17, §14=Track 5의 자기참조 정정은 v0.3에 이미 반영). `handoff/phase1-000`의 "§14" 언급은 draft 스캔 맥락(draft v0.2의 자기참조 오류를 가리키는 회고)이라 비이슈 — 정정 자체는 v0.3 §0/§17에 반영됨.

- [x] **2.3 `통합본 우선`과 `코드 우선` 위상 문구 분리**
  - **처리 결과(확인)**: v0.3 line 5("문서 위상 우선순위" 주)에 "통합본 우선=사실 주장에만, 계획 레이어는 ROADMAP 고유 판단"으로 위상 분리가 이미 반영됨. Phase 0 회귀=코드/데모 spec 우선, Phase 1 목표 사실 충돌=통합본 우선.

### 4.3 현재 양호한 반영 사항 (원본 §3 — 유지)

- [x] status 단일값 문제 정리됨(`DONE (heartbeat marshalling only)` → `DONE` + 비고 분리).
- [x] D-9/D-4 경계 명확화(alert/notification 토픽 신설 여부 ↔ 명명 규칙 분리, D-4(2)=envelope-first 해소 / D-4(1)=`adr/0005` 비준 대기).
- [x] 8토픽 계약 매트릭스를 목표 계약 spec 렌즈로 정리.
- [x] ADR#2 범위를 heartbeat marshalling only로 분리.

---

## 5. 부록 — v0.3 §18/§19에서 이관한 상세 gate-round 이력 (원문 보존)

> **출처**: `docs/phase1/ROADMAP_PHASE1_v0_3.md` §18 변경 이력(v0.3 차수별 행)·§19 변경 요약 표에서 2026-06-05 이관. provenance 보존을 위해 원문 그대로 수용한다. 회고성 매핑이며 현재 상태는 v0.3 본문(§17 D-목록)이 정본이다.

### 5.1 §18에서 이관한 v0.3 차수별 변경 이력 (원문)

| 버전 | 변경 |
|---|---|
| **v0.3 (정본 후보)** | **Pass 1 normalization 반영**: ① source_ref drift-1~4 정정(§7.2.6/§7.2.4=§13_open §C cross-ref, §11→§13_open §J, ADR#13 표현, HANDOFF 절 지정) ② ADR#6/#16/#18 TODO→PARTIAL(N-4) ③ ADR#2 DONE(heartbeat marshalling only) 명시(C-3) ④ T4-3 Phase 1 잔여/후속 분리(C-4) ⑤ T2-4 TODO→DECISION_REQUIRED 강등 + T4-1/T0-2 blocked_by 종속(C-2/D-9) ⑥ 8토픽 계약 매트릭스 §7 신설(C-1) ⑦ DoD-1에 18-ADR 판정 매트릭스 임베드(S-2/N-5) ⑧ source_ref ADR/통합본 조항 병기(S-1/S-3/S-4) ⑨ D-9 신규 + D-목록 갱신 |
| **v0.3 (codex-gate 1차 반영)** | **codex-gate FAIL 9건 정정 (내부 일관성/status 정규화/자기참조)**: ① §5 DoD-1을 "Phase 1 완료 조건"→"ADR 18개 **판정 완료** 조건"으로 명확화, TODO/DECISION_REQUIRED=진행 중 추적 상태로 분리 서술(S-2/N-5 재정정) ② §7 alert/notification 셀을 확정 표기→`[결정 필요](D-9)` 잠정화(ADR#5/D-9 선결정 흔적 제거) ③ §13 T4-3 status `PARTIAL(잔여)/후속`→단일 허용값 `DEFERRED` 정규화(§6 위반 해소) ④ §14↔§17 자기참조 정정(D-목록=§17, §14=Track 5) ⑤ §7 미정 셀에 `[결정 필요]` 직접 박음(선언↔표현 일치) ⑥ §5.1·§14에 ADR 전체 렌즈 vs Phase 1 작업 렌즈 구분 주석(ADR#13 Phase 1 무작업→Track 5 근거) ⑦+⑧ T1-4·T3-9 동일 위상 일관화(둘 다 §6.9(나) Phase 1 확정 정정 + ADR 귀속만 D-5 → status=TODO, T3-9 DECISION_REQUIRED→TODO) ⑨ §17 D-5↔§13 T4-3 충돌 정리(command routing은 §8.3 ADR#4 결정 컬럼 직접 포함→ADR#4 확정 귀속, D-5에서 제외) |
| **v0.3 (codex-gate 2차 반영)** | **codex-gate 2차 FAIL(critical 2 + spec 4) 정정 (내부 일관성/status 단일값/확정↔미정 분리)**: ① **CRITICAL 1+2** — §3.1 #2 / §5.1 #2 / §14 T5-2 status `DONE (heartbeat marshalling only)` → 단일값 `DONE`, 범위 한정은 비고/acceptance_evidence로 분리(§6 단일값 규칙 위반 해소, DoD-1 최종 판정 집합에 ADR#2 깔끔히 DONE) ② **status 전수 sweep** — §5 DoD 표에 "비고" 열 추가, DoD-1/DoD-4/DoD-6 status 셀의 괄호 수식어를 비고로 분리(status 셀=단일 허용값) ③ **SPEC 3** — §7 result-topic-job/log 행을 "(분리 전제 — 확정=D-4/D-5)" 라벨로 명확화 ④ **SPEC 4** — §7 alert/notification 매트릭스 셀을 `[결정 필요] (D-9)`만 남기고 잠정 규칙(envelope 4종·key 잠정값)을 §7.1로 이동("아직 결정 아님" 라벨) ⑤ **SPEC 5** — §3·§11·§12·§17 D-9에 "서비스 구현(Phase 1 확정) ↔ 전용 Kafka 토픽 신설(D-9 미결)은 별개 결정" 경계 주석 추가. D-9·D-4·통합본 Open(§A/§C/§J) 보존, §1 commit pin 유지 |
| **v0.3 (D-9 결정 반영 + gate 3차)** | **D-9=A(Phase 1 확정) 사람 결정(2026-06-03) 반영 + codex-gate 잔여 지적(D-9 계열 4건) 해소**: ① **§17 D-9를 RESOLVED 처리** — alert/notification 토픽은 Phase 1 확정(통합본 §6.9.3 (다) Phase 1 표 + §6.9.5 토픽표), 명명 규칙·result 분리 시점은 D-4. 결정 근거·날짜(2026-06-03) 명시, 미결 목록에서 닫음 ② **§7 매트릭스 alert/notification 행 확정 spec화** — `[결정 필요](D-9)` 제거, envelope 4종 적용 + key rule(alert=`(rule_id,target_id)`/notification=`incident_id`, §6.9.5 확정) 박음. §7.1 "신설 확정 시 잠정 규칙 — 아직 결정 아님" 항목 제거 ③ **§7 result-topic 행 정정(gate spec #3)** — "분리 전제" → "분리=Phase 1 확정(§6.9.2 항목1), envelope/key 확정, 최종 명명 규칙만 D-4"로 확정분/D-4 종속분 경계 명확화 ④ **Track 의존 정상화** — T2-4(alert/notification 토픽 추가) DECISION_REQUIRED→TODO, T4-2(result 분리) DECISION_REQUIRED→TODO, blocked_by에서 D-9 제거(T2-6/T3-1 의존은 전용 토픽 경로 선행으로 유지) ⑤ **§3/§11/§12 경계 주석 갱신** — "전용 토픽 신설 D-9 미결" → "alert/notification 토픽은 Phase 1 확정(§6.9.3); ADR#5는 명명 규칙만 결정(D-4)". D-1/D-2/D-4/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |
| **v0.3 (gate 4차 — §7 계약렌즈/D-4 정정)** | **codex-gate 4차 FAIL(critical 2 + spec 4) 정정 — 지적이 "§7 매트릭스가 *목표 계약 spec*인지 *Phase 1 구현 상태*인지 분리 안 됨" 하나의 뿌리로 수렴**: ① **critical 1 + spec 3·4** — §7 머리에 **렌즈 선언** 추가("이 매트릭스는 *목표 계약 spec*(출처: kafka-payloads.md + envelope.md). 각 셀은 토픽 *계약*을 기술하며 Phase 1 구현 시점·완료 상태가 아님 — 구현 상태는 Track 표가 추적"). 3렌즈(§5.1 ADR 판정 / Track 작업 진행 / §7 계약 spec) 구분 명시 ② **토픽 명명 종속 셀 마커** — `command-topic-{zone}` zone suffix / `result-topic-job`·`result-topic-log`·`alert-topic`·`notification-topic`의 토픽 *이름*에 "(토픽명/zone suffix 명명 규칙 = ADR#5/D-4 종속, 현재 kafka-payloads 이름은 잠정)" 마커. 계약 내용(envelope·key=확정) ↔ 최종 이름(D-4 종속)을 셀 단위 분리. §7 선언과 표 정합(미정=명명 규칙뿐) ③ **critical 2 — §17 D-4 문구 정정** — D-4에서 "result 분리 *시점*" 제거(분리 자체=§6.9.2 항목1 Phase 1 확정), D-4를 "토픽 *명명 규칙* + 토픽 재구조 *실행 선후*"로 좁힘. §13 T4-1/T4-2·§7 result 행 문구 일치 ④ **spec 5 — DoD-1↔§5.1 관계 명확화** — §5/§5.1 머리에 "TODO ADR(#5/#7/#8/#9/#10/#11/#15)=최종 판정 전 진행 중 상태, Phase 1 완료 시 최종 판정으로 닫혀야 DoD-1 충족. IN_PROGRESS=판정 진행 중" 한 줄 고정 ⑤ **spec 6 — §16↔Track 표 위상** — 토픽 handoff 2건(T2-4→`phase1-023`, T4-2→`phase1-041`)을 §16 우선 슬라이스 목록에 추가 + "Track 표가 전체 handoff 추적, §16은 대표 슬라이스" 생략 기준 보강. status 전수 sweep 유지(§6 8값 단일). D-1/D-2/D-4/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |
| **v0.3 (D-4 결정 반영 2026-06-04)** | **D-4 결정 반영(D-4(2) RESOLVED envelope-first / D-4(1) ADR#5 `adr/0005`로 승격, 이름 잠정 유지)**: ① **§17 D-4를 둘로 분리** — D-4(2) 실행 선후 = RESOLVED(2026-06-04, envelope 먼저 Track 0 → Track 4, 근거 `adr/0005` §2.1: envelope은 헤더라 토픽명 독립) / D-4(1) 구체 명명 컨벤션 = `adr/0005-topic-naming.md`로 승격, 비준 대기(명명 *원칙*은 통합본 §4.4.1·§8.3 ADR#5 확정, 구체 컨벤션만 결정 대기 — 토픽 최종 이름 동결 금지) ② **§9 Track 0 머리** — "선후 DECISION_REQUIRED" → "D-4(2) RESOLVED envelope 먼저" ③ **§13 T0-1/T0-2** status DECISION_REQUIRED → DONE(T0-2 결정=envelope 먼저), handoff `phase1-001-envelope-scope.md` 작성됨 ④ **§13 T4-1** status DECISION_REQUIRED → BLOCKED(blocked_by=`adr/0005` 비준), envelope-first 선후 반영. T4-2 blocked_by/비고 D-4(1)/(2) 분리 ⑤ **§7 매트릭스 셀 마커** — "ADR#5/D-4 종속, 잠정" → "ADR#5(`adr/0005`) 비준 대기, 잠정"으로 전수 일관화(command zone suffix/result-job/result-log/alert/notification + §7 머리·8토픽 줄·§7.1) ⑥ **§3/§5.1/§11/§12 경계 주석** D-4를 D-4(1)/D-4(2)로 분기 표기 ⑦ **§16** phase1-001 "작성됨", `adr/0005` 신설 반영(순서 11). D-1/D-2/D-4(1)/D-5/D-8 및 통합본 Open(§A/§C/§J) 보존, §1 commit pin(`4940e1a`) 유지 |

### 5.2 §19에서 이관한 v0.2 → v0.3 변경 요약 표 (원문)

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

> (원문 종결 문단) 모든 사실 정정(N-1~N-4, C-3, C-4, S-1·S-3·S-4) 및 codex-gate 1차 반영(gate-1~9), 2차 반영(round-2 CRITICAL 1+2 / sweep / SPEC 3~5), D-9 결정 반영(gate 3차), gate 4차 정정(§7 계약렌즈/D-4/DoD-1 관계/§16 위상), D-4 결정 반영(2026-06-04)은 v0.3에 적용 완료. 남은 결정 필요는 §17 D-1~D-8(D-4(2)·D-9는 RESOLVED, D-4(1)은 `adr/0005` 비준 대기)로 집약했으며, 통합본 미결 Open(§A/§C/§J) 및 정정 귀속(D-5)·구체 명명 컨벤션(D-4(1))은 추측 금지 대상으로 보존한다(토픽 최종 이름 동결 금지). §1 기준 commit pin(`4940e1a`)은 유지한다.

### 5.3 2026-06-05 추가 결정 (본 handoff에서 반영)

- **command-topic routing 귀속 비준 (사람, 2026-06-05)**: §3.1 항목11을 ADR#4 확정 귀속으로 비준(통합본 §8.3 결정 컬럼 직접 도출, 사실). D-5로 환원하지 않음. v0.3 §3.1 항목11 주·§17 D-5 정정 주·§18 이력 주에 반영.
- **기준 commit pin 결정 이력 기록**: Pass-1 요구(`8d7a076`) → Pass-2 사용자 결정(`4940e1a`, 더 정확) 의도적 변경, v0.3 §18에 기록.

---

## 6. 처리 상태 / 다음 단계

- 본 handoff 작성으로 checklist 1.1·1.2·1.4·2.1 = 해소(`[x]`), 1.5·2.2 = 부분/확인(`[~]`), 1.3 = meta 처리 완료(`[x]`), 2.3 = 기존 반영 확인(`[x]`).
- 구 `docs/phase1/checklist.md`는 meta 세션이 `git rm`으로 정본 트리 밖으로 제거한다(본 handoff가 이관본).
- 잔여 후속(낮음): 1.5 D-9 decision-log 중앙화.

# 식별자(ID) 읽는 법 — ID-GLOSSARY

> **성격**: 이 문서는 monitoring-meta 문서들에 나오는 식별자(ID)를 읽는 법을 안내하는 **범례(descriptive)** 다. 규범이 아니다 — 각 ID의 내용·결정은 통합본/ROADMAP/adr이 기준이다.
> **신규 ID 규칙(2026-06-11 결정)**: 새로 만드는 운영·계획 ID는 **T / D / ADR 3종만** 허용한다. 폐지된 패밀리(G, DoD, N/C/S/drift, P/X/M)는 새로 만들지 않는다.
> **이름 우선(name-first) 표기 규칙(2026-06-11 결정)**: 문장·요약·목록에서 **ID를 단독 주어로 쓰지 않는다 — 항상 `이름(ID)` 꼴**로 쓴다(예: "T4-2 착수" ✗ → "result-topic 분리(T4-2) 착수" ○). 사람은 이름으로 읽고, ID는 교차참조 앵커일 뿐이다. 표에서는 ID 열과 항목(이름) 열을 병행하므로 그대로 둔다.
> 관련 결정 기록: `handoff/id-cleanup/id-cleanup-000-impact.md`

## 1. 본표 — 패밀리별 안내

| 패밀리 | 뜻 | 정의 위치 | 현재성 | 수정 가능 | 신규 생성 | 예시 |
|---|---|---|---|---|---|---|
| **T-n** (T0~T5) | **해야 할 작업**(Track 작업 항목). 앞 숫자는 영역 묶음(Track 0=envelope, 1=기반, 2=코어 도메인, 3=통보·검증·UI, 4=토픽 재구조, 5=무작업)이고 별개 패밀리가 아니다. 상태값은 **ROADMAP §6 허용 8값**(TODO/IN_PROGRESS/DONE/NO-OP/PARTIAL/DEFERRED/BLOCKED/DECISION_REQUIRED)을 따른다 | ROADMAP §9~§14 | 운영 | 가능 | 가능 | `T4-2` = Track 4의 2번 작업 |
| **D-n** | **사람이 정할 결정**. 미결로 시작해 사람 승인 시 본문에 **RESOLVED**로 기록(게이트 운영 status 열은 ROADMAP §6 값). 통합본 Open 연계 항목은 추측 금지 | ROADMAP §17 (D-목록) | 운영 | 가능 | 가능 | `D-2` = β/γ 모듈 분리 결정 |
| **ADR#n / ADR-NNNN** | **확정 결정의 기록 파일**(업계 표준 Architecture Decision Record) | `adr/NNNN-*.md` + 통합본 §8.3 | 운영 | ADR 절차로만 | 가능 | `ADR#5` = `adr/0005-topic-naming.md` |
| **CP-n** | 임계 경로(critical path) 분석 라벨 | `handoff/decisions/phase1-critical-path-analysis.md` | 운영(분석 자산) | 분석 갱신 시 | 분석 문서 안에서만 | `CP-1` |
| ~~**G-n**~~ | (폐지) 게이트 → **D로 흡수**(2026-06-11). 게이트 운영 정보는 §17의 gate_type/status/next_action 열 | 구 ROADMAP §8 | 잔재(폐지) | 불가 | **금지** | `G-2` → `D-2` |
| ~~**DoD-n**~~ | (폐지) Phase 1 완료 조건 → **"§5 완료 조건 N"** 으로 표기(번호 1~7 보존) | 구 ROADMAP §5 | 잔재(폐지) | 불가 | **금지** | `DoD-4` → "§5 완료 조건 4" |
| ~~**N-n / C-n / S-n / drift-n / "Pass 1"**~~ | (폐지) v0.2→v0.3 리뷰 공정의 지적 추적 ID(normalization/consistency/source_ref/drift 지적). 현재 독자에게 추적 가치 없음 — 본문에서 제거, 이력은 §18~19와 부록 checklist가 보유 | 구 `handoff/phase1-000/phase1-000b-consistency-checklist.md` | 잔재(폐지) | 불가 | **금지** | `N-4`, `C-1`, `S-2` |
| ~~**P-n / X-n / M-n**~~ | (폐지) T1-1 일회성 슬라이스 ID → 의미어로 풀어씀 | 구 `handoff/phase1-050/phase1-050-t1-1-datastore-slice.md` | 잔재(폐지) | 불가 | **금지** | `P-1` → "인프라 기동 슬라이스" |
| **A-1 / B-1 / C-1 (ADR 내부)** | **각 ADR 본문 안에서만 쓰는 결정 옵션 식별자**. 폐지된 리뷰 ID C-n과 글자만 같고 무관(동음이의 — §3 경고) | 각 ADR 본문 (예: `adr/0002`) | 운영(ADR-local) | ADR 절차로만 | ADR 내부에서만 | ADR-0002의 `C-1` = 컷오버 결정 |
| **β / γ** | 배포 형태 라벨. **β = 모듈러 모놀리스 + 메시지 처리 분리 / γ = 풀 MSA**. 미결(D-2, 통합본 §13_open §C) — 항상 의미를 병기해 쓴다 | 통합본 §13_open §C / 05 §7.2 | 운영(라벨, 보존 예외) | 통합본 개정으로만 | — | "β(모듈러 모놀리스) 유지 vs γ(풀 MSA) 전환" |
| **§A~§J** | 통합본 Open Questions(미결 보류 사안) 카테고리 라벨 | 통합본 §13_open | 운영(보존 예외) | 통합본 개정으로만 | 통합본 개정으로만 | `§C` = 모듈 분리, `§A` = zone topology, `§J` = AMS 가정 |

## 2. 부록 — 신구 매핑·해독표 (옛 문서·스냅샷 읽기용)

과거 스냅샷(`ROADMAP_PHASE1_draft_v0_2.md`, `e2e/results/*`, 기존 `handoff/*`, proposal-review JSON, git 이력)은 읽기 전용 보존이라 옛 ID가 그대로 남아 있다. 아래 표로 해독한다.

### 부록 A — G-n → 흡수 매핑

| 구 ID | 흡수처 | 사안 |
|---|---|---|
| G-1 | **D-1** | AMS 분석 가정 검증 (통합본 §13_open §J) |
| G-2 | **D-2** | β(모듈러 모놀리스) vs γ(풀 MSA) 모듈 분리 협의 (§C) |
| G-3 | **D-8** | 사이트별 운영 정보 입수 (§A) |
| G-4 | **D-7** | harness + plugin 검증 |
| G-5 | **§5 완료 조건 7** (비고) | source_ref drift 검증 — codex-gate/analyzer 상시 공정 |

### 부록 B — DoD-n → §5 완료 조건 N

DoD-1~DoD-7 → "§5 완료 조건 1"~"§5 완료 조건 7" (번호 그대로 보존).

### 부록 C — 잔재 리뷰 ID 해독 (draft_v0_2·부록 checklist를 읽을 때)

| 구 ID | 뜻 |
|---|---|
| N-1~N-5 | normalization(정규화) 지적 |
| C-1~C-4 | consistency(일관성) 지적 |
| S-1~S-4 | source_ref(출처 인용) 지적 |
| drift-1~4 | source_ref drift(문서 간 어긋남) 지적 |
| "Pass 1" | analyzer normalization 검증 단계(v0.2→v0.3) |

상세 provenance: `handoff/phase1-000/phase1-000b-consistency-checklist.md`.

### 부록 D — 일회성 슬라이스 해독 (T1-1 기록을 읽을 때)

| 구 ID | 뜻 |
|---|---|
| P-1~P-4 | T1-1 인프라 기동·운영골격·연결·smoke 슬라이스 |
| X-1~X-4 | T1-1 잔여 도메인 영속 슬라이스(repository·DDL·트랜잭션 경계·owner_repo) — D-2 후 |
| M-1 | PG 스키마 마이그레이션 항목 (T1-1 out-of-scope) |

### 부록 E — 동음이의 경고 ⚠

**ADR 내부 옵션 식별자 `A-1`/`B-1`/`C-1`(예: ADR-0002의 C-1=컷오버 결정)은 폐지된 리뷰 ID C-n과 무관하다.** `docs/features/heartbeat-collection.md`·`e2e/run-e2e.sh` 주석·Kafka 컨테이너 스레드명(`...-C-1`)에 나오는 것들이 이쪽이다. **일괄 치환 금지.**

## 3. 변경 이력

- 2026-06-11 — 신설. ID 패밀리 12종+ → 운영 3종(T/D/ADR) 단순화 결정 반영(`handoff/id-cleanup/id-cleanup-000-impact.md`).

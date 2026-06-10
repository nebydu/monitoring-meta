# T1-1 영속 저장소 — D-2-무관 슬라이스 정의 (scoping)

> **성격**: 이 문서는 **scoping/정의 문서**다 — 실제 repo handoff(`phase1-050-{repo}.md`)가 아니다. T1-1(영속 저장소, critical path CP-1 뿌리, fan-out 1위, READY) 중 **D-2(β 모듈러 모놀리스 vs γ 풀 MSA)가 바꾸지 않는 부분만** 잘라, 지금 분배 가능한 슬라이스를 확정한다. 슬라이스 확정 후 repo별 handoff는 사람이 별도 작성(또는 후속).
>
> **입력 source of truth**: `docs/phase1/ROADMAP_PHASE1_v0_3.md` §10 T1-1(line 281) / §17 D-2(line 429)·D-3 / `docs/통합본_v0_9.md` §4.2.2 저장소(line 596~598)·§4.2.4(line 610)·§6.x 데이터스토어 언급·§7.2 모듈 분리 정책(line 1976~1995) / `handoff/decisions/phase1-critical-path-analysis.md` §3.2·§4·§6.
>
> **기준 monitoring-meta commit**: `4940e1a115b911e452f96f0083f1c4dc6ede879f`
> **작성일**: 2026-06-07 · **근거 ADR**: `통합본 §8.3 ADR#12`(영속 저장소)

---

## 0. 왜 슬라이스가 필요한가

- T1-1은 critical path CP-1의 뿌리이자 T1-2/T1-4/T2-2/T2-8/T3-5의 공통 선행(critical-path 분석 §4·§5 fan-out 1위)이다. **지금 시작해야 CP-1 전체가 풀린다.**
- 그러나 T1-1 blocked_by = "site 정보 일부(G-3), infra 결정"(§10)이고, 앱 계층 영속 구조는 **D-2(통합본 §13_open §C 미결 Open)** 가 reshape할 수 있다.
- 따라서 T1-1을 **(A) D-2·G-3 무관 = 지금 착수** / **(B) D-2 의존 = 보류** / **(C) 경계 모호 = 사람 확인** 으로 나눈다. (A)만 이 슬라이스로 분배한다.
- **핵심 판단**: 데이터스토어 *엔진/프로비저닝/연결 계층*은 β든 γ든 동일하다(통합본 line 165 "Zone 내부 자체 운영 — Kafka/PG/OpenSearch/Redis/VM/MinIO 모두 self-host"). 모듈 분리(β/γ)가 바꾸는 것은 *어느 deployment가 어느 스키마/도메인을 소유하는가*(앱 계층)이지, *PG/Redis/MinIO/OpenSearch 인스턴스가 존재하는가*가 아니다.

---

## 1. 포함 — D-2 무관, 지금 착수 (슬라이스 본체)

> 데이터스토어 4종(PostgreSQL / OpenSearch / Redis / MinIO)의 **프로비저닝·부트스트랩·연결 계층**. VictoriaMetrics는 통합본상 Phase 2(§8.3 ADR#12 "VM(Phase 2)")이므로 이 슬라이스에서 제외.

| # | 포함 항목 | 왜 β/γ 어느 쪽이든 동일한가 | source_ref |
|---|---|---|---|
| P-1 | **컨테이너/인스턴스 프로비저닝** — PG/OpenSearch/Redis/MinIO self-host 컨테이너 기동, 버전 고정, 볼륨/영속 설정 | 모듈 분리는 *앱 deployment* 수를 바꿀 뿐, 데이터스토어 인스턴스는 β·γ 공통 self-host(통합본 line 165, line 244). | `통합본 §8.3 ADR#12`, line 165/244 |
| P-2 | **HA/기본 운영 설정** — PG HA, OpenSearch 인덱스 템플릿+ILM 골격, Redis(캐시 용도만, blpop 폐기), MinIO 버킷 정책+접근 제어 골격 | 인프라 계층 운영 정책은 앱 모듈 경계와 독립. ILM/버킷 정책은 데이터 성격(로그/파일)에 묶이지 β/γ에 안 묶임. | line 596~598, 728/731 |
| P-3 | **접속/연결 설정(클라이언트 config)** — hub(및 필요 시 script-agent)의 PG JDBC·OpenSearch·Redis·MinIO 엔드포인트/credential/풀 설정. JDBC 표준 + 다중 DB 지원 골격 | 연결 문자열·드라이버·풀은 "어느 모듈이 쓰는가"와 무관하게 동일 엔진을 가리킨다. β(단일 BE)든 γ(다중 서비스)든 같은 PG/Redis를 향함. | line 688 "JDBC 표준 + 다중 DB 지원" |
| P-4 | **연결 smoke 검증** — 각 스토어 기동→hub에서 연결/ping/기본 read-write 왕복 확인(스키마 무관 수준) | 연결 가능성 검증은 스토어 존재 여부 확인이지 도메인 구조와 무관. | §10 T1-1 acceptance "smoke/e2e" |

**이 슬라이스의 한 줄 정의**: "PG/OpenSearch/Redis/MinIO 4종을 self-host로 띄우고, hub가 연결되며, 빈 상태에서 기동 smoke가 통과하는 데까지." — 도메인 스키마/repository 배치는 건드리지 않는다.

---

## 2. 제외 — D-2 의존, 보류

| # | 제외 항목 | 왜 D-2(β/γ)에 의존하는가 | source_ref |
|---|---|---|---|
| X-1 | **repository/DAO 배치 + 모듈 경계** — 어느 deployment가 어느 도메인 영속을 소유하는가 | β=메인 BE 1개가 다수 도메인 repository 보유 vs γ=서비스별 분산. 배치가 정반대(§7.2 (β) 구성 line 1980 ↔ (γ) MSA). | `통합본 §7.2`, line 1976~1995 |
| X-2 | **트랜잭션 경계** — 도메인 간 트랜잭션이 in-process(β) vs 분산/saga(γ) | β는 단일 프로세스 로컬 트랜잭션 가능, γ는 서비스 경계 넘는 분산 일관성 필요. D-2가 직접 결정. | `통합본 §7.2` |
| X-3 | **도메인 모델 영속 매핑** — alert/incident/job/user 등 엔티티의 PG 도메인 배치, OpenSearch 인덱스 소유권 | 통합본 §6.x가 PG를 "alert 도메인/incident 도메인/job 도메인"으로 도메인별 언급(line 1368/1373/1202). 어느 deployment가 이 도메인을 소유하는지는 D-2 결과에 종속. | line 1202/1368/1373/1467 |
| X-4 | **owner_repo 최종 확정** — T1-1 산출물 중 X-1~X-3에 해당하는 부분의 repo 귀속 | §17 D-6 "β/γ 결과에 의존되는 항목은 D-2 후". 앱 계층 영속 코드의 repo 배치는 D-2→D-6 순. | §17 D-6, line 435 |

---

## 3. 경계 모호 — 단정 불가, 사람 확인 필요 (CLAUDE.md §2)

> 아래는 "지금 착수"와 "D-2 보류" 사이 경계라 analyzer가 추측으로 단정하지 않는다. **사람 확인 대기.**

| # | 모호 항목 | 무엇이 모호한가 | 통합본 근거 |
|---|---|---|---|
| M-1 | **PG 스키마 레이아웃 — 단일 prefix vs 도메인별 스키마 분리** | 통합본 §4.2.4 line 610에 **`단일 prefix 또는 도메인별 스키마 분리 [Open, 7장]`** 으로 `[Open]` 명시. 또 §4.2.2 line 596 "서비스별 스키마 분리". 스키마를 *도메인별로 분리*하면 그 경계가 D-2(모듈 경계)와 정렬될 수 있어, 스키마 부트스트랩을 지금 박으면 D-2 결과와 어긋날 위험. → **`[Open]`이므로 추측 금지, 사람 확인.** | `통합본 §4.2.4` line 610 **[Open, 7장]**, line 596 |
| M-2 | **스키마 부트스트랩 범위** — P-1~P-4(연결 계층)는 무관하나, *실제 테이블/인덱스 DDL*을 어디까지 지금 만드는가 | "빈 DB 기동"(P-1)은 안전하나, 도메인 테이블 DDL은 X-3(도메인 모델)·M-1(스키마 분리)에 얽힘. "어느 수준까지의 부트스트랩이 D-2 무관인가"는 M-1 해소에 의존. | M-1 종속 |
| M-3 | **site 정보 일부(G-3) 의존분** — T1-1 blocked_by에 "site 정보 일부(G-3)" 존재 | PG/Redis/MinIO core는 site-중립(critical-path 분석 §3.2)이나, site별 노드 sizing/topology가 프로비저닝 규모에 영향 가능. site-의존분은 **D-8/G-3(통합본 §A 미결 Open)** 대상이라 추측 금지. 슬라이스는 site-중립 core로 한정. | §10 T1-1 blocked_by, `통합본 §13_open §A` |

---

## 4. 분배 메타 (슬라이스 확정 후 repo handoff 작성 시 입력)

| 필드 | 값 | 비고 |
|---|---|---|
| owner repo | **infra 중심** (P-1·P-2 프로비저닝) + **hub** (P-3·P-4 연결 설정·smoke) | §10 T1-1 owner = "infra, hub, monitoring-meta". script-agent는 이 슬라이스에서 영속 클라이언트 보유 근거 약함 → **포함 보류**(통합본상 script-agent는 Kafka 경유, 직접 스토어 접속 항목은 MinIO 스크립트 보관 정도이나 그건 T3-5) |
| 분배 단위 | (1) `phase1-050-infra.md` = P-1/P-2 / (2) `phase1-050-hub.md` = P-3/P-4 | 사람이 슬라이스 승인 후 작성. 본 문서는 "무엇을 분배할지"만 확정 |
| DoD (이 슬라이스) | PG/OpenSearch/Redis/MinIO self-host 기동 + hub 연결 smoke PASS + ILM/버킷 골격 존재 (도메인 스키마/repository 제외) | §10 acceptance "docker/infra config, hub connection config, smoke/e2e"에서 도메인 영속 제외분 |
| e2e 영향 | 현 Phase 0 e2e(PASS 58/0/0)는 in-memory 전제 — 이 슬라이스는 **스토어 기동·연결만** 추가하므로 Phase 0 동작 회귀 없음(데모 spec v0.2.1 무관). 새 smoke는 별도 추가, 기존 메시지 흐름 e2e와 독립 | 데모 spec v0.2.1 회귀 영향 없음 |
| D-3 관계 | D-3(영속·인증 실행순서, 계획 레이어)은 T1-1↔T1-2 *순서*만 정함 — 이 슬라이스(영속 인프라)는 인증과 독립이라 D-3과 병행 가능 | §17 D-3 |

---

## 5. 사람 확인 요청 (슬라이스 확정 전)

1. **M-1 PG 스키마 레이아웃** — 통합본 §4.2.4가 `[Open, 7장]`으로 미결. 이 슬라이스에서 스키마 부트스트랩을 **연결+빈 DB까지만**(도메인 DDL 제외)으로 한정하는 것이 맞는지 확인. (analyzer는 `[Open]`을 추측 해소하지 않음 — CLAUDE.md §2)
2. **M-3 site-의존분 경계** — 프로비저닝 규모(노드 sizing)는 D-8/§A 미결에 걸림. 슬라이스를 site-중립 core로 한정하는 데 동의 여부.
3. **script-agent 포함 여부** — 이 슬라이스에서 script-agent 영속 클라이언트는 제외(근거 약함)로 두는 것이 맞는지.

---

## 6. 결과 보고 스키마

```json
{
  "status": "blocked",
  "outputs": ["handoff/phase1-050/phase1-050-t1-1-datastore-slice.md"],
  "findings": [
    "D-2 무관 슬라이스 = PG/OpenSearch/Redis/MinIO 프로비저닝·연결 계층(P-1~P-4). 데이터스토어 엔진은 β/γ 공통 self-host(통합본 line 165/244)라 모듈 분리와 독립",
    "D-2 의존 보류분 = repository/DAO 배치·모듈 경계·트랜잭션 경계·도메인 영속 매핑(X-1~X-4) + owner_repo는 D-6(D-2 후)",
    "경계 모호 3건(M-1~M-3): PG 스키마 분리는 통합본 §4.2.4 [Open,7장] 미결 — 추측 금지. 슬라이스는 site-중립 core+빈 DB 연결까지로 한정 제안",
    "VictoriaMetrics는 Phase 2(§8.3 ADR#12)라 슬라이스 제외. owner=infra(프로비저닝)+hub(연결/smoke), script-agent 제외 제안",
    "Phase 0 e2e(PASS 58/0/0) 회귀 영향 없음 — 스토어 기동·연결만 추가, 데모 spec v0.2.1 동작 무관"
  ],
  "blockers": [
    "M-1: 통합본 §4.2.4 line 610 '단일 prefix vs 도메인별 스키마 분리 [Open, 7장]' 미결 Open — 스키마 부트스트랩 범위 사람 확인 필요(추측 금지)",
    "M-3: site-의존분이 D-8/통합본 §A 미결에 걸림 — site-중립 core 한정 동의 필요",
    "slice 최종 포함 범위(특히 스키마 부트스트랩 깊이)·script-agent 포함 여부 사람 승인 필요"
  ],
  "next_action": "사람이 §5 3건 확인 → 슬라이스 확정 시 phase1-050-infra.md / phase1-050-hub.md 두 handoff 별도 작성"
}
```

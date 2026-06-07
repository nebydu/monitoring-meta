# 작업 spec — phase1-050-infra (T1-1 영속 D-2-무관 슬라이스: 데이터스토어 프로비저닝)

> 이 handoff는 infra 세션이 받아 실행한다. T1-1(영속 저장소, critical path CP-1 뿌리)의 **D-2-무관 슬라이스 중 infra 몫** = 데이터스토어 4종(PostgreSQL/OpenSearch/Redis/MinIO) self-host 프로비저닝 + 기본 운영 골격(P-1·P-2). **앱 계층 영속 구조(repository/도메인 스키마/모듈 경계)는 D-2 의존이라 이번 범위 밖.** meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-050-infra` (T1-1 슬라이스) |
| 대상 repo | `infra` |
| 기준 monitoring-meta commit | `ec408a8` (실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 근거 | `adr/0005`와 무관 / `통합본 §8.3 ADR#12`(영속 저장소)·§4.2.2 / 슬라이스 정의 `handoff/phase1-050-t1-1-datastore-slice.md` §1 / critical-path 분석 |
| 작성일 | 2026-06-07 |
| 실행 순서 | **1순위** (hub 연결/smoke의 선행 — 스토어가 떠야 hub가 붙는다) |

## 2. 범위 (승인된 슬라이스 경계)

**포함(이번)**: PostgreSQL / OpenSearch / Redis / MinIO **self-host 컨테이너 기동 + 기본 운영 골격**. 빈 상태 기동까지.
**제외(D-2 의존, 보류)**: 도메인 테이블/인덱스 DDL, repository 배치, 모듈 경계, owner_repo 확정(D-6). **VictoriaMetrics**는 Phase 2(§8.3 ADR#12)라 제외.
**site-중립 한정**: 노드 sizing/topology 등 site-의존분은 D-8/§A 미결이라 제외 — 단일 노드 기본 구성으로.

## 3. 변경 목록

### 3.1 P-1 — 컨테이너 프로비저닝 (`docker-compose.yml`)

infra `docker-compose.yml`에 4종 서비스 추가(현재 kafka/zookeeper/otel-collector/kafka-init만 존재):

| 서비스 | 내용 |
|---|---|
| `postgres` | self-host PG, **버전 고정**, 볼륨 영속, 헬스체크, 단일 노드(site-중립) |
| `opensearch` | self-host OpenSearch, 버전 고정, 볼륨, 헬스체크, 단일 노드(보안/discovery 단일노드 설정) |
| `redis` | self-host Redis — **캐시 용도만**(통합본 blpop 폐기 방침), 버전 고정, (영속 필요 시 최소) |
| `minio` | self-host MinIO, 버전 고정, 볼륨, 콘솔/API 포트, 헬스체크 |

### 3.2 P-2 — 기본 운영 골격 (도메인 무관 수준만)

- **PostgreSQL**: 빈 DB + 접속 계정 부트스트랩(연결용). **도메인 스키마/테이블 DDL은 만들지 마라**(M-1 PG 스키마 분리=통합본 §4.2.4 `[Open,7장]` 미결 → 추측 금지).
- **OpenSearch**: 인덱스 **템플릿 + ILM 정책 골격**(로그/데이터 성격 기반의 일반 정책까지만 — 특정 도메인 인덱스 소유권 배치는 제외).
- **Redis**: 캐시 인스턴스 가동까지(키 스페이스 설계는 앱 계층).
- **MinIO**: **버킷 정책 + 접근 제어 골격**(스크립트 보관 등 용도 일반 버킷까지 — 도메인별 객체 배치는 제외).

### 3.3 kafka-init 패턴 참고
기존 `kafka-init`처럼, 필요하면 각 스토어 부트스트랩(빈 DB/버킷/인덱스 템플릿 생성)을 init 컨테이너/스크립트로 둔다. **도메인 DDL 없이** 연결 가능한 빈 상태까지만.

## 4. 적용 결정 (사람 확정 반영)

| 항목 | 결정 |
|---|---|
| 슬라이스 경계 | **연결+빈 DB/버킷/인덱스 템플릿까지** — 도메인 DDL 제외(M-1 [Open] 보류) |
| site | **site-중립 core(단일 노드 기본)** — sizing/topology는 D-8/§A 후 |
| 범위 | PG/OS/Redis/MinIO만, VictoriaMetrics(Phase 2) 제외, script-agent 클라이언트 제외 |

## 5. DoD / 검증

- [ ] `docker compose` 기동 시 postgres/opensearch/redis/minio 4종이 헬스체크 통과로 뜬다(+ 기존 kafka 스택 무영향).
- [ ] 각 스토어 버전 고정·볼륨 영속·단일노드 구성.
- [ ] OS 인덱스 템플릿+ILM 골격 / MinIO 버킷 정책 골격 존재(도메인 인덱스/객체 배치는 없음).
- [ ] **도메인 테이블 DDL·repository·모듈 배치 없음**(D-2 보류분 미포함).
- [ ] 기존 Phase 0 e2e(PASS 58/0/0) 회귀 0 — 스토어 추가는 메시지 흐름과 독립(데모 spec v0.2.1 무관).

## 6. 가드 (공통)

- **동결 데모 spec v0.2.1 수정 금지**(infra엔 보통 없음).
- **도메인 스키마/repository/모듈 경계 금지** — D-2(β/γ) 결정 전이라 재작업 위험. 인프라/연결 계층만.
- **추측 금지**: M-1(PG 스키마 분리 [Open])·site sizing(§A)은 손대지 말고 빈 상태/단일노드로.
- e2e 종단 검증은 meta가 §3.3로 별도(smoke 추가 시 meta e2e-tester가 반영). infra 세션이 직접 e2e 돌리지 않는다.

## 7. 미결정 사안

- 스키마 분리(M-1, 통합본 §4.2.4 [Open,7장])·site sizing(D-8/§A)은 통합본 Open → 이번 슬라이스에서 보류(빈 DB/단일노드). 그 외 본 슬라이스 결정 사항은 없음.

## 8. 결과 보고 스키마

```json
{ "status": "ok | blocked | failed", "outputs": ["변경 파일"], "findings": ["스토어 4종 기동/골격/연결 가능 여부"], "blockers": [], "next_action": "다음 한 줄" }
```

# 작업 spec — phase1-050-infra (T1-1 영속 D-2-무관 슬라이스: 데이터스토어 프로비저닝)

> 이 handoff는 infra 세션이 받아 실행한다. T1-1(영속 저장소, critical path CP-1 뿌리)의 **D-2-무관 슬라이스 중 infra 몫** = 데이터스토어 4종(PostgreSQL/OpenSearch/Redis/MinIO) self-host 프로비저닝 + 기본 운영 골격(P-1·P-2). **앱 계층 영속 구조(repository/도메인 스키마/모듈 경계)는 D-2 의존이라 이번 범위 밖.** meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 0. OUT-OF-SCOPE — 이번 슬라이스 제외 (고정, 손대지 마라)

> 아래는 D-2(β/γ 모듈 분리, 통합본 §13_open §C 미결 Open) 또는 다른 미결 Open에 의존하므로 **이번 슬라이스에서 절대 만들지 않는다.** 지금 박으면 D-2 결과와 어긋나 재작업 위험.

- **도메인 테이블/인덱스 DDL** — 빈 DB/빈 버킷/일반 인덱스 템플릿까지만. 도메인 엔티티 DDL 금지.
- **repository / DAO 배치, 모듈 경계** — 앱 계층(D-2 의존).
- **β/γ 배치 결정** — 어느 deployment가 어느 도메인 영속을 소유하는가(D-2 → D-6).
- **PG 스키마 분리(단일 prefix vs 도메인별)** — 통합본 §4.2.4(line 610) 원문 `"단일 prefix 또는 도메인별 스키마 분리 [Open, 7장]"`, 관련 §4.2.2(line 596) `"서비스별 스키마 분리"`. **`[Open, 7장]` 미결(M-1, 슬라이스 정의 §3 M-1)** → 추측 금지. 스키마를 도메인별로 분리하면 그 경계가 D-2(모듈 경계)와 정렬될 수 있어 지금 박으면 D-2 결과와 어긋날 위험.
- **site sizing / topology 추정** — D-8/통합본 §A 미결 → 단일 노드 기본 구성으로만.

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

### 3.4 기존 compose 스택 충돌 사전확인 (착수 전 필수)

> 현 `docker-compose.yml`에는 zookeeper/kafka/kafka-init/otel-collector가 이미 있다. 4종 추가가 이들과 충돌하지 않는지 **변경 전** 확인한다.

- **포트**: 신규 매핑(PG 5432 / OpenSearch 9200 / Redis 6379 / MinIO 9000·9001)이 기존(9092 kafka, 14318 otel)·호스트 점유와 겹치지 않는지. Windows Hyper-V 예약 범위(기존 otel 4318→14318 우회 선례)도 유의. **이 값들은 기본 후보일 뿐 고정값이 아니다 — 충돌 시 compose 포트 매핑/env override로 호스트 측 포트만 조정**하라(otel 14318 선례처럼).
- **네트워크**: 기존 단일 compose network를 공유하되 서비스명(`postgres`/`opensearch`/`redis`/`minio`)이 기존과 겹치지 않게.
- **볼륨**: 신규 named volume이 기존 볼륨명과 겹치지 않게(데이터 유실 방지).
- 확인 명령 예: `docker compose -f infra/docker-compose.yml config`(머지 결과 검사) → `docker compose up -d`(증분 기동, 기존 kafka 스택 재기동 영향 확인).

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

> **Rollback 경로(기존 Kafka 스택 보존 — 전역 `down -v` 금지)**: 이 슬라이스는 스토어 추가/운영골격만이므로 신규분만 선별 원복한다.
> 1. **신규 서비스만 중지/제거**: `docker compose -f infra/docker-compose.yml stop postgres opensearch redis minio` → `docker compose ... rm -f postgres opensearch redis minio`. **전역 `docker compose down -v`는 쓰지 마라** — 기존 kafka/zookeeper 볼륨까지 지운다.
> 2. **신규 볼륨만 명시 제거**: 먼저 `docker compose -f infra/docker-compose.yml config --volumes`로 실제 생성되는 named volume 목록·이름을 확인한 뒤, `docker volume rm <project>_pgdata <project>_osdata ...`처럼 이번에 추가한 볼륨만 지정 제거. **Kafka/ZooKeeper 기존 볼륨은 제거 대상에서 제외.**
> 3. **문서/compose 변경분 되돌리기**: compose/config 변경 커밋을 `git revert`(또는 해당 커밋만 되돌리기). `git reset`처럼 작업트리를 강제로 되감는 방식은 다른 변경이 섞일 수 있어 쓰지 않는다.

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

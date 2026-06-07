# 작업 spec — phase1-050-hub (T1-1 영속 D-2-무관 슬라이스: 연결 설정 + smoke)

> 이 handoff는 hub 세션이 받아 실행한다. T1-1 D-2-무관 슬라이스 중 **hub 몫** = 데이터스토어 4종(PG/OpenSearch/Redis/MinIO) **클라이언트 연결 설정 + 연결 smoke 검증**(P-3·P-4). **도메인 영속(repository/엔티티/스키마)은 D-2 의존이라 이번 범위 밖** — "연결되고 빈 상태 read-write 왕복이 되는" 데까지만. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-050-hub` (T1-1 슬라이스) |
| 대상 repo | `hub` (Java/Spring) |
| 기준 monitoring-meta commit | `ec408a8` (실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 근거 | `통합본 §8.3 ADR#12`·§4.2.2(line 688 "JDBC 표준 + 다중 DB 지원") / 슬라이스 정의 `handoff/phase1-050-t1-1-datastore-slice.md` §1 |
| 작성일 | 2026-06-07 |
| 실행 순서 | **2순위** (infra `phase1-050-infra.md`로 스토어가 뜬 뒤) |

## 2. 범위 (승인된 슬라이스 경계)

**포함(이번)**: hub의 PG/OpenSearch/Redis/MinIO **연결 설정**(엔드포인트·credential·커넥션 풀)와 **연결 smoke**(ping/기본 read-write 왕복, 스키마 무관).
**제외(D-2 의존, 보류)**: 도메인 repository/DAO, 엔티티 매핑, 트랜잭션 경계, 도메인 스키마 DDL. **이건 D-2(β/γ) 후 별도.**

## 3. 변경 목록

### 3.1 P-3 — 클라이언트 연결 설정

| 스토어 | hub 연결 설정 |
|---|---|
| PostgreSQL | JDBC DataSource(엔드포인트/계정/풀). **JDBC 표준 + 다중 DB 지원 골격**(통합본 line 688). 도메인 엔티티/JPA repository는 만들지 않음 — DataSource 빈 + 연결 풀까지만 |
| OpenSearch | OS 클라이언트(엔드포인트/인증). 인덱스 도메인 매핑은 제외 |
| Redis | Redis 연결(캐시 용도). 키 스페이스/캐시 추상화는 앱 계층(보류) |
| MinIO | S3 호환 클라이언트(엔드포인트/credential/버킷 참조). 도메인 객체 배치는 제외 |

- `application.yml`/config에 엔드포인트·credential은 **infra 슬라이스가 띄운 스토어**를 가리키게(로컬/compose 기준). 비밀값은 기존 hub 관례 따름.

### 3.2 P-4 — 연결 smoke 검증

- 각 스토어에 대해 **기동 시 연결 ping + 빈 상태 기본 read-write 왕복**(임시 키/임시 객체/임시 row in 임시 테이블 수준 — 도메인 스키마 아님)을 확인하는 smoke 테스트.
- 목적: "스토어가 존재하고 hub가 연결된다"의 실증. 도메인 구조와 무관.

### 3.3 문서/주석
- README 등에 추가된 의존 스토어를 1~2줄 명시(연결 계층 한정).

## 4. 적용 결정 (사람 확정 반영)

| 항목 | 결정 |
|---|---|
| 슬라이스 경계 | 연결 설정 + 빈 상태 smoke까지 — **도메인 repository/엔티티/DDL 제외**(D-2 후) |
| PG 스키마 | 도메인 스키마 만들지 않음(M-1 [Open] 보류). 연결 + 빈 DB 왕복까지 |
| 범위 | PG/OS/Redis/MinIO만. VictoriaMetrics(Phase 2) 제외 |

## 5. DoD / 검증

- [ ] hub가 PG/OS/Redis/MinIO 4종에 연결되는 config 존재(infra 슬라이스 스토어 대상).
- [ ] 4종 연결 smoke PASS(ping + 빈 상태 read-write 왕복).
- [ ] **도메인 repository/엔티티/스키마 DDL 없음**(D-2 보류분 미포함).
- [ ] `mvn test` 그린(추가 smoke 포함). 기존 테스트 회귀 0.
- [ ] **Phase 0 e2e(PASS 58/0/0) 회귀 0** — 기존 메시지 흐름(in-memory)과 독립. 데모 spec v0.2.1 동작 무관.

## 6. 가드 (공통)

- **동결 데모 spec v0.2.1 수정 금지**(회귀 앵커).
- **도메인 영속(repository/엔티티/DDL/트랜잭션 경계) 금지** — D-2(β/γ) 전이라 재작업 위험. 연결 계층 + smoke만.
- 재명명/Phase 0 흐름은 그대로 — 이 슬라이스는 스토어 *연결*만 추가, 메시지 흐름 불변.
- e2e 종단 재검증은 meta가 §3.3로 별도(e2e-tester). hub 세션은 `mvn test`까지.

## 7. 미결정 사안

- PG 스키마 분리(M-1, 통합본 §4.2.4 [Open,7장])·도메인 영속 배치(D-2)는 보류 — 본 슬라이스 결정 사항 없음.

## 8. 결과 보고 스키마

```json
{ "status": "ok | blocked | failed", "outputs": ["변경 파일"], "findings": ["연결 설정/smoke 결과"], "blockers": [], "next_action": "다음 한 줄" }
```

# 작업 spec — id-cleanup (infra) — 주석 표기 갱신(권장, 동작 변경 0)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `id-cleanup` | |
| 대상 repo | `infra` | **주석만 갱신(권장) — 동작·설정 값 변경 없음** |
| **기준 monitoring-meta commit** | `3fd722820d2d9ec8fef774405d78e092217d4ef5` | ID 체계 정리 커밋 체인 |
| 작성일 | 2026-06-11 | |
| 근거 ADR | (해당 없음) | meta 문서 거버넌스 결정 |

## 2. 배경 / 공지 내용

monitoring-meta 기준 문서(ROADMAP 등)의 식별자 체계가 **운영 3종(T/D/ADR)으로 단순화**됐다(2026-06-11 결정).

- **G-n(게이트) 폐지 → D-n으로 흡수**: G-1→D-1, G-2→D-2, **G-3→D-8**, G-4→D-7, G-5→§5 완료 조건 7
- **DoD-n 폐지 → "§5 완료 조건 N"** (번호 1~7 보존)
- 읽는 법·신구 매핑: `../monitoring-meta/docs/phase1/ID-GLOSSARY.md`

## 3. 해야 할 것 — 주석 표기 갱신 7곳 (권장)

infra는 **polyrepo 전체에서 폐지 ID가 남은 유일한 살아있는 파일들**을 갖고 있다. 전부 주석이라 동작 영향은 없지만, "G-3 해소 후 하드닝 승격" 같은 **미래 작업 트리거를 안내하는 문장**이라 다음 작업자 가독성을 위해 갱신을 권장한다(이름 우선 표기 `이름(ID)` 꼴 적용).

| 파일:행(약) | 현재 | 갱신 후 |
|---|---|---|
| `docker-compose.yml:105` | `구체화는 G-3(site 보안정책 [Open])·T1-2(인증) 해소 후` | `구체화는 site별 운영 정보(D-8, site 보안정책 [Open])·인증(T1-2) 해소 후` |
| `docker-compose.yml:106` | `트리거 G-3+PKI확정` | `트리거 site별 운영 정보(D-8)+PKI확정` |
| `docker-compose.yml:109` | `트리거 G-3 sizing/topology` | `트리거 site별 운영 정보(D-8) sizing/topology` |
| `docker-compose.yml:112` | `PG 스키마 분리(M-1)·` | `PG 스키마 분리(통합본 §4.2.4 [Open])·` |
| `docker-compose.yml:113` | `site sizing(G-3) 금지` | `site sizing(D-8) 금지` |
| `docker-compose.yml:117` | `(M-1 PG 스키마 분리 = 통합본 §4.2.4 [Open,7장])` | `(PG 스키마 분리 = 통합본 §4.2.4 [Open,7장])` |
| `minio/init-buckets.sh:2`, `opensearch/init-templates.sh:2` | `운영 골격(P-2)` | `운영 골격 슬라이스` |

매핑 근거: `G-3`→**D-8**(사이트별 운영 정보, 통합본 §13_open §A), `P-2`→T1-1 운영골격 슬라이스(일회성 ID 폐지), `M-1`→PG 스키마 마이그레이션(일회성 ID 폐지). 해독표: `../monitoring-meta/docs/phase1/ID-GLOSSARY.md` 부록 A·D.

### 하지 말 것 (out of scope)
- compose 서비스 정의·env·포트 등 **설정 값 변경 일체**(주석만). 주석 수정은 떠 있는 스택(T1-1 검증용)에 무영향 — 재기동 불요.
- `docs/decisions/proposal-review-*.json` 2건의 옛 ID는 **스냅샷이라 무수정**.

## 4. 앞으로 지킬 것 (신규 규칙)

- 새로 만드는 운영·계획 식별자는 **T(작업) / D(결정) / ADR(결정 기록) 3종만** 사용.
- 폐지 패밀리(G, DoD, N/C/S/drift, P/X/M) 신규 생성 금지.

## 5. 완료 기준
- [ ] §3 표의 7곳 주석 치환(diff가 주석 라인만 포함)
- [ ] `grep -rn 'G-[1-5]\|P-[1-4]\|M-1' docker-compose.yml minio/ opensearch/` → 0건
- [ ] `docker compose config` 무오류(주석만 바뀌었음 확인)

## 6. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": [],
  "findings": ["공지 확인 여부"],
  "blockers": [],
  "next_action": "없음(공지 전용)"
}
```

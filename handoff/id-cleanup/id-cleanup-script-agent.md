# 작업 spec — id-cleanup (script-agent) — 공지 전용(코드 변경 0)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `id-cleanup` | |
| 대상 repo | `script-agent` | **공지 전용 — 수정 작업 없음** |
| **기준 monitoring-meta commit** | `3fd722820d2d9ec8fef774405d78e092217d4ef5` | ID 체계 정리 커밋 체인 |
| 작성일 | 2026-06-11 | |
| 근거 ADR | (해당 없음) | meta 문서 거버넌스 결정 |

## 2. 배경 / 공지 내용

monitoring-meta 기준 문서(ROADMAP 등)의 식별자 체계가 **운영 3종(T/D/ADR)으로 단순화**됐다(2026-06-11 결정).

- **G-n(게이트) 폐지 → D-n으로 흡수**: G-1→D-1, G-2→D-2, G-3→D-8, G-4→D-7, G-5→§5 완료 조건 7
- **DoD-n 폐지 → "§5 완료 조건 N"** (번호 1~7 보존)
- 리뷰 잔재(N/C/S/drift/"Pass 1")·일회성(P/X/M) ID는 ROADMAP 본문에서 제거됨
- 읽는 법·신구 매핑: `../monitoring-meta/docs/phase1/ID-GLOSSARY.md`

## 3. script-agent에 미치는 영향 — **변경 0**

script-agent 내 ID 참조(`config_test.go`의 T4-1 주석 등)는 **보존되는 T ID**라 갱신할 것이 없다. 옛 ID(G/DoD 등)를 만나면 glossary 부록으로 해독하면 되고, 소급 수정은 하지 않는다.

## 4. 앞으로 지킬 것 (신규 규칙)

- 새로 만드는 운영·계획 식별자는 **T(작업) / D(결정) / ADR(결정 기록) 3종만** 사용.
- 폐지 패밀리(G, DoD, N/C/S/drift, P/X/M) 신규 생성 금지.
- ADR **내부** 옵션 식별자(A-1/B-1/C-1 등)는 별개로 계속 유효(ADR-local) — 예: ADR-0002의 C-1=컷오버 결정.

## 5. 완료 기준
- [ ] 공지 확인(코드·문서 수정 없음)

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

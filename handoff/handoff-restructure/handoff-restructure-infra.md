# 작업 spec — handoff-restructure (infra)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `handoff-restructure` | |
| 대상 repo | `infra` | 문서 표기만 수정, 스택 동작 변경 없음 |
| **기준 monitoring-meta commit** | `bd43a15ee836866961a415024ff9020af4391559` | handoff 재구성 커밋 |
| 작성일 | 2026-06-10 | |
| 근거 ADR | (해당 없음) | meta 운영 구조 변경 |

## 2. 배경 / 목표

monitoring-meta의 `handoff/`가 **작업 단위 디렉터리 구조**로 재구성됐다(한 작업 단위 = 한 디렉터리,
파일명 불변, 규칙 전문: `../monitoring-meta/handoff/README.md`). infra 문서에 남은 구 평면 경로 표기를 새 규약으로 갱신한다.

## 3. 작업 범위

### 해야 할 것 — 치환 두 종류

1. 일반 패턴: `monitoring-meta/handoff/<work-id>-infra.md` → `monitoring-meta/handoff/<work-id>/<work-id>-infra.md`
   - `.claude/proposal-review.profile` (약 :30)
2. 구체 경로(과거 결정 기록 내 링크): `monitoring-meta/handoff/phase1-050-infra.md` → `monitoring-meta/handoff/phase1-050/phase1-050-infra.md`
   - `docs/decisions/proposal-review-phase1-050-infra-2026-06-10.json` (약 :12, :21)
   - `docs/decisions/proposal-review-phase1-050-infra-asbuilt-2026-06-10.json` (약 :17)

확인 명령: `grep -rn 'monitoring-meta/handoff/' .`

### 하지 말 것 (out of scope)
- compose·config·스택 동작 변경 일체. 떠 있는 스택(T1-1 검증용)을 건드리지 않는다.

### 영향받는 기능 문서 (`docs/features/`) — 필수
- **해당 없음**
- 근거: 문서 표기 치환만 있고 사용자 가시 흐름·인프라 동작 변화가 없다.

## 6. Phase 0 회귀 방지 기준
해당 없음(문서 표기만 수정).

## 7. 미결정 사안
없음.

## 8. 완료 기준 / 검증
- [ ] `grep -rn 'monitoring-meta/handoff/' .` 결과가 전부 `handoff/<디렉터리>/<파일>` 또는 `handoff/<work-id>/<work-id>-infra` 새 규약 형태
- [ ] 스택 동작 영향 없음(문서만)

## 9. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

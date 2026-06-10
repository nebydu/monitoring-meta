# 작업 spec — handoff-restructure (hub)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `handoff-restructure` | |
| 대상 repo | `hub` | 문서 표기만 수정, 코드 변경 없음 |
| **기준 monitoring-meta commit** | `bd43a15ee836866961a415024ff9020af4391559` | handoff 재구성 커밋 |
| 작성일 | 2026-06-10 | |
| 근거 ADR | (해당 없음) | meta 운영 구조 변경 |

## 2. 배경 / 목표

monitoring-meta의 `handoff/`가 평면 구조(43개 파일)에서 **작업 단위 디렉터리 구조**로 재구성됐다:
한 작업 단위(work-id) = 한 디렉터리, 파일명은 불변. 새 경로 규약은
`monitoring-meta/handoff/<work-id>/<work-id>-hub.md`다(규칙 전문: `../monitoring-meta/handoff/README.md`).
hub 문서들이 구 평면 패턴 `handoff/<work-id>-hub.md`를 표기하고 있어 새 규약으로 갱신한다.

## 3. 작업 범위

### 해야 할 것 — 패턴 문자열 치환 (한 종류)

`monitoring-meta/handoff/<work-id>-hub.md` → `monitoring-meta/handoff/<work-id>/<work-id>-hub.md`

대상 파일(2026-06-10 기준 위치 힌트 — 실제는 패턴 grep으로 전수 확인):
- `.claude/CLAUDE.md` (약 :19, :27)
- `.claude/agents/analyzer.md` (약 :3, :12)
- `.claude/agents/implementer.md` (약 :13)
- `.claude/agents/spec-guardian.md` (약 :17)
- `AGENTS.md` (약 :49)
- `.claude/proposal-review.profile` (약 :29)

확인 명령: `grep -rn 'monitoring-meta/handoff/<work-id>' . --include='*.md' --include='*.profile'`

### 하지 말 것 (out of scope)
- 코드·설정 동작 변경 일체. `.claude/settings.json`의 `additionalDirectories: ../monitoring-meta/handoff`는 디렉터리 단위라 하위 디렉터리를 자동 커버하므로 **수정하지 않는다**.
- 과거 결정 기록(JSON 등)에 박힌 구체 경로는 hub에는 해당 없음.

### 영향받는 기능 문서 (`docs/features/`) — 필수
- **해당 없음**
- 근거: 문서 표기 치환만 있고 사용자 가시 흐름·코드 변화가 없다.

## 6. Phase 0 회귀 방지 기준
해당 없음(문서 표기만 수정).

## 7. 미결정 사안
없음.

## 8. 완료 기준 / 검증
- [ ] `grep -rn 'handoff/<work-id>-hub' .` 결과 0건 (전부 `handoff/<work-id>/<work-id>-hub`로 치환)
- [ ] 코드·테스트 영향 없음 (`mvn test` 불필요 — 문서만)

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

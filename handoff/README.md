# handoff/ — repo 간 작업 spec 교환소

monitoring-meta가 분석·결정한 결과를 각 repo(hub / script-agent) 세션으로 넘기는 작업 산출물이 시간순으로 누적되는 곳이다. (루트 `HANDOFF.md`는 별개 — 현재 상태 인계 문서다.)

## 작업 spec 작성 절차

1. **템플릿 복사**: `_TEMPLATE-work-spec.md`를 복사한다.
2. **파일명 규약**: `<work-id>-hub.md`, `<work-id>-script-agent.md` (한 파일 = 한 repo, 양쪽에 걸친 ADR이면 두 파일).
3. **필수 헤더를 모두 채운다.** 특히 **`기준 monitoring-meta commit: <full-hash>`** 는 필수다.
   - 이 spec이 가리키는 정본(통합본 v0.9 / envelope.md / kafka-payloads.md)의 고정 시점을 못 박는다.
   - hub·script-agent는 정본을 상대 경로로 참조만 하므로, 작성↔실행 시점 사이 drift를 막으려면 기준 commit이 필요하다(상세는 템플릿 §1.1).
   - monitoring-meta repo 루트에서 `git rev-parse HEAD`로 얻은 **full 40자 hash**를 기입한다(축약 금지).
4. **미결정 사안**이 하나라도 걸리면 추측으로 채우지 말고 멈추고 사람을 호출한다.

## 파일 종류

| 패턴 | 종류 | 비고 |
|---|---|---|
| `_TEMPLATE-work-spec.md` | 작성 템플릿 | 복사 원본. 직접 실행 대상 아님 |
| `<work-id>-hub.md` / `<work-id>-script-agent.md` | 작업 spec | 각 repo 세션의 입력 |
| `spec-drift-*.md` | drift 검출 보고서 | `spec-sync` 산출물. 작업 spec과 별개 |
| `*-analysis.md` | 분석 산출물 | `analyzer` 산출물 |

## 비고

- 기존 handoff 파일에는 `기준 monitoring-meta commit` 필드를 **소급 적용하지 않는다.** 신규 작성분부터 적용한다.
- 완료·확인이 끝난 `spec-drift-*.md`는 검출 시점의 사진이지 영속 자산이 아니므로 archive 또는 삭제 대상이다.

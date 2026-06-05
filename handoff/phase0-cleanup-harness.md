# 작업 spec — phase0-cleanup-harness

| 항목 | 값 |
|---|---|
| work-id | `phase0-cleanup-harness` |
| target repo | `monitoring-harness` |
| 발행 | monitoring-meta / analyzer |
| 발행일 | 2026-06-05 |
| 선행 분석 | `../monitoring-meta/handoff/phase0-cleanup-000-impact.md` |
| 기준 monitoring-meta commit (full 40자) | `be990c7b936c283d1ad15519fbb9dd6ac7f3deea` |
| 우선순위 | **낮음** (`.example` 템플릿 — 런타임 직접 영향 없음) |

> **commit pin 주의**: 위 pin은 phase0-cleanup 정리 커밋에서 채워졌다. 실행 직전 `git rev-parse HEAD`(monitoring-meta)로 재확인.

---

## 1. 문서 위상 (혼동 금지)

- 데모 spec v0.2.1 = Phase 0 회귀 ground truth. 본 작업으로 정본 위치가
  `monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`로 통합됐다.
- harness의 profile.example은 각 repo 훅 프로파일의 **샘플 템플릿**이므로 데모 spec 경로
  언급이 있으면 새 정본 경로로 정렬해 둔다(샘플의 정확성 유지 목적).

## 2. ground truth 참조

- 데모 spec 단일 정본: `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`

## 3. 배경 / 범위

`.example`은 복사해서 쓰는 템플릿이라 게이트가 직접 읽지 않는다(우선순위 낮음). 다만 잘못된
경로를 샘플로 두면 신규 repo 셋업 시 dangling을 복제하므로 정본 경로로 정렬한다.

## 4. 작업 분해

다음 2개 파일에서 데모 spec을 가리키는 경로(있을 경우)를
`../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`로 교체한다.

- `monitoring-harness/shared/hooks/profiles/hub.profile.example`
- `monitoring-harness/shared/hooks/profiles/script-agent.profile.example`

> 두 파일은 각각 hub/script-agent repo에 복사돼 `codex-gate.profile`이 되는 샘플이다.
> hub/script-agent 세션의 라이브 `codex-gate.profile` repoint(phase0-cleanup-hub/-script-agent
> §4.2)와 **동일한 새 경로 문자열**을 쓰도록 맞춘다.

## 5. DoD (완료기준)

1. 두 `.example`의 데모 spec 경로가 새 정본 경로로 교체됨(해당 언급이 없으면 변경 없음 + 그 사실 보고).
2. `rg "docs/monitoring-demo-message-spec-v0\.2\.1\.md" monitoring-harness/shared/hooks/profiles`
   결과에 구 로컬 경로 0건(새 경로만 또는 0건).
3. 라이브 게이트 repoint(hub/script-agent §4.2)와 경로 문자열 일치.

## 6. 미결정 / 주의

- 본 작업은 후순위로, hub/script-agent repoint와 경로 문자열만 일치시키면 된다. 통합본 미결 항목 비관여.

## 7. 결과 스키마

```json
{"status":"ok|blocked|failed","outputs":["수정 파일(없으면 빈 배열)"],"findings":["경로 언급 유무 + dangling 검증"],"blockers":[],"next_action":"한 줄"}
```

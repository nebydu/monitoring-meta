# 작업 spec — codex-gate-commit-window (harness)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `codex-gate-commit-window` | |
| 대상 repo | `monitoring-harness` | plugin core 수정 |
| **기준 monitoring-meta commit** | (meta의 이 작업 커밋 — push 후 `git -C ../monitoring-meta log --oneline -1`로 확인, `6005cffda4634e1a588afa5e6823b5d253796f22` 이후 첫 hooks 커밋) | reference 구현 동기화점 |
| 작성일 | 2026-06-11 | |
| 근거 ADR | (해당 없음) | meta 자동화 거버넌스 |

## 2. 배경

codex-gate Stop hook 트리거가 "HEAD 대비 작업 트리 diff"만 봐서 **같은 턴 커밋 시 게이트가 우회**되는 사각지대 발견(통합본 v0.10이 실제 사례). meta 자체 hook(`../monitoring-meta/.claude/hooks/codex-gate.sh`)은 `verified_commit` 기반 검증 윈도우로 수정 완료 — **harness plugin core(`shared/hooks/codex-gate-core.sh`)도 동일 구조(:104~111 `BASE="HEAD"`)라 같은 사각지대**를 갖는다.

설계·검증·12라운드 리뷰 기록: `../monitoring-meta/handoff/codex-gate-commit-window/codex-gate-commit-window-000-record.md`

## 3. 해야 할 것

`shared/hooks/codex-gate-core.sh`의 BASE 결정·상태 관리에 **meta hook과 동일한 설계**를 적용:

1. 상태 파일에 `verified_commit`(vc) 필드 — plugin은 상태가 plugin data dir(`~/.claude/plugins/data/harness-monitoring/<repo>/`)에 있으므로 그 레이아웃 기준으로.
2. BASE 결정 5종(vc / merge-base / bootstrap-origin / bootstrap-origin-mb / empty-tree) + 차단 2종(disconnected / no-baseline, fail-closed exit 2). **meta 구현을 reference로 그대로 이식** — `../monitoring-meta/.claude/hooks/codex-gate.sh` §2.
3. 전진 규칙: 윈도우가 BASE..HEAD 전 구간 커버 + 검증 완료(트리거 0 skip / pass)일 때만. escalated·차단·fail은 전진 금지.
4. 상태 축 분리: `cache_status`(구 status 개명+마이그레이션) / `last_result` / skip 시 fail streak 리셋 / 차단 로그 분리(`codex-gate-block.log` 상당).
5. stdout systemMessage는 실행당 단일 JSON 유지(모드 주석은 최종 메시지에 합류).

### 하지 말 것 (out of scope)
- `hooks/codex-gate-entry.sh` 무변경(profile 로딩 로직은 이번과 무관).
- 각 소비 repo(hub/script-agent/infra)의 `codex-gate.profile` 무변경 — core만.
- meta는 plugin 미사용(자체 hook) — meta 쪽 재반영 불요.

### 영향받는 기능 문서 (`docs/features/`) — 필수
- **해당 없음.** 근거: 게이트 자동화 내부 개선 — 사용자 가시 시나리오의 cross-repo 흐름 무변경.

## 4. 검증 (meta에서 수행한 것과 동일 수준)

- [ ] `bash -n` 문법.
- [ ] 격리 스크래치 repo + codex 스텁(PATH 앞 가짜 codex가 `-o` 경로에 pass/fail JSON 기록)으로 핵심 시나리오: **커밋 후 클린 트리에서 트리거됨(사각지대 해소 증명)** / pass 후 skip+vc 전진 / amend→merge-base / 단절·기준 없음 차단(exit 2)+vc 비전진 / escalation 3회 후 already_force_passed 캐시.
- [ ] 반영 후 **`/plugin update`로 marketplace 캐시 갱신**(directory 소스라 라이브 repo 수정만으로는 미반영 — 캐시 함정).
- [ ] 소비 repo 1곳(예: hub)에서 실제 Stop 1회로 동작 확인.

## 5. 주의 (meta 12라운드 리뷰에서 확정된 함정)

- 단절/기준 없음에서 부분 검사 후 SKIP/PASS를 내보내면 "통과처럼 동작" — 반드시 fail-closed.
- escalated에서 vc를 전진시키면 미검증 흡수 — 금지(동일 diff 재방문은 gate_key 캐시가 skip).
- systemMessage 이중 발신 금지(Stop hook stdout은 단일 JSON 기대).
- 알려진 트레이드오프(더티 트리 pass 후 커밋 = 1회 중복 재검증, origin/main=신뢰 기준)는 record 문서 §5 참조 — 재논쟁 불요.

## 6. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["shared/hooks/codex-gate-core.sh", "..."],
  "findings": ["시나리오 검증 결과", "/plugin update 캐시 반영 확인", "소비 repo 실동작 확인"],
  "blockers": [],
  "next_action": "monitoring-meta 세션에 결과 JSON 전달"
}
```

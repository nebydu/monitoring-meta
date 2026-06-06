# monitoring-meta — meta 오케스트레이터 세션 룰

이 repo(`monitoring-meta`)는 **코드를 만들지 않는다.** 기준 문서 spec/문서/종단 검증 산출물만 다루는 오케스트레이터다. 통합본 v0.9 기준 문서를 들고 형제 repo(`../hub`, `../script-agent`)에 작업 spec을 분배하고, polyrepo 종단 검증을 수행한다.

## 0. 절대 원칙
- **meta 세션은 코드를 직접 작성하지 않는다.** 코드 작업은 각 repo의 세션에서 한다. 여기서는 spec·문서·핸드오프·종단 검증 산출물만 만든다.
- `../hub`, `../script-agent`, `../infra`는 **읽기 전용 참조 대상**이다. 어떤 경우에도 수정하지 않는다.
- 응답·주석·문서는 **한국어**, 변수/함수명·디렉터리명·파일명은 영어(단 통합본 등 기존 한국어 파일명은 유지).

## 1. 문서의 성격 — 절대 혼동 금지
모든 sub-agent에게 매 작업 시 상기시킨다:
- **데모 spec v0.2.1** (`docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` = 기준 문서 — phase0-cleanup으로 hub/docs·script-agent/docs 사본에서 monitoring-meta 단일 기준 문서로 통합) → **"Phase 0 코드가 회귀 없이 지켜야 할 동작 spec(ground truth)"**.
- **통합본 v0.9** (`docs/통합본_v0_9.md`) + `docs/kafka-payloads.md` + `docs/envelope.md`(예정) → **"Phase 1+ 도달 목표 spec"**.
- 이 둘을 **같은 ground truth로 다루지 않는다.** 회귀 기준과 목표 기준은 다르다.

## 2. 미결정 사안 — 추측 금지
다음은 **추측으로 메우지 말고 즉시 멈추고 사람을 호출**한다:
- 통합본 v0.9 본문에 `[Open]` / `[Open question]`으로 표기된 항목, 또는 `13_open.md`(13. Open Questions)에 정리된 항목.
- 아직 결정되지 않은 ADR.
- 데모 spec과 통합본의 성격 충돌로 어느 쪽을 따라야 할지 모호한 경우.

## 3. 작업 유형별 표준 흐름

### 3.1 spec 작업 (예: envelope 작성)
1. `analyzer` 호출 → 후보안 + 결정 필요 사안 정리.
2. 사람이 결정 입력.
3. `analyzer` 최종안 작성 (`docs/`에 기록).
4. `spec-sync` drift 검사 → `handoff/spec-drift-<timestamp>.md`.
5. 세션 Stop 시 `codex-gate` hook이 Codex로 일관성 검증.

### 3.2 ADR 분배 (양쪽 repo에 영향)
1. `analyzer` 호출 → 영향 분석.
2. `handoff/<work-id>-hub.md`, `handoff/<work-id>-script-agent.md` 두 파일 생성.
3. 사람에게 "두 핸드오프 파일을 들고 각 repo 세션으로 이동" 안내 후 **meta 세션 종료**.
4. meta에서 코드 작업으로 넘어가지 않는다.

### 3.3 종단 검증
1. `e2e-tester` 단독 호출.
2. 결과는 `e2e/results/<timestamp>.md`에 저장.

## 4. 재시도 정책
- 같은 작업 단위에서 `analyzer` 재호출은 **최대 2회**(meta 작업은 토큰 비용이 크다). 초과 시 사람에게 escalation.

## 5. sub-agent 결과 스키마
모든 sub-agent는 마지막에 아래 구조를 반환한다:
```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

## 6. sub-agent 역할 요약
| agent | model | tools | Write 허용 범위 | 책임 |
|---|---|---|---|---|
| `analyzer` | opus | Read, Grep, Glob, Write | `docs/`, `adr/`, `handoff/` | 통합본+spec+양쪽 코드+데모 spec 종합 분석 |
| `spec-sync` | sonnet | Read, Grep, Glob, Write | `handoff/` | 기준 문서↔사본 spec drift 검출(보고만) |
| `e2e-tester` | sonnet | Read, Write, Bash, Grep, Glob | `e2e/` | polyrepo 종단 검증 실행 |

frontmatter의 `model`은 환경변수 `CLAUDE_CODE_SUBAGENT_MODEL`보다 **우선**한다.

## 7. 디렉터리 약속
- `docs/` — 기준 문서 spec·문서 (통합본, kafka-payloads, envelope 등).
- `adr/` — ADR 결정 기록.
- `handoff/` — 각 repo로 넘기는 작업 spec, drift 보고, 통합본 수정 제안서.
- `e2e/` — 종단 검증 스크립트(`run-e2e.sh`)와 결과(`results/<timestamp>.md`).
- `docs/phase0-snapshot/` — Phase 0 데모 상태 스냅샷(참조 전용).

## 8. Stop hook(Codex 게이트)
세션 종료 시 `.claude/hooks/codex-gate.sh`가 자동 실행되어, spec 관련 변경이 있을 때만 Codex로 "통합본 내부 일관성 + 8토픽 spec 일관성 + ADR/Open 일관성"을 read-only 검증한다. fail이면 종료가 막히고 다음 턴에 수정 작업으로 이어진다. 상세는 hook 스크립트 상단 주석 참조.

Stop hook은 exec form으로 repo-local cmd shim(`.claude/hooks/git-bash.cmd` + args)을 호출한다. shim이 `%ProgramFiles%\Git\bin\bash.exe`를 실행하므로 Windows PATH의 `bash` 우선순위(WSL shim 등)에 의존하지 않는다.

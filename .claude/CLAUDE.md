# monitoring-meta — meta 오케스트레이터 세션 룰

이 repo(`monitoring-meta`)는 **코드를 만들지 않는다.** 기준 문서 spec/문서/종단 검증 산출물만 다루는 오케스트레이터다. 통합본(현재 v0.10) 기준 문서를 들고 형제 repo(`../hub`, `../script-agent`)에 작업 spec을 분배하고, polyrepo 종단 검증을 수행한다.

## 0. 절대 원칙
- **meta 세션은 코드를 직접 작성하지 않는다.** 코드 작업은 각 repo의 세션에서 한다. 여기서는 spec·문서·핸드오프·종단 검증 산출물만 만든다.
  - **예외(2026-06-11 결정)**: meta repo 자신의 자동화(`.claude/hooks/` 스크립트, `e2e/run-e2e.sh` 등 meta 운영 스크립트)는 meta 산출물이므로 meta 세션이 직접 관리한다 — 다른 repo 세션은 meta를 수정할 수 없기 때문. "코드 금지"의 대상은 제품 코드(hub/script-agent/infra)다.
- `../hub`, `../script-agent`, `../infra`는 **읽기 전용 참조 대상**이다. 어떤 경우에도 수정하지 않는다.
- 응답·주석·문서는 **한국어**, 변수/함수명·디렉터리명·파일명은 영어(단 통합본 등 기존 한국어 파일명은 유지).

## 1. 문서의 성격 — 절대 혼동 금지
모든 sub-agent에게 매 작업 시 상기시킨다:
- **데모 spec v0.2.1** (`docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` = 기준 문서 — phase0-cleanup으로 hub/docs·script-agent/docs 사본에서 monitoring-meta 단일 기준 문서로 통합) → **"Phase 0 코드가 회귀 없이 지켜야 할 동작 spec(ground truth)"**.
- **통합본 v0.10** (`docs/통합본_v0_9.md` — 파일명은 안정 앵커로 유지, 내부 버전 v0.10/표기 전용 릴리스) + `docs/kafka-payloads.md` + `docs/envelope.md`(예정) → **"Phase 1+ 도달 목표 spec"**.
- 이 둘을 **같은 ground truth로 다루지 않는다.** 회귀 기준과 목표 기준은 다르다.

## 2. 미결정 사안 — 추측 금지
다음은 **추측으로 메우지 말고 즉시 멈추고 사람을 호출**한다:
- 통합본 본문에 `[Open question]`으로 표기된 항목(v0.10에서 마커 표준화 — 구 문서엔 `[Open]` 변종 잔존 가능), 또는 13장(Open Questions — 단일 집중)에 정리된 항목.
- 아직 결정되지 않은 ADR.
- 데모 spec과 통합본의 성격 충돌로 어느 쪽을 따라야 할지 모호한 경우.

## 3. 작업 유형별 표준 흐름

### 3.1 spec 작업 (예: envelope 작성)
1. `analyzer` 호출 → 후보안 + 결정 필요 사안 정리.
2. 사람이 결정 입력.
3. `analyzer` 최종안 작성 (`docs/`에 기록).
4. `spec-sync` drift 검사 → `handoff/spec-drift/spec-drift-<timestamp>.md`.
5. 세션 Stop 시 `codex-gate` hook이 Codex로 일관성 검증.

### 3.2 ADR 분배 (양쪽 repo에 영향)
1. `analyzer` 호출 → 영향 분석.
2. `handoff/<work-id>/<work-id>-hub.md`, `handoff/<work-id>/<work-id>-script-agent.md` 두 파일 생성(한 작업 단위 = 한 디렉터리).
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
| `feature-doc-writer` | sonnet | Read, Grep, Glob, Write | `docs/features/` | work spec 지정 기능 문서 작성·보완(descriptive) |

frontmatter의 `model`은 환경변수 `CLAUDE_CODE_SUBAGENT_MODEL`보다 **우선**한다.

## 7. 디렉터리 약속
- `docs/` — 기준 문서 spec·문서 (통합본, kafka-payloads, envelope 등).
- `docs/phase1/ID-GLOSSARY.md` — 식별자 읽는 법 범례. **신규 운영·계획 ID는 T(작업)/D(결정)/ADR(결정 기록) 3종만 생성** — 폐지 패밀리(G, DoD, N/C/S/drift, P/X/M) 신규 생성 금지. **표기는 이름 우선(name-first)**: 문장에서 ID 단독 인용 금지, 항상 `이름(ID)` 꼴(예: "result-topic 분리(T4-2)"). 적용은 **새로 쓰거나 고치는 문장부터**(기존 본문 소급 sweep 안 함 — 수정 시 함께 정리) (2026-06-11 결정, `handoff/id-cleanup/`).
- `docs/features/` — 기능 단위 문서(사용자 가시 시나리오의 cross-repo 흐름, **descriptive** — 규범은 통합본/adr). 작성은 `feature-doc-writer`, 헌장은 `docs/features/README.md`.
- `adr/` — ADR 결정 기록.
- `handoff/` — 각 repo로 넘기는 작업 spec, drift 보고, 통합본 수정 제안서. **작업 단위 디렉터리 구조**: `handoff/<work-id>/<work-id>-<target>.md`(파일명에 work-id 접두어 유지) + 횡단 산출물은 `handoff/decisions/`(결정 자산)·`handoff/spec-drift/`(drift 보고). 규칙 전문은 `handoff/README.md`.
- `e2e/` — 종단 검증 스크립트(`run-e2e.sh`)와 결과(`results/<timestamp>.md`).
- `docs/phase0-snapshot/` — Phase 0 데모 상태 스냅샷(참조 전용).

## 8. Stop hook(Codex 게이트)
세션 종료 시 `.claude/hooks/codex-gate.sh`가 자동 실행되어, spec 관련 변경이 있을 때만 Codex로 "통합본 내부 일관성 + 8토픽 spec 일관성 + ADR/Open 일관성"을 read-only 검증한다. fail이면 종료가 막히고 다음 턴에 수정 작업으로 이어진다. 상세는 hook 스크립트 상단 주석 참조.

**검증 윈도우(2026-06-11 보완)**: 마지막 검증 commit(`verified_commit`, 상태 파일에 기록) 이후의 **커밋분 + 작업 트리 + 미추적**을 모두 검사한다 — 같은 턴에 커밋해도 게이트를 우회하지 못한다. rebase·amend는 merge-base 보수 윈도우로 커버. baseline 전진은 **검증이 실제로 완료된 경우만**(skip=트리거 0 확인 / pass) — escalated(강제 통과)는 전진하지 않는다. 단절 이력(vc와 HEAD의 공통 조상 없음)과 기준 없음(vc·origin/main 모두 부재)은 **fail-closed로 종료를 차단**한다(해소: 사람이 수동 검증 후 state의 verified_commit 갱신, 또는 push로 origin/main 생성).

Stop hook은 exec form으로 repo-local cmd shim(`.claude/hooks/git-bash.cmd` + args)을 호출한다. shim이 `%ProgramFiles%\Git\bin\bash.exe`를 실행하므로 Windows PATH의 `bash` 우선순위(WSL shim 등)에 의존하지 않는다.

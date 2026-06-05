# monitoring-meta `.claude/` 셋업 검증 결과

작성일: 2026-05-27
환경: Windows 10 / Git Bash / git 2.53 / codex-cli 0.134.0 (model gpt-5.5) / Python 3.14

## 사전 점검 (§3)
| 항목 | 결과 |
|---|---|
| git / codex 버전 | **OK** (git 2.53, codex-cli 0.134.0) |
| jq 설치 | **NG → 우회** (미설치. choco/scoop 없음. Python 3.14로 JSON 파싱 대체) |
| codex 인증 (`codex exec --sandbox read-only "hello"`) | **OK** (exit 0, gpt-5.5 응답) |
| `codex review --output-schema/--json` | **NG → fallback** (둘 다 미지원 → §5.7 codex exec 경로 채택) |
| codex exec `--output-schema`/`--json`/`-o` | **OK** (지원 확인, `-o`로 최종 JSON 회수) |
| 형제 디렉터리 hub/script-agent/infra | **OK** (모두 존재) |
| 정본 문서 3개 | **OK** (`docs/통합본_v0_9.md`, `docs/kafka-payloads.md`, `docs/envelope.md`). ※ `docs/phase0-snapshot/`(PROJECT_OVERVIEW + 데모 spec v0.2.1 정본)은 **Phase 0 스냅샷(참조용)**으로 재분류(phase0-cleanup) |
| `.claude/` 기존 존재 | **OK** (미존재 → 덮어쓰기 우려 없음) |

## 원안 대비 합의된 편차
1. **Codex 경로 = fallback(codex exec)** — `codex review` 플래그 미지원. hook 상단 주석에 명시.
2. **JSON 파싱 = Python** — jq 미설치. hook 상단 주석에 명시.
3. **baseline 커밋 생성** — repo에 초기 커밋이 없어 `docs/` 전체가 untracked였고, 트리거 가드가 매번 전체를 트리거하는 문제가 있었음. 사람 승인 하에 baseline 커밋(`f53ba05`)을 만들어 `HEAD`를 생성, 트리거가 변경분 기준으로 동작하도록 함. (`.gitignore`에 hook 런타임 산출물 제외, `.gitattributes`로 `*.sh` LF 고정)

## 산출물 트리
```
.claude/
├── CLAUDE.md
├── settings.json
├── codex-schema.json
├── SETUP_VERIFICATION.md
├── hooks/
│   └── codex-gate.sh
└── agents/
    ├── analyzer.md
    ├── spec-sync.md
    └── e2e-tester.md
```

## 검증 (§7)
| 단계 | 결과 | 비고 |
|---|---|---|
| `.claude/` 트리 출력 | **OK** | 7개 정적 파일 + 본 문서 |
| agent frontmatter 인식 | **OK** | 3종 모두 `name`/`model`/`tools` 정상 파싱 (analyzer=opus, spec-sync=sonnet, e2e-tester=sonnet) |
| **dry-run A** (handoff만 변경 → Codex 스킵) | **OK** | exit 0, `codex-gate.log`에 `skipped` 기록, `handoff/test.md` 정리. ※ 초기엔 pipefail+grep 버그로 실패 → `\|\| true` 수정 후 통과 |
| **dry-run B** (docs 변경 → Codex 실호출) | **OK** | 트리거 발화 → codex 호출 → `verdict=pass` 스키마 정합 JSON 수신 → exit 0 → log `pass`. ※ 초기엔 스키마 `required` 누락(`invalid_json_schema` 400)으로 파싱 실패 → `summary`를 required에 추가 후 통과. 통합본 변경 복원 확인 |
| **dry-run C** (spec-sync 단독) | **부분 — 사람 단계** | §7.3 규정대로 "사람이 직접 spec-sync 호출". agent 정의 유효성·입력 존재는 확인(아래). 실제 호출은 사람의 인터랙티브 세션에서 수행 |

## dry-run C 보충
- spec-sync agent 정의: frontmatter 정상(name=spec-sync, model=sonnet, tools=Read,Grep,Glob,Write). `/agents`에 표시될 것.
- 입력 파일 존재 확인: `docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` (데모 spec 단일 정본 — phase0-cleanup으로 hub/docs·script-agent/docs 사본에서 통합), `handoff/` 쓰기 가능.
- **사람 수행 절차**: 인터랙티브 Claude Code 세션에서 spec-sync를 호출하여 두 사본을 비교, `handoff/spec-drift-<timestamp>.md` 생성 확인.
- 참고: 셋업을 수행한 자동화 하니스의 Agent 도구는 빌트인 타입만 노출하여 커스텀 agent를 직접 호출하지 못함(정상). 이는 agent 정의 결함이 아니며, 실제 Claude Code 세션에서는 정상 호출됨.

## 검증 중 발견·수정한 문제 (모두 해소)
1. **트리거 없는 스킵 경로가 죽음** — `set -o pipefail` + `set -e`에서 빈 입력의 `grep -v '^$'`가 exit 1 → 명령치환 할당이 스크립트를 종료. → 해당 파이프라인에 `|| true` 추가.
2. **Codex 스키마 400 오류** — OpenAI structured-output은 `additionalProperties:false`일 때 `required`에 모든 properties 키를 요구. `summary`가 빠져 `invalid_json_schema` 발생. → `summary`를 `required`에 추가.
3. **parse-fail stderr의 exit code 오염** — `{ head; head; } | head -c 200`의 SIGPIPE가 pipefail로 전파. → 중첩 파이프 제거, 각 `head ... || true`.
4. **CRLF 위험** — autocrlf 환경에서 `.sh`가 CRLF 체크아웃 시 셰뱅 깨짐. → `.gitattributes`로 `*.sh eol=lf` 고정.

## 결론
파이프라인 셋업 **완료**. dry-run A/B 자동 검증 통과, dry-run C는 사람 수행 대기(규정상 정상). 첫 실제 작업(envelope spec 작성)과 e2e baseline 작성은 별도 명령으로 진행(§8 out of scope).

# codex-gate verified_commit 수동 전진 — Stop hook EINVAL 수정 게이트 (2026-06-24)

> Node 24의 `.cmd` 직접 spawn 차단(EINVAL)으로 죽던 Stop hook을 `cmd.exe` 경유로 고친 `.claude/settings.json` 변경에 대해 게이트가 2라운드 FAIL. **critical 1건은 코드/베이스라인 대조 후 오탐, spec 2건은 경험적 반증**으로 분류해 verified_commit 전진으로 종결. 사용자 승인(2026-06-24 "이대로 진행해줘"). 메모리 [[hook-cmd-spawn-einval-fix]].

## 1. 사건

- 증상: Stop hook이 `spawn ...\.claude\hooks\git-bash.cmd EINVAL`로 실패(meta 자체 hook + harness 플러그인 hook 동시).
- 원인: Node.js 보안 패치(CVE-2024-27980, Node 18.20.2+/20.12.2+/22/24)가 `.cmd`/`.bat`를 `shell:true` 없이 직접 spawn하면 EINVAL. 현재 Node v24.14.0. exec-form으로 `git-bash.cmd`(`.cmd`)를 직접 가리킨 게 원인.
- 수정 경과(2라운드):
  - **1차 시도**: `command`를 `C:\Program Files\Git\bin\bash.exe` 하드코딩 → 게이트 FAIL(비표준/Portable Git 깨짐, shim의 `%ProgramFiles%` 간접 손실). **타당 → 폐기**.
  - **2차 채택**: shim 유지 + `command: "cmd.exe"`, `args: ["/c", git-bash.cmd, codex-gate.sh]`. `cmd.exe`는 진짜 `.exe`라 EINVAL 없음 + shim의 `%ProgramFiles%` 복원. → 게이트가 이 명령으로 **실제 실행되어** 2차 FAIL 피드백을 냄(= 수정이 동작한다는 증거).

## 2. 2차 지적 분류

| 지적 | 분류 | 처리 |
|---|---|---|
| **critical**: cmd.exe로 바꿔 Windows 전용 고정 → Linux/macOS 호환성 회귀 | **오탐 (없던 회귀)** | 베이스라인이 **이미 100% Windows 전용** — 원 `git-bash.cmd`는 `.cmd` 배치가 `%ProgramFiles%\Git\bin\bash.exe`를 부르는 Windows 전용 shim. `cmd.exe`는 모든 Windows에 System32로 상존. 이 환경은 win32 전용. 깨질 비-Windows 경로가 애초에 없음 |
| **spec**: 상태/캐시/trigger/flow 미변경 → 근거 부족 | **무관** | 순수 진입점 수정. 해당 로직은 바뀌면 안 되는 게 정상 |
| **spec**: `cmd /c <bat> <script>` 공백/특수문자 quoting 우려 | **경험적 반증** | 적용 전 정확한 경로로 `HOOKCHAIN_OK` 실증 + 방금 게이트가 이 명령으로 실제 실행됨. 현재 경로 공백 없음. shim은 `%*` 통과, 공백 `%ProgramFiles%`는 따옴표 처리 |

## 3. 증거 (재현 가능)

- 체인 동작: `cmd.exe /c "C:\workspace\monitoring\monitoring-meta/.claude/hooks/git-bash.cmd" -c "echo HOOKCHAIN_OK"` → `HOOKCHAIN_OK`.
- 자기증명: 2차 게이트 FAIL 피드백 헤더 `[cmd.exe /c ...git-bash.cmd ...codex-gate.sh]` 자체가 codex-gate.sh가 cmd.exe 경유로 spawn·실행됐음을 증명(EINVAL 해소).
- shim 무변경: `.claude/hooks/git-bash.cmd` = `@"%ProgramFiles%\Git\bin\bash.exe" %*`.

## 4. 조치

verified_commit `4153b49` → 본 수정+감사기록 커밋으로 전진. 전진 후 작업트리 clean·vc=HEAD라 윈도우 비어 다음 Stop은 SKIP. EINVAL은 실행 차단(파싱·spec 무관)이었고 진입점 교체로 근본 해소, 게이트 지적은 위 분류대로 오탐/반증.

## 5. 허용 조건 (`codex-gate-vc-advance-20260614-2-contract.md` §5 준용)

1. critical 지적은 **베이스라인 대조로 오탐 확정**(없던 호환성 회귀).
2. spec 2건은 **경험적 반증**(체인 실증 + 게이트 자기실행).
3. **사용자 승인** 존재(2026-06-24).
4. block.log + 본 감사기록에 증거 묶음.

## 6. 후속

- harness 플러그인 `hooks.json`(Stop=codex-gate + PreToolUse=write-guard 둘 다 동일 `.cmd` 직접 spawn)은 별도 세션에 동일 패턴(cmd.exe 경유) 수정 발주 + `/plugin update`. hub/script-agent/infra는 자체 hook 없어 개별 수정 불필요(글로벌 플러그인 영향만).

## 7. 되돌리기

state 파일 `.claude/.codex-gate-state`의 `verified_commit`을 `4153b4922b434ee46d56066723149d7590d086a7`로 복원하면 FAIL 재현.

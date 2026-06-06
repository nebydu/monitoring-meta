# 작업 spec — harness-codex-gate-graceful-skip (plugin이 profile 없는 repo에서 Stop을 막지 않게)

> 이 handoff는 monitoring-harness 세션이 받아 실행한다. `harness@monitoring` plugin의 codex-gate Stop hook이 **profile이 없는 repo에서 `exit 2`로 세션 종료를 막는** 문제를 고친다. 코드 변경은 plugin 진입 스크립트 1곳(+테스트/문서). meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `harness-codex-gate-graceful-skip` |
| 대상 repo | `monitoring-harness` |
| 기준 monitoring-meta commit | 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 확인 (작성 시점 HEAD = `3182370`) |
| 작성일 | 2026-06-06 |
| 관련 | harness G-4/D-7(plugin packaging 안전성), infra `phase1-040-infra.md` §9.1(이 문제를 촉발한 codex-gate 롤아웃) |

## 2. 배경 / 문제 (정확히)

`hooks/hooks.json`이 codex-gate Stop hook을 **모든 repo에 글로벌로 등록**한다(plugin이 user 레벨로 켜져 있으면 모든 프로젝트에 적용). Stop hook은 `hooks/codex-gate-entry.sh`를 부르고, 그 스크립트는 consumer profile을 convention 경로 `${CLAUDE_PROJECT_DIR}/.claude/codex-gate.profile`에서 찾는다.

현재 entry 스크립트는 **profile을 못 찾으면 `exit 2`(구성 오류)** 로 떨어진다:

```bash
PROFILE="${CODEX_GATE_PROFILE:-${1:-${CLAUDE_PROJECT_DIR:-}/.claude/codex-gate.profile}}"
if [ -z "$PROFILE" ] || [ ! -f "$PROFILE" ]; then
  echo "[codex-gate] 구성 오류: consumer profile을 찾지 못함 ('$PROFILE'). <repo>/.claude/codex-gate.profile 존재를 확인하세요." >&2
  exit 2
fi
```

Stop hook이 `exit 2`를 내면 **세션 종료가 막힌다.** 그런데 **plugin 소비자가 아닌 repo**(profile을 두지 않은 repo, 예: monitoring-meta — meta는 자체 구형 `.claude/hooks/codex-gate.sh`를 쓰고 plugin profile이 없다)에서도 글로벌 Stop hook이 발동하므로, 그런 repo는 **세션을 끝낼 때마다 plugin 구성 오류로 Stop이 막힌다.**

즉 "profile이 없다 = 이 repo는 plugin codex-gate의 소비자가 아니다"인데, 현재 코드는 이를 **오류로 취급해 모두를 막는다.** 올바른 동작은 **profile이 없으면 조용히 건너뛰는 것**(plugin이 이 repo를 게이팅하지 않음)이다.

> 임시 회피: monitoring-meta는 `.claude/settings.json`에 `enabledPlugins: { "harness@monitoring": false }`(project override)로 plugin을 꺼 둔 상태다. **이 harness 수정이 반영되면 meta의 그 override는 제거해도 된다**(profile 없는 meta를 plugin이 알아서 건너뛰므로). 단 meta는 plugin 전환 전까지 자체 hook 유지 — override 제거는 meta 세션 판단.

## 3. 정확한 변경

### 3.1 `hooks/codex-gate-entry.sh` — profile 부재 시 graceful skip

profile을 **convention 경로에서 자동 탐색했는데 없을 때**는 `exit 0`(skip). 단, 사용자가 **명시적으로 `CODEX_GATE_PROFILE`을 지정했는데 그 파일이 없을 때**는 진짜 오타/오설정이므로 **기존대로 `exit 2`**로 둔다(이 구분을 권장).

제안 형태(세부는 harness 세션 재량, 동작만 맞추면 됨):

```bash
# profile 경로 결정
EXPLICIT_PROFILE="${CODEX_GATE_PROFILE:-}"
PROFILE="${EXPLICIT_PROFILE:-${1:-${CLAUDE_PROJECT_DIR:-}/.claude/codex-gate.profile}}"

if [ -z "$PROFILE" ] || [ ! -f "$PROFILE" ]; then
  if [ -n "$EXPLICIT_PROFILE" ]; then
    # 명시 지정한 경로가 없음 = 오설정 → 기존대로 막는다
    echo "[codex-gate] 구성 오류: 지정한 CODEX_GATE_PROFILE을 찾지 못함 ('$EXPLICIT_PROFILE')." >&2
    exit 2
  fi
  # convention 경로에 profile 없음 = 이 repo는 plugin codex-gate 소비자가 아님 → 조용히 skip
  exit 0
fi
```

> `exit 0`이면 Stop이 정상 진행된다. skip 사실을 알리고 싶으면 stdout으로 `{"systemMessage":"..."}` JSON 한 줄을 출력해도 되지만(선택), Stop hook 글로벌 발동이라 **조용한 skip(메시지 없음)을 권장**한다 — 매 세션 종료마다 noise가 되지 않도록.

### 3.2 (선택) `shared/hooks/README.md` / wrapper 주석

"profile이 없는 repo에서는 plugin codex-gate가 자동으로 skip된다(소비자 opt-in 모델)"를 1~2줄 명시. consumer가 되려면 `.claude/codex-gate.profile`을 두면 된다는 점.

## 4. 검증 / DoD

- [x] **profile 없는 repo에서 skip**: `CLAUDE_PROJECT_DIR`를 profile 없는 디렉터리로 두고 entry.sh를 Stop 입력(JSON)과 함께 실행 → **exit 0**, 출력 noise 없음(또는 skip 메시지 1줄). 세션 종료가 막히지 않음.
- [x] **명시 오설정은 여전히 차단**: `CODEX_GATE_PROFILE=/없는/경로` 지정 시 **exit 2** 유지.
- [x] **소비자 repo는 정상 게이팅**: profile 있는 hub/script-agent에서는 기존대로 trigger glob 매칭 시 Codex 호출(동작 불변). profile 있고 코드 변경 없으면 core가 SKIP.
- [x] plugin 재패키징/캐시 갱신 후 실제 머신에서 meta 세션 Stop이 더 이상 plugin 구성 오류로 막히지 않음을 확인.
- [x] 기존 hub/script-agent gate 회귀 없음(profile 경로·core 동작 불변).

## 5. 범위 / 제외

- **포함**: `hooks/codex-gate-entry.sh`(필수) + README/주석(선택) + 관련 테스트가 있으면 갱신.
- **제외**: `codex-gate-core.sh` 골격 로직(core의 필수 주입점 검증은 그대로 — entry가 source하기 전에 skip하므로 core까지 가지 않음), profile 내용, consumer repo 파일.

## 6. 미결정 사안

- 없음(동작 결정은 명확: convention 부재=skip / 명시 오설정=차단). 단 "skip 시 메시지를 낼지"는 noise 관점의 사소한 선택 — 권장은 조용한 skip.

## 7. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["entry.sh skip 분기 / 테스트 / 문서 반영 / 캐시 갱신 확인"],
  "blockers": [],
  "next_action": "meta override(enabledPlugins false) 제거 가능 여부 통지 등"
}
```

## 8. 결과 보고 — harness 세션 (2026-06-06)

```json
{
  "status": "ok",
  "outputs": [
    "monitoring-harness hooks/codex-gate-entry.sh (commit b200cd5)",
    "monitoring-harness shared/hooks/README.md (commit b200cd5, opt-in 소비자 모델 명시)"
  ],
  "findings": [
    "entry.sh skip 분기 반영: convention 부재=exit 0(조용한 skip), CODEX_GATE_PROFILE 명시 오설정=exit 2 유지",
    "plugin 캐시 갱신 확인: ~/.claude/plugins/cache/monitoring/harness/b200cd5bc148/ 에 새 가드 존재(grep 검증)",
    "갱신된 캐시 스크립트로 3개 시나리오 직접 실행 통과: ①profile 없는 repo exit 0·출력 0바이트 ②명시 오경로 exit 2+구성 오류 메시지 ③profile 존재 시 가드 통과해 source 진입(marker profile로 실증)",
    "소비자 repo 회귀 없음 근거: 변경 diff가 entry 가드+README에 한정(core/profile 무변경), profile 존재 경로의 source 진입 실증 — hub/script-agent live Stop 재실행은 별도 수행하지 않음",
    "meta의 enabledPlugins opt-out override는 meta commit b284013에서 이미 제거 완료(2026-06-06 21:05) — 현재 meta는 user 레벨 plugin 활성 + profile 부재로 plugin hook이 graceful skip, 게이팅은 자체 .claude/hooks/codex-gate.sh가 수행(이중 게이팅 없음)"
  ],
  "blockers": [],
  "next_action": "없음 — 본 handoff 종결. (선택) meta가 plugin 소비자로 전환할 때 .claude/codex-gate.profile 추가 + 자체 Stop hook 제거를 별도 handoff로 진행"
}
```

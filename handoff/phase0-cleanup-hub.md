# 작업 spec — phase0-cleanup-hub

| 항목 | 값 |
|---|---|
| work-id | `phase0-cleanup-hub` |
| target repo | `hub` |
| 발행 | monitoring-meta / analyzer |
| 발행일 | 2026-06-05 |
| 선행 분석 | `../monitoring-meta/handoff/phase0-cleanup-000-impact.md` |
| 기준 monitoring-meta commit (full 40자) | `be990c7b936c283d1ad15519fbb9dd6ac7f3deea` |

> **commit pin 주의**: 위 pin은 phase0-cleanup 정리 커밋(데모 spec 단일 기준 문서화 + ROADMAP/envelope/PROJECT_OVERVIEW/.claude repoint + HANDOFF.md archive 격하)에서 채워졌다. **실행 직전 `git rev-parse HEAD`(monitoring-meta)로 재확인**하고 hub repoint 경로가 그 commit의 phase0-snapshot 기준 문서를 가리키는지 확인한다.

---

## 1. 문서 성격 (혼동 금지)

- **데모 spec v0.2.1 = Phase 0 회귀 ground truth.** 본 작업으로 기준 문서 위치가
  `hub/docs/`에서 **`monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`**
  로 이동한다(삭제가 아니라 단일 기준 문서 통합).
- 통합본 v0.9 + kafka-payloads + envelope = Phase 1+ 도달 목표(본 작업 범위 아님).

## 2. ground truth 참조

- 데모 spec 단일 기준 문서: `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`
- 데모 동작 개요(참조): `../monitoring-meta/docs/phase0-snapshot/PROJECT_OVERVIEW.md`

## 3. 배경

Phase 0 셋업기에 hub repo 로컬(`hub/docs/`)에 데모 spec **사본**을 두었다. 이를
monitoring-meta 단일 기준 문서로 통합한다. retire 불가(데모 spec 회귀 계약 중 e2e는
§5.4만 커버) → phase0-snapshot 고정 baseline 보존. hub repo의 사본은 삭제하되,
사본을 가리키던 모든 참조를 먼저 새 기준 문서 경로로 재배선한다.

## 4. 작업 분해

### 4.1 데모 spec 경로 repoint (LIVE 참조)

다음 파일에서 데모 spec을 가리키는 경로를
`../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`로 교체한다.
(구 경로 형태: `docs/monitoring-demo-message-spec-v0.2.1.md`,
`hub/docs/monitoring-demo-message-spec-v0.2.1.md`, `./docs/...` 등.)

- `hub/CLAUDE.md`
- `hub/.claude/CLAUDE.md`
- `hub/AGENTS.md`
- `hub/README.md`
- `hub/.claude/agents/analyzer.md`
- `hub/.claude/agents/implementer.md`
- `hub/.claude/agents/tester.md`
- `hub/.claude/agents/spec-guardian.md`

> 경로 표기는 hub repo 루트 기준 상대경로 `../monitoring-meta/docs/phase0-snapshot/...`를
> 쓴다(워크스페이스에서 hub와 monitoring-meta는 형제 디렉터리).

### 4.2 codex-gate.profile — 라이브 게이트 (주의)

`hub/.claude/codex-gate.profile`은 **세션 종료 게이트가 실제 읽는 라이브 설정**이다.
"Phase 0 데모 spec 회귀" 검증 대상으로 지정된 데모 spec 경로 문구를 새 경로로
**정확히** 교체한다. 문자열이 틀리면 게이트가 spec 파일을 못 찾아 깨진다. 교체 후
게이트 프로파일이 파싱되는지(드라이런 가능하면 1회) 확인한다.

### 4.3 HANDOFF.md provenance 정리 + 수동 갱신 룰 제거

루트 HANDOFF.md가 `archive/`로 격하(메타 메인 세션 처리)되므로 hub 쪽 HANDOFF 인용을 정리한다.

- `hub/.claude/CLAUDE.md`, `hub/.claude/agents/analyzer.md`에서:
  - **"HANDOFF.md §5 체크박스를 수동 갱신한다" 류 운영 룰을 제거**한다(격하 후 무효).
  - HANDOFF.md를 provenance(출처)로 인용한 문장은 **인라인화**(필요한 사실을 그 문서에
    직접 적음)하거나 **제거**한다. 외부 dangling 인용으로 남기지 않는다.
- 단, 루트 HANDOFF.md 파일 자체의 격하/이동은 **메타 메인 세션 몫**이다. hub세션은 hub repo
  안의 인용만 정리한다.

### 4.4 사본 삭제 (반드시 마지막)

위 4.1~4.3 repoint·검증을 **모두 끝낸 뒤에만** `hub/docs/monitoring-demo-message-spec-v0.2.1.md`를
삭제한다. (사본을 먼저 지우면 4.x 검증 시 비교 기준이 사라진다.)

## 5. DoD (완료기준) — 순서 강제

1. (먼저) 4.1~4.3 repoint·룰 정리 완료.
2. (검증) **hub repo 루트에서 실행** — 데모 spec **LIVE dangling 0**:
   `rg "monitoring-demo-message-spec-v0\.2\.1\.md" .` (현재 repo 트리 전체) 결과 중 *현행 유효 참조*가
   새 경로(`../monitoring-meta/docs/phase0-snapshot/...`)만 남고 구 로컬 경로(`docs/...`)는 0건.
3. (검증) `hub/.claude/codex-gate.profile`의 데모 spec 회귀 문구가 새 경로로 정확 교체됨.
   게이트 정상 동작 확인.
4. (검증) HANDOFF.md 수동 갱신 룰 제거됨 / HANDOFF dangling 인용 0.
5. (마지막) `hub/docs/monitoring-demo-message-spec-v0.2.1.md` 삭제.
6. `mvn -DskipTests package`(또는 최소 컴파일)로 문서 변경이 빌드에 영향 없음 확인 — 문서
   전용 변경이므로 코드 회귀는 없어야 한다.

## 6. 미결정 / 주의

- 루트 HANDOFF.md archive 격하 **시점**과 본 repoint 시점의 순서는 메타 메인이 조율
  (분석서 D-C2). 격하이 hub repoint보다 먼저면 hub 내 HANDOFF 인용이 일제히 dangling되니,
  4.3을 그 전제로 수행한다.
- 통합본 `[Open]` / 미결 ADR을 새로 건드리지 않는다(본 작업은 경로 재배선 + 운영 룰 정리 한정).

## 7. 결과 스키마

작업 종료 시 아래를 반환한다:
```json
{"status":"ok|blocked|failed","outputs":["수정/삭제 파일"],"findings":["dangling 검증 결과"],"blockers":["HANDOFF 격하 순서 등"],"next_action":"한 줄"}
```

# spec-backfill — script-agent 작업 spec: 통합본 호칭·경로 재배선

> **work-id**: `spec-backfill` / **대상**: `script-agent` / **발주일**: 2026-06-12
> **배경·결정 기록**: `../monitoring-meta/handoff/spec-backfill/spec-backfill-000-impact.md`
> **meta 기준 commit**: `246c4ffb1d7a1848849383084a3f1458e1ad0481` (rename 적용 커밋)

## 1. 무엇이 바뀌었나 (meta 측 — 이미 적용됨)

- 통합본이 **`../monitoring-meta/docs/master-design.md`** 로 rename됐다(버전 없는 영어 파일명 — 이후 버전은 문서 내부 표기로만 관리, 현재 v0.11). 구 경로 `docs/통합본_v0_9.md`는 redirect stub만 남았고 **형제 repo 컷오버 완료 후 제거 예정**이다.
- v0.11은 내용 변경 릴리스(신규 결정 0): heartbeat protobuf 전환(ADR#2)·토픽 명명(ADR#5)·토픽 재명명(T4-1) 완료를 backfill. script-agent 코드 동작과 충돌 없음 — 이미 otlp push·신 토픽명으로 구현돼 있다.

## 2. 작업 내용 — 호칭·경로 갱신 (문서·설정만, 코드 0)

**갱신 규칙**:
- 경로: `../monitoring-meta/docs/통합본_v0_9.md` → `../monitoring-meta/docs/master-design.md`
- 호칭: `통합본 v0.9` → **버전 없는 표기** `통합본`(처음 등장부엔 `통합본(../monitoring-meta/docs/master-design.md)` 권장) — 다음 버전 인상 때 재갱신이 없도록 버전을 박지 않는다.
- **시점 기록(과거 결정 JSON·완료된 handoff 사본·커밋 pinning 행)은 보존**한다.

**대상(2026-06-11 spec-drift 보고 §2.1 실측 8곳 — 적용 시 `grep -rn "통합본"` 으로 재실측해 누락 보완)**:

| 파일 | 위치(당시 실측) |
|---|---|
| `AGENTS.md` | 46행 `통합본 v0.9` |
| `.claude/CLAUDE.md` | 14행 `통합본 v0.9를 방향 판단의 최상위 기준` / 18행 `통합본 v0.9`+경로 / 34행 |
| `.claude/agents/analyzer.md` | 3행 / 18행 |
| `.claude/agents/implementer.md` | 24행 `통합본 v0.9와 충돌하지 않아야` |
| `.claude/agents/spec-guardian.md` | 40행 `통합본 v0.9 기준` |
| (codex-gate/proposal-review profile 등 추가 매칭) | grep 재실측으로 보완 |

## 3. DoD

- [ ] `grep -rn "통합본_v0_9" .` 매치 0 (시점 기록 제외 — 제외한 행은 보고에 명시)
- [ ] `grep -rn "통합본 v0\.9" .` 매치 0 (상동)
- [ ] 제품 코드·테스트 0 변경 (문서·에이전트 설정·profile만)
- [ ] **e2e 회귀 확인**: 3개 repo 컷오버 후 `monitoring-meta/e2e/run-e2e.sh` 실행 — baseline **60/0/0** 유지 (rename 포함 작업의 공통 DoD — 한 repo에서 대표 1회면 충분, 누가 돌렸는지 보고에 명시)
- [ ] 적용 완료를 monitoring-meta에 보고(이 파일 경로 회신) → 3건 취합 후 meta가 구 경로 stub 제거

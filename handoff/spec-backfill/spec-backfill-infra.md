# spec-backfill — infra 작업 spec: 통합본 호칭·경로 재배선

> **work-id**: `spec-backfill` / **대상**: `infra` / **발주일**: 2026-06-12
> **배경·결정 기록**: `../monitoring-meta/handoff/spec-backfill/spec-backfill-000-impact.md`
> **meta 기준 commit**: `246c4ffb1d7a1848849383084a3f1458e1ad0481` (rename 적용 커밋)

## 1. 무엇이 바뀌었나 (meta 측 — 이미 적용됨)

- 통합본이 **`../monitoring-meta/docs/master-design.md`** 로 rename됐다(버전 없는 영어 파일명 — 이후 버전은 문서 내부 표기로만 관리, 현재 v0.11). 구 경로 `docs/통합본_v0_9.md`는 redirect stub만 남았고 **형제 repo 컷오버 완료 후 제거 예정**이다.
- v0.11은 내용 변경 릴리스(신규 결정 0). infra 설정과 충돌 없음 — `otel-collector-config.yml`의 `otlp_proto`·신 토픽명이 오히려 이번 backfill의 근거다.

## 2. 작업 내용 — 호칭·경로 갱신 (설정 주석·profile만, 컨테이너 구성 0 변경)

**갱신 규칙**:
- 경로: `../monitoring-meta/docs/통합본_v0_9.md` → `../monitoring-meta/docs/master-design.md`
- 호칭: `통합본 v0.9` → **버전 없는 표기** `통합본` — 다음 버전 인상 때 재갱신이 없도록 버전을 박지 않는다.
- **시점 기록은 보존**: `docs/decisions/proposal-review-*.json`(과거 결정 기록)은 수정하지 않는다.

**대상(2026-06-12 meta 측 실측 — 적용 시 `grep -rn "통합본"` 으로 재실측해 누락 보완)**:

| 파일 | 위치 | 갱신 |
|---|---|---|
| `.claude/codex-gate.profile` | 18행 `CODEX_GATE_PROMPT` | 호칭 2곳(`통합본 v0.9` ×2) + 경로 1곳(`../monitoring-meta/docs/통합본_v0_9.md`) |
| `.claude/proposal-review.profile` | 19행 주석 / 30행 `PROPOSAL_REVIEW_POLICY` | 호칭·경로 각 1곳 |
| `docker-compose.yml` | 103·112·117·175행 주석 | **무수정** — 버전 없는 `통합본 §x` 표기라 영향 없음 |

## 3. DoD

- [ ] `grep -rn "통합본_v0_9" .` 매치 0 (시점 기록 `docs/decisions/*.json` 제외 — 제외 행은 보고에 명시)
- [ ] `grep -rn "통합본 v0\.9" .` 매치 0 (상동)
- [ ] `docker compose config` 문법 검증 통과(주석 외 0 변경이므로 형식 확인용)
- [ ] **e2e 회귀 확인**: 3개 repo 컷오버 후 `monitoring-meta/e2e/run-e2e.sh` 실행 — baseline **60/0/0** 유지 (rename 포함 작업의 공통 DoD — 한 repo에서 대표 1회면 충분, 누가 돌렸는지 보고에 명시)
- [ ] 적용 완료를 monitoring-meta에 보고(이 파일 경로 회신) → 3건 취합 후 meta가 구 경로 stub 제거

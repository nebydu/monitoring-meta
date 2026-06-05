# phase0-cleanup-000 — Phase 0 셋업기 산출물 정리: 영향분석 / 참조 인벤토리

> 작성: analyzer (monitoring-meta) · 작성일 2026-06-05
> work-id: `phase0-cleanup-000` · target: meta(분석) + repo별 후속 handoff
>
> **문서 위상 (혼동 금지)**: 데모 spec v0.2.1 = Phase 0 회귀 ground truth.
> 통합본 v0.9 + kafka-payloads + envelope = Phase 1+ 도달 목표.

---

## 0. 작업 개요

Phase 0 셋업기에 양쪽 repo 로컬(`hub/docs/`, `script-agent/docs/`)에 사본으로
두었던 **데모 spec v0.2.1을 monitoring-meta 단일 정본**
(`docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`)으로 통합하고,
이를 가리키던 모든 참조를 새 경로로 재배선한다. **삭제가 아니라 통합**이다
(데모 spec은 phase0-snapshot에 동결 baseline으로 보존).

데모 spec 참조 35파일 + HANDOFF.md 참조 10파일 = 총 45개 참조 surface를 본 표에 집약한다.

---

## 1. retire 조건 판정 (데모 spec 동결 baseline 보존 근거)

**판정: retire(폐기) 불가 → phase0-snapshot 동결 baseline으로 보존.**

근거(사용자 확정 + 코드 확인):
- `e2e/run-e2e.sh`는 데모 spec **§5.4(heartbeat 논리계약)만** 회귀 검증한다(ADR#2
  종단 검증 경로).
- 데모 spec **§2.2 헤더 4종**(`x-message-id`/`x-message-version`/`x-source`/`x-trace-id`),
  **command-topic envelope**, **result 토픽 계약**은 e2e가 **미커버**.
- 즉 데모 spec이 보장하는 회귀 계약의 일부만 자동 검증되므로, spec 문서 자체를
  ground truth 동결 baseline으로 유지해야 회귀 기준이 사라지지 않는다.
- 따라서 데모 spec은 `docs/phase0-snapshot/`에 단일 정본으로 보존하고, 각 repo
  사본만 삭제한다(사본 삭제는 repoint·검증 완료 후 수행 — DoD 순서 참조).

---

## 2. 참조 인벤토리 (45개)

처리주체 범례: `analyzer`(본 작업에서 meta가 직접) / `meta메인`(메타 메인 세션) /
`hub세션` / `script-agent세션` / `harness세션`.
LIVE = 현행 유효 참조(dangling 시 실패) / HISTORICAL = 시점 스냅샷(원칙 비수정,
LIVE dangling 검증 비대상).

### 2.1 meta 내부 — 이미 완료 (4건, 재작업 금지)

| repo | 파일 | LIVE/HIST | 처리주체 | repoint 대상 | 비고 |
|---|---|---|---|---|---|
| meta | `docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` | LIVE | analyzer | (신규 단일정본) | **완료(이전 호출)** — 본문 verbatim + 위상 헤더 |
| meta | `docs/envelope.md` | LIVE | analyzer | `docs/phase0-snapshot/...` (2곳) | **완료(이전 호출)** |
| meta | `handoff/_TEMPLATE-work-spec.md` | LIVE | analyzer | `../monitoring-meta/docs/phase0-snapshot/...` | **완료(이전 호출)** |
| meta | `handoff/phase1-001-envelope-scope.md` | LIVE | analyzer | `../monitoring-meta/docs/phase0-snapshot/...` | **완료(이전 호출)** |

### 2.2 meta 내부 — 본 작업에서 analyzer 처리 (이번 호출)

| repo | 파일 | LIVE/HIST | 처리주체 | 처리 | 비고 |
|---|---|---|---|---|---|
| meta | `docs/phase0-snapshot/PROJECT_OVERVIEW.md` | LIVE | analyzer | 데모 spec 경로 5곳 정정 + §3.1/§8.1 superseded 표시 | **완료(이번)** — 본문 보존, 표시만 |
| meta | `docs/phase1/ROADMAP_PHASE1_v0_3.md` | LIVE | analyzer→meta메인 | **D-C1 재배선 적용(be990c7)** | 작성 시점엔 [결정 필요]였으나, 사용자 D-C1 결정 후 메인이 루트 `HANDOFF.md §5/§7` source_ref 15곳을 ROADMAP §9~§14/§17·통합본 §8.3/§13_open으로 외과적 재배선. §4·§16 "HANDOFF"(handoff/ 역할)는 보존. 무결성 보존(§5) |
| meta | `handoff/adr-002-analysis.md` (라인7) | HIST | analyzer | **본문 비수정** | (a)repoint 후보였으나 303줄 전면 Write 무결성 위험 → 본 표에 "경로는 당시 기준" 집약. LIVE 검증 비대상 |
| meta | `handoff/adr-002-hub.md` (라인23) | HIST | analyzer | **본문 비수정** | 당시 repo 사본을 가리킨 시점 사실. 본 표 집약 |
| meta | `handoff/adr-002-script-agent.md` (라인21) | HIST | analyzer | **본문 비수정** | 동일 |
| meta | `handoff/envelope-draft-analysis.md` (라인5) | HIST | analyzer | **본문 비수정** | (a)repoint 후보였으나 216줄 전면 Write 무결성 위험 → 본 표 집약 |
| meta | `handoff/spec-drift-20260527-000000.md` | HIST | analyzer | **본문 비수정** | 정본/사본 위치 비교가 본문 논지(repoint 시 의미 붕괴) → (b)취지의 집약 |
| meta | `handoff/spec-drift-envelope-20260527-143000.md` | HIST | analyzer | **본문 비수정** | 동일 |
| meta | `handoff/phase1-000-roadmap-normalization.md` | HIST | (없음) | 변경 불필요 | 데모 spec 직접 경로 없음. HANDOFF.md 언급만(메인 몫) |
| meta | `handoff/phase1-000b-consistency-checklist.md` | HIST | (없음) | 변경 불필요 | 데모 spec 직접 경로 없음. HANDOFF.md 언급만(메인 몫) |

> **HISTORICAL 처리 방침 (G 산출물 — 최종)**: 6개 HISTORICAL handoff
> (`adr-002-analysis`, `adr-002-hub`, `adr-002-script-agent`, `envelope-draft-analysis`,
> `spec-drift-20260527-000000`, `spec-drift-envelope-20260527-143000`)는 **본문을 수정하지
> 않는다.** 사유: (1) 모두 시점 스냅샷이라 **LIVE dangling 검증의 실패 대상이 아니다**,
> (2) 67~303줄 파일을 1줄 repoint/주석을 위해 전면 Write하면 본문 무결성 위험이 이득보다 크다,
> (3) 이들 참조의 의미는 "그 작업 시점에 데모 spec 정본/사본이 hub/docs·script-agent/docs에
> 있었다"는 **당시 사실**이며, 경로는 *당시 기준*으로 해석해야 한다(현재 정본은
> `monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md`).
> 이 "당시 기준" 단서를 본 표가 **집약 주석**으로 대신한다(개별 파일 (b)주석과 동등한 효과,
> 무결성 위험 0). 향후 해당 파일을 다른 사유로 편집할 일이 생기면 그때 1줄 단서를 인라인하면 된다.

### 2.3 hub repo — hub세션 처리 (handoff: phase0-cleanup-hub.md)

| 파일 | LIVE/HIST | 처리주체 | repoint 대상 | 비고 |
|---|---|---|---|---|
| `hub/docs/monitoring-demo-message-spec-v0.2.1.md` | — | hub세션 | (사본 삭제) | **repoint·검증 후 삭제** (DoD 순서) |
| `hub/CLAUDE.md` | LIVE | hub세션 | `../monitoring-meta/docs/phase0-snapshot/...` | 데모 spec 경로 |
| `hub/.claude/CLAUDE.md` | LIVE | hub세션 | 동일 + **HANDOFF provenance 정리 + "HANDOFF §5 체크박스 수동 갱신" 룰 제거** | |
| `hub/AGENTS.md` | LIVE | hub세션 | 동일 | |
| `hub/README.md` | LIVE | hub세션 | 동일 | |
| `hub/.claude/codex-gate.profile` | LIVE(게이트) | hub세션 | "Phase 0 데모 spec 회귀" 문구를 새 경로로 정확 교체 | **라이브 게이트 — 주의** |
| `hub/.claude/agents/analyzer.md` | LIVE | hub세션 | 데모 spec 경로 + **HANDOFF §5 수동 갱신 룰 제거** | |
| `hub/.claude/agents/implementer.md` | LIVE | hub세션 | 데모 spec 경로 | |
| `hub/.claude/agents/tester.md` | LIVE | hub세션 | 데모 spec 경로 | |
| `hub/.claude/agents/spec-guardian.md` | LIVE | hub세션 | 데모 spec 경로 | |

### 2.4 script-agent repo — script-agent세션 처리 (handoff: phase0-cleanup-script-agent.md)

hub와 동형. Go 컨텍스트(go test), 동일 파일군 + provenance + 사본 삭제.

| 파일 | LIVE/HIST | 처리주체 | repoint 대상 | 비고 |
|---|---|---|---|---|
| `script-agent/docs/monitoring-demo-message-spec-v0.2.1.md` | — | script-agent세션 | (사본 삭제) | repoint·검증 후 삭제 |
| `script-agent/CLAUDE.md` | LIVE | script-agent세션 | `../monitoring-meta/docs/phase0-snapshot/...` | |
| `script-agent/.claude/CLAUDE.md` | LIVE | script-agent세션 | 동일 + HANDOFF provenance 정리 + 수동 갱신 룰 제거 | |
| `script-agent/AGENTS.md` | LIVE | script-agent세션 | 동일 | |
| `script-agent/README.md` | LIVE | script-agent세션 | 동일 | |
| `script-agent/.claude/codex-gate.profile` | LIVE(게이트) | script-agent세션 | 새 경로로 정확 교체 | 라이브 게이트 — 주의 |
| `script-agent/.claude/agents/analyzer.md` | LIVE | script-agent세션 | 데모 spec 경로 + HANDOFF §5 수동 갱신 룰 제거 | |
| `script-agent/.claude/agents/implementer.md` | LIVE | script-agent세션 | 데모 spec 경로 | |
| `script-agent/.claude/agents/tester.md` | LIVE | script-agent세션 | 데모 spec 경로 | |
| `script-agent/.claude/agents/spec-guardian.md` | LIVE | script-agent세션 | 데모 spec 경로 | |

### 2.5 monitoring-harness — harness세션 처리 (handoff: phase0-cleanup-harness.md)

| 파일 | LIVE/HIST | 처리주체 | repoint 대상 | 비고 |
|---|---|---|---|---|
| `shared/hooks/profiles/hub.profile.example` | LIVE | harness세션 | 데모 spec 경로 → 새 경로 | `.example` 템플릿 — 우선순위 낮음 |
| `shared/hooks/profiles/script-agent.profile.example` | LIVE | harness세션 | 동일 | 동일 |

### 2.6 메인 세션 처리 대상 (analyzer 손대지 않음)

| 파일 | 처리주체 | 비고 |
|---|---|---|
| 루트 `HANDOFF.md` | meta메인 | `archive/`로 강등(사용자 확정 2). analyzer/sub-agent 비수정 대상 |
| `.claude/*` (meta repo) | meta메인 | 본 sub-agent Write 범위 밖 |
| 각 repo `.claude/*` 중 HANDOFF.md 강등 연동 후속 | meta메인 ↔ repo세션 | HANDOFF archive 후 깨지는 참조는 repo세션 handoff에 포함(§3) |

> **HANDOFF.md 참조 10파일 분포**: hub 2(`.claude/CLAUDE.md`, `.claude/agents/analyzer.md`),
> script-agent 2(동형), meta HISTORICAL 2(`phase1-000-roadmap-normalization.md`,
> `phase1-000b-consistency-checklist.md` — 비수정), ROADMAP 1(D-C1 [결정 필요]),
> 루트 HANDOFF.md 자체 + meta `.claude/*`(메인 몫). repo의 LIVE 4건은 §2.3/§2.4 handoff에 포함.

---

## 3. repo 세션 작업 요약 + 완료기준

- **hub세션**(phase0-cleanup-hub.md): 데모 spec 경로 8파일 repoint, codex-gate.profile
  라이브 교체, HANDOFF provenance 정리 + 수동 갱신 룰 제거, **검증 후** 사본 삭제.
- **script-agent세션**(phase0-cleanup-script-agent.md): hub 동형(Go/go test).
- **harness세션**(phase0-cleanup-harness.md): profile.example 2개 repoint(후순위).

**공통 완료기준 (DoD)**:
1. 해당 repo 내 데모 spec **LIVE dangling 0** (구 경로 `docs/monitoring-demo-message-spec-v0.2.1.md`
   또는 `hub/docs/...`/`script-agent/docs/...`를 가리키는 *현행* 참조가 0건).
2. `codex-gate.profile`의 데모 spec 회귀 문구가 새 경로로 정확히 교체됨(라이브 게이트
   — 잘못 교체 시 게이트가 깨짐).
3. **순서 강제**: repoint·검증을 **먼저** 끝내고, 그 다음 로컬 사본
   `docs/monitoring-demo-message-spec-v0.2.1.md`를 삭제한다(사본 먼저 지우면 검증 불능).
4. 기준 commit pin은 meta가 정리 커밋 후 채운 full 40자 해시 사용(실행 전 `git rev-parse HEAD` 재확인).

---

## 4. [결정 필요] (사람 입력 대기)

- **D-C1 (ROADMAP HANDOFF source_ref 재배선)**: ROADMAP_PHASE1_v0_3.md는
  `HANDOFF.md §5(작업 위상)` / `§7(미결정)`을 **의도적 source_ref 표기 규칙**으로 채택했다
  (§1 라인26~28 drift-3 정밀화, §4 ROADMAP↔HANDOFF 역할 정의). ROADMAP 본문은 §5/§7 내용을
  자체적으로 담지 않고 루트 HANDOFF.md를 *보조 입력*으로 외부 참조한다. 따라서 `HANDOFF.md §5/§7`
  를 ROADMAP 자체 절로 **무손실 치환 불가**. 게다가 루트 HANDOFF.md는 `archive/` 강등이
  **메인 세션 처리 대상**이라, 강등 후 (a) archive 경로로 재배선할지 (b) ROADMAP §4·§5에 §5/§7
  요지를 인라인 흡수할지 (c) 참조를 통합본/envelope 정본으로 대체할지 결정이 선행돼야 한다.
  → analyzer는 ROADMAP를 변경하지 않았음. **[해소 2026-06-05] D-C1 결정 = ROADMAP 자체 절+통합본 정본 재배선((b)/(c) 혼합). 메인 세션이 §5/§7 source_ref 15곳을 외과적 Edit로 재배선(be990c7). §4·§16 "HANDOFF"(handoff/ 역할 명칭)는 보존.**

- **D-C2 (HANDOFF.md archive 연동 repo 참조 순서)**: 각 repo `.claude/CLAUDE.md`·
  `agents/analyzer.md`의 "HANDOFF §5 체크박스 수동 갱신" 룰 제거 + provenance 인용 정리는 repo
  세션 handoff에 포함했으나, 루트 HANDOFF.md 강등 자체는 메인 세션 몫이다. **강등 시점**과
  repo repoint 시점의 순서를 메인이 조율해야 한다(강등 먼저면 repo의 HANDOFF 인용이 일제히 dangling). **[해소 2026-06-05] D-C2 기본값 적용: 메인이 meta-side 의존을 먼저 끊고 be990c7에서 archive 강등 → repo는 분배 세션에서 자기 인용 정리. 강등~repoint 사이 dangling 창을 줄이려 루트에 redirect tombstone `HANDOFF.md`(전체 본문은 `archive/HANDOFF.md`)를 둠.**

- **(없음 확인)** 통합본 v0.9 `[Open]` / `13_open.md` / 미결 ADR을 새로 건드리는 변경은 본 작업에
  포함되지 않음. PROJECT_OVERVIEW의 Alert/Incident phase 귀속 충돌은 **정본(통합본/ROADMAP)이 이미
  Phase 1로 확정**(통합본 §6.9.3, ROADMAP §3/§5.1)되어 있어 추측이 아니라 superseded 표시로 해소함.

---

## 5. ROADMAP 무결성 (D-C1 재배선 적용 후 — be990c7)

- 섹션: §1~§19 **19개 전부 존재**(`## 1`~`## 19` grep 확인).
- ADR 행: §5.1 ADR status 표에 `#1`~`#18` **18개 행 존재**.
- §1 기준 pin: `4940e1a115b911e452f96f0083f1c4dc6ede879f` **보존**.
- 문서 버전: **v0.3 (정본 후보) 보존**.
- 결론: **(정정)** analyzer 작성 시점엔 ROADMAP 무변경이었으나, 사용자 D-C1 결정 후 메인 세션이 루트 `HANDOFF.md §5/§7` source_ref 15곳을 외과적 재배선(be990c7). §4·§16 "HANDOFF"(handoff/ 역할 명칭)는 보존. 위 4개 무결성 지표(섹션/ADR/pin/버전)는 **재배선 후에도 그대로 유지됨**을 재확인.

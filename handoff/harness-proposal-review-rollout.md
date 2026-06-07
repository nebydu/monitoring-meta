# 완료 보고 — harness-proposal-review-rollout (H6: /proposal-review 전 repo 배포)

> 이 문서는 **완료 보고**다(실행 대상 작업 spec 아님). monitoring-harness plugin H6에서
> `/proposal-review`(결정 전 제안 교차 리뷰 command)를 구현하고 5개 repo(plugin 1 + consumer 4)에
> 배포 완료한 기록이다. graceful-skip 건과 달리 meta 지시서 없이 harness 전략 초안에서 출발했으므로,
> 별도 보고 파일로 남긴다.

## 1. 헤더

| 필드 | 값 |
|---|---|
| 작업 ID | `harness-proposal-review-rollout` |
| 주관 repo | `monitoring-harness` (H6) |
| 결정 기준 문서 | `monitoring-harness/docs/decisions/proposal-review-scope.md` (H4 재해석 + plugin 2축 정의) |
| 보고일 | 2026-06-07 |
| 관련 | `harness-codex-gate-graceful-skip.md`(선행 — 의도 신호 원칙의 출처), `proposal-review-meta-consumer-20260607.json`(meta 실전 1회 아티팩트) |

## 2. 무엇이 생겼나 (요약)

- **plugin 2축화**: ① runtime codex-gate(Stop hook, sa/hub 전용 — H4 유지) + ② `/proposal-review`
  command(명시 호출, **meta 포함 전 repo 소비 가능**). H4 재해석으로 범위 충돌 해소.
- **command 구성**: `commands/proposal-review.md` + 최소 runner(state/escalation 없음 — 대화형) +
  공통 프롬프트(verdict 경계: block=방향·결정기록 충돌 / revise=보완) + schema
  (`approve|revise|block`, `critical_issues` 어휘 통일).
- **consumer 모델**: convention `.claude/proposal-review.profile`(문맥 문서 배열 + 도메인 정책).
  부재 시 degraded 실행 + 그 사실을 출력 JSON `context` 필드에 명시(조용한 skip 금지 —
  codex-gate와 반대 방향, 의도 신호 원칙).
- **통합본 발췌 원칙**: 통합본 v0.9(170KB)는 전 consumer에서 상시 주입 제외. 직접 쟁점인 제안은
  본문에 관련 절 발췌. 발췌 없으면 Codex가 missing_context로 지적하도록 정책 주입.

## 3. repo별 반영 커밋

| repo | 커밋 | 내용 |
|---|---|---|
| monitoring-harness | `f1e9c10` → `62b8962` → `a455246` → `196a50d` → `49946e0` | scope 결정 → MVP 구현 → profile 탐색 수정 → H6 마감 → CRLF 규칙 |
| monitoring-meta | `ce616d1`, `1306546`, `0d861dc` | profile 등록(+실전 아티팩트) / `*.profile` LF / root 산출 수정 |
| script-agent | `f161570`, `660aaa5` | profile 등록 / root 산출 수정 |
| hub | `950c2f3`, `063858e`, `48da1ea` | `*.profile` LF / profile 등록 / root 산출 수정 |
| infra | `808786a`, `b47fcef`, `0da1820` | profile 등록(+LF 일반화) / root 산출 수정(선행) / dry-run 아티팩트 |

## 4. 검증 (전부 배포 캐시 `49946e03c892` 기준 재확인 완료)

- **plugin 설치 상태**: installed_plugins 3항목(sa/hub project + user) 모두 `49946e0` —
  runner 수정 포함 최신.
- **4 consumer profile 발견·문맥 조립**: meta 6/6, sa 5/5, hub 5/5, infra 6/6 통과.
- **실 codex 리뷰 4회** — 전 repo에서 **의도적 결함 제안**을 주입 문맥 근거로 차단함을 실증:
  - meta: profile 등록 제안 자체 → `revise`(배포 공백 자기지적 — 실제 미배포 의존을 정확히 적발)
  - sa: 단일 consumer 직렬 위반 제안 → `block`(high, 데모 spec §6.2 불변식 ⑤ 인용)
  - hub: envelope 헤더 생략 제안 → `block`(high, §2.2 인용 + 거짓 전제를 envelope.md 대조 반박)
  - infra: otlp_json 회귀 제안 → `block`(high, ADR-0002 인용 + 현행 collector 설정값 직접 확인)
- **codex-gate 회귀 없음**: `b200cd5..49946e0` 사이 hooks 경로 무변경(diff 0).

## 5. 과정에서 발견·수정한 함정 3건 (재발 방지 기록)

1. **`CLAUDE_PROJECT_DIR`는 hook 컨텍스트 전용** — command의 Bash tool 환경에는 없다.
   초기 runner가 이 변수로만 profile을 찾아 consumer에서 항상 degraded. → `git rev-parse`
   fallback(harness `a455246`).
2. **profile root 산출의 cwd 의존** — profile 내부 `git rev-parse`는 repo 밖 cwd에서 즉사,
   **다른 repo cwd에서는 타 repo 문서를 warning 없이 주입**(조용한 문맥 오염). →
   `BASH_SOURCE` 기준 산출로 4 repo 정렬(infra `b47fcef` 선행, 나머지 3 repo 후속).
3. **bash가 source하는 비-.sh 파일의 CRLF 사각지대** — `*.sh` LF 규칙이 `.profile`을 못 덮어
   fresh clone에서 변수/glob 끝 `\r`로 게이트·문맥이 조용히 무력화될 수 있었다. →
   전 repo `.gitattributes`에 `*.profile`(+harness는 `*.example`) LF 고정.

## 6. 결과 보고

```json
{
  "status": "ok",
  "outputs": [
    "monitoring-harness: commands/proposal-review.md, shared/analysis/(runner·prompt), shared/schemas/proposal-review-schema.json, docs/decisions/proposal-review-scope.md, milestones H6",
    "consumer 4 repo: .claude/proposal-review.profile (+.gitattributes LF 규칙)",
    "monitoring-meta handoff: proposal-review-meta-consumer-20260607.json (실전 아티팩트)"
  ],
  "findings": [
    "H4 재해석으로 plugin 2축화 — meta는 runtime gate만 범위 밖, proposal-review는 소비 가능",
    "실 codex 리뷰 4/4에서 주입 문맥 근거 인용·거짓 전제 반박 실증 (block 3, revise 1)",
    "함정 3건 발견·수정: CLAUDE_PROJECT_DIR hook 전용 / profile root cwd 의존(조용한 문맥 오염) / 비-.sh source 파일 CRLF 사각지대",
    "전 검증을 배포 캐시(49946e0) 기준으로 재확인 — 소스가 아니라 배포본 동작이 DoD"
  ],
  "blockers": [],
  "next_action": "운영 수칙 2개만 유지 — ① 기준 문서 추가/이동 작업 DoD에 각 repo profile 문맥 목록 갱신 포함, ② 통합본이 직접 쟁점인 제안은 본문에 관련 절 발췌"
}
```

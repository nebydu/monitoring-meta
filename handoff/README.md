# handoff/ — repo 간 작업 spec 교환소

monitoring-meta가 분석·결정한 결과를 각 repo(hub / script-agent / infra / harness) 세션으로 넘기는 작업 산출물이 누적되는 곳이다. (셋업기 루트 `HANDOFF.md`는 phase0-cleanup으로 `archive/HANDOFF.md`로 격하됨 — 현행 작업 상태·미결정의 기준 문서는 `docs/phase1/ROADMAP_PHASE1_v0_3.md` §9~§14/§17이다.)

## 디렉터리 구조 — 작업 단위 기준

**한 작업 단위(work-id) = 한 디렉터리.** 한 작업에서 나온 산출물(영향 분석 + repo별 spec + proposal-review JSON)이 한 폴더에 묶인다. 파일명은 work-id 접두어를 그대로 유지한다(grep 호환·이력 추적).

```
handoff/
├── README.md, _TEMPLATE-work-spec.md          # 운영 파일 — root 고정
├── <work-id>/                                  # 작업 단위 디렉터리 (예: adr-002/, phase1-040/)
│   ├── <work-id>-000-impact.md / <work-id>-analysis.md   # analyzer 영향 분석
│   ├── <work-id>-hub.md / -infra.md / -script-agent.md / -harness.md  # repo별 작업 spec
│   └── proposal-review-*.json                  # 이 단위에 귀속된 결정 리뷰
├── decisions/                                  # 작업 단위에 귀속되지 않는 결정 자산
│   └── (D-N 결정 입력 패킷, critical-path 분석, 단위 없는 proposal-review 등)
└── spec-drift/                                 # spec-sync drift 보고 (소모성)
    └── spec-drift-<timestamp>.md
```

규칙:
- **디렉터리명 = work-id** (파일명 공통 접두어와 동일). 단일 파일 작업이어도 디렉터리를 만든다(자동화 glob 일관성 — codex-gate가 `handoff/adr-*/*.md`를 트리거로 본다).
- **proposal-review JSON**은 귀속 작업 단위 디렉터리에, 귀속 단위가 없으면 `decisions/`에 둔다.
- **`spec-drift/`**는 검출 시점의 사진이지 영속 자산이 아니므로 완료·확인 후 archive 또는 삭제 대상이다.

> 이력: 2026-06-10 평면 구조(43개 파일)를 작업 단위 디렉터리로 재구성했다. 파일명은 변경하지 않았으므로 구 경로 `handoff/<파일명>`은 `handoff/<work-id>/<파일명>`으로 1:1 대응된다.

## 작업 spec 작성 절차

1. **템플릿 복사**: `_TEMPLATE-work-spec.md`를 복사한다.
2. **경로 규약**: `handoff/<work-id>/<work-id>-hub.md`, `handoff/<work-id>/<work-id>-script-agent.md` (한 파일 = 한 repo, 양쪽에 걸친 ADR이면 두 파일).
3. **필수 헤더를 모두 채운다.** 특히 **`기준 monitoring-meta commit: <full-hash>`** 는 필수다.
   - 이 spec이 가리키는 기준 문서(통합본 v0.9 / envelope.md / kafka-payloads.md)의 고정 시점을 못 박는다.
   - hub·script-agent는 기준 문서를 상대 경로로 참조만 하므로, 작성↔실행 시점 사이 drift를 막으려면 기준 commit이 필요하다(상세는 템플릿 §1.1).
   - monitoring-meta repo 루트에서 `git rev-parse HEAD`로 얻은 **full 40자 hash**를 기입한다(축약 금지).
4. **미결정 사안**이 하나라도 걸리면 추측으로 채우지 말고 멈추고 사람을 호출한다.

## 파일 종류

| 패턴 | 종류 | 위치 | 비고 |
|---|---|---|---|
| `_TEMPLATE-work-spec.md` | 작성 템플릿 | root | 복사 원본. 직접 실행 대상 아님 |
| `<work-id>-hub.md` 등 | 작업 spec | `<work-id>/` | 각 repo 세션의 입력 |
| `*-analysis.md` / `*-000-impact.md` | 분석 산출물 | `<work-id>/` | `analyzer` 산출물 |
| `proposal-review-*.json` | 결정 리뷰 아티팩트 | `<work-id>/` 또는 `decisions/` | `/proposal-review --out` 산출물 (proposal + Codex verdict) |
| `d<N>-*.md` 등 결정 패킷 | 결정 자산 | `decisions/` | 작업 단위 이전의 결정 입력·분석 |
| `spec-drift-*.md` | drift 검출 보고서 | `spec-drift/` | `spec-sync` 산출물. 작업 spec과 별개 |

## 비고

- 기존 handoff 파일에는 `기준 monitoring-meta commit` 필드를 **소급 적용하지 않는다.** 신규 작성분부터 적용한다.

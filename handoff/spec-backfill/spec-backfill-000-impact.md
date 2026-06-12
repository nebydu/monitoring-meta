# spec-backfill — 영향 범위·결정 기록 (000-impact)

> **work-id**: `spec-backfill`
> **작성일**: 2026-06-12
> **목적**: 통합본이 v0.9 확정 이후 내려진 결정·완료된 전환을 미래형/잠정형으로 서술하던 stale 6건을 backfill하고, 파일명을 버전 없는 영어 이름(`docs/master-design.md`)으로 rename. 코드 변경 없음 — 문서 정합 작업.

## 0. meta commit pinning (full 40자)

| 커밋 | hash | 내용 |
|---|---|---|
| 커밋 1/3 | `e0af2ef0826a52415dc4640f639f7b4f1db166de` | 통합본 v0.11 내용 backfill (구 파일명 시점) |
| 커밋 2/3 | `246c4ffb1d7a1848849383084a3f1458e1ad0481` | `git mv` → `docs/master-design.md` + meta 내부 경로 재배선 + 구 경로 redirect stub |
| 커밋 3/3 | `a1a693d6b3244463c9d2590f191fb85d02898baf` | handoff 발주(000-impact + 형제 repo 3건) + spec-drift 보고 + proposal-review 보완(adr/0005 D-5·T4-1 stale 정정) |

## 1. 사람 결정 기록 (2026-06-12 승인)

| 결정 | 내용 | 채택 |
|---|---|---|
| 결정 1 | 버전 인상 | **v0.11 인상(내용 변경 릴리스)** — 결정 요약 박스·mermaid·표가 바뀌므로 표기 전용 v0.10과 구분. 신규 결정 0 — `adr/0002`·`adr/0005` 기존 결정의 반영만 |
| 결정 2 | rename 묶음 | **같은 work-id에 포함**(최초 권고는 분리였으나 사용자 정정) — `docs/통합본_v0_9.md` → **`docs/master-design.md`**. v0.10 때 예고한 후속 결정(DEC-1, `handoff/v0-10-notation/v0-10-notation-000-impact.md` §DEC-1)의 발동. 이후 버전은 문서 내부 표기로만 관리 |
| 결정 2a | 새 파일명 | **`master-design.md`** — "최상위 설계 기준" 역할이 이름에 드러남 (영어 파일명 — 사용자 지정) |
| 결정 2b | 형제 repo 적용 방식 | **handoff 발주** — meta `settings.json` deny(`Write/Edit(../**)`)로 직접 수정 불가. 경로 재배선 포함 handoff 3건(hub/script-agent/infra), 각 repo 세션에서 적용 |
| 결정 3 | §7.2/D-2(β/γ) 절 | **범위 제외 확정** — 6단계 동료 자료 검토 결과로 변경 가능성이 있어 무수정 |

**호칭 방침**: 형제 repo·meta의 통합본 호칭은 "통합본 v0.9" 같은 버전 박힌 표기 대신 **버전 없는 표기**("통합본(`docs/master-design.md`)" 또는 문맥상 "통합본")로 통일한다 — 다음 버전 인상 때 재 sweep이 필요 없도록(결정 2의 "버전은 내부 표기로만 관리" 취지). 단 **시점 기록**(commit pinning 행, 과거 결정 JSON, 과거 handoff/drift 보고)은 보존한다.

## 2. 사전 검증 결과 (후보 6건 전부 사실 확인 — 제외 0건)

| # | 후보 | 검증 결과 (소스 대조) |
|---|---|---|
| 1 | ADR#2 완료 미반영 | 통합본 8곳 미래형 확인(§6.7 본문·mermaid·§6.9.2·§6.9.5·§8.3·§4.4.1·§6.8표·11장 요약). 실제: `adr/0002` **Accepted**(2026-05-31), infra `otel-collector-config.yml:20`=`otlp_proto`, e2e 60/0/0 |
| 2 | ADR#5 결정 미반영 | §8.3 "zone 단위 + 의미 기반", §4.4.1 "(zone 단위)", §6.2 mermaid "command-topic-zone-N", §6.8 routing "zone당 1개" 확인. 실제: `adr/0005` **Accepted**(2026-06-06, 규칙 B + **단일 물리 command-topic**, zone 전개=다중 zone 진입 시 미래 트리거 D-4(1)-future). `heartbeats-topic` 복수형 명시 예외(`adr/0005` §2.2.1)도 통합본 미기록 확인 |
| 3 | 분가 문서 참조 0건 | 통합본 본문에 envelope.md/kafka-payloads.md/adr//docs/features 참조 grep 0건 확인 |
| 4 | 인덱스 stale | 실존하지 않는 분할 파일 13개 나열(`docs/CHANGELOG.md` 등 glob 0건), 깨진 상대 링크 11곳, "분할=source of truth" 단락이 현실 반대. 추가: 인덱스 변경 이력 요약에 v0.10 행 누락(전체 표엔 존재) |
| 5 | kafka-payloads 매핑 표 stale | 12행 "실제 재명명은 Track 4 T4-1(별도 handoff)"가 토픽 재명명(T4-1) 완료(2026-06-07, 3토픽 물리=논리, e2e 58/0/0) 미반영 확인 |
| 6 | 형제 repo 호칭 | hub 13곳/script-agent 8곳(`handoff/spec-drift/spec-drift-20260611-000000.md` §2.1) + **infra 3곳 신규 확인**(`codex-gate.profile:18` 호칭 2곳+경로 1곳, `proposal-review.profile:30` 호칭·경로) |

**위치 정정 1건**: work spec이 DEC-1 rename 트리거 위치를 "ROADMAP 잔존 항목 표"라 했으나 실제 위치는 `handoff/v0-10-notation/v0-10-notation-000-impact.md` §DEC-1(+메모리) — 트리거 내용 자체는 실재(위치 표기 오기).

**추가 발견 1건(반영함)**: ROADMAP §5.1 ADR#5 행이 "잔여=재명명 구현(T4-1)"로 T4-1 완료 미반영 → 커밋 1에서 정정.

## 3. 적용 내역 (meta — 완료)

- `docs/master-design.md`(통합본 v0.11): 후보 1~4 backfill + 변경 이력 v0.11 행(내용 변경 릴리스 명시, v0.10 표기 전용과 구분). §7.2/D-2(β/γ) 절 무수정(결정 3). 미결정([Open question]/13장) 사안 무결정 — zone 전개 시점·heartbeat 운영 baseline 등 Open 유지.
- `docs/kafka-payloads.md`: 매핑 표 "T4-1 완료 / result-topic 분리(T4-2) 잔여" 기준 정정 + 상위 근거 경로 갱신.
- ROADMAP: §5.1 ADR#4·#5 행 정정(기준 문서 먼저) → 액티브 큐 사본 갱신.
- `docs/features/` 5개 파일 + `_template.md`: 호칭을 버전 없는 표기로 전환(affected_feature_docs — `heartbeat-collection.md`의 ADR#2 서술은 이미 완료형으로 정확해 내용 수정 불요, 호칭·경로만). commit pinning 행 보존.
- rename + meta 활성 참조 재배선(커밋 2): `.claude/CLAUDE.md`·agents 4종·`proposal-review.profile`·`codex-gate.sh`·`SETUP_VERIFICATION.md`·`handoff/_TEMPLATE-work-spec.md`·루트 `HANDOFF.md`·ROADMAP·`envelope.md`. 시점 기록(과거 handoff·drift 보고·archive·phase0-snapshot·draft)은 보존.
- 구 경로 `docs/통합본_v0_9.md` = redirect tombstone stub.

## 3.5 Open 보존 검증 (proposal-review 권고 반영 — 기계 대조)

`git diff 74d7368..e0af2ef`(커밋 1, 통합본 본문 diff) 기준:

- [x] `[Open question]` 마커 **삭제 0건** (`grep -cE "^-.*\[Open"` = 0) — D-1(13장 §J)·D-2(13장 §C)·D-4(1)-future(zone suffix)·D-8(13장 §A) 전부 미결 유지.
- [x] §7.2/β/γ 접촉 행 3건 전수 확인 — ① "13_open §C"→"13장 §C" 링크 표기 정정(내용 불변), ②③ 변경 이력 v0.11 행의 범위 제외 설명. **§7.2 본문 무수정**.
- [x] zone 전개·heartbeat 운영 baseline(주기/timeout)·Agent OFFLINE severity 등 ADR Open 항목은 v0.11에서 결정하지 않음 — 완료형 전환은 Accepted 결정(A-1/B-1/C-1, 규칙 B)의 반영에 한정.

**proposal-review 결과(2026-06-12, `proposal-review-spec-backfill-20260612.json`)**: verdict **revise** → 보완 반영으로 종결(critical 1건 = `adr/0005` §4 D-5 Open 잔재 → 본 커밋에서 정정 — D-5는 2026-06-07 RESOLVED·ADR#5 간접 소속 확정. §5 T4-1 "분배 대기" stale도 완료형으로 정정. 둘 다 기존 결정의 반영, 신규 결정 0). missing_context 3건(diff 미주입)은 위 기계 대조 + Stop 시 codex-gate 재검증으로 갈음 — 게이트 반복 룰(1~2회 제한)에 따라 재호출하지 않음.

## 4. 산출물·발주 구분 (개수 표기 일관화)

- **이 디렉터리 산출물 = 4건**: `000-impact`(이 문서, meta 보관) + **형제 repo 발주 3건**(아래 표 — 각 repo 세션에서 적용).

| handoff | 대상 | 요지 |
|---|---|---|
| `spec-backfill-hub.md` | hub | "통합본 v0.9" 호칭 13곳 + 경로 재배선 |
| `spec-backfill-script-agent.md` | script-agent | 동일 8곳 + 경로 재배선 |
| `spec-backfill-infra.md` | infra | `codex-gate.profile`·`proposal-review.profile` 호칭·경로 갱신 |

**공통 DoD**: 문서·설정 참조 갱신만(제품 코드·동작 0 변경) / 컷오버 후 **e2e baseline(60/0/0) 회귀 확인**(`monitoring-meta/e2e/run-e2e.sh` — rename 포함 작업이므로) / 적용 완료 보고.

## 5. 잔존 항목 / 되돌리기

- [x] 형제 repo 3건 컷오버 **완료**(2026-06-12 사용자 보고 + meta 측 grep 재검증 — hub·script-agent 잔존 0, infra 잔존은 보존 명시한 시점 기록 `docs/decisions/*.json` 2건뿐) → **구 경로 stub(`docs/통합본_v0_9.md`) 제거 완료**(이 커밋).
- [x] e2e baseline(60/0/0) 회귀 확인 — **PASS 60/0/0** (`e2e/results/20260612-222625.md`, 2026-06-12).
- [x] **기존 위상 불일치 — 별도 work-id로 분리 → 종결(2026-06-13, work-id `open-alignment` — 통합본 v0.12 + 결정 기록 `handoff/open-alignment/open-alignment-000-decision-packet.md` §9)**: 범위 두 갈래 — 모두 **v0.8부터 존재, v0.11 diff 무접촉(기계 대조 — 29 hunk 중 해당 절 0)**, 항목별 사람 결정 필요라 v0.11 "신규 결정 0" 원칙상 제외했던 것:
  - **(가) §7.5 ↔ §6.1.2·13장 Open 위상 충돌**: §7.5가 baseline 결정으로 서술한 항목을 §6.1.2·13장이 Open으로 유지 — Agentless polling 합류 토픽(단일 metrics-topic vs 별도, 13장 §H), 통보 정책 평가 엔진, Knox 조직도 동기화 주기, 시스템 자체 OpenSearch 분리, WebSocket 권한 필터링(13장 §B/§C/§E/§G 성격).
  - **(나) 본문 6.x.5 Open 절 잔존 vs 13장 "단일 집중" 선언**: 13장 도입부는 "본문 각 절에서 Open question 절을 제거하고 누적"이라 선언하나 `§6.1.2`·`§6.2.5`·`§6.3.2`·`§6.4.9`·`§6.5.4`·`§6.6.5`·`§6.7.5`·`§6.8.6` 등이 잔존(v0.8 미집행). 일부 항목은 §7.5/ADR에서 결정돼 본문 Open과 상태가 공존 — 절별로 "제거 집행 vs 선언 완화 vs 해소 표시"를 결정해야 함. (v0.11에서는 ADR Accepted로 닫힌 §6.2.5 위임 2행만 cross-ref 정정 — 기존 결정 반영.)

**되돌리기 경로 (커밋 의존성 — proposal-review 권고 반영)**: 커밋 2(rename+재배선)는 커밋 1(v0.11 내용)을 전제한다. 되돌릴 땐 **역순으로 revert**(커밋 2 먼저 → 필요 시 커밋 1) — 커밋 2만 revert하면 파일명은 구로 돌아가되 v0.11 내용은 남는다(내용만 살리고 rename만 무를 때의 의도된 상태). 커밋 1만 revert하는 조합은 금지(신 파일명에 v0.10 내용이 남아 변경 이력 표와 어긋남). 참고: 구 경로에 stub을 남기는 설계라 git은 커밋 2를 R(rename)로 기록하지 않음 — 이력 추적은 본 문서의 commit pinning과 커밋 메시지로 한다.

## 6. sub-agent 결과 스키마

```json
{
  "status": "ok",
  "outputs": [
    "docs/master-design.md (rename + v0.11 backfill)",
    "docs/통합본_v0_9.md (redirect stub)",
    "docs/kafka-payloads.md",
    "docs/phase1/ROADMAP_PHASE1_v0_3.md",
    "docs/features/* (호칭·경로)",
    ".claude/* 활성 참조 재배선",
    "handoff/spec-backfill/spec-backfill-{000-impact,hub,script-agent,infra}.md"
  ],
  "findings": [
    "후보 6건 전부 사실 — 제외 0건",
    "infra에도 통합본 버전 호칭·경로 참조 3곳 실재 → 발주 조건 충족",
    "DEC-1 rename 트리거 위치는 ROADMAP가 아니라 handoff/v0-10-notation impact §DEC-1 (work spec 위치 오기)",
    "ROADMAP §5.1 ADR#5 행 T4-1 완료 미반영 추가 발견 → 정정"
  ],
  "blockers": [],
  "next_action": "handoff 3건을 들고 hub/script-agent/infra 세션에서 적용 → e2e 60/0/0 확인 → 완료 보고 후 meta가 구 경로 stub 제거"
}
```

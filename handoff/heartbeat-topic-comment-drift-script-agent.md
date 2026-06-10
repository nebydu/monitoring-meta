# 작업 spec — heartbeat-topic-comment-drift (script-agent)

> 형제 repo(script-agent) **주석·문서 정정** 작업. heartbeat 파일럿 문서(`docs/features/heartbeat-collection.md`) 작성 중 관측된 drift다. meta는 형제 repo를 수정하지 않으므로 이 spec을 script-agent 세션이 들고 가서 수행한다.

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID | `heartbeat-topic-comment-drift` | |
| 대상 repo | `script-agent` | |
| **기준 monitoring-meta commit** | `b591f29270dded69bc7637728b3fe4be1adb9b05` | 이 시점 기준 문서(ADR-0005 등) 전제 |
| 작성일 | 2026-06-10 | |
| 근거 ADR | `adr/0005-topic-naming.md` §2.2.1 (최종 논리명 `heartbeats-topic`) | T4-1 재명명 완료 |

## 2. 배경 / 목표

T4-1 토픽 재명명에서 **코드의 토픽 상수**는 최종 논리명으로 전환됐다(e2e §8 PASS — `heartbeats-topic` 등 신명). 그러나 script-agent의 **설명 주석·문서**에는 구 토픽명 `heartbeats`(최종은 `heartbeats-topic`)가 잔존한다. 동작에는 영향 없으나 인수인계·독해 시 혼동을 준다.

목표: script-agent 주석·문서의 구 토픽명 표기를 최종 논리명으로 정정한다. **코드 동작·토픽 상수는 손대지 않는다**(이미 신명, 회귀 위험 0).

## 3. ground truth 참조 경로

- `../monitoring-meta/adr/0005-topic-naming.md` §2.2.1 — 최종 논리명 표(`heartbeats-topic` = 복수형 명시 예외).
- `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준.

## 4. 작업 범위

### 해야 할 것 (meta가 관측한 위치 — script-agent가 자기 repo에서 확인 후 정정)

- `internal/heartbeat/heartbeat.go:3` — ``Kafka `heartbeats` 토픽으로 재발행`` → `heartbeats-topic`. (토픽 명시, 구명 확실)
- `internal/heartbeat/heartbeat.go:10` — `Kafka heartbeats 토픽을 직접 다루지 않는다` → `heartbeats-topic`. (토픽 명시, 구명 확실)
- `README.md:26` — ``... audit-topic / `heartbeats` 토픽은`` → `heartbeats-topic`. (다른 토픽은 신명인데 heartbeats만 구명)
- `README.md:64` — Liveness 행 `` `heartbeats` `` → `heartbeats-topic`. (토픽 컬럼)
- `README.md:131` — `` `heartbeats` 토픽 consume`` → 토픽명은 `heartbeats-topic`. **단 "consume" 서술 자체의 정확성(script-agent가 heartbeats를 consume하지 않음 — OTLP push만)도 함께 점검** 권고.
- `internal/model/types.go:3` — `heartbeats는 OTel Collector가 발행하므로` → **판단 필요**: 여기 `heartbeats`가 *토픽명* 지칭이면 `heartbeats-topic`으로, *heartbeat 신호 개념* 지칭이면 그대로 둔다(앞줄 `command-topic / job-results / audit-topic`은 신명 토픽 나열이라 토픽명일 가능성). script-agent가 의미를 보고 결정.
- **repo 전체 점검 권고**: 위는 meta가 heartbeat 파일럿 범위에서 관측한 것일 뿐 전수조사가 아니다. script-agent 세션이 자기 repo 주석·문서 전반의 구 토픽명(`heartbeats`/`commands`/`audit-events`) 잔존을 함께 점검한다.

### 하지 말 것 (out of scope)

- **코드 토픽 상수·로직 변경 금지.** `config.go` 등 토픽 default는 이미 신명(e2e §8 PASS) — 건드리면 회귀.
- **`heartbeat.go:6` otlp_json 문구 정정 금지.** ``Phase 0 baseline은 otlp_json(데모 spec §5.4), Phase 1에서 otlp_proto로 전환한다(ADR-0002 A-1, Accepted)`` 는 과거→현재 전환을 정확히 기술한 **정확한 맥락 설명**이다. otlp_json이라는 단어가 있다는 이유로 지우면 위상 설명이 손실된다.
- envelope 위상 주석 등 다른 영역 변경 금지(이 작업은 토픽명 표기 한정).

## 5. Phase 0 회귀 방지 기준

주석·문서만 수정하므로 동작 회귀 없음. 데모 spec v0.2.1 §5.4 heartbeat 논리 계약 불변. `go test ./...`로 무회귀만 확인.

## 6. 영향받는 기능 문서 (`docs/features/`)

- **해당 없음.** 주석/문서 표기 정정은 흐름 동작을 바꾸지 않는다. `docs/features/heartbeat-collection.md`는 이미 `heartbeats-topic` 신명으로 정확히 서술돼 있어 보완 불필요.

## 7. 미결정 사안

- 없음. (단 `types.go:3`·`README.md:131`은 "토픽명 vs 개념" / "consume 서술 정확성" 판단이 필요 — 이는 script-agent 세션의 코드 독해로 결정 가능한 사안이며 기준 문서 미결정이 아니다.)

## 8. 완료 기준 / 검증

- [ ] heartbeat.go·README의 토픽명 표기 = `heartbeats-topic`(구명 `heartbeats` 토픽 지칭 제거)
- [ ] `types.go:3`·`README.md:131` 의미 판단 후 정정 또는 보존(근거 주석/커밋 메시지에 남김)
- [ ] otlp_json 맥락 문구(heartbeat.go:6) **불변**
- [ ] `go test ./...` 무회귀
- [ ] (선택) repo 전체 구 토픽명 잔존 점검 결과 보고

## 9. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["수정한 파일 경로"],
  "findings": ["발견 사항 — types.go/README 판단 결과 포함"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

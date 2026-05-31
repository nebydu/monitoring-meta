# 작업 spec — adr-002 (script-agent)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID | `adr-002` | heartbeat otlp_json → otlp_proto 전환 |
| 대상 repo | `script-agent` | **거의 무변경**(확인 위주) |
| 기준 monitoring-meta commit | `f59c9caa3a6ea1cfa4d860f82944e8abdf940d6d` | full hash |
| 작성일 | 2026-05-31 | |
| 근거 ADR | `adr/0002-heartbeat-otlp-proto.md` | 결정: A-1 / B-1 / C-1 / 토픽명 분리 |

## 2. 문서 위상 상기

ground truth 우선순위: 코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(도달 목표).

## 3. ground truth 참조 경로

- `../monitoring-meta/adr/0002-heartbeat-otlp-proto.md` — 본 작업 결정
- `../monitoring-meta/handoff/adr-002-analysis.md` — 영향 분석서(§7.3 script-agent)
- `docs/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준(각 repo 사본)

## 4. 배경 / 목표

heartbeat wire format은 OTel Collector가 결정한다. script-agent는 `internal/heartbeat/heartbeat.go`에서 OTel SDK로 `agent.heartbeat` Gauge를 OTLP HTTP로 push만 하며, **Kafka·직렬화 형식에 비관여**다. A-1(OTLP 표준 protobuf) 채택이므로 Agent는 **wire format을 모른 채 그대로 동작**한다.

끝났을 때 도달 상태: script-agent는 사실상 변경 없이, OTel Go SDK 버전이 Collector/hub와 정합함을 확인.

## 5. 작업 범위

### 해야 할 것 (영향 분석서 §7.3)
- `internal/heartbeat/heartbeat.go`: **변경 불필요 가능성이 큼.** OTLP Go SDK 버전이 Collector/hub OTel 버전과 정합하는지만 확인(B-1: 버전 핀).
- 필요 시 `go.mod`의 OTel 관련 의존성 버전 핀 정합 확인.

### 하지 말 것 (out of scope)
- Agent에 Kafka 직접 producer 추가 금지(A-1 채택이므로 불필요). ※ A-2(커스텀 proto)였다면 필요했을 작업이나 채택 안 됨.
- proto 스키마/직렬화 코드 작성 금지(B-1: 표준 라이브러리 의존, wire는 Collector 소관).
- `internal/config/config.go`, `cmd/agent/main.go` 변경 금지(무변경 대상).

## 6. Phase 0 회귀 방지 기준

- 데모 spec v0.2.1 §5.4 heartbeat 동작 회귀 0. heartbeat 생성 주기(기본 10초)·attr(agent_id)·metric name(agent.heartbeat)·resource(service.name=script-agent) 불변.
- 컷오버 C-1: Agent는 배포 타이밍에 무관(wire format 비관여). 단 OTel SDK 버전이 Collector와 어긋나면 OTLP push 자체가 깨질 수 있으니 버전 정합만 확인.

## 7. 미결정 사안

없음. (A-1/B-1/C-1/토픽명 분리 모두 2026-05-31 확정.)

## 8. 완료 기준 / 검증

- [ ] OTel Go SDK 버전이 Collector/hub와 정합 확인(또는 핀).
- [ ] heartbeat OTLP push 동작 회귀 없음.
- [ ] 테스트: `go test ./...`.
- [ ] Phase 0 회귀 없음(§6).
- [ ] polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로(없으면 빈 배열)"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

# 작업 spec — adr-002 (infra)

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID | `adr-002` | heartbeat otlp_json → otlp_proto 전환 |
| 대상 repo | `infra` | wire format 전환의 **1차 주체** |
| 기준 monitoring-meta commit | `f59c9caa3a6ea1cfa4d860f82944e8abdf940d6d` | full hash |
| 작성일 | 2026-05-31 | |
| 근거 ADR | `adr/0002-heartbeat-otlp-proto.md` | 결정: A-1 / B-1 / C-1 / 토픽명 분리 |

## 2. 문서 성격 상기

ground truth 우선순위: 코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope(도달 목표).
- heartbeats-topic은 envelope 4종 예외군 → 본 작업은 envelope 규약과 무관.

## 3. ground truth 참조 경로

- `../monitoring-meta/adr/0002-heartbeat-otlp-proto.md` — 본 작업 결정
- `../monitoring-meta/docs/kafka-payloads.md` — heartbeats-topic payload 기준 문서
- `../monitoring-meta/handoff/adr-002/adr-002-analysis.md` — 영향 분석서(§7.1 infra)

## 4. 배경 / 목표

heartbeat의 Kafka wire format은 OTel Collector가 결정한다. 데모는 `encoding: otlp_json`. Phase 1 목표는 OTLP 표준 protobuf(`otlp_proto`)다. 끝났을 때 도달 상태: Collector가 heartbeat을 OTLP **protobuf**로 발행한다.

## 5. 작업 범위

### 해야 할 것
- `otel-collector-config.yml`의 kafka exporter `encoding: otlp_json` → `otlp_proto` (1줄).

### 하지 말 것 (out of scope)
- **이 작업에서 물리 토픽명(`heartbeats`)을 변경하지 말 것.** 토픽명(물리 `heartbeats` ↔ 논리 `heartbeats-topic`) 처리는 본 ADR 범위 밖의 **별도 사안**이며 ADR #2는 토픽명을 결정하지 않는다.
- 토픽 신설/분리 금지(컷오버 C-1 빅뱅 채택 → 기존 토픽 그대로).
- **메시지 키 정책을 변경하지 말 것** — 키 정책은 기준 문서 통합본 §8.2 ADR 결정표가 "`heartbeats-topic` 키 = OTel 기본(ordering 불필요)"로 **이미 결정**했으므로 그대로 따른다(ordering은 Open 아님).
- Schema Registry 도입 금지(A-1, ADR #1 준수).

## 6. Phase 0 회귀 방지 기준

- 데모 spec v0.2.1 §5.4 heartbeat 동작 회귀 0.
- **컷오버 C-1(빅뱅): 이 encoding 전환은 hub 디코더 교체(adr-002-hub)와 반드시 동시 배포**해야 한다. infra만 먼저 바꾸면 hub가 JSON 파서로 protobuf를 받아 디코드 실패 → 일시적 OFFLINE 오판. 배포 순서를 hub 세션과 맞출 것.
- envelope 성격은 `docs/envelope.md` §4.2 기준 문서를 따른다(`heartbeats-topic`은 OTLP 위임군 예외). 전환은 직렬화만 바꾸므로 이 예외 성격은 불변이다(Collector는 OTLP 표준 헤더만 발행 — 새 헤더가 끼어들지 않음을 회귀 확인).

## 7. 미결정 사안

없음. (A-1/B-1/C-1/토픽명 분리 모두 2026-05-31 확정.)

## 8. 완료 기준 / 검증

- [ ] Collector가 heartbeats 토픽에 OTLP protobuf(binary)로 발행.
- [ ] hub 디코더 교체분과 동시 배포되어 heartbeat 수신·갱신 정상(end-to-end).
- [ ] Phase 0 회귀 없음(§6).
- [ ] polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행.

## 9. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

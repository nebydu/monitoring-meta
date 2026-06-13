# 작업 spec — phase1-041-infra (T4-2 result-topic 분리: infra)

> 이 handoff는 infra 세션이 받아 실행한다. 단일 `job-results` 토픽을 `result-topic-job`(SCRIPT 결과) + `result-topic-log`(LOG 결과) 둘로 **분리**하는 T4-2의 **infra 몫**(토픽 물리 생성 + 구 토픽 제거)이다. **실행 순서 1순위** — 두 신규 토픽이 존재해야 hub(2토픽 구독)·script-agent(분기 발행)가 붙는다. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `phase1-041-infra` (T4-2) |
| 대상 repo | `infra` |
| 기준 monitoring-meta commit | 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인 |
| 근거 ADR/spec | `adr/0005-topic-naming.md` **Accepted**(규칙 B) / `docs/kafka-payloads.md`(result-topic-job·result-topic-log 절·토픽 명명 규칙) / 통합본 `docs/master-design.md` §6.9.2 항목1·§6.9.5 / 영향 분석 `handoff/phase1-041/phase1-041-000-impact.md` §0·§4 |
| 작성일 | 2026-06-13 |
| 실행 순서 | **1순위** (hub/script-agent보다 먼저 — 신규 2토픽 생성 기반) |

## 2. 분리 매핑 (T4-2 = job-results 1→2)

| 현행 물리명 (Phase 0) | 최종 논리명 (규칙 B) | 분기 기준(현행 코드 enum) |
|---|---|---|
| `job-results` (단일) | `result-topic-job` | job_type = `SCRIPT_JOB` |
| `job-results` (단일) | `result-topic-log` | job_type = `LOG_JOB` |

- 구 `job-results`는 **제거**한다(§5.3+§5.4 확정 = 동시 컷오버 + 구 토픽 제거, 폐쇄망 클린 재기동 전제·잔류 메시지 0).
- T4-1로 재명명된 `command-topic`/`audit-topic`/`heartbeats-topic` 3토픽은 **그대로 유지**한다(이번 작업 범위 밖, 건드리지 말 것).

## 3. 정확한 변경 목록

### 3.1 필수 (런타임 — kafka-init 토픽 생성 루프)

| 파일:라인 | 현재 | 변경 |
|---|---|---|
| `docker-compose.yml:64` | `for t in command-topic job-results audit-topic heartbeats-topic; do` | `for t in command-topic result-topic-job result-topic-log audit-topic heartbeats-topic; do` |

- `job-results`를 루프에서 **삭제**하고 `result-topic-job`/`result-topic-log` 둘을 추가한다.
- partitions/replication-factor는 기존과 동일(`--partitions 1 --replication-factor 1`).
- `--create --if-not-exists` 옵션은 그대로 둔다.

### 3.2 문서/주석 동기화 (이번 handoff 포함)

- `docker-compose.yml` 및 infra README 등에 `job-results` 토픽명 주석이 있으면 `result-topic-job`/`result-topic-log`로 동기화. (heartbeats-topic exporter 주석 등 T4-1 잔재는 건드리지 말 것.)
- repo 전체에서 `job-results` 문자열 잔존 0(클린 분리 완전성, §5.6 R-B 근거).

## 4. 적용 결정 (사람 확정 2026-06-13 — 그대로 반영)

| 항목 | 결정 |
|---|---|
| payload 경계 (§5.1) | **옵션 A — 토픽만 분리.** infra는 payload 무관(토픽 물리 생성만). |
| 컷오버 방식 (§5.3) | **동시 컷오버** — infra(2토픽 생성·구 토픽 제거) → hub/script-agent 같은 윈도우. 이중 발행 없음. |
| 구 토픽 처리 (§5.4) | **구 `job-results` 제거** — kafka-init 루프에서 삭제. 폐쇄망 클린 재기동 전제(잔류 메시지 0)라 별도 드레인 절차 불요. |
| 회귀 0 정의 (§5.6) | R-A(동작 등가)+R-B(분리 완전성)+R-C(분기 정확성) 병행. e2e는 meta가 §3.3로 별도 검증. |

## 5. DoD / 검증 (완료 조건)

- [ ] `docker-compose.yml` kafka-init 루프가 `command-topic` / `result-topic-job` / `result-topic-log` / `audit-topic` / `heartbeats-topic` 생성. **`job-results` 루프에서 제거됨.**
- [ ] 인프라 클린 기동 후 `kafka-topics --list`에 `result-topic-job` + `result-topic-log` 존재, **`job-results` 미생성**(분리 완전성 R-B).
- [ ] T4-1 3토픽(`command-topic`/`audit-topic`/`heartbeats-topic`) 무변경 유지.
- [ ] 주석/README `job-results` 잔존 0.
- [ ] 동결 데모 spec·무관 파일 변경 없음.

## 6. 가드 (공통 — impact §6.2)

- **동결 데모 spec v0.2.1은 회귀 앵커 — 수정 금지.** (infra repo엔 보통 없지만 사본 있으면 손대지 마라.)
- 분리는 Phase 1 **forward 변경**이지 Phase 0 회귀가 아니다(통합본 §6.9.2 항목1로 명시된 정정 대상).
- payload는 §5.1=A로 현행 `JobResult` 구조 유지 — infra는 payload 무관이나 토픽 2개에 모두 같은 payload가 흐른다는 전제만 인지.
- key=`agent_id`·envelope 4종은 분리와 무관하게 동일(건드릴 것 없음).
- e2e 종단 재검증은 **meta가 §3.3로 별도 수행** — infra 세션이 직접 e2e 돌리지 않는다.

## 7. 실패 시 롤백 경로 (동시 컷오버 실패 대비)

동시 컷오버(infra+hub+script-agent 같은 윈도우)가 실패하면:
- infra 단독 롤백: `docker-compose.yml:64` 루프를 `command-topic job-results audit-topic heartbeats-topic`(T4-1 직후 상태)로 되돌리고 클린 재기동 → 구 `job-results` 단일 토픽 복귀.
- hub(consumer)·script-agent(producer)도 동시에 구 `job-results` 구독/발행으로 되돌려야 단절이 해소된다(각 repo handoff §7 참조). **infra만 단독 롤백하면 안 됨** — 세 repo 롤백은 같은 윈도우에서 함께.
- 폐쇄망 클린 재기동이라 잔류 offset 정리 불요(새 토픽/구 토픽 모두 빈 상태로 재생성).

## 8. 미결정 사안

- 없음. 분리 방향·명명·실행 순서·ADR 소속 모두 RESOLVED(D-4(1)/D-4(2)/D-5, `adr/0005` Accepted). §5 결정 4건 사람 확정 완료(2026-06-13). 통합본 13장 Open question·미결 ADR 저촉 없음.

## 9. meta 복귀 게이트 (이 handoff 단독으로 작업을 닫지 않는다)

infra 구현 완료 후 형제 repo 3곳(infra+hub+script-agent) 구현 + meta e2e 60/0/0(R-A+R-B+R-C, §6-LOG 보존) 통과 후 **monitoring-meta 세션으로 복귀**한다. meta가 닫을 계약 문서(형제 repo는 닫지 않음):
- (i) `docs/kafka-payloads.md` 매핑표 상태("T4-2 잔여"→"일치") + result-topic-job/log 절 "현행 물리명" 갱신
- (ii) 통합본 §6.9.5·§6.9.2 항목1·§4.4.1 상태 반영
- (iii) ROADMAP §13 T4-2=DONE·T4-5=DONE·acceptance_evidence 기록
- (iv) spec-sync 재검사
- (v) features 2문서(script-job-execution.md·log-job-collection.md) 보완(feature-doc-writer)

## 10. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["kafka-init 토픽 생성(2신규+구 제거) / 주석 동기화 / kafka-topics --list 확인 결과"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

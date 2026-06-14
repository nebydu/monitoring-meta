# ADR-0019 — result 토픽 분리와 result payload 정렬의 위상 분리

- **Status**: Accepted
- **Date**: 2026-06-14 (옵션 A 사람 확정 2026-06-13 → ADR 승격 2026-06-14)
- **관련**: ADR#5(토픽 명명, `adr/0005`)·ADR#6(메시지 키)·ADR#10(LOG_JOB occurred_at)·ADR#14(LOG_JOB file_state) / 통합본 §6.9.2 항목1·§6.9.5 / `docs/kafka-payloads.md` result-topic-job·result-topic-log / ROADMAP T4-2(토픽 분리)·T3-7(occurred_at) / 동결 데모 spec v0.2.1 §5.2 / `handoff/phase1-041/`(T4-2 발주) §5.1
- **Scope**: result-topic-job / result-topic-log의 **payload 위상**에 한정. 토픽 *명명·분리* 결정은 ADR#5/D-5 소속, command-topic payload는 본 ADR 범위 밖.

## Context

T4-2는 단일 `job-results` 토픽을 `result-topic-job`(SCRIPT/SQL 결과) + `result-topic-log`(LOG 결과)로 **분리**한다. 그런데 두 계층의 payload 정의가 어긋나 있다:

- **목표 스키마**: `docs/kafka-payloads.md`의 result-topic-job/log JSON은 Phase 1 종착 목표(평면 `exit_code`/`stdout_ref`/`metrics`·`mode`·`status` 소문자 / `log_source`/`file_state`/`occurred_at`/평면 `line_count`).
- **현 단계 코드·데모**: hub `JobResult.java`·script-agent `result.go`는 **공통 `JobResult`**(중첩 `script`/`log`, `status` 대문자 `SUCCESS|FAIL|TIMEOUT`, `job_type` `SCRIPT_JOB|LOG_JOB`)를 발행한다. 이 구조는 동결 데모 spec v0.2.1 §5.2(코드 주석이 §5.2.1/5.2.2/5.2.3 직접 인용)와 **동일**하다.

데모 spec §5.2.3 노트는 이미 **"본개발에서 envelope + job_type별 분기 메시지 구조로 전환 검토 (ADR)"**를 예고했다. 본 ADR이 그 예고된 결정을 닫는다.

문제: 계약 문서에 "이 평면 스키마가 목표이고 T4-2 단계는 공통 `JobResult`를 유지한다"는 **위상 구분이 없어**, 코드(공통 `JobResult`)와 계약(목표 평면)이 drift로 보이고 자동 검증(codex-gate)이 계약 위반으로 오판한다.

## Decision

**result payload의 토픽 분리(물리 라우팅)와 필드 정렬(스키마 진화)을 독립 단계로 분리한다.**

1. **T4-2 = 토픽만 분리**한다. payload는 **현 단계 공통 `JobResult`**(데모 spec v0.2.1 §5.2 구조)를 그대로 두 토픽에 실어 보낸다. `result-topic-job`은 `script`를, `result-topic-log`은 `log`를 채우고 나머지는 `null`. envelope·메시지 키 정책은 본 ADR이 재결정하지 않고 **단일 출처(`docs/envelope.md` / ADR#6)를 참조**한다 — 분리와 무관하게 동일(result는 key=`agent_id`).
2. **Phase 1 현 단계 result payload 계약 = 공통 `JobResult`**다. hub/script-agent 코드의 현 단계 검증 기준은 이 계약이며, 평면 목표 스키마와 다른 것은 **drift가 아니라 의도된 단계 차이**다.
3. **목표 평면 스키마로의 정렬은 후속 Track**에서 항목별로 수행한다. 본 ADR은 그 정렬을 선결정하지 않고 **후속 Track으로 위임**한다.

### 정렬 항목의 추적 위상 (선결정 금지 — 실재 매핑만)

| 항목 | 현 단계 | 목표 | 추적 |
|---|---|---|---|
| `occurred_at`(LOG sample line) | 없음(데모 §5.2.3 노트) | `sample_lines[].occurred_at` | **ADR#10 / T3-7 (TODO)** |
| `file_state`(LOG) | Agent local만, BE 미전송 | 동일 유지 | **ADR#14 (NO-OP, T5-4)** — 정렬 대상 아님 |
| `status` enum 소문자화·`mode`·`metrics`·`stdout_ref`·중첩→평면·`job_type` SHELL/SQL/LOG화 | 공통 `JobResult` | 평면 목표 | **전담 Track 미배정** — 후속 Track 위임(본 ADR이 Track ID를 정하지 않는다) |

## Consequences

- `docs/kafka-payloads.md`의 result-topic-job/log 절은 **① 현 단계 계약(공통 `JobResult`) + ② 목표 계약(평면)**을 병기하고, 현 단계 검증 기준이 ①임을 명시한다. → spec 공백 해소.
- 옵션 A(payload 유지) 결정의 소유 위상이 handoff/impact가 아니라 **본 ADR**로 격상된다. → 위상 역전 해소.
- hub/script-agent의 T4-2 구현(공통 `JobResult` 2토픽 발행/구독)은 현 단계 계약 준수이며 회귀 0(데모 spec §5.2 동작 보존).
- 목표 정렬은 별 Track에서 각 ADR(#10 등)로 추적하며, 이 ADR은 "분리와 정렬은 별개 단계"라는 위상만 고정한다.

## 되돌리기

본 ADR을 Superseded 처리하면 result payload 단계화 위상이 풀린다. 그 경우 kafka-payloads의 ① 현 단계 계약 블록과 본 ADR 인용을 함께 제거해야 한다(현 단계 검증 기준이 다시 코드로 암묵화됨).

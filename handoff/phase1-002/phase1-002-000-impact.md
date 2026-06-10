# phase1-002 영향 분석 — envelope 적용 (Track 0 — T0-3 산출물 → T0-4 구현 근거)

> **[상태 갱신 — 2026-06-06]** 본문은 **작성 당시 기준**이다. D-4(1) 토픽 명명 컨벤션은 **2026-06-06 Accepted**(`adr/0005-topic-naming.md`: 후보 B / `command-topic` 단일 토픽 / 신규까지). 본문의 "토픽명 잠정" 표현은 작성 시점 상태이며, 토픽 최종 논리명·명명 규칙의 현행 기준 문서는 `docs/kafka-payloads.md`("토픽 명명 규칙" 절)다. 실제 재명명은 Track 4 T4-1.

> 이 문서는 analyzer가 작성한 **영향 분석 노트**다. 결정 문서가 아니라 현황 판정 + repo별 작업 윤곽 + 결정 필요 사안 정리다.
> phase1-001(`handoff/phase1-001/phase1-001-envelope-scope.md`)이 envelope 적용 **범위**(공통 6 ● / OTLP 2 ✕)를 확정했고, 본 분석은 그 범위 안에서 **지금 실제로 무엇을 구현할지**를 코드 실재 기준으로 한정한다.

- 작성일: 2026-06-05
- 분석 대상 코드: `../hub`(Java/Spring), `../script-agent`(Go), `../infra`(read-only)
- ground truth: `docs/envelope.md`(§2 헤더/§2.3 가드/§4 토픽별/§6 회귀), `docs/kafka-payloads.md`, `docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` §2.2(Phase 0 회귀)

---

## 1. 토픽별 envelope 4종 현황 판정 (코드 실재 기준)

판정 구분: **(a) 이미 적용됨** / **(b) 실재하지만 미적용 → phase1-002 구현 대상** / **(c) 미존재/미분리 → 연기**.

| envelope.md 논리명(§4.1) | 코드 실재 토픽 | producer 위치 | producer envelope 발행 | consumer 위치 | consumer x-source 가드 | 판정 |
|---|---|---|---|---|:-:|---|
| `command-topic` | `commands` | hub `producer/CommandPublisher.java` | ● 4종 발행 완료(L67–73) | script-agent `cmd/agent/main.go` `consumeCommands` | 헤더 미참조(파싱 안 함) | **(a) producer 적용됨** / consumer 가드 명시화 대상 |
| `result-topic-job` | `job-results` | script-agent `internal/jobresult/publisher.go` | ● `BuildHeaders` 발행 완료(L31) | hub `ingest/jobresult/JobResultConsumer.java` | 헤더 미참조 | **(a) producer 적용됨** / consumer 가드 명시화 대상 |
| `result-topic-log` | (미분리 — `job-results`에 통합) | — | — | — | — | **(c) 연기**: 토픽 분리(result job/log) 자체가 미수행. 분리는 별도 Track(통합본 §6.9.2 항목1). envelope은 분리 시 동일 BuildHeaders 재사용 |
| `audit-topic` | `audit-events` | script-agent `internal/audit/publisher.go` | ● `BuildHeaders` 발행 완료(L132) | hub `ingest/audit/AuditConsumer.java` | 헤더 미참조 | **(a) producer 적용됨** / consumer 가드 명시화 대상 |
| `alert-topic` | 미존재 | — | — | — | — | **(c) 연기(Track 2)**: Alert Processor 미구현. 서비스 빌드 시 envelope 동시 적용 |
| `notification-topic` | 미존재 | — | — | — | — | **(c) 연기(Track 3)**: Notification/Incident Service 미구현. 서비스 빌드 시 envelope 동시 적용 |
| `heartbeats-topic` | `heartbeats` | otel-collector(infra) | ✕ 제외(OTLP 위임군) | hub `ingest/heartbeat/HeartbeatConsumer.java` | N/A | **제외** — envelope 4종 미적용 유지(회귀 검증 대상) |
| `metrics-topic` | 미존재(Phase 2) | — | ✕ 제외 | — | — | **제외** — Phase 1 미사용 |

### 1.1 핵심 결론 (이 분석의 본질)

- **producer 측 envelope 신규 적용 작업은 사실상 없다.** 실재하는 공통 토픽 3종(command / job-results / audit-events) 모두 producer가 **이미 envelope 4종을 발행**한다. 즉 phase1-001이 "범위"로 잡은 6 ● 중 실재 3종의 producer 발행은 Phase 0에서 이미 충족됐다.
- 실재하지만 envelope이 producer에서 빠진 토픽(판정 (b))은 **없다.**
- **phase1-002의 실제 잔여 작업 = consumer 측 "알 수 없는 `x-source` 가드"(envelope §2.3)를 명시 동작으로 박는 것**이다. 현재 양쪽 consumer는 헤더를 아예 참조하지 않아 "우연히 안 깨지는" 상태다. envelope §2.3을 **의도된 가드**로 문서화·테스트로 고정한다(회귀 방지 자산).
- `result-topic-log`(토픽 분리) / `alert-topic` / `notification-topic`은 **컴포넌트 미존재 → 연기**. envelope을 "없는 토픽"에 지금 적용할 수 없다. 해당 서비스/토픽이 생기는 Track 1/2/3에서 envelope 동시 적용을 **요건으로 명시**만 한다.

## 2. repo별 작업 요약

| repo | 이번 phase1-002 작업 | 강도 |
|---|---|:-:|
| hub (Java) | (1) consumer 2종(JobResult/Audit)에 `x-source` 가드 명시 + 테스트. (2) producer 헤더 키/version/source 상수의 외부화 점검(토픽명 잠정 대비). (3) Phase 0 회귀 0 보장 | 가벼움~중간 |
| script-agent (Go) | (1) command consumer(`consumeCommands`)에 `x-source` 가드 명시 + 테스트. (2) producer는 이미 적용 — 회귀만. (3) 토픽명 외부화는 이미 config(env)로 충족 — 확인만 | 가벼움 |
| infra | 토픽 생성 스크립트가 공통 토픽군 포함하는지 점검. 현재 `commands job-results audit-events heartbeats` 4종만 사전 생성. envelope은 앱 헤더라 Collector 변경 없음 | 매우 가벼움(점검만) |

## 3. 토픽명 외부화 현황 (D-4(1) 승인 대비)

- script-agent: 이미 env var로 외부화됨(`internal/config/config.go` `KAFKA_TOPIC_*`, 기본값 데모명). **추가 작업 거의 없음** — 잠정명 주의만.
- hub: `config/KafkaConfig.java` `Topics` 상수에 하드코딩(`commands`/`job-results`/`audit-events`/`heartbeats`). 상수로는 모여 있으나 외부 설정(properties)화는 안 됨. D-4(1) 승인 시 재명명 용이하도록 **상수 단일 지점 유지**를 명시(설정화는 토픽 재명명 Track 4-1 소관, 본 작업서는 강제 안 함).
- **주의**: 현재 코드 토픽명은 데모명(`commands` 등)이고 kafka-payloads 잠정 논리명(`command-topic` 등)과 다르다. **토픽 재명명은 본 작업(phase1-002) 범위 밖**(envelope은 토픽명 독립, D-4(2) RESOLVED). 이름은 건드리지 않는다.

## 4. phase1-001과의 관계

phase1-001은 envelope 적용 **범위/제외**(6 ● / 2 ✕)와 **순서**(envelope-first)를 확정했다. 본 phase1-002는 그 범위 내에서 **코드 실재 기준 구현 대상을 (a)/(c)로 분해**해, 실제 잔여 작업이 "consumer x-source 가드 명시화 + 연기 항목 요건화"임을 확정한다.

## 5. 결정 필요 사안 (사람 입력)

- **없음 (block 아님).** 본 작업은 envelope.md에 확정된 §2.3 가드·§6 회귀 기준만 코드로 고정한다. D-4(1) 토픽 명명은 본 작업과 독립(토픽명 미변경)이라 막히지 않는다.
- 보존(결정 아님, 본 범위 밖 명시): `result-topic-job/log` 토픽 분리 시점(통합본 §6.9.2), alert/notification 서비스 빌드 시점(Track 2/3), `x-message-id` dedup·`x-trace-id` 복원(envelope §9 O1 / T2-8) — 전부 연기.

# D-5 ADR 소속 분류 — 승인 패킷

> **성격**: 이 문서는 **결정을 내리지 않는다.** ROADMAP `§17 D-5` 정의에 따라 데모 정정 중 ADR 소속이 미결인 항목 각각에 대해 *후보 ADR 소속 + 근거 + 확신도*를 제시하고, **사람 승인**을 받기 위한 패킷이다. CLAUDE.md §2 / 강제 룰 5에 따라 analyzer는 후보 분류만 하고 최종 소속을 단정하지 않는다.
>
> **입력 source of truth**: `docs/phase1/ROADMAP_PHASE1_v0_3.md` §17 D-5 / §3.1 demo-correction matrix / `docs/통합본_v0_9.md` §6.9.2(=§6.9(나), line 1742~1758) / §8.3 ADR 18개 매핑(line 2284~2303) / `handoff/phase1-critical-path-analysis.md` §5(a-1 D-5).
>
> **기준 monitoring-meta commit**: `4940e1a115b911e452f96f0083f1c4dc6ede879f`
> **작성일**: 2026-06-07 · **owner(분류)**: analyzer/codex-gate · **owner(승인)**: human

---

## 0. D-5 정확 식별 — 몇 건인가

ROADMAP §17 D-5 원문(line 434)을 통합본 §6.9.2 정정표(11건)와 대조해 확정한다. **D-5 = 정확히 3건**이다(개수 일치 확인).

§6.9.2 11개 정정 항목 중 ADR 소속이 *미결*인 것만 추리면:

| §6.9.2 항목 | 재분류(§3.1) | D-5 대상? | 근거 |
|---|---|---|---|
| 2 Heartbeat 직렬화 → ADR#2 | ADR 명시 | 아니오 | §6.9.2 "Phase 1 (ADR #2)" 명시 |
| 3 `x-message-id` 중복 → ADR#15 | ADR 명시 | 아니오 | §6.9.2 "(ADR #15)" 명시 |
| 4 영속 저장소 → ADR#12 | ADR 명시 | 아니오 | §8.3 ADR#12 |
| 5 인증/인가 → ADR#7 | ADR 명시 | 아니오 | §8.3 ADR#7 |
| 6 Frontend → ADR#8 | ADR 명시 | 아니오 | §6.9.2 "(ADR #8)" |
| 7 Agent 자가등록 → ADR#11 | ADR 명시 | 아니오 | §6.9.2 "(ADR #11)" |
| 9 LOG_JOB occurred_at → ADR#10 | ADR 명시 | 아니오 | §6.9.2 "(ADR #10)" |
| 11 `command-topic` zone routing → ADR#4 | **확정 소속(사실)** | 아니오 | §8.3 ADR#4 결정 컬럼 = "동일 + zone 단위 토픽 routing" 직접 포함 → 2026-06-05 사람 승인으로 D-5 제외 |
| **1 `job-results` 토픽 분리** | **ADR 간접 소속 [결정 필요]** | **예 (D-5-1)** | §6.9.2 "Phase 1"만 표기, §8.3 직접 ADR 번호 미부여 |
| **8 Quartz JobStore DB-backed** | **ADR 바깥 [결정 필요]** | **예 (D-5-2)** | §6.9.2 "Phase 1"만 표기(ADR 번호 없음), §8.3 직접 ADR 없음 |
| **10 audit actor.type 범위 확장** | **ADR 바깥 [결정 필요]** | **예 (D-5-3)** | §6.9.2 "Phase 1 (확장)"만 표기, §8.3 직접 ADR 없음 |

→ **D-5는 3건**: (D-5-1) `job-results` 분리, (D-5-2) Quartz JobStore, (D-5-3) audit actor.type. ROADMAP §17 D-5 원문 개수와 **일치**한다.

> **공통 전제 (3건 모두 해당)**: 세 항목 모두 *구현 필요성 자체는 Phase 1 확정*이다(§6.9.2 / §3.1 / T4-2·T1-4·T3-9 status=TODO). **D-5가 막는 것은 "ADR 소속 라벨"뿐**이며, 작업 *착수*를 막지 않는다. 즉 D-5는 **DoD-2(데모 정정 11개를 §3.1 재분류대로 추적 완료)를 닫는 유일한 키**다(critical-path 분석 §5 a-1).

---

## 1. D-5-1 — `job-results` 토픽 분리

| 항목 | 내용 |
|---|---|
| ① 정정 내용 | `job-results` 단일 토픽 → `result-topic-job` + `result-topic-log` 2개로 분리(§6.9.2 항목1). 분리 자체=Phase 1 확정. |
| ② **후보 ADR 소속** | **ADR#5 (토픽 명명)** — 간접 소속 후보 |
| ③ 근거 | §8.3 ADR#5 주제 = "토픽 명명"(데모 "환경 prefix 없음" → v0.x "zone 단위 + 의미 기반"). 토픽 분리·명명은 ADR#5 의미 영역과 직접 연결. **단 §8.3 ADR#5 결정 컬럼은 *명명 규칙*만 언급하고 `job-results` 분리를 *번호로 직접* 부여하지 않음**(§3.1 항목1 "ADR#5 의미 연결, §8.3 직접 번호 미부여 → D-5"). |
| ④ 확신도 | **중간** — 의미 연결은 명확하나 §8.3에 번호 직접 부여가 없어 "간접 소속"에 머문다. |
| ⑤ 대안 소속 | (a) **ADR#6 (메시지 키)** — 분리된 두 토픽의 key(`agent_id`)가 ADR#6 영역과 겹침. 단 분리 *행위* 자체는 명명(#5)에 더 가깝고 key는 이미 §6.9.5 확정이라 #6은 약함. (b) **ADR 바깥(Phase 1 확정 정정, 소속 무)** — D-5-2/D-5-3과 동일 성격으로 처리하는 안. |
| ⑥ 소속 확정 시 풀리는 것 | T4-2(`result-topic-job`/`-log` 분리)의 **ADR 소속 라벨** 확정 → §5.1 #5(ADR#5 닫힘 by T4-1+T4-2) 완결 + DoD-2 1/3 진전. T4-2 *구현*은 이미 착수 가능(blocked_by=T4-1 DONE). |

---

## 2. D-5-2 — Quartz JobStore DB-backed Clustered

| 항목 | 내용 |
|---|---|
| ① 정정 내용 | in-memory JobStore → DB-backed Clustered JobStore(§6.9.2 항목8 / §6.2 "Quartz Clustered (DB-backed JobStore)"). 구현 필요성=Phase 1 확정. |
| ② **후보 ADR 소속** | **ADR 바깥 (Phase 1 확정 정정, ADR 소속 없음)** — 후보 |
| ③ 근거 | §8.3에 Quartz 관련 ADR은 **#17(Quartz misfire)뿐**이고, #17 결정 컬럼은 "`DO_NOTHING` 동일 유지"로 **misfire 정책에 한정**된다(통합본 line 2302 / line 1732). JobStore를 in-memory→DB-backed로 바꾸는 것은 misfire와 별개 사안 → §8.3 어느 행도 직접 포함하지 않음. §3.1 항목8 "§8.3 직접 ADR 없음(ADR#17 misfire와 별개)". |
| ④ 확신도 | **높음** — §8.3 정독상 JobStore 백엔드 전환을 담는 ADR 행이 없음이 명확. ADR#17과의 분리도 통합본이 명시. |
| ⑤ 대안 소속 | **ADR#17로 확대 귀속** — Quartz라는 같은 컴포넌트라는 이유로 #17에 묶는 안. 단 #17 결정 컬럼이 misfire "동일 유지"라 JobStore 전환을 담으면 ADR 내용과 충돌 → **권장하지 않음**(사람 판단 필요). |
| ⑥ 소속 확정 시 풀리는 것 | T1-4(Quartz JobStore)의 **ADR 소속 라벨** 확정(현재 "ADR 소속 미정(D-5)"). T1-4 *구현*은 T1-1 PG 선행 후 착수(D-5 무관). DoD-2 1/3 진전. |

---

## 3. D-5-3 — audit actor.type 범위 확장

| 항목 | 내용 |
|---|---|
| ① 정정 내용 | `audit-events` actor.type을 `AGENT` 단독 → `AGENT`+`USER`+`SYSTEM` 확장(§6.9.2 항목10 / §6.6.2 line 1537). action 종류도 데모 3종 → 사용자 액션 추가. |
| ② **후보 ADR 소속** | **ADR 바깥 (Phase 1 확정 정정, ADR 소속 없음)** — 후보 |
| ③ 근거 | §8.3에서 audit 관련 ADR은 **#3(Audit 채널)뿐**이고, #3 결정 컬럼은 "Kafka 직행 동일 유지"로 **전송 채널에 한정**된다(line 2288). actor.type *모델 확장*은 채널과 별개 → §8.3 어느 행도 직접 포함하지 않음. §3.1 항목10 "§8.3 직접 ADR 없음". |
| ④ 확신도 | **높음** — §8.3 정독상 actor 모델 확장을 담는 ADR 행이 없음이 명확. #3은 채널 사안으로 분리됨. |
| ⑤ 대안 소속 | **ADR#3로 확대 귀속** — 같은 audit 도메인이라는 이유로 #3에 묶는 안. 단 #3 결정 컬럼이 "채널 동일 유지"라 actor 모델 확장을 담으면 ADR 범위와 어긋남 → **권장하지 않음**(사람 판단 필요). |
| ⑥ 소속 확정 시 풀리는 것 | T3-9(audit actor.type)의 **ADR 소속 라벨** 확정(현재 "ADR 소속 미정(D-5)"). T3-9는 T1-1 무관, command pipeline 의존. DoD-2 1/3 진전 → **3건 모두 닫히면 DoD-2 완료 조건 충족 가능**. |

---

## 4. 결정 요청 (사람 승인 항목 — 한눈에)

각 건마다 후보(✅ 권장)와 대안을 제시한다. **analyzer는 어느 것도 선택하지 않았다.** 사람이 승인란에 표기한다.

| # | 정정 항목 | 후보 소속(✅ 권장) | 확신도 | 대안 | 승인란 |
|---|---|---|---|---|---|
| D-5-1 | `job-results` 분리 (T4-2) | **ADR#5 (간접)** ✅ | 중간 | ADR#6 / ADR 바깥 | ☐ 후보 ☐ 대안(___) |
| D-5-2 | Quartz JobStore (T1-4) | **ADR 바깥(Phase 1 확정 정정)** ✅ | 높음 | ADR#17 확대 | ☐ 후보 ☐ 대안(___) |
| D-5-3 | audit actor.type (T3-9) | **ADR 바깥(Phase 1 확정 정정)** ✅ | 높음 | ADR#3 확대 | ☐ 후보 ☐ 대안(___) |

**승인 시 효과**: 3건 모두 소속 확정 → §5.1 #5(ADR#5) 라벨 완결 + T1-4·T3-9 "ADR 소속 미정" 주석 해소 → **DoD-2 닫힘 가능**. 작업(T4-2/T1-4/T3-9) 구현 착수는 D-5와 무관하게 이미 가능(blocked_by 별도).

> **주의 (CLAUDE.md §2)**: D-5-1의 확신도가 "중간"인 것은 §8.3이 `job-results` 분리에 ADR 번호를 *직접* 부여하지 않았기 때문이다. 사람이 "ADR#5 간접"으로 승인할지, "ADR 바깥"으로 D-5-2/D-5-3과 통일할지는 판단이 필요하다. analyzer가 단정하지 않는다.

---

## 5. 결과 보고 스키마

```json
{
  "status": "blocked",
  "outputs": ["handoff/d5-classification-packet.md"],
  "findings": [
    "D-5 = 정확히 3건 확인(job-results 분리 / Quartz JobStore / audit actor.type). command-topic routing(항목11)은 ADR#4 확정소속으로 이미 D-5 제외됨",
    "D-5-1 job-results: ADR#5 간접 소속 후보(확신 중간 — §8.3 번호 직접 미부여), 대안 ADR#6/바깥",
    "D-5-2 Quartz JobStore: ADR 바깥 후보(확신 높음 — §8.3 #17은 misfire 한정, JobStore 전환 별개)",
    "D-5-3 audit actor.type: ADR 바깥 후보(확신 높음 — §8.3 #3은 채널 한정, actor 모델 확장 별개)",
    "3건 모두 구현 자체는 Phase 1 확정 — D-5는 ADR 소속 라벨만 막으며 DoD-2 닫는 유일 키"
  ],
  "blockers": [
    "D-5-1/D-5-2/D-5-3 각각의 최종 ADR 소속은 사람 승인 필요(§4 결정 요청 표). analyzer 단정 금지(CLAUDE.md §2)"
  ],
  "next_action": "사람이 §4 표 3건 승인 → 승인 결과를 ROADMAP §17 D-5 RESOLVED 주석 + §3.1 항목1/8/10에 반영(후속 작업)"
}
```

# codex-gate verified_commit 수동 전진 — 예외 감사 기록 (2026-06-14)

> **성격**: fail-closed 게이트의 baseline(verified_commit)을 사람이 수동 전진시킨 **예외 조치의 감사 기록**. 선례 `codex-gate-vc-advance-20260613.md`와 형식 동일하나 **명분이 다르다** — 그건 "구조적 오탐"이었고, 이번은 **"게이트 완벽주의 루프 + 타당하지만 사소한 미해소 지적의 후속 분리"**다. 미해소 지적이 baseline에 흡수되는 리스크를 인정하고, 그래서 §5에 후속 정합 작업으로 명시 등록한다.

## 1. 사건 요약

- **작업**: T4-2 result payload 위상 정식화(ADR#19 신설 + kafka-payloads 현 단계/목표 계약 병기). 커밋 `e7b70d6`.
- **게이트 이력**: payload 위상을 계약 문서에 반영하려는 시도가 codex-gate **4연속 FAIL**.
  1. 1차(위상 주석): JSON "목표" 격하 + "위반 아니다"로 현 단계 검증 기준 소멸.
  2. 2차(위상 주석 재설계): 현 단계 기준을 코드/handoff로 앵커 → spec 공백 + 위상 역전.
  3. 3차(ADR#19 + 두 계약 병기): 방향 수용, 정합 5건 지적(카운트·envelope 참조·SCRIPT_JOB/SQL·소유 문구·file_state) → 수정.
  4. 4차: 또 새 정합 3건(hub 게이트 누락·envelope 참조형·ROADMAP 미배정 TODO).
- **판단**: 3차에서 **핵심 방향(현 단계/목표 병기 + ADR#19 소유)은 codex가 구조적으로 수용**했고, 이후는 매번 이전 지적 해소→새 사소 지적이 나오는 **수렴하지 않는 루프**(메모리 `gate-review-loop-lesson` 12라운드 반성 재현). 사용자에게 "마지막 1회" 약속 후 초과 → 자동 정정 중단.
- **조치**: 사용자 승인(AskUserQuestion 2026-06-14 "수동 통과 + 3건 후속 등록")으로 verified_commit `14b4936` → `e7b70d6`(및 본 감사기록 커밋) 수동 전진. 남은 3건은 §5 후속 등록.

## 2. 증거 묶음 (재현 가능)

| 항목 | 값 |
|---|---|
| 전진 전 verified_commit | `14b4936ec508` (2026-06-13 20:58, vc_advance 선례) |
| 산출물 커밋 | `e7b70d6b034e` (ADR#19 + 4문서, 5 files +108/-6) |
| 이 구간 게이트 트리거 파일 | `adr/0019`·`docs/kafka-payloads.md`·`docs/master-design.md`·`docs/phase1/ROADMAP_PHASE1_v0_3.md` (state `triggered` 일치) |
| fail 이력 | `.claude/codex-gate.log`(16:08 fail), state `fail_count`=2, `cache_status`=failing |
| 사용자 승인 | AskUserQuestion 2026-06-14 — 옵션 "수동 통과 + 3건 후속 등록 (권장)" |

## 3. 핵심 방향 수용 + 미해소 지적 (정직 기록)

- **codex 수용분(3차 이후)**: ① 현 단계 계약(공통 `JobResult`)을 spec에 직접 명시 → spec 공백 해소 ② 결정 소유 = ADR#19(handoff 아님) → 위상 역전 해소. 구조 자체에 대한 반대는 없었다.
- **미해소(4차 지적 — §5로 분리)**:
  1. 매핑표/주석의 토픽명 전환 게이트가 `infra/script-agent 컷오버`로 한정 — **hub(consumer) 컷오버 누락**(owner=hub/script-agent/infra).
  2. kafka-payloads `result-topic-job` ①의 `envelope 4종 적용, key=agent_id`가 직접 확정 문장 — ADR#19/`envelope.md`·ADR#6 단일 출처와 동조하려면 **참조형으로 낮춰야** 함.
  3. ROADMAP에 평면화·status·mode·metrics·stdout_ref·job_type화 정렬이 **미배정 TODO로 드러나지 않음**(ADR#19는 Track ID 미정이라 별도 항목 필요).
- **리스크 인정**: 위 3건은 타당한 지적이며, 미해소 상태로 verified_commit을 전진시키면 그만큼 baseline에 미정합이 흡수된다. 이를 §5 후속 작업으로 닫는 것을 조건으로 통과한다.

## 4. 이번 수동 전진의 명분 (선례와 구분)

`codex-gate-roadmap-falsepos`(오탐) 허용 조건과 **다르다**. 이번 명분:
1. 핵심 설계 방향이 게이트에 의해 구조적으로 수용됨(반대 지적 아님).
2. 잔여 지적이 **사소한 정합/추적 보강**이고 계약 *내용*의 오류가 아님(동작·e2e 영향 0 — 코드 미변경).
3. 게이트가 매 라운드 새 사소 지적으로 **수렴하지 않는 루프**(메모리 교훈 임계 도달).
4. 사용자 승인 존재.
5. 잔여 지적을 §5에 후속 작업으로 등록(흡수된 미정합을 추적 가능하게).

> 이 명분은 "오탐이라 무시"가 아니라 "타당하나 사소·후속 분리". 잔여 지적이 계약 *내용* 오류(payload 필드/키/envelope 실제 충돌)였다면 통과하지 않았다. file_state 모순(phase1-044 §3.5)도 같은 이유로 후속 Track에 분리.

## 5. 후속 정합 작업 (등록 — 다음 meta 세션에서 처리)

T4-2 meta 복귀 게이트(컷오버+e2e 후)에서 아래를 함께 닫는다:

- [ ] **F-1**: kafka-payloads 매핑표 + result-topic-log 절의 "토픽명 일치 전환 게이트"에 **hub(consumer) 컷오버 포함**(현재 infra/script-agent만). owner = hub/script-agent/infra 정합.
- [ ] **F-2**: kafka-payloads `result-topic-job` ①의 `envelope 4종/key=agent_id`를 **참조형**(`docs/envelope.md`/ADR#6 단일 출처)으로 낮춤 — ADR#19 표현과 동조.
- [ ] **F-3**: ROADMAP에 평면 목표 정렬의 **미배정 항목(status enum·mode·metrics·stdout_ref·중첩→평면·job_type SHELL/SQL/LOG화)을 TODO/미배정으로 명시** — ADR#19가 Track ID를 정하지 않으므로 추적 공백 방지.
- [ ] **F-4(별건)**: file_state 모순(목표 스키마 payload 포함 ↔ ADR#14 Agent local 미전송) — phase1-044 §3.5 후속 확인 사안.

## 6. 되돌리기

- state 파일: `.claude/.codex-gate-state`(git 비추적). 복원값 `verified_commit`=`14b4936ec508c08f8387f268df9ce6b84770bd3a` → FAIL 상태 복원.
- 산출물 되돌리기: `git revert e7b70d6`(ADR#19 포함 전부). 단 ADR#19 방향은 수용됐으므로 revert보다 §5 후속 보완이 정상 경로.

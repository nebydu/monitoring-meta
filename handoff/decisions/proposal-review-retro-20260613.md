# proposal-review 회고 결과 처리 기록 (2026-06-13)

> **성격**: open-alignment(v0.12)·ams-assumption-baseline(v0.13) 적용 **후** 사용자 요청으로 돌린 회고 proposal-review의 verdict와, 그에 대한 메인 세션(Fable 5)의 채택/보류 판단·근거. proposal-review는 자문(advisory) — 최종 판단은 사람·세션이 한다.

## verdict
- **revise** (confidence: medium, profile 주입 정상). runner 원본 JSON 발췌는 세션 로그 참조.
- 총평(codex): 두 work-id 모두 제약 아래 방향은 타당. 단 AMS 고역전비용 가정·팀 채널 부재 통제가 약해 "적용 전이라면 보완 요구" 수준.

## 항목별 처리 (메인 세션 판단)

| codex 지적 | 판단 | 처리 |
|---|---|---|
| **C1** 팀 채널 부재 시 종료 조건 없음 | **타당(가볍게)** | decisions ⑤ 전역 fallback 규칙 — 채널 미형성+게이트 임박 시 사용자 2차 재승인 갈음, 고위험 항목 DEFERRED |
| **C2** J-04/05/14 설계 격리 원칙 지금 명시 | **절반** | 추적(decisions ④「되돌릴 설계 범위」컬럼)만 채택. **격리 방식 명문화는 보류** — 복합 이벤트 추상화는 T2-1 구현 세션의 기술 결정이라 meta 선점=추측 금지 위반 |
| **P1** decisions 필드 보강(5종) | **채택(축소)** | `used_by_design`(되돌릴 설계 범위 컬럼)+전역 fallback만. blocks·reversal_cost는 현황 표에 기존, review_deadline은 차단 시점 컬럼과 중복, 항목별 fallback은 과잉 |
| **P2** T2-1 전 3건 1페이지 | **보류** | 확정값 0건이라 지금 쓸 내용 없음(빈 양식=ceremony). decisions ⑥에 "확정 시 이 표로 기록" 절차만 예고 |
| **P3** 채널 미형성 대체 경로 | **채택** | C1과 동일 — fallback 규칙에 합침 |
| **P4** v0.12 취소선 제거 TODO | **채택** | open-alignment 패킷 §10 후속 부채 TODO 등재(외부 앵커 정리 후 집행) |
| (codex 5) grep/분류표 첨부 | **보류** | 분류표는 패킷 §3~§4에 기존. missing_context는 codex가 diff 미열람한 것이지 실제 누락 아님 |

## 보류 항목의 재개 트리거
- C2 격리 원칙·P2 1페이지 → **T2-1(Rule Engine) 착수 시점**에 구현 세션이 판단. 그때 J-04·J-05·J-14 잠정 확정과 함께 처리(decisions ⑥ 형식).
- P4 취소선 제거 → 외부 앵커(envelope·adr/0002) 재배선 완료 또는 차기 대규모 정리 릴리스.

## 2라운드 회고(같은 처리 재검토, verdict=revise medium) — 수렴 보완

1라운드 처리 결과를 다시 돌린 회고의 지적 처리(이번이 마지막 — 추가 재호출은 권하지 않음, scope §5 자동 수렴 loop 금지):

| 2라운드 지적 | 판단 | 처리 |
|---|---|---|
| C1 fallback ⑤가 "팀 리뷰 대체"로 단정 | **타당** | ⑤ 재서술 — "대체 아닌 임시 진행, 재검증 부채 유지, 기록된 항목 한정, 고위험은 DEFERRED 기본+위험 명시 수용 결정 필요" |
| C1 발동 시점 "N일 전" 구체화 | **거름** | N일=근거 없는 임의 숫자(추측). "착수 임박+위험도·되돌림 비용·대체 옵션 기록 시" 조건으로만 정밀화 |
| C2 T2-1 handoff 필수 선행 체크 | **타당** | ⑥에 "T2-1 handoff acceptance criteria 선행 조건 — 3건 표 미완 시 착수 불가" + 「격리/추상화 결정」컬럼 |
| P2 1페이지를 고정 섹션으로 흡수 | **타당** | decisions에 「T2-1 착수 전 필수 게이트」고정 섹션(J-04/05/14 placeholder 3행, 6컬럼) 신설 |
| P4 완료 기준 명시 | **타당** | §10에 트리거+완료 기준(6장 절 취소선 줄 삭제→§E 카드 단일화, 순수 미결 §6.3.2·§6.8.6 불가침, grep 재확인) |

## 적용 산출물
- `handoff/decisions/ams-assumption-decisions.md` — 규칙 ④⑤⑥(⑤⑥ 2라운드 보완), 기록 표 「되돌릴 설계 범위」컬럼, **「T2-1 착수 전 필수 게이트」고정 섹션 신설**.
- `handoff/open-alignment/open-alignment-000-decision-packet.md` §10 — 취소선 제거 부채 TODO(2라운드: 완료 기준 추가).
- 통합본 본문 무변경(이번 처리는 추적·절차 보강뿐 — AMS 가정의 답·설계 결정 0).

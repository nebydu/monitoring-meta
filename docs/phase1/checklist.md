# Phase 1 문서 정합성 체크리스트

작성일: 2026-06-04

대상 문서:
- `docs/phase1/ROADMAP_PHASE1_v0_3.md`
- `docs/phase1/ROADMAP_PHASE1_draft_v0_2.md`
- `handoff/phase1-000-roadmap-normalization.md`
- `handoff/phase1-001-envelope-scope.md`
- `adr/0005-topic-naming.md`
- `docs/통합본_v0_9.md`
- `docs/kafka-payloads.md`
- `docs/envelope.md`
- `HANDOFF.md`

## 1. 우선 수정 항목

- [ ] `ROADMAP_PHASE1_v0_3.md` 기준 commit pin 정합화
  - 현재: `4940e1a115b911e452f96f0083f1c4dc6ede879f`
  - Pass 1 요구: `8d7a07668eb7d1d7db375fe2342d90f174bdfc49`
  - 근거: `handoff/phase1-000-roadmap-normalization.md`가 v0.3 헤더에 동일 기준 commit을 pin하라고 명시함.
  - 처리 방향: 원래 Pass 1 기준을 따르거나, 최신 기준으로 바꾼 이유와 결정 이력을 별도 기록한다.

- [ ] `command-topic` zone routing의 ADR 귀속 확정 여부 재검토
  - 현재 v0.3: ADR#4 확정 귀속, D-5에서 제외.
  - Pass 1: `command-topic routing`은 ADR#4 간접 귀속 후보이며 `[결정 필요]`, analyzer 임의 확정 금지.
  - 처리 방향: D-5에 다시 포함하거나, ADR#4 확정 귀속 결정을 별도 decision record로 남긴다.

- [ ] `phase1-001-envelope-scope.md` 기준 commit과 참조 ADR 재현성 정리
  - 현재 기준 commit: `f6697ac840d8f498974c5bb8d14038f93de7fbb3`
  - 문제: 같은 문서가 `adr/0005-topic-naming.md`를 근거로 참조하지만, 해당 ADR은 다음 커밋에서 추가됨.
  - 처리 방향: 기준 commit을 `adr/0005`가 포함된 커밋으로 갱신하거나, 기준 commit에 포함된 문서만 근거로 삼도록 조정한다.

- [ ] `adr/0005-topic-naming.md` 상태를 부분 결정 구조로 명확화
  - 현재 ADR 상태: `Proposed`.
  - ROADMAP/handoff 사용 방식: D-4(2)는 `RESOLVED`, D-4(1)은 비준 대기.
  - 처리 방향: ADR 안에 `D-4(2)=Accepted/Resolved`, `D-4(1)=Proposed`처럼 decision status 표를 추가한다.

- [ ] D-9 해소 결정의 독립 근거 보강
  - 현재 ROADMAP: D-9를 2026-06-03 사람 결정으로 RESOLVED 처리.
  - Pass 1: D-9는 추측 금지 결정 필요 항목.
  - 처리 방향: `adr/0005` 또는 별도 decision log에 D-9 해소 근거와 결정자를 남긴다.

## 2. 문서 구조 개선 항목

- [ ] v0.3 변경 이력 축약
  - 현재 `ROADMAP_PHASE1_v0_3.md` 하단 변경 이력이 너무 길고 과거 실패/수정 문구가 많이 남아 있음.
  - 위험: grep 기반 gate가 과거 문구(`DECISION_REQUIRED`, `[결정 필요](D-9)` 등)에 재반응할 수 있음.
  - 처리 방향: 최종본에는 현재 상태 중심의 요약만 남기고 상세 gate round 이력은 별도 appendix 또는 handoff로 분리한다.

- [ ] D-목록 번호 정책 확인
  - 현재 v0.3: D-목록은 §17, §14는 Track 5.
  - 초기 프롬프트/Pass 1 일부 문맥: “§14 목록” 표현 존재.
  - 처리 방향: 최종본에서 D-목록 위치를 §17로 유지한다면 “§14 자기참조 오류 정정”을 명시하고, 다른 문서의 §14 참조를 전수 확인한다.

- [ ] `통합본 우선`과 `코드 우선` 위상 문구 분리
  - 현재 ROADMAP/HANDOFF 계열은 “코드 → 데모 spec → 통합본” 우선순위와 “통합본 최상위” 문구가 함께 존재함.
  - 처리 방향: Phase 0 회귀 판단은 코드/데모 spec 우선, Phase 1 목표 spec과 사실 충돌 판단은 통합본 우선으로 명시해 혼동을 줄인다.

## 3. 현재 양호한 반영 사항

- [x] status 단일값 문제는 대체로 정리됨.
  - `DONE (heartbeat marshalling only)` 같은 복합 status를 `DONE` + 비고로 분리함.

- [x] D-9/D-4 경계는 이전보다 명확해짐.
  - alert/notification 토픽 신설 여부와 토픽 명명 규칙을 분리함.
  - D-4(2)는 envelope-first로 해소, D-4(1)은 `adr/0005` 비준 대기로 분리함.

- [x] 8토픽 계약 매트릭스는 목표 계약 spec 렌즈로 정리됨.
  - 구현 완료 상태와 계약 정의를 분리해 설명함.

- [x] ADR#2 범위는 heartbeat marshalling only로 잘 분리됨.
  - envelope 나머지 토픽 적용과 ADR#2 완료 상태를 혼동하지 않도록 설명함.

## 4. 최종본 전 확인 순서

1. 기준 commit pin 정책을 확정한다.
2. `command-topic routing` ADR 귀속을 D-5 미결로 되돌릴지, 별도 결정으로 닫을지 확정한다.
3. D-9 해소와 D-4(2) 해소의 사람 결정 근거를 ADR 또는 decision log에 남긴다.
4. `phase1-001-envelope-scope.md`의 기준 commit이 참조 문서들을 재현 가능한지 확인한다.
5. ROADMAP 하단 변경 이력을 현재 상태 중심으로 축약한다.
6. `rg "§14|D-9|command-topic routing|기준 monitoring-meta commit|4940e1a|8d7a076"`로 남은 drift를 확인한다.

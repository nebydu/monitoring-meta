> **이 레이어는 기술(descriptive) 문서다 — 규범(normative)의 답은 통합본(`docs/master-design.md`) / `adr/`에 있다.**

# docs/features — 기능 단위 문서 레이어

인수인계·팀 공유용. **사용자 가시 시나리오**(예: 수집주기 설정 → 로그 수집 → 결과 수신)를 축으로, 어떤 컴포넌트·repo·토픽을 거쳐 **소스 레벨로 흐름을 따라갈 수 있는지** 안내한다.

## 1. 이 레이어의 위상 (혼동 금지)

- **기술(descriptive) 문서다.** 코드의 **현재 상태**를 서술한다. 규범(normative) 문서가 아니다.
- **spec 질문의 답은 여기 없다.** 도달 목표 spec = `docs/master-design.md`(통합본) + `docs/kafka-payloads.md` + `docs/envelope.md`, 결정 기록 = `adr/`. 이 레이어는 **구현 흐름 안내만** 담당한다.
- **통합본·ADR과 충돌하는 서술을 발견하면 임의 수정하지 않는다.** 멈추고 사람에게 보고한다(이 레이어가 규범을 덮어쓰지 않는다).
- **단위 = 컴포넌트가 아니라 사용자 가시 시나리오**(수직 슬라이스, cross-repo). "HeartbeatConsumer 문서"가 아니라 "heartbeat 수집·전송 흐름 문서".
- **구현 완료된 기능만 다룬다.** 미구현 spec은 통합본의 영역이다(여기에 미래 설계를 쓰지 않는다).

## 2. 문서 작성 규칙

- **코드 앵커 = 수명 긴 식별자만 사용.** 토픽명, 패키지/모듈 경계, 진입점 클래스·함수명 등. **라인 번호·git commit hash 사용 금지**(코드가 바뀌면 깨지는 앵커 금지).
- **코드 앵커 금지 규칙과 메타 헤더의 "기준 meta commit"은 별개다.** 본문에서 코드를 가리키는 **코드 앵커**로는 라인번호·commit hash를 쓰지 않는다. 반면 템플릿 §0 메타 헤더의 "기준 meta commit"은 이 문서가 **어느 시점 통합본/adr spec을 참조했는지**를 고정하는 출처 메타데이터이며 코드 앵커가 아니다 — 둘을 혼동하지 않는다.
- **"최종 검증 기준" 필드 필수.** 이 문서의 서술이 어느 시점 무엇으로 사실 확인됐는지 — 예: 어느 `e2e/results/<timestamp>.md`, 어느 golden case 기준인지 명시.
- **코드에서 확인한 사실만 기재.** 추측 금지. 확인 못 한 동작은 쓰지 않거나 "미확인"으로 표기한다.
- **충돌·미결정 발견 시 멈추고 보고.** 통합본/ADR과 어긋나는 코드 동작, 미결정 사안을 만나면 문서에 단정하지 말고 사람을 호출한다.
- 문서는 **한국어**, 식별자는 **영어**. 본문은 **간결한 개조식/명사형 종결**.
- 새 문서는 `_template.md`를 복사해 시작한다. 파일명은 시나리오 기반 영어 kebab-case(예: `heartbeat-collection.md`).

## 3. 작성·갱신 파이프라인

> 이 파이프라인(작업 분장·권한 모델)은 monitoring-meta 운영 규약(`.claude/CLAUDE.md`)에 속한다 — 제품 spec(통합본)·아키텍처 결정(`adr/`)이 정하는 사항이 아니며, 이 레이어 신설 작업에서 사람 승인 하에 정해진 것이다.

- 신규 작성·보완은 `feature-doc-writer` sub-agent가 수행한다(Write 범위 = `docs/features/`에 한정).
- **작업 대상은 work spec의 "영향받는 기능 문서" 항목에 지정된 것만.** agent는 영향 문서를 스스로 판단하지 않는다 — 지정이 없거나 불분명하면 멈추고 사람을 호출한다.
- 어떤 작업이 어떤 기능 문서에 영향을 주는지는 `analyzer`가 work spec 분석 시 산출한다(신규 작성 대상 / 보완 대상 / 해당 없음).

## 4. 인덱스

| 기능 문서 | 사용자 시나리오 | 관여 repo | 최종 검증 기준 | 상태 |
|---|---|---|---|---|
| [heartbeat-collection.md](heartbeat-collection.md) | script-agent가 살아있음을 hub가 주기적으로 인지 | script-agent, infra, hub | `e2e/results/20260610-152424.md` PASS 58/0/0 | 검증됨 |
| [script-job-execution.md](script-job-execution.md) | 스케줄 등록 → Quartz 트리거 → command-topic → SCRIPT_JOB 실행 → job-results → hub 수신·표시 | hub, script-agent, infra | `e2e/results/20260610-152424.md` PASS 58/0/0 | 검증됨 |
| [log-job-collection.md](log-job-collection.md) | 스케줄 등록 → command-topic → LOG_JOB 실행(offset 추적·tail-f 스타일) → job-results → hub 수신·표시 | hub, script-agent, infra | `e2e/results/20260611-095734.md` PASS 60/0/0 | 검증됨 |
| [agent-lifecycle-audit.md](agent-lifecycle-audit.md) | agent 기동 → AGENT_STARTED(audit-topic) → hub AgentRegistry 등록 / job 실행 → JOB_EXECUTED / agent 종료 → AGENT_STOPPED → OFFLINE 마킹 | script-agent, hub, infra | `e2e/results/20260611-095734.md` PASS 60/0/0 | 검증됨 |

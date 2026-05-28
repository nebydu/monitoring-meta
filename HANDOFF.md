# 인계 문서 — monitoring 본개발 자동화 셋업

> 이 문서는 새 대화창에서도 동일한 컨텍스트로 작업을 이어가기 위한 단일 인계 자산이다. 작업 단계가 바뀔 때마다 §5 체크리스트와 §7 미결정 사안을 갱신한다.
>
> 위치 규약: monitoring-meta repo의 **루트**에 둔다. `handoff/` 디렉터리는 작업 산출물 교환소이고 이 문서와는 별도다.
>
> 갱신 기준일: 2026-05-28 (hub `.claude/` 셋업 검토 완료 시점)

## 1. 한 줄 요약

monitoring 솔루션의 polyrepo(hub / script-agent / infra / monitoring-meta) 구조에서 Phase 1 본개발을 sub-agent 파이프라인 + Codex read-only 검증 hook으로 자동화하는 중. **envelope spec 작성은 완료**(monitoring-meta/docs/envelope.md 박힘). 다만 이건 spec 정의만의 완료이고, **hub과 script-agent 코드는 여전히 Phase 0 동작을 따른다**. monitoring-meta와 hub의 `.claude/` 셋업은 완료됐고, 다음 단계는 script-agent `.claude/` 셋업(5단계).

## 2. 결정된 기반 사실

- **레포 구조**: polyrepo. `C:\workspace\monitoring\` 아래 `hub/`, `script-agent/`, `infra/`, `monitoring-meta/` 4개. 각각 독립 GitHub repo. 상위 폴더는 git 아님.
- **monitoring-meta**: 신규 repo. 공통 spec + 통합 검증 + repo 간 작업 핸드오프를 책임.
- **셸 환경**: Git Bash. hook 스크립트는 `.sh`. JSON 파싱은 원칙적으로 `jq`를 쓰되, 현재 hub hook은 로컬 Git Bash에 `jq`가 없어 Python 파싱을 운영상 예외로 기록했다.
- **Codex 역할**: read-only 검토 전담. Stop hook으로 호출됨. 수동 호출 Codex(사람이 직접)는 종전대로 수정 가능.
- **언어 규칙**: 한국어 답변/주석/문서. 영어 식별자.

## 3. 정본 문서 위치와 위상

| 문서 | 위치 | 위상 |
|---|---|---|
| 통합본_v0_9.md | monitoring-meta/docs/ | **Phase 1+ 도달 목표 spec의 단일 정본** |
| kafka-payloads.md | monitoring-meta/docs/ | 통합본 별첨, 8토픽 payload |
| envelope.md | monitoring-meta/docs/ | **정의 완료. 코드 구현은 미실행.** |
| PROJECT_OVERVIEW.md | monitoring-meta/docs/phase0-snapshot/ | Phase 0 데모 코드 상태 스냅샷 (참조용) |
| monitoring-demo-message-spec-v0.2.1.md | hub/docs/ (정본 후보) + script-agent/docs/ (사본) | **Phase 0 코드가 회귀 없이 지켜야 할 동작 spec** |

ground truth 우선순위: 코드 → 데모 spec v0.2.1 (Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope (Phase 1+ 도달 목표).

**중요한 위상 구분**: envelope.md가 박혔다는 건 "spec이 결정됐다"는 의미이지 "코드가 envelope을 따르게 됐다"는 의미가 아니다. 현재 hub의 Spring Kafka Producer/Consumer와 script-agent의 Go Kafka 발행/소비 코드는 여전히 데모 spec v0.2.1 envelope 구조(또는 envelope 부재 상태)를 따르고 있다. envelope을 코드에 반영하는 작업은 4·5·6단계 + 후속 코드 ADR로 점진 처리한다.

## 4. 디렉터리 배치

```
C:\workspace\monitoring\
├── hub\                              # 기존 repo, .claude\ 셋업 완료
├── script-agent\                     # 기존 repo, .claude\ 미셋업
├── infra\                            # 기존 repo, .claude\ 안 만듦
└── monitoring-meta\                  # 신규 repo, .claude\ 셋업 완료
    ├── HANDOFF.md                    # ← 이 문서 (루트, 단일 인계 자산)
    ├── README.md                     # repo 소개 (별도)
    ├── .claude\
    │   ├── CLAUDE.md
    │   ├── settings.json
    │   ├── codex-schema.json
    │   ├── hooks\codex-gate.sh
    │   └── agents\
    │       ├── analyzer.md
    │       ├── spec-sync.md
    │       └── e2e-tester.md
    ├── docs\                         # 정본 spec 문서 전용
    │   ├── 통합본_v0_9.md
    │   ├── kafka-payloads.md
    │   ├── envelope.md               # 정의 완료
    │   └── phase0-snapshot\
    │       └── PROJECT_OVERVIEW.md
    ├── handoff\                      # 작업 산출물 교환소 (시간순 누적)
    │   ├── envelope-draft-analysis.md
    │   ├── spec-drift-*.md
    │   └── (향후 ADR 분배 spec이 추가됨)
    ├── adr\                          # ADR 결정 기록
    └── e2e\                          # 종단 검증 스크립트
```

**디렉터리 명명 주의**: `HANDOFF.md`(루트, 단일 파일, 운영 문서)와 `handoff/`(디렉터리, 작업 산출물 교환소)는 이름이 비슷하지만 위상이 다르다. HANDOFF.md는 현재 상태 인계, handoff/는 시간순 누적 산출물.

## 5. 현재 작업 위상

각 단계 완료 시 사람이 직접 체크박스를 갱신한다.

- [x] 1단계: monitoring-meta repo 생성, 정본 문서 이동
- [x] 2단계: monitoring-meta `.claude/` 셋업 (analyzer, spec-sync, e2e-tester)
- [x] 3단계: envelope spec 작성 — **spec 정의만 완료. 코드 구현은 미실행.**
  - [x] 1라운드 — 후보안 + 결정 사안 분석 (`handoff/envelope-draft-analysis.md`)
  - [x] 1번 외부 surface 분리 작업 — LOG job → result-topic-log 라우팅 규칙 명시
  - [x] 2번 외부 surface 보완 — heartbeats otlp_json↔protobuf 경계 + OTLP 예외 의미
  - [x] 2라운드 — `docs/envelope.md` 확정 + Stop hook 검증
- [x] 4단계: hub `.claude/` 셋업 (sub-agent 6개)
- [ ] 5단계: script-agent `.claude/` 셋업 (sub-agent 6개)
- [ ] 6단계: 첫 코드 ADR — ADR #2 heartbeat protobuf 전환 (envelope을 코드에 반영하는 첫 작업)
- [ ] 7단계 이후: 나머지 토픽의 envelope 적용 ADR (envelope spec ↔ 코드 gap 해소)

## 6. 셋업된 monitoring-meta `.claude/` 구조

- **sub-agent 3종**:
  - `analyzer` — 통합본 + 양쪽 코드 영향 분석. Write 권한은 `docs/`, `adr/`, `handoff/`에만.
  - `spec-sync` — 정본↔사본 spec drift 검출만. Write 권한은 `handoff/`에만. 다른 repo 파일 수정 금지.
  - `e2e-tester` — polyrepo 종단 검증. Write 권한은 `e2e/`에만.
- **표준 작업 흐름**:
  - spec 작업: analyzer → 사람 결정 → analyzer 최종안 → spec-sync drift → Stop hook 검증.
  - ADR 분배(양쪽 repo 영향): analyzer → `handoff/<work-id>-hub.md` + `handoff/<work-id>-script-agent.md` → 사람이 각 repo로 이동.
  - 종단 검증: e2e-tester 단독.
- **Stop hook 발화 대상**: `docs/통합본_v0_9.md`, `docs/envelope.md`, `docs/kafka-payloads.md`, `adr/*.md` 변경 시 `codex review --uncommitted` 호출 (또는 fallback `git diff HEAD | codex exec`). `handoff/`, `e2e/`, `.claude/` 변경만 있으면 스킵.
- **Hook 안전장치**: stop_hook_active 무한루프 가드, 3회 fail 후 강제 통과, 2회 파싱 실패 후 강제 통과 모두 포함. Hook 운영 상태 파일(`.codex-gate-state`, `.codex-gate-log`, `.codex-gate-issues.txt`, `.codex-gate-stderr.txt`, `.codex-last-message.json` 등)은 `.gitignore`에 등록.
- **결과 보고 스키마**: `{ status, outputs, findings, blockers, next_action }` + `외부 surface` 섹션(범위 밖 issue 분류용).

## 7. 미결정 사안 (작업 중 결정 필요)

- **envelope spec ↔ 현재 코드 gap**: envelope이 monitoring-meta에 박혔지만 hub과 script-agent 코드는 미반영 상태. 첫 코드 ADR(#2)이 일부만 해소(heartbeats 부분). 나머지 7개 토픽의 envelope 적용은 후속 ADR로. **ADR 카탈로그에 "envelope 반영 작업"을 명시적으로 추가할지** 결정 필요.
- **데모 spec v0.2.1 정본 위치**: envelope 작업 결과를 따라 hub/docs에 머무는지 monitoring-meta로 끌어올려질지 사람 확인 필요. envelope 2라운드 작업 중에 같이 다뤄졌을 가능성 있음 — `docs/envelope.md`와 `handoff/envelope-draft-analysis.md` 호환성 매트릭스 확인.
- **hub의 모듈러 모놀리스 → 9개 deployment 분리 시점**: 통합본 v0.9 §7.2 β 구조 기준. Phase 1 중반에 일부 분리 예정. hub `.claude/`의 sub-agent들이 "분리 좋은 패키지 구조"를 강제하도록 셋업.
- **hub/AGENTS.md 갱신**: "자동화 hook에서 호출되는 Codex는 read-only 검토만, 사람이 수동 호출하는 Codex는 종전대로" 한 단락 추가. 4단계 셋업 완료 후 사람이 수동 처리.

## 8. hub `.claude/` 셋업 완료 요약 (4단계)

- **sub-agent 6종**: `analyzer`, `implementer`, `tester`, `reviewer`, `spec-guardian`, `refactorer`.
- **권한 분리**: `tester`/`reviewer`/`spec-guardian` Edit 금지. `refactorer`는 기능 추가·동작 변경·인터페이스 변경 금지.
- **표준 호출 순서**: analyzer → implementer → tester → (병렬) reviewer + spec-guardian → (필요시) refactorer → Stop 시 Codex.
- **재시도 한도**: implementer 재호출 최대 3회, 초과 시 사람 escalation.
- **ground truth 참조 경로**:
  - `../monitoring-meta/docs/통합본_v0_9.md` — Phase 1+ 도달 목표
  - `../monitoring-meta/docs/envelope.md` — 공통 envelope 정본
  - `../monitoring-meta/docs/kafka-payloads.md` — 8토픽 payload 정본
  - `docs/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준
- **작업 입력**: `../monitoring-meta/handoff/<work-id>-hub.md` 형식의 작업 spec을 입력으로 받음.
- **spec-guardian의 역할**: Phase 0 데모 spec과 Phase 1 목표 spec(envelope + kafka-payloads)의 위상 차이를 인지하면서, 현재 코드가 어느 위상에 있는지 판단하고 정합성 검토. envelope.md가 박혔다고 해서 코드가 자동으로 envelope을 따르는 게 아님을 모든 검토에 반영.
- **drift 보고서 반영**: `handoff/spec-drift-envelope-20260527-143000.md`의 결론은 hub `.claude/agents/spec-guardian.md`에 강제 룰로 반영됨. 결론은 drift 없음이며, envelope 헤더 4종 키/값/생략 로직 회귀 방지를 critical로 둔다. 향후 drift 보고서가 갱신되면 사람 수동으로 재반영한다.
- **reviewer의 강제 룰**: 통합본 v0.9 §7.2 β 구조 모듈 경계를 가로지르는 의존이 생기면 critical로 잡음. 메인 BE(Auth/Job/Approval/Knox/Validation/Agent State)와 분리 대상(rule-engine, Script Result, Alert/Incident, Notification, Metric Ingest)의 경계 의식.
- **셸 / Stop hook**: Git Bash. `settings.json`은 Windows PATH의 WSL bash 오인식을 피하기 위해 Git Bash 절대경로(`C:\Program Files\Git\bin\bash.exe`)를 exec form으로 호출한다. Codex hook 발화 대상은 hub 코드 경로(`src/main/**`, `src/test/**`, `pom.xml`)이고, `.claude/**`, `docs/**`, `analysis/**`만 변경된 경우 스킵한다.
- **검증 메모**: `stop_hook_active` 무한루프 가드와 스킵 경로는 Git Bash 직접 실행 dry-run으로 통과 확인. 현재 환경에 `jq`가 없어 hook JSON 파싱은 Python으로 구현되어 있으며, `codex review --uncommitted` 대신 `codex exec --sandbox read-only` fallback 경로를 직접 사용한다. 이는 handoff 원문 요구와 다른 운영상 예외로 기록한다.

## 9. 운영 룰 (모든 단계 공통)

- 미결정 사안은 추측으로 메우지 않는다. 통합본 v0.9의 Open question 또는 미결정 ADR은 발견 즉시 멈추고 사람 호출.
- 결과 보고에 "외부 surface" 섹션 standard. 분리 가능 여부 컬럼 필수.
- Codex hook이 fail 경로를 무한히 돌지 않도록 retry 카운터 + 강제 통과 가드 항상 유지.
- 한 번의 명령으로 단계를 뛰어넘지 않는다. 각 단계 사이에 사람 확인 게이트 필수.
- **spec 정의 완료와 코드 구현 완료를 절대 동일시하지 않는다**. envelope.md가 박혀도 hub/script-agent 코드는 별도 ADR로 반영해야 함.
- HANDOFF.md(이 문서)는 각 단계 종료 시마다 §5 체크리스트 + §7 미결정 사안 갱신. 갱신은 **사람이 수동**으로 한다(sub-agent에게 자동 갱신을 위임하지 않음 — 미결정 사안 해소나 다음 단계 결정이 모두 사람 판단이라서). 갱신 안 하면 다음 대화창에서 컨텍스트 어긋남.

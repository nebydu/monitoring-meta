# 인계 문서 — monitoring 본개발 자동화 셋업

> 이 문서는 새 대화창에서도 동일한 컨텍스트로 작업을 이어가기 위한 단일 인계 자산이다. 작업 단계가 바뀔 때마다 §5 체크리스트와 §7 미결정 사안을 갱신한다.
>
> 위치 규약: monitoring-meta repo의 **루트**에 둔다. `handoff/` 디렉터리는 작업 산출물 교환소이고 이 문서와는 별도다.
>
> 갱신 기준일: 2026-05-29 (hub·script-agent `.claude/` 셋업 완료 시점)

## 1. 한 줄 요약

monitoring 솔루션의 polyrepo(hub / script-agent / infra / monitoring-meta) 구조에서 Phase 1 본개발을 sub-agent 파이프라인 + Codex read-only 검증 hook으로 자동화하는 중. **세 repo(monitoring-meta, hub, script-agent)의 `.claude/` 셋업이 모두 완료**됐고, **envelope spec 작성도 완료**(monitoring-meta/docs/envelope.md). 다만 envelope은 일부만 코드에 반영된 상태(아래 §5 참조)다. 다음 단계는 첫 코드 ADR(6단계, ADR #2 heartbeat protobuf 전환).

## 2. 결정된 기반 사실

- **레포 구조**: polyrepo. `C:\workspace\monitoring\` 아래 `hub/`, `script-agent/`, `infra/`, `monitoring-meta/` 4개. 각각 독립 GitHub repo. 상위 폴더는 git 아님.
- **monitoring-meta**: 공통 spec + 통합 검증 + repo 간 작업 핸드오프를 책임. 런타임에 구동되는 시스템이 아니라 개발 시점의 작업장 + 공통 자산 보관소.
- **공통 정본 참조 방식**: envelope.md, kafka-payloads.md, 통합본은 monitoring-meta에 **단일 정본**으로 두고, hub/script-agent는 **상대 경로로 참조만 하며 사본을 두지 않는다**. (데모 spec v0.2.1만 hub/docs·script-agent/docs 양쪽에 사본 존재 — 이건 Phase 0 유산.)
- **셸 환경**: Git Bash. hook 스크립트는 `.sh`, JSON 파싱은 `python`(이 환경에 `jq` 미설치).
- **Codex 역할**: read-only 검토 전담. Stop hook으로 호출됨. 수동 호출 Codex(사람이 직접)는 종전대로 수정 가능.
- **언어 규칙**: 한국어 답변/주석/문서. 영어 식별자.

## 3. 정본 문서 위치와 위상

| 문서 | 위치 | 위상 |
|---|---|---|
| 통합본_v0_9.md | monitoring-meta/docs/ | **Phase 1+ 도달 목표 spec의 단일 정본** |
| kafka-payloads.md | monitoring-meta/docs/ | 통합본 별첨, 8토픽 payload. 단일 정본, 사본 없음 |
| envelope.md | monitoring-meta/docs/ | 모든 메시지 공통 봉투(메타데이터). 단일 정본, 사본 없음. **command-topic 헤더는 기구현, 나머지 토픽 적용·protobuf 전환은 미실행** |
| PROJECT_OVERVIEW.md | monitoring-meta/docs/phase0-snapshot/ | Phase 0 데모 코드 상태 스냅샷 (참조용) |
| monitoring-demo-message-spec-v0.2.1.md | hub/docs/ + script-agent/docs/ (사본) | **Phase 0 코드가 회귀 없이 지켜야 할 동작 spec**. 양쪽 사본 동일 |

ground truth 우선순위: 코드 → 데모 spec v0.2.1 (Phase 0 회귀 방지) → 통합본 v0.9 + kafka-payloads + envelope (Phase 1+ 도달 목표).

**위상 구분**: envelope.md가 박혔다는 건 "spec이 결정됐다"는 의미이지 "코드가 envelope을 전부 따르게 됐다"는 의미가 아니다. spec-sync drift 보고서(2026-05-27) 기준 command-topic의 헤더 로직(hub CommandPublisher.java, script-agent envelope.go)은 이미 envelope.md와 일치하지만, 나머지 토픽의 envelope 적용과 heartbeat protobuf 전환은 미실행이다.

## 4. 디렉터리 배치

```
C:\workspace\monitoring\
├── hub\                              # 기존 repo, .claude\ 셋업 완료
│   ├── .claude\                      # sub-agent 6종 + Codex hook
│   └── docs\monitoring-demo-message-spec-v0.2.1.md
├── script-agent\                     # 기존 repo, .claude\ 셋업 완료
│   ├── .claude\                      # sub-agent 6종 + Codex hook
│   └── docs\monitoring-demo-message-spec-v0.2.1.md
├── infra\                            # 기존 repo, .claude\ 안 만듦
└── monitoring-meta\                  # 신규 repo, .claude\ 셋업 완료
    ├── HANDOFF.md                    # ← 이 문서 (루트, 단일 인계 자산)
    ├── README.md
    ├── .claude\
    │   ├── CLAUDE.md
    │   ├── settings.json
    │   ├── codex-schema.json
    │   ├── hooks\codex-gate.sh
    │   └── agents\
    │       ├── analyzer.md
    │       ├── spec-sync.md          # 역할 재검토 대상 (§7 참조)
    │       └── e2e-tester.md
    ├── docs\
    │   ├── 통합본_v0_9.md
    │   ├── kafka-payloads.md
    │   ├── envelope.md
    │   └── phase0-snapshot\PROJECT_OVERVIEW.md
    ├── handoff\                      # 작업 산출물 교환소 (시간순 누적)
    ├── adr\
    └── e2e\
```

**디렉터리 명명 주의**: `HANDOFF.md`(루트, 단일 파일, 운영 문서)와 `handoff/`(디렉터리, 작업 산출물 교환소)는 위상이 다르다.

## 5. 현재 작업 위상

각 단계 완료 시 사람이 직접 체크박스를 갱신한다.

- [x] 1단계: monitoring-meta repo 생성, 정본 문서 이동
- [x] 2단계: monitoring-meta `.claude/` 셋업 (analyzer, spec-sync, e2e-tester)
- [x] 3단계: envelope spec 작성 — **spec 정의 완료. command-topic 헤더는 기구현, 나머지 토픽 적용은 미실행.**
  - [x] 1라운드 — 후보안 + 결정 사안 분석
  - [x] 1번 외부 surface 분리 작업 — LOG job → result-topic-log 라우팅 규칙 명시
  - [x] 2번 외부 surface 보완 — heartbeats otlp_json↔protobuf 경계 + OTLP 예외 의미
  - [x] 2라운드 — `docs/envelope.md` 확정 + Stop hook 검증
- [x] 4단계: hub `.claude/` 셋업 (sub-agent 6개)  ※ 실제 구조는 §8 / hub/.claude 대조 확인 권장
- [x] 5단계: script-agent `.claude/` 셋업 (sub-agent 6개)  ※ 실제 구조는 §8 / script-agent/.claude 대조 확인 권장
- [ ] 6단계: 첫 코드 ADR — ADR #2 heartbeat protobuf 전환 (envelope을 코드에 반영하는 첫 양쪽 걸친 작업)
- [ ] 7단계 이후: 나머지 토픽의 envelope 적용 ADR (envelope spec ↔ 코드 gap 해소)

## 6. 셋업된 `.claude/` 구조 요약

**monitoring-meta** — sub-agent 3종:
- `analyzer` — 통합본 + 양쪽 코드 영향 분석. Write 권한은 `docs/`, `adr/`, `handoff/`에만.
- `spec-sync` — **역할 재검토 대상**. 단일 정본 결정으로 "정본↔사본 동기화" 역할이 사실상 소멸. 현재 가치 있는 일(정본 내부 일관성, spec↔코드 정합성, cross-repo 일관성)은 각각 Codex hook / 각 repo spec-guardian과 겹침. §7 참조.
- `e2e-tester` — polyrepo 종단 검증. Write 권한은 `e2e/`에만.

**hub / script-agent** — 각 sub-agent 6종 (analyzer, implementer, tester, reviewer, spec-guardian, refactorer). 표준 호출 순서: analyzer → implementer → tester → (병렬) reviewer + spec-guardian → (필요시) refactorer → Stop 시 Codex. hub은 Spring Boot/Maven 컨텍스트(`mvn test`), script-agent는 Go 컨텍스트(`go test ./...`). 권한 분리: tester/reviewer/spec-guardian Edit 금지, refactorer 기능 추가 금지.
※ 위 hub/script-agent 구조는 셋업 메모(§8) 기준 예상치다. 실제 각 repo의 `.claude/agents/`와 대조해 정확히 맞는지 확인할 것.

**Stop hook (monitoring-meta)**: `docs/통합본_v0_9.md`, `docs/envelope.md`, `docs/kafka-payloads.md`, `adr/*.md` 변경 시 Codex 검토. `handoff/`, `e2e/`, `.claude/` 변경만 있으면 스킵. 무한루프 가드 + 3회 fail 후 강제 통과 + 2회 파싱 실패 후 강제 통과 포함. 상태 파일(`.codex-gate-state`, `codex-gate.log`, `.codex-gate-issues.txt`, `.codex-gate-stderr.txt`, `.codex-last-message.json`)은 `.gitignore` 등록.

## 7. 미결정 사안 (작업 중 결정 필요)

- **spec-sync 거취**: 단일 정본 결정으로 동기화 역할이 소멸. 선택지 — ① 폐기(내부 일관성=Codex hook, spec↔코드=각 repo spec-guardian, cross-repo 검증=e2e-tester로 흡수), ② `cross-repo-conformance`로 재정의(양쪽 코드가 같은 envelope/payload를 일관 구현했는지 한 자리에서 검증). 권장: ADR #2를 한 번 굴려보고 e2e-tester만으로 cross-repo 검증이 충분한지 본 뒤 결정. 그 전까지 spec-sync를 "동기화 도구"로 인식하지 말 것. scope creep(spec↔코드 비교까지 손댄 점) 정리 필요.
- **envelope spec ↔ 현재 코드 gap**: command-topic 헤더만 기구현. 나머지 7개 토픽 envelope 적용 + heartbeat protobuf 전환은 미실행. ADR #2가 일부(heartbeats) 해소. **ADR 카탈로그에 "envelope 반영 작업"을 토픽별로 명시 추가할지** 결정 필요.
- **hub의 모듈러 모놀리스 → 9개 deployment 분리 시점**: 통합본 v0.9 §7.2 β 구조 기준. Phase 1 중반에 일부 분리 예정. hub `.claude/`의 reviewer가 "분리 좋은 패키지 구조"를 강제.
- **hub/AGENTS.md 갱신**: "자동화 hook의 Codex는 read-only 검토만, 사람 수동 호출 Codex는 종전대로" 한 단락 추가. 사람이 수동 처리.
- **cross-repo contract audit 트리거**: 양쪽 코드가 같은 envelope/payload 계약을 지키는지 보는 감사를 누가 언제 발화시킬지 미정. 현재 monitoring-meta Stop hook은 docs 변경만, 각 repo hook은 자기 코드만 본다. e2e-tester에 흡수할지 별도 메커니즘을 둘지 결정 필요.

## 8. hub / script-agent `.claude/` 셋업 시 적용한 핵심 룰

> 4·5단계 셋업 완료. 아래는 셋업 시 적용하기로 한 룰이며, 실제 각 repo의 `.claude/` 파일과 대조해 일치 여부를 확인할 것.

- **sub-agent 6종**: `analyzer`, `implementer`, `tester`, `reviewer`, `spec-guardian`, `refactorer`.
- **권한 분리**: tester/reviewer/spec-guardian Edit 금지. refactorer는 기능 추가·동작 변경·인터페이스 변경 금지.
- **표준 호출 순서**: analyzer → implementer → tester → (병렬) reviewer + spec-guardian → (필요시) refactorer → Stop 시 Codex.
- **재시도 한도**: implementer 재호출 최대 3회, 초과 시 사람 escalation.
- **ground truth 참조 경로** (상대 경로, 사본 두지 않음):
  - `../monitoring-meta/docs/통합본_v0_9.md`, `../monitoring-meta/docs/envelope.md`, `../monitoring-meta/docs/kafka-payloads.md`
  - `docs/monitoring-demo-message-spec-v0.2.1.md` (Phase 0 회귀 방지 기준)
- **형제 디렉터리 읽기**: hub·script-agent는 `../monitoring-meta/docs/`, `../monitoring-meta/handoff/`를 상대 경로로 **참조만** 한다(작업 입력과 정본). 별도 `settings.json` 읽기 권한 등록은 불필요하며(필요 시 승인 프롬프트로 처리), 실제 두 repo `settings.json`에도 Stop hook 설정만 있다.
- **작업 입력**: `../monitoring-meta/handoff/<work-id>-hub.md` / `<work-id>-script-agent.md`를 입력으로 받음(복사 아님, 참조).
- **spec-guardian**: Phase 0 데모 spec과 Phase 1 목표 spec의 위상 차이를 인지하며 현재 코드가 어느 위상에 있는지 판단하고 정합성 검토. envelope.md가 박혀도 코드가 자동으로 따르는 게 아님을 반영.
- **reviewer**: 통합본 v0.9 §7.2 β 구조 모듈 경계를 가로지르는 의존이 생기면 critical. 메인 BE(Auth/Job/Approval/Knox/Validation/Agent State) vs 분리 대상(rule-engine, Script Result, Alert/Incident, Notification, Metric Ingest) 경계 의식.
- **셸/hook**: Git Bash. Codex hook은 monitoring-meta codex-gate.sh와 동일 구조이되 발화 대상은 각 repo 코드 경로(hub: `src/main/**`,`src/test/**`,`pom.xml` / script-agent: `**/*.go`,`go.mod`).

## 9. 운영 룰 (모든 단계 공통)

- 미결정 사안은 추측으로 메우지 않는다. 통합본 v0.9의 Open question 또는 미결정 ADR은 발견 즉시 멈추고 사람 호출.
- 결과 보고에 "외부 surface" 섹션 standard. 분리 가능 여부 컬럼 필수.
- Codex hook이 fail 경로를 무한히 돌지 않도록 retry 카운터 + 강제 통과 가드 항상 유지.
- 한 번의 명령으로 단계를 뛰어넘지 않는다. 각 단계 사이에 사람 확인 게이트 필수. **양쪽 repo에 걸친 작업은 세션 경계를 넘으므로(monitoring-meta 분석/분배 → hub 세션 → script-agent 세션 → monitoring-meta e2e) 한 명령으로 완전 자동화되지 않는다. 세션 전환은 사람이 한다.**
- **spec 정의 완료와 코드 구현 완료를 절대 동일시하지 않는다**.
- **spec-drift 보고서 정리**: 동기화/확인이 끝난 `handoff/spec-drift-*.md`는 archive 또는 삭제. 검출 시점의 사진이지 영속 자산이 아니므로 `.gitignore`에 `handoff/spec-drift-*.md` 등록 권장.
- HANDOFF.md(이 문서)는 각 단계 종료 시마다 §5 체크리스트 + §7 미결정 사안을 **사람이 수동**으로 갱신. Project Knowledge 사본도 함께 교체 업로드(monitoring-meta 루트가 정본, Knowledge는 복제).
# 작업 spec — &lt;work-id&gt;

> **이 파일은 작성 템플릿이다.** 실제 작업 spec은 이 파일을 복사해
> `handoff/<work-id>/<work-id>-hub.md`, `handoff/<work-id>/<work-id>-script-agent.md`로 만든다(한 작업 단위 = 한 디렉터리, 한 파일 = 한 repo).
> (Windows 파일명에 `<` `>`를 못 쓰므로 템플릿 자체는 `_TEMPLATE-work-spec.md`로 둔다.
> `<work-id>`는 실제 파일에서 작업 식별자로 치환되는 자리표시자다.)
>
> 아래 `<...>` 자리표시자를 모두 채운다. **채우지 못하는 항목(특히 미결정 사안)이 있으면
> 추측으로 메우지 말고 작성을 멈추고 사람을 호출한다.**
>
> **ID 명명 규칙**: spec 본문에서 새 식별자를 만들 때는 **T(작업)/D(결정)/ADR(결정 기록) 3종만** 쓴다.
> 폐지 패밀리(G, DoD, N/C/S/drift, P/X/M) 신규 생성 금지 — 읽는 법은 `docs/phase1/ID-GLOSSARY.md`.

## 1. 필수 헤더

| 필드 | 값 | 비고 |
|---|---|---|
| 작업 ID (work-id) | `<work-id>` | 파일명 앞부분과 일치 |
| 대상 repo | `hub` \| `script-agent` | 한 파일당 한 repo만 |
| **기준 monitoring-meta commit** | `<full-hash>` | **필수.** 이 spec이 가리키는 기준 문서(통합본 v0.10 / envelope.md / kafka-payloads.md)의 **고정 시점**. 아래 §1.1 참조 |
| 작성일 | `YYYY-MM-DD` | |
| 근거 ADR | `adr/<n>-<slug>.md` \| `(해당 없음)` | |

### 1.1 "기준 monitoring-meta commit"이 필수인 이유

hub·script-agent 세션은 기준 문서 spec을 **상대 경로로 참조만** 한다(`../monitoring-meta/docs/...`, 사본 없음).
그 기준 문서는 시간이 지나면 갱신되므로, 작업 spec을 **언제 시점의 기준 문서**을 기준으로 썼는지 못 박지 않으면
작성 시점과 실행(코드 작업) 시점 사이에 spec drift가 끼어든다.
이 해시가 있으면 실행 세션이 "이 spec은 meta `<hash>` 상태를 전제로 한다"를 확정하고,
필요 시 `git -C ../monitoring-meta log <hash>..HEAD -- docs/`로 그 사이 기준 문서 변경을 점검할 수 있다.

작성 시 monitoring-meta repo 루트에서:

```bash
git rev-parse HEAD     # full 40자 hash를 그대로 기입
```

(축약 hash 금지 — full hash로 기입한다.)

## 2. 문서 성격 상기 (매 작업 고정)

ground truth 우선순위: **코드 → 데모 spec v0.2.1(Phase 0 회귀 방지) → 통합본 v0.10 + kafka-payloads + envelope(Phase 1+ 도달 목표)**.

- 데모 spec v0.2.1은 "회귀 없이 지켜야 할 동작"이고, 통합본/envelope/kafka-payloads는 "도달 목표"다. **둘을 같은 기준으로 다루지 않는다.**
- envelope.md가 박혔다고 코드가 자동으로 envelope을 따르는 게 아니다. 현재 코드가 어느 성격에 있는지 먼저 판단한다.

## 3. ground truth 참조 경로 (상대 경로, 사본 두지 않음)

- `../monitoring-meta/docs/master-design.md` — 통합본, Phase 1+ 도달 목표 (버전 없는 파일명 — 버전은 문서 내부 표기로만 관리)
- `../monitoring-meta/docs/envelope.md` — 공통 봉투 기준 문서
- `../monitoring-meta/docs/kafka-payloads.md` — 8토픽 payload 기준 문서
- `../monitoring-meta/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md` — Phase 0 회귀 방지 기준(monitoring-meta 단일 기준 문서 — 작업 B로 단일화)

## 4. 배경 / 목표

<이 작업이 왜 필요한가, 끝났을 때 도달 상태는 무엇인가 — 2~4줄>

## 5. 작업 범위

### 해야 할 것
- <구체 작업 1>
- <구체 작업 2>

### 하지 말 것 (out of scope)
- <범위 밖 명시 — scope creep 방지>

### 영향받는 기능 문서 (`docs/features/`) — 필수
이 작업이 기능 단위 문서(사용자 가시 시나리오의 cross-repo 흐름, descriptive)에 미치는 영향.
analyzer 산출(`affected_feature_docs`)을 그대로 옮긴다. 다음 중 하나로 명시(누락 금지):
- **<신규 작성 대상 `<name>` | 보완 대상 `docs/features/<name>.md` | 해당 없음>**
- 근거: <왜 그렇게 판단했는지>
- 판단 불가면 추측하지 말고 §7 미결정 사안으로 넘긴다(사람 결정).
- 실제 작성·보완은 meta의 `feature-doc-writer`가 **이 지정만 받아** 수행한다(그 agent는 영향 문서를 스스로 판단하지 않는다).

## 6. Phase 0 회귀 방지 기준

<이 작업이 데모 spec v0.2.1의 어떤 동작을 깨면 안 되는지. 깨질 위험이 있는 지점 명시. 없으면 "해당 없음".>

## 7. 미결정 사안 (있으면 실행 전 멈춤)

<통합본의 `[Open question]` 항목, 미결정 ADR, 데모 spec↔통합본 성격 충돌 등.
하나라도 이 작업에 걸리면 실행 세션은 코드 작성 전 사람을 호출한다. 없으면 "없음".>

## 8. 완료 기준 / 검증

- [ ] <기능/동작 기준>
- [ ] 테스트: hub `mvn test` / script-agent `go test ./...`
- [ ] Phase 0 회귀 없음(§6 기준)
- [ ] (해당 repo에 잔존 시) 통합본 구 호칭("통합본 v0.9")·구 경로(`통합본_v0_9.md`) → 버전 없는 호칭 `통합본` + 경로 `docs/master-design.md` 갱신 1줄 포함 — 본 갱신은 `handoff/spec-backfill/` 3건으로 발주됨 (전부 갱신되면 이 체크 항목 자체를 템플릿에서 제거)
- [ ] <필요 시 polyrepo 종단 검증은 meta `e2e-tester`로 별도 수행>

## 9. 결과 보고 스키마 (실행 세션이 마지막에 반환)

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["생성/수정한 파일 경로"],
  "findings": ["발견 사항"],
  "blockers": ["사람 결정이 필요한 항목"],
  "next_action": "다음에 할 일 한 줄"
}
```

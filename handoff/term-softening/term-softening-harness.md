# 작업 spec — term-softening-harness (문서 용어 순화: 어려운 한자어 → 쉬운 말)

> 이 handoff는 monitoring-harness 세션이 받아 실행한다. monitoring-meta 문서 전체에 적용한 **용어 순화(동의어 1:1 교체, 뜻 불변)** 를 harness repo의 한국어 문서에도 적용한다. 코드/스크립트 로직은 건드리지 않고 **문서(.md) + 게이트 프롬프트 문자열**만 대상이다. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `term-softening-harness` |
| 대상 repo | `monitoring-harness` |
| 기준 monitoring-meta commit | `6c6f3c0` (full: 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 재확인) |
| 작성일 | 2026-06-06 |
| 근거 | monitoring-meta `memory/doc-term-glossary.md`(순화 표 기준), meta 커밋 91a0fc6~6d18a8d(동일 작업 선례) |

## 2. 배경 / 목적

한국 사람도 잘 안 쓰는 딱딱한 한자어(특히 "비준")를 **같은 뜻의 쉬운 단어로 1:1 교체**한다. 뜻을 길게 풀지 않는다. monitoring-meta·hub·script-agent와 동일 어휘로 맞춘다(cross-repo 일관성).

조사 결과(읽기 전용) harness 대상어 = **.md 16건 / 8개 파일 + profile.example 2개**. 단 archive는 제외(아래 §5).

## 3. 순화 표 (glossary)

| 어려운 말 | 쉬운 말 | | 어려운 말 | 쉬운 말 |
|---|---|---|---|---|
| 비준 | 승인 | | 전수 | 전체 |
| 정본 | 기준 문서(수식어일 땐 "기준") | | 거울 | 사본 |
| 선후 | 순서 | | 귀속 | 소속 |
| 종속 | 의존 | | 외과적 | 부분 |
| 정합성 | 일관성 | | 환원 | 되돌림 |
| 정합 | 일치 | | 위상 | 문맥별: 문서 성격 / 작업 상태 / 우선순위 |
| 동결 | 고정 | | 승격 | 격상 |
| 명문화 | 명시 | | 강등 | 격하 |
| 이연 | 연기 | | | |

**유지(바꾸지 마라 — 기술 표준어/공통 용어):** 회귀(regression), envelope, payload, 핸드오프/handoff, 종단 검증.

## 4. 적용 방법 (결정적 — 그대로 실행)

### 4.1 sed 스크립트 2개 생성

```bash
cat > /tmp/soften.sed <<'SED'
s/정합성/일관성/g
s/정합/일치/g
s/비준/승인/g
s/선후/순서/g
s/종속/의존/g
s/동결/고정/g
s/명문화/명시/g
s/승격/격상/g
s/강등/격하/g
s/이연/연기/g
s/전수/전체/g
s/거울/사본/g
s/귀속/소속/g
s/외과적/부분/g
s/정본/기준 문서/g
s/위상/성격/g
SED
cat > /tmp/particle.sed <<'SED'
s/기준 문서이다/기준 문서다/g
s/기준 문서으로/기준 문서로/g
s/기준 문서을/기준 문서를/g
s/기준 문서은/기준 문서는/g
s/기준 문서과/기준 문서와/g
s/기준 문서이/기준 문서가/g
s/일치을/일치를/g
s/일치이/일치가/g
s/일치으로/일치로/g
s/연기을/연기를/g
s/연기이/연기가/g
SED
```
> 순서 중요: `정합성→일관성`이 `정합→일치`보다 먼저(soften.sed 줄 순서대로면 충족).

### 4.2 대상 문서에 적용 + 수동 정리

```bash
FILES="docs/consumer-contract.md docs/decisions/h4-meta-readiness.md docs/milestones.md README.md shared/schemas/equivalence-check.md shared/schemas/README.md"
for f in $FILES; do
  sed -i -f /tmp/soften.sed "$f"
  sed -i -f /tmp/particle.sed "$f"
  sed -i 's/작업 성격/작업 상태/g; s/환원하지/되돌리지/g; s/환원/되돌림/g' "$f"
done
```

### 4.3 어색 조합 점검 + 수동 손질

```bash
grep -rn -E "기준\(기준 문서\)|기준 문서 문서|기준 문서(으로|을|은|과)|작업 성격|일치(을|으로)|환원" $FILES
```
- `기준(기준 문서)` → `기준 문서`
- **schema canonical 표현 주의**: 이 repo에서 "정본"은 종종 *codex-schema.json의 정본(canonical 버전)* 뜻("LF 정본", "공통 1부 (정본)", "정본 EOL")이다. sed가 "기준 문서"로 바꾸면 "LF 기준 문서"처럼 어색할 수 있으니, 이런 자리는 **"기준"**(예: "LF를 기준으로 채택", "공통 1부 (기준)", "기준 EOL")으로 손질해라(파일은 문서가 아니라 스키마).
- 그 외 뜻이 어색해지면 그 자리만 표현 조정(길게 풀지 마라).

### 4.4 게이트 프롬프트(profile.example) — 신중 적용

대상: `shared/hooks/profiles/hub.profile.example`, `shared/hooks/profiles/script-agent.profile.example`의 `CODEX_GATE_PROMPT` 문자열 안 "작업 위상", "위상 분류", "위상 주의", "spec 정합성" 등.
- 동의어 교체(위상→성격/작업 상태, 정합성→일관성)는 의미상 안전하다(Codex가 둘 다 이해).
- **단** 이 문자열은 운영 게이트 프롬프트다: ① grep 검사 키워드로 쓰이는 표현이 없는지 확인 후 적용, ② live `hub`/`script-agent` repo의 `.claude/codex-gate.profile`(별도 term-softening handoff로 처리)과 **같은 어휘로 일관**되게 둘 것. 위 §4.2 sed를 이 두 파일에도 적용하되, 적용 후 프롬프트가 문법적으로 자연스러운지 1줄씩 확인해라.

## 5. 범위 / 제외

- **포함**: 위 §4.2의 6개 .md + §4.4의 profile.example 2개.
- **제외**: `docs/archive/**`(design-h0.md, archive/README.md — 보관/동결), 코드·스크립트 로직(`.sh` 본문 동작), 타임스탬프 산출물.

## 6. DoD / 검증

- [ ] 대상 문서에서 순화 표 어휘 잔존 0: `grep -roh -E "정합성|정합|비준|선후|종속|동결|명문화|승격|강등|이연|전수|거울|귀속|외과적|정본|위상" $FILES shared/hooks/profiles/*.example | wc -l` → 0
- [ ] 어색 조합(§4.3 grep) 0, schema canonical 자리 "기준"으로 자연스럽게 손질.
- [ ] 유지어(회귀/envelope/payload/핸드오프/종단 검증) 불변.
- [ ] archive 무변경, 스크립트 로직 무변경.
- [ ] profile.example 프롬프트가 문법적으로 자연스럽고 live `.profile`과 어휘 일관.

## 7. 미결정 사안

- 없음. 동의어 1:1 교체이며 뜻을 바꾸지 않는다. 뜻이 바뀌는 자리가 나오면 멈추고 그 자리만 조정.

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 파일 경로"],
  "findings": ["치환 건수 / 수동 손질한 곳 / profile 적용 여부"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

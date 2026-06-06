# 작업 spec — term-softening-hub (문서 용어 순화: 어려운 한자어 → 쉬운 말)

> 이 handoff는 hub 세션이 받아 실행한다. monitoring-meta 문서 전체에 적용한 **용어 순화(동의어 1:1 교체, 뜻 불변)** 를 hub repo의 한국어 문서에도 동일하게 적용한다. 코드(.java)는 건드리지 않고 **.md 문서만** 대상이다. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `term-softening-hub` |
| 대상 repo | `hub` (Java/Spring) |
| 기준 monitoring-meta commit | `6d18a8de5d62b70354860cdd3473f6b065ecd02f` (full 40자). **실행 전 `git rev-parse HEAD`로 최신 재확인** |
| 작성일 | 2026-06-06 |
| 근거 | monitoring-meta `memory/doc-term-glossary.md`(순화 표 기준 문서), meta 커밋 91a0fc6~6d18a8d(동일 작업 선례) |

## 2. 배경 / 목적

한국 사람도 잘 안 쓰는 딱딱한 한자어(특히 "비준")를 **같은 뜻의 쉬운 단어로 1:1 교체**한다. 뜻을 길게 풀지 않는다. monitoring-meta는 이미 전체 적용 완료했고, hub repo 문서도 동일 어휘로 맞춘다(cross-repo 일관성).

조사 결과 hub 대상어 = **33건 / 6개 .md**:
`.claude/agents/analyzer.md`(5), `.claude/agents/implementer.md`(2), `.claude/agents/spec-guardian.md`(12), `.claude/CLAUDE.md`(6), `analysis/phase1-002-hub-analysis.md`(7), `README.md`(1).

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
> 순서 중요: `정합성→일관성`이 `정합→일치`보다 **먼저**(soften.sed 줄 순서대로면 충족). particle.sed는 "정본"(받침)→"기준 문서"(받침 없음) 조사 교정용.

### 4.2 대상 .md에 적용 + 수동 정리

```bash
# 대상 .md(코드 제외). 아래 6개 또는 repo .md 전체에서 대상어 포함 파일.
FILES=".claude/agents/analyzer.md .claude/agents/implementer.md .claude/agents/spec-guardian.md .claude/CLAUDE.md analysis/phase1-002-hub-analysis.md README.md"
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
- `기준(기준 문서)` → `기준 문서` (중복 제거)
- `기준 문서 spec`/`기준 문서 문서` 처럼 "정본"이 수식어였던 자리는 `기준 spec` 등으로 자연스럽게 손질("문서 문서" 중복 금지)
- 그 외 뜻이 어색해지면 그 자리만 표현 조정(길게 풀지 마라)

## 5. 범위 / 제외

- **포함**: hub repo의 한국어 `.md` 문서(위 6개 + 추가 발견 시 포함).
- **제외**: 코드 파일(`.java` 등), 외부 사본/동결 스냅샷(예: 데모 spec 사본이 남아 있다면 — verbatim 동결이라 제외. phase0-cleanup으로 이미 삭제됐을 것), 타임스탬프 실행 로그류.
- **codex-gate.profile**: 게이트 프롬프트 파일에 대상어가 있으면 교체해도 무방(동의어)하나, grep 검사 키워드로 쓰이는 표현이 있는지만 확인 후 적용.

## 6. DoD / 검증

- [ ] 대상 .md에서 순화 표 어휘 잔존 0: `grep -roh -E "정합성|정합|비준|선후|종속|동결|명문화|승격|강등|이연|전수|거울|귀속|외과적|정본|위상" $FILES | wc -l` → 0
- [ ] 어색 조합(§4.3 grep) 0.
- [ ] 유지어(회귀/envelope/payload/핸드오프/종단 검증) 불변.
- [ ] 코드(.java) 무변경 — `git diff --stat`에 .java 없음.
- [ ] 빌드/테스트 영향 없음(문서 변경이라 `mvn test` 불필요하나, 의심되면 1회 확인).

## 7. 미결정 사안

- 없음. 동의어 1:1 교체이며 뜻을 바꾸지 않는다. 뜻이 바뀌는 자리가 나오면 멈추고 그 자리만 조정.

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 .md 파일 경로"],
  "findings": ["치환 건수 / 수동 손질한 곳"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

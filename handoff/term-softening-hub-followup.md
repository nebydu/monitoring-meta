# 작업 spec — term-softening-hub-followup (hub 잔여 `위상` 순화: 위상 → 단계)

> 이 handoff는 hub 세션이 받아 실행한다. 앞선 `term-softening-hub`에서 다른 한자어는 모두 교체됐으나 **`위상` 21건 중 20건이 남아 있다.** hub의 `위상`은 대부분 "Phase 0 / Phase 1 중 **어느 단계**에 있는가"라는 *단계 위치* 뜻이므로, 기계적 `위상→성격`이 아니라 **`위상→단계`**로 순화한다. 코드(.java)는 건드리지 않고 **.md 문서만** 대상. meta는 지시서만 쓴다(형제 repo 직접 수정 금지).

## 1. 필수 헤더

| 필드 | 값 |
|---|---|
| 작업 ID (work-id) | `term-softening-hub-followup` |
| 대상 repo | `hub` (Java/Spring) |
| 선행 작업 | `term-softening-hub` (커밋 `44a76a6`, `1372f17` — 다른 어휘·`위상` 1건 완료) |
| 기준 monitoring-meta commit | 실행 전 `git -C ../monitoring-meta rev-parse HEAD`로 확인 |
| 작성일 | 2026-06-06 |
| 사용자 결정 | 옵션 A — hub `위상`은 "단계" 뜻이 맞으니 `위상→단계`로 마저 순화 |

## 2. 배경

`위상`(位相)은 한국 사람이 잘 안 쓰는 딱딱한 한자어다. meta 글로서리는 문맥별(성격/상태/우선순위)로 매핑하지만, **hub의 `위상`은 거의 전부 "Phase 0 단계인지 Phase 1 단계인지"라는 단계(phase position) 뜻**이라 `단계`가 가장 자연스럽다. `성격`으로 바꾸면 의미가 약해지므로 쓰지 않는다.

## 3. 정확한 교체 목록 (20건 — 그대로 적용)

아래는 현재 잔존 위치다. **전부 `위상→단계`**로 바꾼다(아래 §5 예외 1건 제외).

| 파일 | 줄(대략) | 현재 → 교체 |
|---|---|---|
| `.claude/agents/analyzer.md` | 32 | `작업 위상 분류` → `작업 단계 분류` |
| `.claude/agents/implementer.md` | 24 | `위상 분류 후 구현 … 분류한 위상(…)` → `단계 분류 후 구현 … 분류한 단계(…)` |
| `.claude/agents/spec-guardian.md` | 3 | `어느 위상에 있는지` → `어느 단계에 있는지` |
| `.claude/agents/spec-guardian.md` | 8 | `어느 위상에 있는지 판단` → `어느 단계에 있는지 판단` |
| `.claude/agents/spec-guardian.md` | 14 | `envelope 위상인가, 아직 Phase 0 위상인가` → `envelope 단계인가, 아직 Phase 0 단계인가` |
| `.claude/agents/spec-guardian.md` | 32 | `정상 위상` → `정상 단계` |
| `.claude/agents/spec-guardian.md` | 33 | `Phase 0 위상이므로` → `Phase 0 단계이므로` |
| `.claude/agents/spec-guardian.md` | 39 | `위상 분류` → `단계 분류` |
| `.claude/agents/spec-guardian.md` | 41 | `현재 작업 위상(…)` → `현재 작업 단계(…)` |
| `.claude/CLAUDE.md` | 10 | `## 1. 위상 구분 경고` → `## 1. 단계 구분 경고` |
| `.claude/CLAUDE.md` | 11 | `데모 spec(v0.2.1) 위상에 있다` → `… 단계에 있다` |
| `.claude/CLAUDE.md` | 12 | `이 위상 차이를 인지한 채로` → `이 단계 차이를 인지한 채로` |
| `.claude/CLAUDE.md` | 13 | `Phase 0 위상에서는 정상` → `Phase 0 단계에서는 정상` |
| `.claude/CLAUDE.md` | 64 | `위상 분류 + envelope 헤더` → `단계 분류 + envelope 헤더` |
| `analysis/phase1-002-hub-analysis.md` | 40 | `## 3. 작업 위상 분류` → `## 3. 작업 단계 분류` |
| `analysis/phase1-002-hub-analysis.md` | 42 | 표 헤더 `\| 위상 \|` → `\| 단계 \|` |
| `analysis/phase1-002-hub-analysis.md` | 46 | `Phase 위상 무관` → `Phase 단계 무관` |

> 줄 번호는 참고용이다(편집하면 밀린다). **단어 기준으로 찾아 바꾼다.**

### 적용 명령(권장)

```bash
FILES=".claude/agents/analyzer.md .claude/agents/implementer.md .claude/agents/spec-guardian.md .claude/CLAUDE.md analysis/phase1-002-hub-analysis.md"
for f in $FILES; do sed -i 's/위상/단계/g' "$f"; done
```
→ 위 5개 파일에는 보존해야 할 `위상`이 없으므로 일괄 치환해도 안전하다. `README.md`는 **명령에서 제외**(아래 §5).

## 4. 자연스러움 점검

치환 후 한 번 읽어 어색하면 그 자리만 손질(길게 풀지 마라). 예상 결과는 모두 자연스럽다:
- "어느 단계에 있는지", "Phase 0 단계", "단계 구분 경고", "단계 분류" — 정상.

## 5. 예외 — 바꾸지 마라 (1건)

- **`README.md:6`의 "§0 위상"** → **그대로 둔다.** 이건 동결된 데모 spec v0.2.1의 §0 섹션 제목("## 0. 위상")을 **인용**한 것이다. 동결 문서 제목을 그대로 가리켜야 하므로 `단계`로 바꾸면 인용이 깨진다.

## 6. DoD / 검증

- [ ] §3 5개 파일에서 `위상` 0건: `grep -rn "위상" .claude/agents/*.md .claude/CLAUDE.md analysis/phase1-002-hub-analysis.md` → 출력 없음.
- [ ] `README.md:6`의 "§0 위상"은 **유지**(인용).
- [ ] 코드(.java) 무변경 — `git diff --stat`에 .java 없음.
- [ ] 다른 어휘(앞 작업분) 회귀 없음.

## 7. 미결정 사안

- 없음. 동의어 1:1 교체(`위상→단계`), 뜻 불변. README §0 인용만 예외.

## 8. 결과 보고 스키마

```json
{
  "status": "ok | blocked | failed",
  "outputs": ["변경 .md 파일 경로"],
  "findings": ["치환 건수 / README 예외 처리 확인"],
  "blockers": [],
  "next_action": "다음에 할 일 한 줄"
}
```

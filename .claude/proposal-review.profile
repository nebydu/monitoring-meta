# proposal-review.profile — monitoring-meta consumer 델타 (H6)
# /proposal-review command가 Codex 리뷰에 주입할 meta 문맥. 도메인 결정은 이 파일에만 둔다.
# 골격: monitoring-harness plugin shared/analysis/proposal-review-runner.sh
#
# 적용 조건: harness a455246 이상(runner의 git rev-parse fallback 포함) — 그 이전 캐시에서는
#   command 컨텍스트가 이 profile을 못 찾아 degraded(문맥 없는 리뷰)로 동작한다. 깨지진 않지만
#   문맥 주입이 안 되므로, /plugin update로 a455246+ 반영 후 사용할 것.
# drift 완화: 기준 문서를 추가/이동하는 작업의 DoD에 "이 profile 문맥 목록 갱신"을 포함한다.
# dry-run: 이 repo에서 `/proposal-review` 호출 → 출력 JSON context 필드가
#   "profile: .../proposal-review.profile"이면 주입 성공, "none"이면 degraded.

# repo 루트 기준 절대경로로 해석 (호출 cwd 무관하게 동작)
# - git rev-parse는 cwd 의존이라 repo 밖 cwd에서 source 시 즉사, 다른 repo cwd에서는
#   엉뚱한 root로 조용히 진행하는 결함이 있었다 → profile 파일 위치 기준으로 산출.
# - 의미: 이 파일이 놓인 디렉터리(.claude/)의 부모 = repo root. convention 위치를
#   벗어난 곳에 profile을 두면 그 위치 기준으로 해석된다. (infra b47fcef와 동일 조치)
_META_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 문맥 문서 — 결정 리뷰에 필요한 기준 문서들.
# 통합본_v0_9.md(170KB)는 매 리뷰 주입 비용이 커서 제외한다(아래 POLICY에서 안내).
# 통합본이 직접 쟁점인 제안은 proposal 본문에 관련 절을 발췌해 넣을 것.
PROPOSAL_REVIEW_CONTEXT_DOCS=(
  "$_META_ROOT/docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md"
  "$_META_ROOT/docs/kafka-payloads.md"
  "$_META_ROOT/docs/envelope.md"
  "$_META_ROOT/docs/phase1/ROADMAP_PHASE1_v0_3.md"
  "$_META_ROOT/adr/0002-heartbeat-otlp-proto.md"
  "$_META_ROOT/adr/0005-topic-naming.md"
)

PROPOSAL_REVIEW_POLICY="monitoring-meta는 코드를 만들지 않는 오케스트레이터다(spec·문서·핸드오프·종단 검증 산출물만). 리뷰 시 반드시 지킬 구분: 데모 spec v0.2.1은 'Phase 0 회귀 기준(ground truth)'이고 통합본 v0.9(이 입력에 미포함, 170KB라 제외 — docs/통합본_v0_9.md)는 'Phase 1+ 도달 목표 spec'이다. 이 둘을 같은 기준으로 다루는 제안은 결함이다. [Open]/[Open question] 표기 항목이나 미결정 ADR을 결정된 것으로 전제한 제안은 block 대상이다. 형제 repo(hub/script-agent/infra)는 읽기 전용 참조 대상이며 meta가 직접 수정하는 제안도 block 대상이다. 통합본이 직접 쟁점인데 발췌가 없으면 missing_context로 지적하라."

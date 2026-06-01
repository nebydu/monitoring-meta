#!/usr/bin/env bash
# run-e2e.sh — monitoring polyrepo 종단 검증 스크립트 (baseline v1)
#
# 검증 범위:
#   1. [정적] ADR-0002 컷오버 C-1 정합 — infra(otlp_proto)·hub(ByteArrayDeserializer·proto 디코더) 동시 전환 확인
#   2. [정적] 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 확인
#   3. [정적] envelope 예외 위상 — heartbeats에 envelope 헤더 검사 없음 확인
#   4. [유닛] hub mvn test / script-agent go test ./... 실행 후 결과 기록
#   5. [동적 — Docker 가용 시] infra 기동 → hub run → script-agent run
#             → AGENT_STARTED 확인 → SCRIPT_JOB 등록 → JOB_RESULT 수신
#             → script-agent 종료 → AGENT_STOPPED 확인 → infra 종료
#      동적 검증은 현 데모 skeleton이 AGENT_STARTED/SCRIPT_JOB/JOB_RESULT 흐름을
#      완전 구현했을 때 통과한다. 미구현 단계는 SKIP으로 기록한다.
#
# 규칙:
#   - 실패 시 코드를 고치지 않는다 — 로그만 기록하고 종료한다.
#   - 형제 repo(../hub, ../script-agent, ../infra)는 절대 수정하지 않는다.
#   - 결과는 e2e/results/<timestamp>.md 에 저장된다.
#
# 근거 문서:
#   adr/0002-heartbeat-otlp-proto.md  (결정 A-1/B-1/C-1)
#   handoff/adr-002-{infra,hub,script-agent}.md
#   docs/kafka-payloads.md (heartbeats-topic)
#   docs/envelope.md §4.2 (OTLP 위임군 예외)
#   데모 spec v0.2.1 §5.4 (Phase 0 ground truth)

set -euo pipefail

# ---------------------------------------------------------------------------
# 경로 설정
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INFRA_DIR="$(cd "${META_ROOT}/../infra" && pwd)"
HUB_DIR="$(cd "${META_ROOT}/../hub" && pwd)"
AGENT_DIR="$(cd "${META_ROOT}/../script-agent" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RESULT_FILE="${RESULTS_DIR}/${TIMESTAMP}.md"

mkdir -p "${RESULTS_DIR}"

# ---------------------------------------------------------------------------
# 결과 누적 변수
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
SKIP=0
FINDINGS=()   # 발견 사항 (관측 사실만)
BLOCKERS=()   # 사람 판단 필요 항목

log_pass() { PASS=$((PASS+1)); FINDINGS+=("PASS: $1"); echo "[PASS] $1"; }
log_fail() { FAIL=$((FAIL+1)); FINDINGS+=("FAIL: $1"); echo "[FAIL] $1"; }
log_skip() { SKIP=$((SKIP+1)); FINDINGS+=("SKIP: $1"); echo "[SKIP] $1"; }
log_info() { FINDINGS+=("INFO: $1"); echo "[INFO] $1"; }
add_blocker() { BLOCKERS+=("$1"); echo "[BLOCKER] $1"; }

# ---------------------------------------------------------------------------
# 헬퍼: 파일 내 패턴 검색 (grep 대체)
# ---------------------------------------------------------------------------
file_contains() {
    local file="$1"
    local pattern="$2"
    grep -qE "${pattern}" "${file}" 2>/dev/null
}

# ---------------------------------------------------------------------------
# §1. 정적 검증 — ADR-0002 C-1 컷오버 정합
# ---------------------------------------------------------------------------
echo ""
echo "=== §1 ADR-0002 C-1 컷오버 정합 (정적) ==="

COLLECTOR_CFG="${INFRA_DIR}/otel-collector-config.yml"
KAFKA_CFG="${HUB_DIR}/src/main/java/com/monitoring/hub/config/KafkaConfig.java"
DECODER="${HUB_DIR}/src/main/java/com/monitoring/hub/ingest/heartbeat/HeartbeatOtlpDecoder.java"
CONSUMER="${HUB_DIR}/src/main/java/com/monitoring/hub/ingest/heartbeat/HeartbeatConsumer.java"
POM="${HUB_DIR}/pom.xml"

# §1-A: infra — kafka exporter encoding = otlp_proto
if file_contains "${COLLECTOR_CFG}" "encoding:[[:space:]]*otlp_proto"; then
    log_pass "infra/otel-collector-config.yml: encoding=otlp_proto 확인"
elif file_contains "${COLLECTOR_CFG}" "encoding:[[:space:]]*otlp_json"; then
    log_fail "infra/otel-collector-config.yml: encoding이 여전히 otlp_json — ADR-0002 미완료"
else
    log_fail "infra/otel-collector-config.yml: encoding 설정을 찾을 수 없음"
fi

# §1-B: hub KafkaConfig — heartbeatConsumerFactory value deserializer = ByteArrayDeserializer
if file_contains "${KAFKA_CFG}" "ByteArrayDeserializer"; then
    log_pass "hub/KafkaConfig.java: ByteArrayDeserializer 사용 확인 (ADR-0002 value 전환)"
else
    log_fail "hub/KafkaConfig.java: ByteArrayDeserializer 미사용 — String deserializer가 남아 있을 수 있음"
fi

# §1-C: hub 코드에 StringDeserializer가 heartbeat consumer에도 남아있지 않은지
#   heartbeatConsumerFactory 내부에서 StringDeserializer 두 번 쓰이는 케이스를 탐지
#   (key는 String, value도 String인 경우가 위반). key=String, value=byte[]가 정상.
#   KafkaConfig 전체에 ByteArrayDeserializer가 있으면 §1-B가 이미 잡으므로 여기서는
#   HeartbeatConsumer가 byte[] 타입으로 선언됐는지만 확인.
if file_contains "${CONSUMER}" "ConsumerRecord<String, byte\[\]>"; then
    log_pass "hub/HeartbeatConsumer.java: ConsumerRecord<String, byte[]> 타입 확인"
else
    log_fail "hub/HeartbeatConsumer.java: ConsumerRecord<String, byte[]> 타입 선언 없음 — 타입 불일치 가능"
fi

# §1-D: hub HeartbeatOtlpDecoder — ExportMetricsServiceRequest.parseFrom 사용
if file_contains "${DECODER}" "ExportMetricsServiceRequest"; then
    log_pass "hub/HeartbeatOtlpDecoder.java: OTLP proto 디코더(ExportMetricsServiceRequest) 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: ExportMetricsServiceRequest 없음 — JSON 파서가 남아있을 수 있음"
fi

# §1-E: hub pom.xml — opentelemetry-proto 의존성
if file_contains "${POM}" "opentelemetry-proto"; then
    log_pass "hub/pom.xml: opentelemetry-proto 의존성 추가 확인"
else
    log_fail "hub/pom.xml: opentelemetry-proto 의존성 없음"
fi

# §1-F: pom.xml 버전 핀 확인
PROTO_VER=$(grep -oE 'opentelemetry-proto.version>[^<]+' "${POM}" 2>/dev/null | sed 's/opentelemetry-proto.version>//') || true
if [ -n "${PROTO_VER}" ]; then
    log_info "hub/pom.xml: opentelemetry-proto 버전 핀 = ${PROTO_VER}"
else
    log_fail "hub/pom.xml: opentelemetry-proto 버전 핀 없음 — B-1 버전 핀 불이행"
fi

# ---------------------------------------------------------------------------
# §2. 정적 검증 — 데모 spec §5.4 논리 계약 회귀 0
# ---------------------------------------------------------------------------
echo ""
echo "=== §2 데모 spec §5.4 논리 계약 회귀 0 (정적) ==="

HEARTBEAT_GO="${AGENT_DIR}/internal/heartbeat/heartbeat.go"
GOMOD="${AGENT_DIR}/go.mod"

# §2-A: metric name = agent.heartbeat
if file_contains "${HEARTBEAT_GO}" '"agent\.heartbeat"'; then
    log_pass "script-agent/heartbeat.go: metric name=\"agent.heartbeat\" 확인"
else
    log_fail "script-agent/heartbeat.go: metric name \"agent.heartbeat\" 없음"
fi

# §2-B: attribute key = agent_id
if file_contains "${HEARTBEAT_GO}" '"agent_id"'; then
    log_pass "script-agent/heartbeat.go: attribute agent_id 확인"
else
    log_fail "script-agent/heartbeat.go: attribute agent_id 없음"
fi

# §2-C: resource service.name = script-agent
if file_contains "${HEARTBEAT_GO}" '"script-agent"'; then
    log_pass "script-agent/heartbeat.go: resource service.name=script-agent 확인"
else
    log_fail "script-agent/heartbeat.go: resource service.name=script-agent 없음"
fi

# §2-D: value = 1 (Gauge Observe 1.0 또는 정수 1)
if file_contains "${HEARTBEAT_GO}" 'Observe\(1'; then
    log_pass "script-agent/heartbeat.go: Gauge value=1 Observe 확인"
else
    log_fail "script-agent/heartbeat.go: Gauge value=1 Observe 없음"
fi

# §2-E: HeartbeatOtlpDecoder metric name 상수 = agent.heartbeat
if file_contains "${DECODER}" '"agent\.heartbeat"'; then
    log_pass "hub/HeartbeatOtlpDecoder.java: METRIC_NAME=\"agent.heartbeat\" 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: METRIC_NAME=\"agent.heartbeat\" 없음"
fi

# §2-F: HeartbeatOtlpDecoder agent_id attribute 상수
if file_contains "${DECODER}" '"agent_id"'; then
    log_pass "hub/HeartbeatOtlpDecoder.java: ATTR_AGENT_ID=\"agent_id\" 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: ATTR_AGENT_ID=\"agent_id\" 없음"
fi

# §2-G: time_unix_nano proto fixed64 → Instant 변환 (getTimeUnixNano 사용)
if file_contains "${DECODER}" "getTimeUnixNano"; then
    log_pass "hub/HeartbeatOtlpDecoder.java: getTimeUnixNano (proto fixed64) 사용 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: getTimeUnixNano 없음 — JSON Long.parseLong 위상일 가능성"
fi

# §2-H: script-agent OTel Go SDK 버전 (go.mod)
OTEL_VER=$(grep 'go.opentelemetry.io/otel ' "${GOMOD}" 2>/dev/null | awk '{print $2}') || true
if [ -n "${OTEL_VER}" ]; then
    log_info "script-agent/go.mod: OTel Go SDK = ${OTEL_VER}"
else
    log_fail "script-agent/go.mod: OTel Go SDK 버전 확인 불가"
fi

# ---------------------------------------------------------------------------
# §3. 정적 검증 — envelope 예외 위상 (heartbeats에 envelope 헤더 검사 없음)
# ---------------------------------------------------------------------------
echo ""
echo "=== §3 envelope 예외 위상 (정적) ==="

# §3-A: HeartbeatConsumer에 envelope 헤더(x-message-version 등) 검사 없음
if file_contains "${CONSUMER}" "x-message-version\|x-source-service\|x-schema-id\|x-idempotency-key"; then
    log_fail "hub/HeartbeatConsumer.java: envelope 헤더 검사가 추가됨 — heartbeats는 OTLP 예외군이므로 위반"
else
    log_pass "hub/HeartbeatConsumer.java: envelope 헤더 검사 없음 (OTLP 위임군 예외 위상 준수)"
fi

# §3-B: HeartbeatConsumer 주석에 envelope 예외 위상 언급 (코드 의도 명시 확인)
if file_contains "${CONSUMER}" "envelope.*예외\|OTLP.*예외\|예외군"; then
    log_pass "hub/HeartbeatConsumer.java: envelope 예외 위상 주석 명시 확인"
else
    log_info "hub/HeartbeatConsumer.java: envelope 예외 위상 주석이 명시적이지 않음 (기능 위반은 아님)"
fi

# ---------------------------------------------------------------------------
# §4. 유닛 테스트 실행
# ---------------------------------------------------------------------------
echo ""
echo "=== §4 유닛 테스트 실행 ==="

# §4-A: hub mvn test
echo "[INFO] hub: mvn test 실행 중..."
HUB_TEST_LOG="${RESULTS_DIR}/${TIMESTAMP}-hub-test.log"
set +e
(cd "${HUB_DIR}" && mvn test --no-transfer-progress 2>&1) > "${HUB_TEST_LOG}"
HUB_EXIT=$?
set -e

if [ ${HUB_EXIT} -eq 0 ]; then
    HUB_SUMMARY=$(grep "Tests run:" "${HUB_TEST_LOG}" | tail -1 || echo "통계 없음")
    log_pass "hub mvn test 성공. 요약: ${HUB_SUMMARY}"
else
    HUB_FAIL_LINES=$(grep -E "FAILED|ERROR|Tests run:.*Failures: [^0]|Tests run:.*Errors: [^0]" "${HUB_TEST_LOG}" | head -20 || echo "상세 없음")
    log_fail "hub mvn test 실패 (exit=${HUB_EXIT}). 실패 라인: ${HUB_FAIL_LINES}"
    log_info "hub 테스트 전체 로그: ${HUB_TEST_LOG}"
fi

# §4-B: script-agent go test ./...
echo "[INFO] script-agent: go test ./... 실행 중..."
AGENT_TEST_LOG="${RESULTS_DIR}/${TIMESTAMP}-agent-test.log"
set +e
(cd "${AGENT_DIR}" && go test ./... 2>&1) > "${AGENT_TEST_LOG}"
AGENT_EXIT=$?
set -e

if [ ${AGENT_EXIT} -eq 0 ]; then
    log_pass "script-agent go test ./... 성공"
    cat "${AGENT_TEST_LOG}" | while IFS= read -r line; do log_info "  agent-test: ${line}"; done
else
    log_fail "script-agent go test ./... 실패 (exit=${AGENT_EXIT})"
    head -30 "${AGENT_TEST_LOG}" | while IFS= read -r line; do log_info "  agent-test: ${line}"; done
fi

# ---------------------------------------------------------------------------
# §5. 주석 drift 검사 (관측 기록)
# ---------------------------------------------------------------------------
echo ""
echo "=== §5 주석 drift 검사 ==="

# script-agent/heartbeat.go 3번 줄: 아직 otlp_json 언급
if file_contains "${HEARTBEAT_GO}" "otlp_json"; then
    log_info "DRIFT(주석): script-agent/internal/heartbeat/heartbeat.go 패키지 주석에 'otlp_json' 언급 잔존 (코드 동작에는 영향 없음 — 주석만 구식). 사람 확인 권고."
    add_blocker "script-agent/internal/heartbeat/heartbeat.go 패키지 주석 3번 줄이 'otlp_json'을 언급 — ADR-0002 완료 후에도 주석이 구식 상태. 코드 동작에는 영향 없으나 drift 기록. (수정 여부는 script-agent 세션에서 결정)"
fi

# ---------------------------------------------------------------------------
# §6. 동적 검증 — Docker 기동 시도 (현재 구현 범위 기반 SKIP 정책)
# ---------------------------------------------------------------------------
echo ""
echo "=== §6 동적 검증 (Docker) ==="

# Docker 가용성 확인
DOCKER_OK=false
if docker info --format "{{.ServerVersion}}" > /dev/null 2>&1; then
    DOCKER_VER=$(docker info --format "{{.ServerVersion}}" 2>/dev/null)
    log_info "Docker 데몬 가용 (버전: ${DOCKER_VER})"
    DOCKER_OK=true
else
    log_info "Docker 데몬 불가 — 동적 검증 전체 SKIP"
fi

if [ "${DOCKER_OK}" = "true" ]; then
    # §6-A: infra 기동 상태 확인 (현재 실행 중인지)
    COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"
    KAFKA_RUNNING=$(docker compose -f "${COMPOSE_FILE}" ps --status running --format json 2>/dev/null | grep -c "kafka" || true)

    if [ "${KAFKA_RUNNING}" -gt 0 ]; then
        log_info "infra: kafka 컨테이너 이미 실행 중"
    else
        log_info "infra: kafka 미기동 상태"
    fi

    # §6-B: 데모 end-to-end 시나리오 (AGENT_STARTED → SCRIPT_JOB → JOB_RESULT → AGENT_STOPPED)
    #   현재 hub/script-agent 데모 skeleton의 구현 완료 수준 확인:
    #   - heartbeat 파이프라인(§1~§3 정적 검증) : 구현됨
    #   - AGENT_STARTED audit 이벤트 : AuditConsumer 코드 존재 여부 확인
    AUDIT_CONSUMER="${HUB_DIR}/src/main/java/com/monitoring/hub/ingest/audit/AuditConsumer.java"
    if [ -f "${AUDIT_CONSUMER}" ]; then
        log_info "hub/AuditConsumer.java 존재 — AGENT_STARTED 이벤트 처리 코드 있음"
    else
        log_info "hub/AuditConsumer.java 없음"
    fi

    #   - SCRIPT_JOB / JOB_RESULT 완전 종단 루프 : script-agent job runner 여부 확인
    AGENT_JOB_DIR="${AGENT_DIR}/internal/job"
    if [ -d "${AGENT_JOB_DIR}" ]; then
        log_info "script-agent/internal/job 디렉터리 존재 — Job runner 코드 있음"
    else
        log_info "script-agent/internal/job 없음"
    fi

    # 실제 동적 기동 검증 (infra → hub → agent → 이벤트 확인)은
    # hub가 standalone 모드로 Kafka 없이 기동되지 않거나 (EmbeddedKafka 미설정),
    # script-agent가 실제 Collector endpoint를 요구하므로 별도 오케스트레이션이 필요하다.
    # 현재 baseline에서는 정적 검증으로 ADR-0002 컷오버 정합을 검증하고,
    # 동적 기동 시나리오는 SKIP으로 기록한다.
    log_skip "동적 E2E 기동 시나리오 (infra up → hub run → agent run → 이벤트 수신 확인): 현 baseline은 정적 검증만 수행. 동적 기동 시나리오는 인프라·서비스 기동 오케스트레이션 완성 후 활성화 필요."
    add_blocker "동적 E2E 시나리오(infra/hub/agent 실제 기동·이벤트 확인)는 이번 baseline에 포함되지 않음 — 활성화 조건: hub standalone 기동 가능(EmbeddedKafka 또는 실 Kafka), script-agent OTel Collector endpoint 연결 가능. 사람이 활성화 여부를 결정해야 함."
fi

# ---------------------------------------------------------------------------
# 결과 집계 및 MD 파일 생성
# ---------------------------------------------------------------------------
echo ""
echo "=== 결과 집계 ==="
echo "PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"

if [ ${FAIL} -eq 0 ]; then
    OVERALL_STATUS="ok"
elif [ ${FAIL} -gt 0 ]; then
    OVERALL_STATUS="failed"
fi
[ ${PASS} -eq 0 ] && [ ${FAIL} -eq 0 ] && OVERALL_STATUS="blocked"

{
    echo "# E2E 검증 결과 — ${TIMESTAMP}"
    echo ""
    echo "**실행일시**: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "**종합 상태**: ${OVERALL_STATUS^^}"
    echo "**PASS**: ${PASS}  **FAIL**: ${FAIL}  **SKIP**: ${SKIP}"
    echo ""
    echo "## 검증 범위"
    echo ""
    echo "- ADR-0002 C-1 빅뱅 컷오버 정합 (infra otlp_proto ↔ hub ByteArrayDeserializer + proto 디코더)"
    echo "- 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 (metric name / agent_id / service.name / value / time_unix_nano)"
    echo "- envelope 예외 위상 (heartbeats-topic: OTLP 위임군 → envelope 헤더 검사 없음)"
    echo "- hub mvn test / script-agent go test ./..."
    echo "- 주석 drift 관측"
    echo "- 동적 E2E 시나리오 (Docker)"
    echo ""
    echo "## 발견 사항"
    echo ""
    for f in "${FINDINGS[@]}"; do
        echo "- ${f}"
    done
    echo ""
    echo "## 블로커 (사람 판단 필요)"
    echo ""
    if [ ${#BLOCKERS[@]} -eq 0 ]; then
        echo "없음"
    else
        for b in "${BLOCKERS[@]}"; do
            echo "- ${b}"
        done
    fi
    echo ""
    echo "## 메타"
    echo ""
    echo "- 스크립트: \`e2e/run-e2e.sh\` (baseline v1)"
    echo "- 결과 파일: \`e2e/results/${TIMESTAMP}.md\`"
    echo "- hub 테스트 로그: \`e2e/results/${TIMESTAMP}-hub-test.log\`"
    echo "- agent 테스트 로그: \`e2e/results/${TIMESTAMP}-agent-test.log\`"
} > "${RESULT_FILE}"

echo ""
echo "결과 저장: ${RESULT_FILE}"
echo ""

# 비정상 종료 시에도 결과 파일은 남긴다
if [ "${OVERALL_STATUS}" = "failed" ]; then
    exit 1
fi
exit 0

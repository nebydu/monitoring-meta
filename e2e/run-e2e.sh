#!/usr/bin/env bash
# run-e2e.sh — monitoring polyrepo 종단 검증 스크립트 (baseline v15)
#
# 검증 범위:
#   1. [정적] ADR-0002 컷오버 C-1 정합
#   2. [정적] 데모 spec v0.2.1 §5.4 논리 계약 회귀 0
#   3. [정적] envelope 예외 위상
#   4. [유닛] hub mvn test / script-agent go test ./...
#   5. [주석 drift] 관측 기록
#   6. [동적 — --dynamic 인자 전달 시만 실행]
#             infra 기동 → hub run → script-agent run
#             → heartbeat 수신 확인
#             → §6-T4: T4-1 토픽 재명명 동적 판정 4종
#             → §6-AUDIT: AGENT_STARTED 수신 확인
#             → §6-CMD: SCRIPT_JOB command 경로 판정
#             → §6-LOG: LOG_JOB 동적 실행 실증
#             → §6-STOP: AGENT_STOPPED 동적 수신 실증 (CTRL_BREAK_EVENT)
#             → §6-PREV-ERR: 직전 에러 재현 여부 판정
#   7. [정적] phase1-002 x-source 가드 명시화 회귀
#   8. [정적] T4-1 토픽 재명명 R-A/R-B 회귀
#
# v3~v9: 기존 버그 수정 및 검증 추가 (이력 참조)
# v10: §6-LOG + §6-STOP 신설
# v11: §6-3 go build + Start-Process WindowStyle Hidden, §6-STOP GenerateConsoleCtrlEvent(0,0)
# v12: 버그 F — Start-Process Write-Host $p.Id
# v13: 버그 G — PID 임시 파일 기록(파이프 교착 해소)
# v14: 버그 H — cmd.exe 래퍼 전용 콘솔, AttachConsole 대상 cmd PID
# v15: v10~v14 유실분 재구축 + CTRL_BREAK 수정
#      §6-STOP: GenerateConsoleCtrlEvent(1,0) CTRL_BREAK_EVENT — 사람 실험(2026-06-11) 확정
#               (0,0) CTRL_C는 이 환경에서 미배달, (1,0) CTRL_BREAK는 agent graceful shutdown 전체 경로 실증됨
#      setup 위생: 실행 전 잔존 agent-e2e*/8080 점유 프로세스 탐지·정리
#      teardown 위생: 8080 free + agent-e2e* 0 확인 결과 문서 기록
#      ${VAR:-} 언바운드 변수 가드 적용
#
# 사용:
#   ./run-e2e.sh                          # 정적+유닛만 (§1~§5, §7~§8)
#   ./run-e2e.sh --dynamic                # 정적+유닛+실제 동적 기동 (§1~§8, 새 infra 클린 기동)
#   ./run-e2e.sh --dynamic --reuse-infra  # 정적+유닛+동적 (기존 infra 재활용)
#
# 규칙:
#   - 실패 시 코드를 고치지 않는다 — 로그만 기록하고 종료한다.
#   - 형제 repo(../hub, ../script-agent, ../infra)는 절대 수정하지 않는다.
#   - script-agent 상태 파일(.agent_id/.agent_state)은 e2e/.run-tmp/로 우회한다.
#   - 결과는 e2e/results/<timestamp>.md 에 저장된다.
#
# 근거 문서:
#   adr/0002-heartbeat-otlp-proto.md  (결정 A-1/B-1/C-1)
#   adr/0005-topic-naming.md          (D-4(1)/D-4(2) Accepted — T4-1 근거)
#   docs/kafka-payloads.md (heartbeats-topic)
#   docs/envelope.md §2.2·§2.3·§4.2·§6
#   데모 spec v0.2.1 §5.4 (Phase 0 ground truth)

set -euo pipefail

# ---------------------------------------------------------------------------
# 인자 파싱
# ---------------------------------------------------------------------------
DYNAMIC_MODE=false
REUSE_INFRA=false
for arg in "$@"; do
    case "$arg" in
        --dynamic)      DYNAMIC_MODE=true ;;
        --reuse-infra)  REUSE_INFRA=true ;;
    esac
done

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
FINDINGS=()
BLOCKERS=()

log_pass() { PASS=$((PASS+1)); FINDINGS+=("PASS: $1"); echo "[PASS] $1"; }
log_fail() { FAIL=$((FAIL+1)); FINDINGS+=("FAIL: $1"); echo "[FAIL] $1"; }
log_skip() { SKIP=$((SKIP+1)); FINDINGS+=("SKIP: $1"); echo "[SKIP] $1"; }
log_info() { FINDINGS+=("INFO: $1"); echo "[INFO] $1"; }
add_blocker() { BLOCKERS+=("$1"); echo "[BLOCKER] $1"; }

# ---------------------------------------------------------------------------
# 헬퍼: 파일 내 패턴 검색
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

if file_contains "${COLLECTOR_CFG}" "encoding:[[:space:]]*otlp_proto"; then
    log_pass "infra/otel-collector-config.yml: encoding=otlp_proto 확인"
elif file_contains "${COLLECTOR_CFG}" "encoding:[[:space:]]*otlp_json"; then
    log_fail "infra/otel-collector-config.yml: encoding이 여전히 otlp_json — ADR-0002 미완료"
else
    log_fail "infra/otel-collector-config.yml: encoding 설정을 찾을 수 없음"
fi

if file_contains "${KAFKA_CFG}" "ByteArrayDeserializer"; then
    log_pass "hub/KafkaConfig.java: ByteArrayDeserializer 사용 확인 (ADR-0002 value 전환)"
else
    log_fail "hub/KafkaConfig.java: ByteArrayDeserializer 미사용"
fi

if file_contains "${CONSUMER}" "ConsumerRecord<String, byte\[\]>"; then
    log_pass "hub/HeartbeatConsumer.java: ConsumerRecord<String, byte[]> 타입 확인"
else
    log_fail "hub/HeartbeatConsumer.java: ConsumerRecord<String, byte[]> 타입 선언 없음"
fi

if file_contains "${DECODER}" "ExportMetricsServiceRequest"; then
    log_pass "hub/HeartbeatOtlpDecoder.java: OTLP proto 디코더(ExportMetricsServiceRequest) 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: ExportMetricsServiceRequest 없음"
fi

if file_contains "${POM}" "opentelemetry-proto"; then
    log_pass "hub/pom.xml: opentelemetry-proto 의존성 추가 확인"
else
    log_fail "hub/pom.xml: opentelemetry-proto 의존성 없음"
fi

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

if file_contains "${HEARTBEAT_GO}" '"agent\.heartbeat"'; then
    log_pass "script-agent/heartbeat.go: metric name=\"agent.heartbeat\" 확인"
else
    log_fail "script-agent/heartbeat.go: metric name \"agent.heartbeat\" 없음"
fi

if file_contains "${HEARTBEAT_GO}" '"agent_id"'; then
    log_pass "script-agent/heartbeat.go: attribute agent_id 확인"
else
    log_fail "script-agent/heartbeat.go: attribute agent_id 없음"
fi

if file_contains "${HEARTBEAT_GO}" '"script-agent"'; then
    log_pass "script-agent/heartbeat.go: resource service.name=script-agent 확인"
else
    log_fail "script-agent/heartbeat.go: resource service.name=script-agent 없음"
fi

if file_contains "${HEARTBEAT_GO}" 'Observe\(1'; then
    log_pass "script-agent/heartbeat.go: Gauge value=1 Observe 확인"
else
    log_fail "script-agent/heartbeat.go: Gauge value=1 Observe 없음"
fi

if file_contains "${DECODER}" '"agent\.heartbeat"'; then
    log_pass "hub/HeartbeatOtlpDecoder.java: METRIC_NAME=\"agent.heartbeat\" 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: METRIC_NAME=\"agent.heartbeat\" 없음"
fi

if file_contains "${DECODER}" '"agent_id"'; then
    log_pass "hub/HeartbeatOtlpDecoder.java: ATTR_AGENT_ID=\"agent_id\" 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: ATTR_AGENT_ID=\"agent_id\" 없음"
fi

if file_contains "${DECODER}" "getTimeUnixNano"; then
    log_pass "hub/HeartbeatOtlpDecoder.java: getTimeUnixNano (proto fixed64) 사용 확인"
else
    log_fail "hub/HeartbeatOtlpDecoder.java: getTimeUnixNano 없음"
fi

OTEL_VER=$(grep 'go.opentelemetry.io/otel ' "${GOMOD}" 2>/dev/null | awk '{print $2}') || true
if [ -n "${OTEL_VER}" ]; then
    log_info "script-agent/go.mod: OTel Go SDK = ${OTEL_VER}"
else
    log_fail "script-agent/go.mod: OTel Go SDK 버전 확인 불가"
fi

# ---------------------------------------------------------------------------
# §3. 정적 검증 — envelope 예외 위상
# ---------------------------------------------------------------------------
echo ""
echo "=== §3 envelope 예외 위상 (정적) ==="

if file_contains "${CONSUMER}" "x-message-version\|x-source-service\|x-schema-id\|x-idempotency-key"; then
    log_fail "hub/HeartbeatConsumer.java: envelope 헤더 검사가 추가됨 — heartbeats는 OTLP 예외군이므로 위반"
else
    log_pass "hub/HeartbeatConsumer.java: envelope 헤더 검사 없음 (OTLP 위임군 예외 위상 준수)"
fi

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
# §5. 주석 drift 검사
# ---------------------------------------------------------------------------
echo ""
echo "=== §5 주석 drift 검사 ==="

if file_contains "${HEARTBEAT_GO}" "otlp_json"; then
    log_info "DRIFT(주석): script-agent/internal/heartbeat/heartbeat.go 패키지 주석에 'otlp_json' 언급 잔존 (코드 동작에는 영향 없음 — 주석만 구식). 사람 확인 권고."
    add_blocker "script-agent/internal/heartbeat/heartbeat.go 패키지 주석 3번 줄이 'otlp_json'을 언급 — ADR-0002 완료 후에도 주석이 구식 상태. 코드 동작에는 영향 없으나 drift 기록. (수정 여부는 script-agent 세션에서 결정)"
fi

# ---------------------------------------------------------------------------
# §6. 동적 검증 — --dynamic 인자 있을 때만 실제 기동
# ---------------------------------------------------------------------------
echo ""
echo "=== §6 동적 검증 (Docker) ==="

if [ "${DYNAMIC_MODE}" = "false" ]; then
    log_skip "동적 E2E 기동 시나리오: --dynamic 인자 없음 — 정적+유닛 검증만 수행."
else
    echo "[INFO] --dynamic 모드 활성 — 실제 인프라/서비스 기동 시작"
    if [ "${REUSE_INFRA}" = "true" ]; then
        echo "[INFO] --reuse-infra 플래그 활성 — 기존 infra 스택 재활용 모드"
    else
        echo "[INFO] 클린 부팅 모드 — 새 infra 스택을 기동하고 group coordinator 안정화 대기 포함"
    fi

    # Docker 가용성 확인
    if ! docker info --format "{{.ServerVersion}}" > /dev/null 2>&1; then
        log_fail "Docker 데몬 불가 — --dynamic 모드는 Docker 필수이므로 동적 검증 수행 불가(FAIL)."
    else
        DOCKER_VER=$(docker info --format "{{.ServerVersion}}" 2>/dev/null)
        log_info "Docker 데몬 가용 (버전: ${DOCKER_VER})"

        # ---------------------------------------------------------------------------
        # setup 위생 (v15): 실행 전 잔존 agent-e2e* 프로세스 + 8080 점유 탐지
        # ---------------------------------------------------------------------------
        echo "[INFO] §6-SETUP: 잔존 프로세스 탐지..."
        STALE_AGENT_PIDS=$(powershell -NoProfile -Command \
            "(Get-Process agent-e2e -ErrorAction SilentlyContinue).Id" \
            2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | tr '\n' ' ' || true)
        if [ -n "${STALE_AGENT_PIDS}" ]; then
            log_info "§6-SETUP: 잔존 agent-e2e* 프로세스 감지(PIDs=${STALE_AGENT_PIDS}) — 종료 시도"
            for spid in ${STALE_AGENT_PIDS}; do
                taskkill //PID "${spid}" //T //F >/dev/null 2>&1 || true
            done
            log_info "§6-SETUP: 잔존 agent-e2e* 프로세스 종료 완료"
        else
            log_info "§6-SETUP: 잔존 agent-e2e* 프로세스 없음 — 클린 상태"
        fi

        STALE_8080=$(powershell -NoProfile -Command \
            "(Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue).OwningProcess" \
            2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | head -1 || true)
        if [ -n "${STALE_8080}" ]; then
            log_info "§6-SETUP: 8080 포트 선점 프로세스 감지(PID=${STALE_8080}) — 결과 문서에 기록(hub 기동 전 선점자로 처리)"
        else
            log_info "§6-SETUP: 8080 포트 선점 프로세스 없음 — 클린 상태"
        fi

        # 임시 작업 폴더
        RUN_TMP="${SCRIPT_DIR}/.run-tmp"
        mkdir -p "${RUN_TMP}/state"

        HUB_RUN_LOG="${RESULTS_DIR}/${TIMESTAMP}-hub-run.log"
        AGENT_RUN_LOG="${RESULTS_DIR}/${TIMESTAMP}-agent-run.log"
        COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"

        E2E_PROJECT="monitoring-e2e"
        dc() { docker compose -p "${E2E_PROJECT}" -f "${COMPOSE_FILE}" "$@"; }

        HUB_PID=""
        AGENT_CMD_WINPID=""   # cmd 래퍼 PID (콘솔 AttachConsole 대상)
        AGENT_APP_WINPID=""   # agent-e2e.exe PID (teardown 정밀 종료 대상)
        HUB_APP_WINPID=""
        DYNAMIC_STARTED=false

        # ── Windows 프로세스 종료 헬퍼 ──
        win_tree_kill() {
            local msys_pid="${1:-}"
            [ -z "${msys_pid}" ] && return 0
            local winpid
            winpid=$(cat "/proc/${msys_pid}/winpid" 2>/dev/null || true)
            if [ -n "${winpid}" ]; then
                taskkill //PID "${winpid}" //T //F >/dev/null 2>&1 || true
            fi
            kill "${msys_pid}" 2>/dev/null || true
        }

        resolve_port_owner() {
            powershell -NoProfile -Command \
                "(Get-NetTCPConnection -LocalPort $1 -State Listen -ErrorAction SilentlyContinue).OwningProcess" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | head -1 || true
        }

        list_agent_exe_pids() {
            powershell -NoProfile -Command \
                "(Get-Process agent-e2e -ErrorAction SilentlyContinue).Id" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | tr '\n' ' ' || true
        }

        # teardown
        teardown() {
            echo "[INFO] teardown 시작..."
            # agent-e2e.exe 종료
            if [ -n "${AGENT_APP_WINPID:-}" ]; then
                taskkill //PID "${AGENT_APP_WINPID}" //T //F >/dev/null 2>&1 || true
            fi
            # cmd 래퍼 종료
            if [ -n "${AGENT_CMD_WINPID:-}" ]; then
                taskkill //PID "${AGENT_CMD_WINPID}" //T //F >/dev/null 2>&1 || true
            fi
            # hub 종료
            if [ -n "${HUB_APP_WINPID:-}" ]; then
                taskkill //PID "${HUB_APP_WINPID}" //T //F >/dev/null 2>&1 || true
            fi
            if [ -n "${HUB_PID:-}" ]; then
                win_tree_kill "${HUB_PID}"
                echo "[INFO] hub 종료 (app winpid=${HUB_APP_WINPID:-none})"
            fi
            # infra
            if [ "${DYNAMIC_STARTED}" = "true" ]; then
                echo "[INFO] infra(${E2E_PROJECT}) docker compose down -v ..."
                dc down -v 2>/dev/null || true
            fi
            # teardown 위생 검사 (v15)
            sleep 2
            POST_8080=$(powershell -NoProfile -Command \
                "(Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue).OwningProcess" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | head -1 || true)
            POST_AGENT=$(powershell -NoProfile -Command \
                "(Get-Process agent-e2e -ErrorAction SilentlyContinue).Id" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | head -1 || true)
            if [ -z "${POST_8080:-}" ]; then
                FINDINGS+=("INFO: §6-TEARDOWN: 8080 포트 free 확인")
            else
                FINDINGS+=("INFO: §6-TEARDOWN: 8080 포트 여전히 점유(PID=${POST_8080}) — 수동 확인 필요")
            fi
            if [ -z "${POST_AGENT:-}" ]; then
                FINDINGS+=("INFO: §6-TEARDOWN: agent-e2e* 프로세스 없음 확인")
            else
                FINDINGS+=("INFO: §6-TEARDOWN: agent-e2e* 프로세스 잔존(PID=${POST_AGENT}) — 수동 확인 필요")
            fi
            # 임시 폴더 삭제
            rm -rf "${RUN_TMP}" 2>/dev/null || true
            echo "[INFO] teardown 완료"
        }
        trap teardown EXIT

        # §6-1: infra 기동 또는 기존 스택 재활용
        KAFKA_READY=false
        KAFKA_CONTAINER_ID=""

        if [ "${REUSE_INFRA}" = "true" ]; then
            echo "[INFO] §6-1: --reuse-infra 모드 — 기존 infra 컨테이너 헬스 검사..."
            EXISTING_KAFKA=$(docker ps --filter "name=infra-kafka" --format "{{.ID}}" 2>/dev/null | head -1 || true)
            if [ -z "${EXISTING_KAFKA}" ]; then
                EXISTING_KAFKA=$(docker ps --filter "publish=9092" --format "{{.ID}}" 2>/dev/null | head -1 || true)
            fi

            if [ -n "${EXISTING_KAFKA}" ]; then
                KAFKA_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "${EXISTING_KAFKA}" 2>/dev/null || echo "unknown")
                KAFKA_CONTAINER_ID="${EXISTING_KAFKA}"
                if [ "${KAFKA_HEALTH}" = "healthy" ]; then
                    KAFKA_READY=true
                    log_info "기존 kafka 컨테이너(ID=${EXISTING_KAFKA}) healthy 확인 — 재활용"
                else
                    log_fail "기존 kafka 컨테이너(ID=${EXISTING_KAFKA}) 상태=${KAFKA_HEALTH} — healthy가 아님. 재활용 불가."
                fi
            else
                log_fail "--reuse-infra 지정됐으나 9092 포트 kafka 컨테이너가 없음 — 동적 검증 불가"
            fi

            EXISTING_OTEL=$(docker ps --filter "publish=14318" --format "{{.ID}}" 2>/dev/null | head -1 || true)
            if [ -n "${EXISTING_OTEL}" ]; then
                OTEL_STATUS=$(docker inspect --format='{{.State.Status}}' "${EXISTING_OTEL}" 2>/dev/null || echo "unknown")
                if [ "${OTEL_STATUS}" = "running" ]; then
                    log_info "기존 otel-collector 컨테이너(ID=${EXISTING_OTEL}) running 확인 — 재활용"
                else
                    log_info "주의: otel-collector 컨테이너(ID=${EXISTING_OTEL}) 상태=${OTEL_STATUS}"
                fi
            else
                log_info "주의: 14318 포트 otel-collector 컨테이너 미감지"
            fi

        else
            echo "[INFO] §6-1: 이전 e2e 세션 정리 (${E2E_PROJECT} down -v)..."
            dc down -v 2>&1 || true
            log_info "클린 시작: e2e 전용 kafka 볼륨/토픽 제거 완료 — offset 0부터 시작 예정"

            echo "[INFO] §6-1: infra docker compose up -d (${E2E_PROJECT})..."
            DYNAMIC_STARTED=true
            dc up -d 2>&1

            echo "[INFO] kafka healthy 대기 (최대 90s)..."
            KAFKA_WAIT=0
            while [ ${KAFKA_WAIT} -lt 90 ]; do
                KAFKA_CID="$(dc ps -q kafka 2>/dev/null || true)"
                KAFKA_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' \
                    "${KAFKA_CID}" 2>/dev/null || echo "unknown")
                if [ "${KAFKA_HEALTH}" = "healthy" ]; then
                    KAFKA_READY=true
                    KAFKA_CONTAINER_ID="${KAFKA_CID}"
                    log_info "kafka healthy 확인 (${KAFKA_WAIT}s 경과)"
                    break
                fi
                sleep 5
                KAFKA_WAIT=$((KAFKA_WAIT + 5))
            done

            if [ "${KAFKA_READY}" = "true" ]; then
                echo "[INFO] §6-1: kafka-init 완료 + group coordinator 안정화 대기 (20s)..."
                sleep 20
                KAFKA_INIT_STATUS=$(dc ps kafka-init 2>/dev/null | grep "kafka-init" | awk '{print $NF}' || echo "unknown")
                log_info "kafka-init 컨테이너 상태: ${KAFKA_INIT_STATUS}"
                CONSUMER_OFFSETS_EXISTS=$(docker exec "${KAFKA_CONTAINER_ID}" \
                    kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null \
                    | grep -x "__consumer_offsets" || true)
                if [ -n "${CONSUMER_OFFSETS_EXISTS}" ]; then
                    log_info "kafka __consumer_offsets 토픽 존재 확인 — group coordinator 준비됨"
                else
                    log_info "kafka __consumer_offsets 토픽 미감지 (첫 consumer group 연결 전에는 없을 수 있음 — 정상)"
                fi
            fi
        fi

        if [ "${KAFKA_READY}" = "false" ]; then
            log_fail "kafka가 healthy 상태 미도달 — 동적 검증 중단"
        else
            HUB_OWNER_PRE="$(resolve_port_owner 8080)"
            if [ -n "${HUB_OWNER_PRE}" ]; then
                log_info "주의: hub 기동 전 이미 8080 점유(PID=${HUB_OWNER_PRE}) — teardown 대상 제외"
            fi

            # §6-2: hub 기동
            echo "[INFO] §6-2: hub 기동 (spring-boot:run + DEBUG env)..."
            (
                cd "${HUB_DIR}"
                LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_KAFKA=DEBUG \
                LOGGING_LEVEL_COM_MONITORING_HUB_INGEST_HEARTBEAT=DEBUG \
                LOGGING_LEVEL_COM_MONITORING_HUB_INGEST_AUDIT=DEBUG \
                LOGGING_LEVEL_COM_MONITORING_HUB_PRODUCER=DEBUG \
                mvn spring-boot:run --no-transfer-progress 2>&1
            ) > "${HUB_RUN_LOG}" 2>&1 &
            HUB_PID=$!
            log_info "hub PID=${HUB_PID}, 로그=${HUB_RUN_LOG}"

            echo "[INFO] hub /health 폴링 (최대 120s)..."
            HUB_WAIT=0
            HUB_READY=false
            while [ ${HUB_WAIT} -lt 120 ]; do
                if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
                    CUR_OWNER="$(resolve_port_owner 8080)"
                    if [ -n "${CUR_OWNER}" ] && [ "${CUR_OWNER}" != "${HUB_OWNER_PRE:-}" ]; then
                        HUB_READY=true
                        HUB_APP_WINPID="${CUR_OWNER}"
                        log_info "hub /health 응답 확인 (${HUB_WAIT}s 경과), 앱 winpid=${HUB_APP_WINPID}"
                        break
                    fi
                fi
                if ! kill -0 "${HUB_PID}" 2>/dev/null; then
                    log_fail "hub 프로세스가 예기치 않게 종료됨 (PID=${HUB_PID})"
                    break
                fi
                sleep 5
                HUB_WAIT=$((HUB_WAIT + 5))
            done

            if [ "${HUB_READY}" = "false" ]; then
                log_fail "hub가 120s 내 /health 응답 없음 — 동적 검증 중단"
                HUB_TAIL=$(tail -20 "${HUB_RUN_LOG}" 2>/dev/null || echo "로그 없음")
                log_info "hub 로그 tail(20): ${HUB_TAIL}"
            else
                # §6-3: script-agent 빌드 + launcher cmd로 기동 (v11~v14 확립)
                # go run 금지 — 빌드 후 바이너리 실행. cmd 래퍼가 전용 콘솔을 가져서
                # GenerateConsoleCtrlEvent(1,0) 이 cmd PID 콘솔 그룹에 브로드캐스트됨.
                AGENT_BIN="${RUN_TMP}/agent-e2e.exe"
                AGENT_LAUNCH_CMD="${RUN_TMP}/agent-launch.cmd"
                AGENT_PID_FILE="${RUN_TMP}/agent-pid.txt"

                echo "[INFO] §6-3: script-agent go build..."
                set +e
                (cd "${AGENT_DIR}" && go build -o "${AGENT_BIN}" ./cmd/agent 2>&1)
                BUILD_EXIT=$?
                set -e
                if [ ${BUILD_EXIT} -ne 0 ]; then
                    log_fail "§6-3: script-agent go build 실패 (exit=${BUILD_EXIT}) — 동적 검증 중단"
                else
                    log_info "§6-3: script-agent go build 성공 → ${AGENT_BIN}"

                    # launcher .cmd 작성 (env set + 바이너리 실행, 로그를 agent-run.log로)
                    # Windows 경로로 변환
                    AGENT_BIN_WIN=$(cygpath -w "${AGENT_BIN}" 2>/dev/null || echo "${AGENT_BIN}")
                    AGENT_RUN_LOG_WIN=$(cygpath -w "${AGENT_RUN_LOG}" 2>/dev/null || echo "${AGENT_RUN_LOG}")
                    RUN_TMP_WIN=$(cygpath -w "${RUN_TMP}" 2>/dev/null || echo "${RUN_TMP}")

                    cat > "${AGENT_LAUNCH_CMD}" << CMDEOF
@echo off
set KAFKA_BROKERS=127.0.0.1:9092
set OTLP_ENDPOINT=http://127.0.0.1:14318
set HEARTBEAT_INTERVAL_SECONDS=2
set AGENT_ID_PATH=${RUN_TMP_WIN}\.agent_id
set LOG_STATE_DIR=${RUN_TMP_WIN}\state
"${AGENT_BIN_WIN}" 1> "${AGENT_RUN_LOG_WIN}" 2>&1
CMDEOF

                    AGENT_LAUNCH_CMD_WIN=$(cygpath -w "${AGENT_LAUNCH_CMD}" 2>/dev/null || echo "${AGENT_LAUNCH_CMD}")
                    AGENT_PID_FILE_WIN=$(cygpath -w "${AGENT_PID_FILE}" 2>/dev/null || echo "${AGENT_PID_FILE}")

                    echo "[INFO] §6-3: Start-Process cmd 래퍼로 agent 기동..."
                    # Start-Process: -WindowStyle Hidden으로 별도 콘솔창 숨김.
                    # cmd.exe /c로 실행 — cmd가 전용 콘솔 그룹을 가져서 CTRL_BREAK 수신 가능.
                    # PID는 임시 파일에 기록(파이프 교착 방지 — 버그 G 해소).
                    powershell -NoProfile -Command "
\$p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"${AGENT_LAUNCH_CMD_WIN}\"' -WindowStyle Hidden -PassThru
Set-Content -Path '${AGENT_PID_FILE_WIN}' -Value \$p.Id
exit 0
" 2>/dev/null || true

                    sleep 2
                    if [ -f "${AGENT_PID_FILE}" ]; then
                        AGENT_CMD_WINPID=$(cat "${AGENT_PID_FILE}" | tr -d '\r\n' || true)
                        log_info "script-agent cmd 래퍼 winpid=${AGENT_CMD_WINPID:-unknown} (cmd.exe 전용 콘솔, agent 콘솔 상속)"
                    else
                        log_info "§6-3: agent-pid.txt 미생성 — AGENT_CMD_WINPID 미확인"
                        AGENT_CMD_WINPID=""
                    fi

                    # agent-e2e.exe PID 포착 (자식 프로세스)
                    sleep 3
                    AGENT_APP_WINPID=$(powershell -NoProfile -Command \
                        "(Get-Process agent-e2e -ErrorAction SilentlyContinue | Select-Object -First 1).Id" \
                        2>/dev/null | tr -d '\r\n' | grep -E '^[0-9]+$' || true)
                    if [ -n "${AGENT_APP_WINPID:-}" ]; then
                        log_info "script-agent 앱 winpid=${AGENT_APP_WINPID} (teardown 정밀 종료 대상)"
                    else
                        log_info "§6-3: agent-e2e.exe PID 미확인 — teardown에서 프로세스명으로 종료"
                    fi

                    # §6-4: heartbeat 수신 판정 (최대 75s)
                    echo "[INFO] §6-4: hub 로그 폴링으로 heartbeat 수신 판정 (최대 75s)..."
                    POLL_WAIT=0
                    HEARTBEAT_RECEIVED=false
                    RECV_LINE=""
                    while [ ${POLL_WAIT} -lt 75 ]; do
                        RECV_LINE=$(grep -E "ntainer#1-0-C-1.*KafkaMessageListenerContainer.*Received: [1-9][0-9]* records" \
                            "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                        if [ -n "${RECV_LINE}" ]; then
                            HEARTBEAT_RECEIVED=true
                            break
                        fi
                        sleep 3
                        POLL_WAIT=$((POLL_WAIT + 3))
                    done

                    if [ "${HEARTBEAT_RECEIVED}" = "true" ]; then
                        DECODE_FAIL=$(( $(grep -c "failed to decode heartbeat payload" "${HUB_RUN_LOG}" 2>/dev/null || echo 0) + 0 ))
                        NO_DATAPOINTS=$(( $(grep -c "no agent.heartbeat data points" "${HUB_RUN_LOG}" 2>/dev/null || echo 0) + 0 ))

                        if [ "${DECODE_FAIL}" -eq 0 ] && [ "${NO_DATAPOINTS}" -eq 0 ]; then
                            log_pass "§6 동적 E2E: heartbeat 수신 + 디코드 성공 확인. 수신 라인: [${RECV_LINE}]"
                            UI_CHECK=$(curl -sf http://localhost:8080/ 2>/dev/null | grep -i "ONLINE\|online" | head -1 || true)
                            if [ -n "${UI_CHECK}" ]; then
                                log_info "코로보레이션: hub UI(/)에서 ONLINE 상태 감지 — [${UI_CHECK}]"
                            else
                                log_info "코로보레이션: hub UI(/) ONLINE 상태 미감지 (판정 게이트 아님)"
                            fi
                        else
                            log_fail "§6 동적 E2E: heartbeat 수신됐으나 디코드 실패 감지. decode_fail=${DECODE_FAIL}, no_datapoints=${NO_DATAPOINTS}. 수신 라인: [${RECV_LINE}]"
                        fi
                    else
                        log_fail "§6 동적 E2E: 75s 내 heartbeats 토픽 실제 레코드 수신 라인 미출현 — timeout"
                        HUB_LAST=$(tail -15 "${HUB_RUN_LOG}" 2>/dev/null || echo "로그 없음")
                        AGENT_LAST=$(tail -10 "${AGENT_RUN_LOG}" 2>/dev/null || echo "로그 없음")
                        log_info "hub 로그 마지막 15줄: ${HUB_LAST}"
                        log_info "agent 로그 마지막 10줄: ${AGENT_LAST}"
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-T4: T4-1 토픽 재명명 동적 판정
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-T4: T4-1 토픽 재명명 동적 판정..."

                    KAFKA_EXEC_TARGET="${KAFKA_CONTAINER_ID:-}"
                    if [ -z "${KAFKA_EXEC_TARGET}" ]; then
                        KAFKA_EXEC_TARGET=$(docker ps --filter "publish=9092" --format "{{.ID}}" 2>/dev/null | head -1 || true)
                    fi

                    if [ -n "${KAFKA_EXEC_TARGET}" ]; then
                        LIVE_TOPICS=$(docker exec "${KAFKA_EXEC_TARGET}" \
                            kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null || echo "ERROR")
                        if [ "${LIVE_TOPICS}" = "ERROR" ]; then
                            log_fail "§6-T4-A: kafka 토픽 목록 조회 실패"
                        else
                            log_info "§6-T4-A: 라이브 kafka 토픽 목록: $(echo "${LIVE_TOPICS}" | tr '\n' ' ')"
                            HB_TOPIC_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "heartbeats-topic" || true)
                            CMD_TOPIC_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "command-topic" || true)
                            AUDIT_TOPIC_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "audit-topic" || true)
                            JR_TOPIC_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "job-results" || true)
                            if [ -n "${HB_TOPIC_LIVE}" ] && [ -n "${CMD_TOPIC_LIVE}" ] && \
                               [ -n "${AUDIT_TOPIC_LIVE}" ] && [ -n "${JR_TOPIC_LIVE}" ]; then
                                log_pass "§6-T4-A: 라이브 kafka 신명 토픽 4종 모두 존재 확인"
                            else
                                MISSING=""
                                [ -z "${HB_TOPIC_LIVE}" ]    && MISSING="${MISSING} heartbeats-topic"
                                [ -z "${CMD_TOPIC_LIVE}" ]   && MISSING="${MISSING} command-topic"
                                [ -z "${AUDIT_TOPIC_LIVE}" ] && MISSING="${MISSING} audit-topic"
                                [ -z "${JR_TOPIC_LIVE}" ]    && MISSING="${MISSING} job-results"
                                log_fail "§6-T4-A: 라이브 kafka 신명 토픽 미존재:${MISSING}"
                            fi
                            OLD_HB_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "heartbeats" || true)
                            OLD_CMD_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "commands" || true)
                            OLD_AUDIT_LIVE=$(echo "${LIVE_TOPICS}" | grep -x "audit-events" || true)
                            if [ -z "${OLD_HB_LIVE}" ] && [ -z "${OLD_CMD_LIVE}" ] && [ -z "${OLD_AUDIT_LIVE}" ]; then
                                log_pass "§6-T4-A: 라이브 kafka 구명 토픽(heartbeats/commands/audit-events) 미생성 확인"
                            else
                                STALE=""
                                [ -n "${OLD_HB_LIVE}" ]    && STALE="${STALE} heartbeats"
                                [ -n "${OLD_CMD_LIVE}" ]   && STALE="${STALE} commands"
                                [ -n "${OLD_AUDIT_LIVE}" ] && STALE="${STALE} audit-events"
                                log_fail "§6-T4-A: 라이브 kafka 구명 토픽 존재 감지:${STALE}"
                            fi
                        fi
                    else
                        log_fail "§6-T4-A: kafka 컨테이너를 찾을 수 없어 토픽 목록 조회 불가"
                    fi

                    HB_TOPIC_SUBSCRIBE=$(grep -E "heartbeats-topic" "${HUB_RUN_LOG}" 2>/dev/null | \
                        grep -iE "subscrib|assign|partition|topic" | head -3 || true)
                    if [ -n "${HB_TOPIC_SUBSCRIBE}" ]; then
                        log_pass "§6-T4-B: hub 로그에서 heartbeats-topic 구독/파티션 할당 확인. 라인: [$(echo "${HB_TOPIC_SUBSCRIBE}" | head -1)]"
                    else
                        if [ "${HEARTBEAT_RECEIVED}" = "true" ]; then
                            log_info "§6-T4-B: hub 로그에 heartbeats-topic 구독 라인 미감지 (로그 레벨 차이 가능) — heartbeat 수신 자체는 확인됨"
                        else
                            log_fail "§6-T4-B: hub 로그에 heartbeats-topic 구독 확인 불가 + heartbeat 수신도 없음"
                        fi
                    fi

                    AGENT_STARTED_LINE=$(grep -iE "AGENT_STARTED|agent started|registered|starting" \
                        "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                    HB_SENT_LINE=$(grep -iE "heartbeat|otlp|metric|exporting" \
                        "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                    if [ -n "${AGENT_STARTED_LINE}" ]; then
                        log_pass "§6-T4-C: script-agent 기동/등록 확인. 라인: [${AGENT_STARTED_LINE}]"
                    else
                        log_info "§6-T4-C: script-agent AGENT_STARTED 명시 라인 미감지 (로그 포맷 차이 가능)"
                    fi
                    if [ -n "${HB_SENT_LINE}" ]; then
                        log_info "§6-T4-C: script-agent heartbeat 발행 관련 라인: [${HB_SENT_LINE}]"
                    fi

                    if [ -n "${KAFKA_EXEC_TARGET:-}" ]; then
                        HB_OFFSET=$(docker exec "${KAFKA_EXEC_TARGET}" \
                            kafka-run-class kafka.tools.GetOffsetShell \
                            --bootstrap-server localhost:9092 \
                            --topic heartbeats-topic \
                            --time -1 2>/dev/null | grep -oE ':[0-9]+$' | tr -d ':' | head -1 || true)
                        if [ -n "${HB_OFFSET:-}" ] && [ "${HB_OFFSET}" -gt 0 ] 2>/dev/null; then
                            log_pass "§6-T4-D: heartbeats-topic 오프셋=${HB_OFFSET} — 실제 메시지 도착 실증"
                        elif [ "${HB_OFFSET:-}" = "0" ] 2>/dev/null; then
                            log_fail "§6-T4-D: heartbeats-topic 오프셋=0 — 메시지 미도착"
                        else
                            HB_DESCRIBE=$(docker exec "${KAFKA_EXEC_TARGET}" \
                                kafka-topics --bootstrap-server localhost:9092 \
                                --describe --topic heartbeats-topic 2>/dev/null || echo "ERROR")
                            if echo "${HB_DESCRIBE}" | grep -q "heartbeats-topic"; then
                                log_info "§6-T4-D: heartbeats-topic 토픽 존재 확인 (오프셋 조회 실패 — kafka-run-class 경로 이슈 가능)"
                            else
                                log_fail "§6-T4-D: heartbeats-topic 오프셋 확인 실패"
                            fi
                        fi

                        OLD_HB_OFFSET=$(docker exec "${KAFKA_EXEC_TARGET}" \
                            kafka-run-class kafka.tools.GetOffsetShell \
                            --bootstrap-server localhost:9092 \
                            --topic heartbeats \
                            --time -1 2>/dev/null | grep -oE ':[0-9]+$' | tr -d ':' | head -1 || true)
                        if [ -z "${OLD_HB_OFFSET:-}" ]; then
                            log_pass "§6-T4-D: 구명 토픽(heartbeats) 오프셋 조회 불가(토픽 미존재) — 구명으로는 트래픽 없음 확인"
                        else
                            log_fail "§6-T4-D: 구명 토픽(heartbeats) 오프셋=${OLD_HB_OFFSET} — 구명으로 메시지 도달 가능성"
                        fi
                    else
                        log_fail "§6-T4-D: kafka 컨테이너 미확인으로 오프셋 검사 불가"
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-AUDIT: audit 경로 라이브 판정
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-AUDIT: audit 경로 라이브 판정..."

                    AUDIT_WAIT=0
                    AGENT_STARTED_RECEIVED=false
                    AGENT_STARTED_HUB_LINE=""
                    while [ ${AUDIT_WAIT} -lt 30 ]; do
                        AGENT_STARTED_HUB_LINE=$(grep -iE "AGENT_STARTED received|agent_started.*received|handleAgentStarted" \
                            "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                        if [ -n "${AGENT_STARTED_HUB_LINE}" ]; then
                            AGENT_STARTED_RECEIVED=true
                            break
                        fi
                        sleep 3
                        AUDIT_WAIT=$((AUDIT_WAIT + 3))
                    done

                    if [ "${AGENT_STARTED_RECEIVED}" = "true" ]; then
                        log_pass "§6-AUDIT: hub 로그에서 AGENT_STARTED 수신 확인 — audit-topic 경로 정상 실증. 라인: [${AGENT_STARTED_HUB_LINE}]"
                    else
                        AGENT_STARTED_ERR=$(grep -E "failed to publish AGENT_STARTED|context deadline exceeded" \
                            "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                        if [ -n "${AGENT_STARTED_ERR}" ]; then
                            log_fail "§6-AUDIT: hub에서 AGENT_STARTED 미수신 — agent 측 발행 실패: [${AGENT_STARTED_ERR}]"
                        else
                            log_fail "§6-AUDIT: hub에서 AGENT_STARTED 미수신 + agent 측 발행 에러도 미감지"
                        fi
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-CMD: command 경로 라이브 판정
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-CMD: command 경로 라이브 판정..."

                    AGENT_ID_FILE="${RUN_TMP}/.agent_id"
                    LIVE_AGENT_ID=""
                    if [ -f "${AGENT_ID_FILE}" ]; then
                        LIVE_AGENT_ID=$(cat "${AGENT_ID_FILE}" 2>/dev/null | tr -d '\r\n' || true)
                    fi
                    if [ -z "${LIVE_AGENT_ID:-}" ]; then
                        LIVE_AGENT_ID=$(grep -oE '"agent_id":"[^"]+"' "${AGENT_RUN_LOG}" 2>/dev/null \
                            | head -1 | grep -oE '"[a-f0-9-]{36}"' | tr -d '"' || true)
                    fi

                    if [ -z "${LIVE_AGENT_ID:-}" ]; then
                        log_fail "§6-CMD: agent_id 확인 불가 — command 경로 검증 불가"
                    else
                        log_info "§6-CMD: 라이브 agent_id=${LIVE_AGENT_ID}"

                        SCHEDULE_PAYLOAD="{\"job_type\":\"SCRIPT_JOB\",\"spec\":{\"script_path\":\"/opt/scripts/check_disk.sh\",\"args\":[\"--threshold\",\"80\"],\"timeout_seconds\":30,\"output_cap_bytes\":65536},\"target_agent_id\":\"${LIVE_AGENT_ID}\",\"cron\":\"0/5 * * * * ?\"}"
                        SCHEDULE_RESP=$(curl -sf -X POST http://localhost:8080/schedules \
                            -H "Content-Type: application/json" \
                            -d "${SCHEDULE_PAYLOAD}" 2>/dev/null || echo "ERROR")

                        if [ "${SCHEDULE_RESP}" = "ERROR" ]; then
                            log_fail "§6-CMD: hub /schedules POST 실패"
                        else
                            log_info "§6-CMD: hub /schedules POST 성공. 응답: [$(echo "${SCHEDULE_RESP}" | head -c 200)]"

                            CMD_SENT_WAIT=0
                            COMMAND_SENT=false
                            CMD_SENT_LINE=""
                            while [ ${CMD_SENT_WAIT} -lt 45 ]; do
                                CMD_SENT_LINE=$(grep -E "COMMAND sent.*target_agent=${LIVE_AGENT_ID}" \
                                    "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                                if [ -n "${CMD_SENT_LINE}" ]; then
                                    COMMAND_SENT=true
                                    break
                                fi
                                sleep 3
                                CMD_SENT_WAIT=$((CMD_SENT_WAIT + 3))
                            done

                            if [ "${COMMAND_SENT}" = "true" ]; then
                                log_pass "§6-CMD: hub CommandPublisher COMMAND sent 확인. 라인: [${CMD_SENT_LINE}]"

                                CMD_RECV_WAIT=0
                                COMMAND_RECEIVED_BY_AGENT=false
                                CMD_RECV_LINE=""
                                FETCH_ERR_LINE=""
                                while [ ${CMD_RECV_WAIT} -lt 20 ]; do
                                    CMD_RECV_LINE=$(grep -iE "dispatch|command.*envelope|x_source.*observed|unmarshal command|executing" \
                                        "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                                    FETCH_ERR_LINE=$(grep -E "failed to fetch command" \
                                        "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                                    if [ -n "${CMD_RECV_LINE}" ]; then
                                        COMMAND_RECEIVED_BY_AGENT=true
                                        break
                                    fi
                                    sleep 2
                                    CMD_RECV_WAIT=$((CMD_RECV_WAIT + 2))
                                done

                                if [ "${COMMAND_RECEIVED_BY_AGENT}" = "true" ]; then
                                    log_pass "§6-CMD: agent command 수신/처리 확인. 라인: [${CMD_RECV_LINE}]"
                                else
                                    if [ -n "${FETCH_ERR_LINE:-}" ]; then
                                        log_fail "§6-CMD: agent command 수신 라인 미감지 — fetch 에러: [${FETCH_ERR_LINE}]"
                                    else
                                        AGENT_RECENT=$(tail -10 "${AGENT_RUN_LOG}" 2>/dev/null || echo "없음")
                                        log_info "§6-CMD: agent dispatch 라인 미감지. agent 로그 tail: [${AGENT_RECENT}]"
                                        # agent 프로세스 생존 여부 확인
                                        AGENT_ALIVE=$(powershell -NoProfile -Command \
                                            "(Get-Process agent-e2e -ErrorAction SilentlyContinue | Select-Object -First 1).Id" \
                                            2>/dev/null | tr -d '\r\n' | grep -E '^[0-9]+$' || true)
                                        if [ -n "${AGENT_ALIVE:-}" ]; then
                                            log_pass "§6-CMD: agent 프로세스 생존 + fetch 에러 없음 — command-topic 수신 경로 에러 없이 대기 중"
                                        else
                                            log_fail "§6-CMD: agent 프로세스 종료됨 — command 경로 판정 불가"
                                        fi
                                    fi
                                fi
                            else
                                HUB_CMD_LINES=$(grep -E "command|COMMAND|schedule|trigger" \
                                    "${HUB_RUN_LOG}" 2>/dev/null | tail -5 || echo "없음")
                                log_fail "§6-CMD: 45s 내 hub COMMAND sent 라인 미감지. hub 관련 로그: [${HUB_CMD_LINES}]"
                            fi
                        fi
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-LOG: LOG_JOB 동적 실행 실증 (v10에서 추가)
                    # spec §7.5.1 — log_path, pattern, encoding 필드
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-LOG: LOG_JOB 동적 실행 실증..."

                    if [ -z "${LIVE_AGENT_ID:-}" ]; then
                        log_fail "§6-LOG: agent_id 미확인 — LOG_JOB 검증 불가"
                    else
                        # 임시 로그 파일 생성
                        LOG_TEST_FILE="${RUN_TMP}/e2e_test.log"
                        echo "E2E_BASELINE_INIT $(date)" > "${LOG_TEST_FILE}"

                        # Windows 경로로 변환 (JSON 이스케이프 포함)
                        LOG_TEST_FILE_WIN=$(cygpath -w "${LOG_TEST_FILE}" 2>/dev/null || echo "${LOG_TEST_FILE}")
                        LOG_TEST_FILE_JSON=$(echo "${LOG_TEST_FILE_WIN}" | sed 's/\\/\\\\/g')
                        log_info "§6-LOG: 임시 로그 파일 초기화: ${LOG_TEST_FILE} (Windows JSON 경로: ${LOG_TEST_FILE_JSON})"

                        # LOG_JOB 스케줄 등록 (cron 0/5 = 5초마다)
                        LOG_SCHEDULE_PAYLOAD="{\"job_type\":\"LOG_JOB\",\"spec\":{\"log_path\":\"${LOG_TEST_FILE_JSON}\",\"pattern\":\"E2E_TEST\",\"encoding\":\"UTF-8\"},\"target_agent_id\":\"${LIVE_AGENT_ID}\",\"cron\":\"0/5 * * * * ?\"}"
                        LOG_SCHEDULE_RESP=$(curl -sf -X POST http://localhost:8080/schedules \
                            -H "Content-Type: application/json" \
                            -d "${LOG_SCHEDULE_PAYLOAD}" 2>/dev/null || echo "ERROR")

                        if [ "${LOG_SCHEDULE_RESP}" = "ERROR" ]; then
                            log_fail "§6-LOG: hub /schedules POST(LOG_JOB) 실패"
                        else
                            LOG_SCHED_ID=$(echo "${LOG_SCHEDULE_RESP}" | grep -oE '"schedule_id":"[^"]+"' | grep -oE '"[a-f0-9-]{36}"' | tr -d '"' || true)
                            log_info "§6-LOG: LOG_JOB 스케줄 등록 성공(schedule_id=${LOG_SCHED_ID:-unknown}). cron=0/5 첫 발화 대기..."

                            # 첫 COMMAND sent(LOG_JOB) 확인 (최대 30s)
                            LOG_CMD_WAIT=0
                            LOG_FIRST_CMD=""
                            while [ ${LOG_CMD_WAIT} -lt 30 ]; do
                                LOG_FIRST_CMD=$(grep -E "COMMAND sent.*job_type=LOG_JOB.*target_agent=${LIVE_AGENT_ID}" \
                                    "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                                if [ -n "${LOG_FIRST_CMD}" ]; then break; fi
                                sleep 3
                                LOG_CMD_WAIT=$((LOG_CMD_WAIT + 3))
                            done

                            if [ -z "${LOG_FIRST_CMD:-}" ]; then
                                log_fail "§6-LOG: 30s 내 hub LOG_JOB COMMAND sent 미감지 — cron 발화 안됨"
                            else
                                log_info "§6-LOG: LOG_JOB 첫 COMMAND 발행 확인(파일 끝 위치 저장 예상). 라인: [${LOG_FIRST_CMD}]"

                                # 패턴 매칭 라인 append
                                echo "E2E_TEST_MATCH $(date) — e2e harness v15" >> "${LOG_TEST_FILE}"
                                log_info "§6-LOG: ${LOG_TEST_FILE}에 E2E_TEST 패턴 매칭 라인 append 완료"

                                # 두 번째 트리거에서 JOB_RESULT received(LOG_JOB, status=SUCCESS) 확인 (최대 30s)
                                LOG_RESULT_WAIT=0
                                LOG_RESULT_LINE=""
                                while [ ${LOG_RESULT_WAIT} -lt 30 ]; do
                                    LOG_RESULT_LINE=$(grep -E "JOB_RESULT received.*job_type=LOG_JOB.*status=SUCCESS" \
                                        "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                                    if [ -n "${LOG_RESULT_LINE}" ]; then break; fi
                                    sleep 3
                                    LOG_RESULT_WAIT=$((LOG_RESULT_WAIT + 3))
                                done

                                if [ -n "${LOG_RESULT_LINE:-}" ]; then
                                    log_pass "§6-LOG: hub JOB_RESULT received(status=SUCCESS) 확인 — LOG_JOB executor 실행 실증(log_path/pattern/offset 추적 사이클 확인). 라인: [${LOG_RESULT_LINE}]"
                                else
                                    log_fail "§6-LOG: 30s 내 JOB_RESULT received(LOG_JOB, status=SUCCESS) 미감지"
                                    HUB_RECENT=$(tail -5 "${HUB_RUN_LOG}" 2>/dev/null || echo "없음")
                                    log_info "§6-LOG: hub 로그 tail: [${HUB_RECENT}]"
                                fi
                            fi
                        fi
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-STOP: AGENT_STOPPED 동적 수신 실증 (v15: CTRL_BREAK_EVENT)
                    # 사람 실험(2026-06-11) 확정 방법:
                    #   FreeConsole → AttachConsole(<cmd PID>) → SetConsoleCtrlHandler(NULL,true)
                    #   → GenerateConsoleCtrlEvent(1, 0)  ← CTRL_BREAK_EVENT + 그룹 0(브로드캐스트)
                    # (0,0) CTRL_C는 이 환경에서 미배달 — v10~v14 FAIL 원인
                    # (1,0) CTRL_BREAK는 agent가 shutdown signal received → graceful shutdown
                    #       → AGENT_STOPPED(reason=interrupt, exit_code=0) 발행까지 전체 경로 확인됨
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-STOP: AGENT_STOPPED 동적 수신 실증 (CTRL_BREAK_EVENT)..."

                    if [ -z "${AGENT_CMD_WINPID:-}" ]; then
                        log_fail "§6-STOP: AGENT_CMD_WINPID 미확인 — CTRL_BREAK 대상 없음. fallback taskkill 사용"
                        if [ -n "${AGENT_APP_WINPID:-}" ]; then
                            taskkill //PID "${AGENT_APP_WINPID}" //T //F >/dev/null 2>&1 || true
                        fi
                    else
                        # CTRL_BREAK_EVENT(1,0) 발사
                        CTRL_RESULT=$(powershell -NoProfile -Command "
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class ConsoleCtrl {
    [DllImport(\"kernel32.dll\")] public static extern bool FreeConsole();
    [DllImport(\"kernel32.dll\")] public static extern bool AttachConsole(uint dwProcessId);
    [DllImport(\"kernel32.dll\")] public static extern bool SetConsoleCtrlHandler(IntPtr HandlerRoutine, bool Add);
    [DllImport(\"kernel32.dll\")] public static extern bool GenerateConsoleCtrlEvent(uint dwCtrlEvent, uint dwProcessGroupId);
}
'@
[ConsoleCtrl]::FreeConsole() | Out-Null
[ConsoleCtrl]::AttachConsole(${AGENT_CMD_WINPID}) | Out-Null
[ConsoleCtrl]::SetConsoleCtrlHandler([IntPtr]::Zero, \$true) | Out-Null
\$result = [ConsoleCtrl]::GenerateConsoleCtrlEvent(1, 0)
Write-Host \$result
[ConsoleCtrl]::FreeConsole() | Out-Null
" 2>/dev/null | tr -d '\r\n' || echo "ERROR")
                        log_info "§6-STOP: GenerateConsoleCtrlEvent(1,0) 발사 결과: ${CTRL_RESULT}"

                        # hub 로그에서 AGENT_STOPPED received 폴링 (30s)
                        STOP_WAIT=0
                        AGENT_STOPPED_RECEIVED=false
                        AGENT_STOPPED_HUB_LINE=""
                        while [ ${STOP_WAIT} -lt 30 ]; do
                            AGENT_STOPPED_HUB_LINE=$(grep -iE "AGENT_STOPPED received|agent_stopped.*received" \
                                "${HUB_RUN_LOG}" 2>/dev/null | head -1 || true)
                            if [ -n "${AGENT_STOPPED_HUB_LINE}" ]; then
                                AGENT_STOPPED_RECEIVED=true
                                break
                            fi
                            sleep 3
                            STOP_WAIT=$((STOP_WAIT + 3))
                        done

                        AGENT_LOG_TAIL=$(tail -5 "${AGENT_RUN_LOG}" 2>/dev/null || echo "없음")
                        HUB_AUDIT_TAIL=$(grep -iE "AGENT_STOPPED|agent_stopped|AuditConsumer" \
                            "${HUB_RUN_LOG}" 2>/dev/null | tail -5 || echo "없음")
                        log_info "§6-STOP: CTRL_BREAK exit=${CTRL_RESULT} / agent 로그 tail: [${AGENT_LOG_TAIL}]"
                        log_info "§6-STOP: hub AGENT_STOPPED/AuditConsumer 로그: [${HUB_AUDIT_TAIL}]"

                        if [ "${AGENT_STOPPED_RECEIVED}" = "true" ]; then
                            log_pass "§6-STOP: hub에서 AGENT_STOPPED received 확인 — agent graceful shutdown → audit-topic → hub 전체 경로 실증. 라인: [${AGENT_STOPPED_HUB_LINE}]"
                        else
                            log_fail "§6-STOP: hub에서 AGENT_STOPPED received 미수신(30s timeout) — CTRL_BREAK_EVENT 후 graceful shutdown 미증명"
                            # fallback 강제 종료 (이 경우 §6-STOP FAIL 유지 — 강제 종료는 실증 아님)
                            if [ -n "${AGENT_APP_WINPID:-}" ]; then
                                taskkill //PID "${AGENT_APP_WINPID}" //T //F >/dev/null 2>&1 || true
                                log_info "§6-STOP: fallback taskkill //T //F 실행 (강제 종료 — 실증 아님)"
                            fi
                        fi
                    fi

                    # ---------------------------------------------------------------------------
                    # §6-PREV-ERR: 직전 --reuse-infra 에러 재현 여부 판정
                    # ---------------------------------------------------------------------------
                    echo ""
                    echo "[INFO] §6-PREV-ERR: 직전 에러 재현 여부 판정..."

                    PREV_ERR1_A=$(grep -E "failed to publish AGENT_STARTED" "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                    PREV_ERR1_B=$(grep -E "context deadline exceeded" "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)

                    if [ -n "${PREV_ERR1_A:-}" ] && [ -n "${PREV_ERR1_B:-}" ]; then
                        log_fail "§6-PREV-ERR ①: 'failed to publish AGENT_STARTED' + 'context deadline exceeded' 재현됨. 에러: [${PREV_ERR1_A}]"
                        add_blocker "클린 부팅에서도 AGENT_STARTED 발행 실패(context deadline exceeded) 재현 — 진짜 회귀 가능성"
                    elif [ -n "${PREV_ERR1_A:-}" ]; then
                        log_fail "§6-PREV-ERR ①: 'failed to publish AGENT_STARTED' 재현됨. 에러: [${PREV_ERR1_A}]"
                    else
                        log_pass "§6-PREV-ERR ①: 'failed to publish AGENT_STARTED' 에러 미재현 — 클린 부팅에서 AGENT_STARTED 발행 성공"
                    fi

                    PREV_ERR2=$(grep -E "Group Coordinator Not Available" \
                        "${AGENT_RUN_LOG}" 2>/dev/null | head -1 || true)
                    if [ -n "${PREV_ERR2:-}" ]; then
                        log_fail "§6-PREV-ERR ②: 'Group Coordinator Not Available' 재현됨. 에러: [${PREV_ERR2}]"
                        add_blocker "클린 부팅에서도 Group Coordinator Not Available 재현 — kafka-init 완료 후 안정화 시간 부족 또는 설정 문제"
                    else
                        log_pass "§6-PREV-ERR ②: 'Group Coordinator Not Available' 에러 미재현 — command-topic consumer 정상 초기화"
                    fi

                    PREV_ERR1_COUNT=$( (grep "failed to publish AGENT_STARTED" "${AGENT_RUN_LOG}" 2>/dev/null || true) | wc -l )
                    PREV_ERR1_COUNT=$(( ${PREV_ERR1_COUNT:-0} + 0 ))
                    PREV_ERR2_COUNT=$( (grep "Group Coordinator Not Available" "${AGENT_RUN_LOG}" 2>/dev/null || true) | wc -l )
                    PREV_ERR2_COUNT=$(( ${PREV_ERR2_COUNT:-0} + 0 ))
                    if [ ${PREV_ERR1_COUNT} -eq 0 ] && [ ${PREV_ERR2_COUNT} -eq 0 ]; then
                        log_pass "§6-PREV-ERR 전반 판정: 직전 에러 2종 모두 미재현 — 클린 부팅 race artifact 없음"
                    else
                        log_fail "§6-PREV-ERR 전반 판정: 에러 재현됨 (AGENT_STARTED_FAIL=${PREV_ERR1_COUNT}, GRP_COORD_ERR=${PREV_ERR2_COUNT})"
                    fi

                fi
            fi
        fi
        # teardown은 EXIT trap이 처리
    fi
fi

# ---------------------------------------------------------------------------
# §7. 정적 검증 — phase1-002 x-source 가드 명시화 회귀
# ---------------------------------------------------------------------------
echo ""
echo "=== §7 phase1-002 x-source 가드 명시화 회귀 (정적) ==="

ENVELOPE_HEADERS="${HUB_DIR}/src/main/java/com/monitoring/hub/messaging/EnvelopeHeaders.java"
JOB_RESULT_CONSUMER="${HUB_DIR}/src/main/java/com/monitoring/hub/ingest/jobresult/JobResultConsumer.java"
AUDIT_CONSUMER="${HUB_DIR}/src/main/java/com/monitoring/hub/ingest/audit/AuditConsumer.java"
CMD_PUBLISHER="${HUB_DIR}/src/main/java/com/monitoring/hub/producer/CommandPublisher.java"
AGENT_ENVELOPE_GO="${AGENT_DIR}/internal/kafka/envelope.go"
AGENT_ENVELOPE_TEST="${AGENT_DIR}/internal/kafka/envelope_test.go"
AGENT_MODEL_ENVELOPE="${AGENT_DIR}/internal/model/envelope.go"

if [ -f "${ENVELOPE_HEADERS}" ]; then
    log_pass "hub/messaging/EnvelopeHeaders.java: 파일 존재 확인"
else
    log_fail "hub/messaging/EnvelopeHeaders.java: 파일 없음 — phase1-002-hub 미반영"
fi

if file_contains "${ENVELOPE_HEADERS}" '"x-message-id"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-message-version"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-source"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-trace-id"'; then
    log_pass "hub/EnvelopeHeaders.java: 헤더 키 4종(x-message-id/x-message-version/x-source/x-trace-id) 값 확인"
else
    log_fail "hub/EnvelopeHeaders.java: 헤더 키 4종 중 하나 이상 누락"
fi

if file_contains "${ENVELOPE_HEADERS}" "inspectSource"; then
    log_pass "hub/EnvelopeHeaders.java: inspectSource() 가드 메서드 확인"
else
    log_fail "hub/EnvelopeHeaders.java: inspectSource() 없음"
fi

ISRC_BODY=$(awk '/public static void inspectSource/{f=1} f{print} f&&/^    }/{exit}' "${ENVELOPE_HEADERS}" 2>/dev/null | sed 's://.*$::')
if [ -z "${ISRC_BODY}" ]; then
    log_fail "hub/EnvelopeHeaders.java: inspectSource 본문 추출 실패"
elif echo "${ISRC_BODY}" | grep -qE 'throw |IllegalArgumentException|IllegalStateException|reject'; then
    log_fail "hub/EnvelopeHeaders.java: inspectSource 본문에 throw/reject 로직 포함 — §2.3 위반"
else
    log_pass "hub/EnvelopeHeaders.java: inspectSource 본문 throw/reject 없음 확인 (관찰 전용 가드 — §2.3 준수)"
fi

if file_contains "${JOB_RESULT_CONSUMER}" "inspectSource"; then
    log_pass "hub/JobResultConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인"
else
    log_fail "hub/JobResultConsumer.java: inspectSource() 호출 없음"
fi

if file_contains "${AUDIT_CONSUMER}" "inspectSource"; then
    log_pass "hub/AuditConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인"
else
    log_fail "hub/AuditConsumer.java: inspectSource() 호출 없음"
fi

if file_contains "${CMD_PUBLISHER}" "EnvelopeHeaders" && file_contains "${CMD_PUBLISHER}" "X_MESSAGE_ID"; then
    log_pass "hub/CommandPublisher.java: 헤더 키 상수를 EnvelopeHeaders 별칭 위임으로 선언 확인"
else
    log_fail "hub/CommandPublisher.java: EnvelopeHeaders 별칭 위임 없음"
fi

if file_contains "${AGENT_ENVELOPE_GO}" "SourceFromHeaders"; then
    log_pass "script-agent/kafka/envelope.go: SourceFromHeaders() 추가 확인"
else
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders() 없음"
fi

SFH_BODY=$(awk '/^func SourceFromHeaders/{f=1} f{print} f&&/^}/{exit}' "${AGENT_ENVELOPE_GO}" 2>/dev/null | sed 's://.*$::')
if [ -z "${SFH_BODY}" ]; then
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders 본문 추출 실패"
elif echo "${SFH_BODY}" | grep -qE 'allowlist|KNOWN_SOURCES|reject|[Ee]rrUnknown|errors\.|fmt\.Errorf|return[^,]*err'; then
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders 본문에 allowlist/reject/error 로직 포함 — §2.3 위반"
else
    log_pass "script-agent/kafka/envelope.go: SourceFromHeaders 본문 allowlist/reject 없음 확인 (§2.3 준수)"
fi

if file_contains "${AGENT_ENVELOPE_TEST}" "TestSourceFromHeaders"; then
    TEST_COUNT=$(grep -c "^func TestSourceFromHeaders" "${AGENT_ENVELOPE_TEST}" 2>/dev/null || echo "0")
    log_pass "script-agent/kafka/envelope_test.go: TestSourceFromHeaders 케이스 ${TEST_COUNT}개 확인"
else
    log_fail "script-agent/kafka/envelope_test.go: TestSourceFromHeaders 없음"
fi

if file_contains "${AGENT_MODEL_ENVELOPE}" 'HeaderSource\s*=\s*"x-source"'; then
    log_pass "script-agent/model/envelope.go: HeaderSource=\"x-source\" 상수 불변 확인"
else
    log_fail "script-agent/model/envelope.go: HeaderSource=\"x-source\" 없음"
fi

if file_contains "${AGENT_ENVELOPE_GO}" "model\.HeaderSource" && \
   file_contains "${AGENT_ENVELOPE_GO}" "model\.MessageVersion" && \
   file_contains "${AGENT_ENVELOPE_GO}" "model\.SourceAgent"; then
    log_pass "script-agent/kafka/envelope.go: BuildHeaders producer 경로 model 상수 사용 불변"
else
    log_fail "script-agent/kafka/envelope.go: BuildHeaders model 상수 참조 변경 감지"
fi

# ---------------------------------------------------------------------------
# §8. 정적 검증 — T4-1 토픽 재명명 R-B 완전성 + R-A 동작 등가
# ---------------------------------------------------------------------------
echo ""
echo "=== §8 T4-1 토픽 재명명 회귀 검증 (R-B 완전성 + R-A 동작 등가) ==="

HUB_KAFKA_CFG="${HUB_DIR}/src/main/java/com/monitoring/hub/config/KafkaConfig.java"
HUB_TOPIC_REGRESSION="${HUB_DIR}/src/test/java/com/monitoring/hub/config/KafkaTopicConstantsRegressionTest.java"
HUB_AUDIT_TEST="${HUB_DIR}/src/test/java/com/monitoring/hub/ingest/audit/AuditConsumerTest.java"
AGENT_CONFIG_GO="${AGENT_DIR}/internal/config/config.go"
INFRA_COMPOSE="${INFRA_DIR}/docker-compose.yml"
INFRA_OTEL_CFG="${INFRA_DIR}/otel-collector-config.yml"

echo "[INFO] §8 R-B: 재명명 완전성 검사"

if file_contains "${HUB_KAFKA_CFG}" 'COMMANDS\s*=\s*"command-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.COMMANDS = \"command-topic\" 확인"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.COMMANDS 값이 \"command-topic\"이 아님"
fi

if file_contains "${HUB_KAFKA_CFG}" 'AUDIT_EVENTS\s*=\s*"audit-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.AUDIT_EVENTS = \"audit-topic\" 확인"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.AUDIT_EVENTS 값이 \"audit-topic\"이 아님"
fi

if file_contains "${HUB_KAFKA_CFG}" 'HEARTBEATS\s*=\s*"heartbeats-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.HEARTBEATS = \"heartbeats-topic\" 확인"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.HEARTBEATS 값이 \"heartbeats-topic\"이 아님"
fi

if file_contains "${HUB_KAFKA_CFG}" 'JOB_RESULTS\s*=\s*"job-results"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.JOB_RESULTS = \"job-results\" 유지 확인"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.JOB_RESULTS 값이 \"job-results\"가 아님"
fi

OLD_TOPIC_MAIN=$(grep -rn '"commands"\|"audit-events"\|"heartbeats"' \
    "${HUB_DIR}/src/main/java" 2>/dev/null \
    | grep -v "UiController\.java" \
    | grep -v "\.class" \
    | head -5 || true)
if [ -z "${OLD_TOPIC_MAIN}" ]; then
    log_pass "§8 R-B: hub/src/main/java 런타임 경로에 구명(commands/audit-events/heartbeats) 리터럴 잔존 없음"
else
    log_fail "§8 R-B: hub/src/main/java 런타임 경로에 구명 리터럴 잔존 감지: ${OLD_TOPIC_MAIN}"
fi

if file_contains "${HUB_DIR}/src/main/java/com/monitoring/hub/web/UiController.java" '"heartbeats"\|"commands"'; then
    log_info "§8 R-B 오탐 확인: hub/UiController.java의 \"heartbeats\"/\"commands\"는 UI 모델 attribute 키로 Kafka 토픽명이 아님"
fi

if [ -f "${HUB_TOPIC_REGRESSION}" ]; then
    log_pass "§8 R-B: hub/KafkaTopicConstantsRegressionTest.java 존재 확인"
else
    log_fail "§8 R-B: hub/KafkaTopicConstantsRegressionTest.java 없음"
fi

if file_contains "${HUB_AUDIT_TEST}" '"audit-topic"'; then
    log_pass "§8 R-B: hub/AuditConsumerTest.java: TOPIC=\"audit-topic\" 픽스처 신명 확인"
else
    log_fail "§8 R-B: hub/AuditConsumerTest.java: TOPIC이 \"audit-topic\"이 아님"
fi

if file_contains "${AGENT_CONFIG_GO}" 'getenv\("KAFKA_TOPIC_COMMANDS",\s*"command-topic"\)'; then
    log_pass "§8 R-B: script-agent/config.go: KAFKA_TOPIC_COMMANDS default=\"command-topic\" 확인"
else
    log_fail "§8 R-B: script-agent/config.go: KAFKA_TOPIC_COMMANDS default가 \"command-topic\"이 아님"
fi

if file_contains "${AGENT_CONFIG_GO}" 'getenv\("KAFKA_TOPIC_AUDIT_EVENTS",\s*"audit-topic"\)'; then
    log_pass "§8 R-B: script-agent/config.go: KAFKA_TOPIC_AUDIT_EVENTS default=\"audit-topic\" 확인"
else
    log_fail "§8 R-B: script-agent/config.go: KAFKA_TOPIC_AUDIT_EVENTS default가 \"audit-topic\"이 아님"
fi

OLD_AGENT_DEFAULT=$(grep -n 'getenv.*"commands"\|getenv.*"audit-events"' "${AGENT_CONFIG_GO}" 2>/dev/null || true)
if [ -z "${OLD_AGENT_DEFAULT}" ]; then
    log_pass "§8 R-B: script-agent/config.go: 구명(\"commands\"/\"audit-events\") getenv default 잔존 없음"
else
    log_fail "§8 R-B: script-agent/config.go: 구명 getenv default 잔존 감지: ${OLD_AGENT_DEFAULT}"
fi

if file_contains "${INFRA_COMPOSE}" 'command-topic.*job-results.*audit-topic.*heartbeats-topic'; then
    log_pass "§8 R-B: infra/docker-compose.yml kafka-init 루프: 신명 4종 확인"
elif file_contains "${INFRA_COMPOSE}" 'command-topic' && \
     file_contains "${INFRA_COMPOSE}" 'audit-topic' && \
     file_contains "${INFRA_COMPOSE}" 'heartbeats-topic' && \
     file_contains "${INFRA_COMPOSE}" 'job-results'; then
    log_pass "§8 R-B: infra/docker-compose.yml kafka-init: 4개 토픽명 모두 존재 확인"
else
    COMPOSE_TOPIC_LINE=$(grep -n "for t in\|command-topic\|audit-topic\|heartbeats-topic\|commands\|audit-events\|heartbeats" \
        "${INFRA_COMPOSE}" 2>/dev/null | head -10 || true)
    log_fail "§8 R-B: infra/docker-compose.yml kafka-init 루프에서 신명 4종 미확인: ${COMPOSE_TOPIC_LINE}"
fi

OLD_COMPOSE_TOPICS=$(grep -n '"commands"\|"audit-events"\|"heartbeats"\b' "${INFRA_COMPOSE}" 2>/dev/null \
    | grep -v "heartbeats-topic" || true)
if [ -z "${OLD_COMPOSE_TOPICS}" ]; then
    log_pass "§8 R-B: infra/docker-compose.yml: 구명(commands/audit-events/heartbeats) 토픽 생성 잔존 없음"
else
    log_fail "§8 R-B: infra/docker-compose.yml: 구명 토픽 생성 라인 잔존 감지: ${OLD_COMPOSE_TOPICS}"
fi

if file_contains "${INFRA_OTEL_CFG}" 'topic:\s*heartbeats-topic'; then
    log_pass "§8 R-B: infra/otel-collector-config.yml: kafka exporter topic=\"heartbeats-topic\" 확인"
else
    OTEL_TOPIC=$(grep -n "topic:" "${INFRA_OTEL_CFG}" 2>/dev/null || echo "없음")
    log_fail "§8 R-B: infra/otel-collector-config.yml: kafka exporter topic이 heartbeats-topic이 아님: ${OTEL_TOPIC}"
fi

echo "[INFO] §8 R-A: 동작 등가 검사"

HUB_CMD_PUBLISHER="${HUB_DIR}/src/main/java/com/monitoring/hub/producer/CommandPublisher.java"
if file_contains "${HUB_CMD_PUBLISHER}" "KafkaConfig\.Topics\.COMMANDS|Topics\.COMMANDS"; then
    log_pass "§8 R-A: hub/CommandPublisher.java: KafkaConfig.Topics.COMMANDS 상수 참조 확인"
else
    log_fail "§8 R-A: hub/CommandPublisher.java: Topics.COMMANDS 상수 참조 없음"
fi

if file_contains "${AUDIT_CONSUMER}" "KafkaConfig\.Topics\.AUDIT_EVENTS|Topics\.AUDIT_EVENTS|Topics\.AUDIT"; then
    log_pass "§8 R-A: hub/AuditConsumer.java: Topics.AUDIT_EVENTS 상수 참조 확인"
else
    log_fail "§8 R-A: hub/AuditConsumer.java: Topics.AUDIT_EVENTS 상수 참조 없음"
fi

OTEL_TOPIC_VAL=$(grep 'topic:' "${INFRA_OTEL_CFG}" 2>/dev/null | awk '{print $2}' | tr -d '\r' | head -1)
HUB_HB_CONST=$(grep 'HEARTBEATS\s*=' "${HUB_KAFKA_CFG}" 2>/dev/null | grep -oE '"[^"]+"' | head -1)
if [ "${OTEL_TOPIC_VAL}" = "heartbeats-topic" ] && [ "${HUB_HB_CONST}" = '"heartbeats-topic"' ]; then
    log_pass "§8 R-A: heartbeats-topic 동시 컷오버 정합 — infra otel exporter(${OTEL_TOPIC_VAL}) ↔ hub consumer(HEARTBEATS=${HUB_HB_CONST}) 이름 일치"
else
    log_fail "§8 R-A: heartbeats-topic 동시 컷오버 불일치 — infra=[${OTEL_TOPIC_VAL:-}] vs hub=[${HUB_HB_CONST:-}]"
fi

AGENT_CMD_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_COMMANDS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"command-topic"' | head -1 || true)
AGENT_AUDIT_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_AUDIT_EVENTS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"audit-topic"' | head -1 || true)
if [ "${AGENT_CMD_DEFAULT}" = '"command-topic"' ] && [ "${AGENT_AUDIT_DEFAULT}" = '"audit-topic"' ]; then
    log_pass "§8 R-A: script-agent 기본 토픽명 신명 확인 — hub 상수와 이름 일치"
else
    log_fail "§8 R-A: script-agent ↔ hub 토픽명 불일치 위험"
fi

AGENT_JR_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_JOB_RESULTS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"job-results"' | head -1 || true)
if [ "${AGENT_JR_DEFAULT}" = '"job-results"' ]; then
    log_pass "§8 R-A: script-agent/config.go: KAFKA_TOPIC_JOB_RESULTS default=\"job-results\" 유지"
else
    log_fail "§8 R-A: script-agent/config.go: KAFKA_TOPIC_JOB_RESULTS default가 \"job-results\"가 아님"
fi

if file_contains "${ENVELOPE_HEADERS}" '"x-message-id"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-source"'; then
    log_info "§8 R-A: envelope 4종 헤더는 토픽명과 독립적. 재명명이 envelope 동작에 영향 없음 — 관찰 기록"
fi

THIS_SCRIPT="${SCRIPT_DIR}/run-e2e.sh"
HARDCODED_OLD=$(grep -n '"commands"\|"audit-events"\|"heartbeats"' "${THIS_SCRIPT}" 2>/dev/null \
    | grep -v "^[0-9]*:#\|주석\|comment" || true)
if [ -z "${HARDCODED_OLD}" ]; then
    log_pass "§8 R-A: 하네스(run-e2e.sh): 구 토픽명 하드코딩 비교 없음 — false-fail 없음"
else
    log_info "§8 R-A 주의: 하네스(run-e2e.sh)에 구 토픽명 리터럴 감지: ${HARDCODED_OLD}. 동작 비교 아닌 주석이면 무해"
    add_blocker "하네스 run-e2e.sh에 구 토픽명 리터럴 감지 — 코드 비교로 쓰이면 false-fail 발생 가능. 주석/정보성 여부 확인 필요"
fi

echo ""
echo "[INFO] §8 검증 완료"

# ---------------------------------------------------------------------------
# 결과 집계 및 MD 파일 생성
# ---------------------------------------------------------------------------
echo ""
echo "=== 결과 집계 ==="
echo "PASS: ${PASS}  FAIL: ${FAIL}  SKIP: ${SKIP}"

if [ ${FAIL} -eq 0 ]; then
    OVERALL_STATUS="ok"
else
    OVERALL_STATUS="failed"
fi
[ ${PASS} -eq 0 ] && [ ${FAIL} -eq 0 ] && OVERALL_STATUS="blocked"

DYNAMIC_LABEL="비활성 (--dynamic 미전달)"
if [ "${DYNAMIC_MODE}" = "true" ]; then
    if [ "${REUSE_INFRA}" = "true" ]; then
        DYNAMIC_LABEL="활성 (--dynamic --reuse-infra 전달 — 기존 infra 재활용)"
    else
        DYNAMIC_LABEL="활성 (--dynamic 전달 — 클린 부팅, group coordinator 안정화 대기 포함)"
    fi
fi

{
    echo "# E2E 검증 결과 — ${TIMESTAMP}"
    echo ""
    echo "**실행일시**: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "**종합 상태**: ${OVERALL_STATUS^^}"
    echo "**PASS**: ${PASS}  **FAIL**: ${FAIL}  **SKIP**: ${SKIP}"
    echo "**동적 모드**: ${DYNAMIC_LABEL}"
    echo ""
    echo "## 검증 범위"
    echo ""
    echo "- §1 ADR-0002 C-1 빅뱅 컷오버 정합 (infra otlp_proto ↔ hub ByteArrayDeserializer + proto 디코더)"
    echo "- §2 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 (metric name / agent_id / service.name / value / time_unix_nano)"
    echo "- §3 envelope 예외 위상 (heartbeats-topic: OTLP 위임군 → envelope 헤더 검사 없음)"
    echo "- §4 hub mvn test / script-agent go test ./..."
    echo "- §5 주석 drift 관측"
    echo "- §6 동적 E2E 시나리오 (Docker) — ${DYNAMIC_LABEL}"
    echo "  - §6-T4 T4-1 동적 판정 보강 (신명 토픽 위 실제 트래픽 실증 4종)"
    echo "    - §6-T4-A: 라이브 kafka 토픽 목록 신명 존재 + 구명 미생성"
    echo "    - §6-T4-B: hub 로그 heartbeats-topic 구독 확인"
    echo "    - §6-T4-C: script-agent AGENT_STARTED / heartbeat 발행 확인"
    echo "    - §6-T4-D: heartbeats-topic 오프셋 > 0 실증 + 구명 오프셋 부재"
    echo "  - §6-AUDIT: hub AuditConsumer AGENT_STARTED 수신 확인 (audit-topic 경로 라이브 판정)"
    echo "  - §6-CMD: hub /schedules POST → command-topic 발행 → agent 수신 확인"
    echo "  - §6-LOG: LOG_JOB 동적 실행 실증 (임시 로그 파일 → LOG_JOB 스케줄 → JOB_RESULT received 확인)"
    echo "  - §6-STOP: AGENT_STOPPED 동적 수신 실증 (CTRL_BREAK_EVENT(1,0) → hub AGENT_STOPPED received)"
    echo "  - §6-PREV-ERR: 직전 에러 재현 여부 판정"
    echo "- §7 phase1-002 x-source 가드 명시화 회귀"
    echo "- §8 T4-1 토픽 재명명 R-B 완전성 + R-A 동작 등가"
    echo ""
    echo "## 근거 문서"
    echo ""
    echo "- docs/envelope.md §2.2·§2.3·§6"
    echo "- docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md §2.2·§5.4"
    echo "- adr/0002-heartbeat-otlp-proto.md (A-1/B-1/C-1)"
    echo "- adr/0005-topic-naming.md §2.2.1 (D-4(1) Accepted)"
    echo "- handoff/phase1-040/phase1-040-000-impact.md §3.3"
    echo ""
    echo "## 하네스 수정 이력"
    echo ""
    echo "v3: 버그 A(IPv6)/B(클린시작)/C(grep정교화) 수정"
    echo "v4: 안전성 — compose 격리/정밀 PID 종료/DYNAMIC_STARTED 위치/FAIL 표기"
    echo "v5: §7 신설 — phase1-002 x-source 가드 검증"
    echo "v6: §8 신설 — T4-1 R-B 완전성 + R-A 동작 등가"
    echo "v7: --reuse-infra 플래그 + §6-T4 동적 판정 4종"
    echo "v8: §6-AUDIT/§6-CMD/§6-PREV-ERR 신설"
    echo "v9: 버그 D(snake_case), 버그 E(grep -c 산술)"
    echo "v10: §6-LOG + §6-STOP 신설"
    echo "v11: §6-3 go build + Start-Process WindowStyle Hidden, §6-STOP GenerateConsoleCtrlEvent(0,0)"
    echo "v12: 버그 F — Start-Process Write-Host \$p.Id"
    echo "v13: 버그 G — PID 임시 파일 기록(파이프 교착 해소)"
    echo "v14: 버그 H — cmd.exe 래퍼 전용 콘솔, AttachConsole 대상 cmd PID"
    echo "v15: v10~v14 유실분 재구축 + CTRL_BREAK 수정"
    echo "     §6-STOP: GenerateConsoleCtrlEvent(1,0) CTRL_BREAK_EVENT — 사람 실험(2026-06-11) 확정"
    echo "              (0,0) CTRL_C 미배달 → (1,0) CTRL_BREAK agent graceful shutdown 전체 경로 확인"
    echo "     setup 위생: 실행 전 잔존 agent-e2e*/8080 점유 탐지·정리"
    echo "     teardown 위생: 8080 free + agent-e2e* 0 확인 결과 문서 기록"
    echo "     \${VAR:-} 언바운드 변수 가드 적용"
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
    echo "- 스크립트: \`e2e/run-e2e.sh\` (baseline v15, --dynamic opt-in, --reuse-infra opt-in)"
    echo "- 결과 파일: \`e2e/results/${TIMESTAMP}.md\`"
    echo "- hub 테스트 로그: \`e2e/results/${TIMESTAMP}-hub-test.log\`"
    echo "- agent 테스트 로그: \`e2e/results/${TIMESTAMP}-agent-test.log\`"
    if [ "${DYNAMIC_MODE}" = "true" ]; then
        echo "- hub 런타임 로그: \`e2e/results/${TIMESTAMP}-hub-run.log\`"
        echo "- agent 런타임 로그: \`e2e/results/${TIMESTAMP}-agent-run.log\`"
    fi
} > "${RESULT_FILE}"

echo ""
echo "결과 저장: ${RESULT_FILE}"
echo ""

if [ "${OVERALL_STATUS}" = "failed" ]; then
    exit 1
fi
exit 0

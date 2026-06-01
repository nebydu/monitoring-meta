#!/usr/bin/env bash
# run-e2e.sh — monitoring polyrepo 종단 검증 스크립트 (baseline v4)
#
# 검증 범위:
#   1. [정적] ADR-0002 컷오버 C-1 정합 — infra(otlp_proto)·hub(ByteArrayDeserializer·proto 디코더) 동시 전환 확인
#   2. [정적] 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 확인
#   3. [정적] envelope 예외 위상 — heartbeats에 envelope 헤더 검사 없음 확인
#   4. [유닛] hub mvn test / script-agent go test ./... 실행 후 결과 기록
#   5. [주석 drift] 관측 기록
#   6. [동적 — --dynamic 인자 전달 시만 실행] infra 기동 → hub run → script-agent run
#             → heartbeat 수신 확인 (PASS 조건: Spring Kafka DEBUG 실제 레코드 수신 라인 출현 +
#                failed to decode / no agent.heartbeat data points 부재)
#
# v3 변경사항 (하네스 버그 3건 수정):
#   - 버그 A (IPv6 우회): script-agent 기동 시 OTLP_ENDPOINT/KAFKA_BROKERS를 127.0.0.1로 명시
#   - 버그 B (kafka 클린 시작): up -d 전 down -v 실행으로 잔존 볼륨/메시지 제거
#   - 버그 C (grep 오인 매칭): 초기화 로그 제외, 실제 ConsumerRecord 수신 라인
#     (ntainer#1-0-C-1.*KafkaMessageListenerContainer.*Received: [1-9])만 양성으로 판정
#
# v4 변경사항 (코드 리뷰 반영 — 안전성):
#   - ① compose 프로젝트를 'monitoring-e2e'로 격리 → down -v가 형제 infra 볼륨 불간섭
#   - ② 무차별 종료 제거 → hub=/health 시점 8080 소유 PID, agent=기동 후 신규 agent.exe PID만 정밀 종료
#   - ③ DYNAMIC_STARTED를 up -d 직전에 설정 → 부분 실패 시에도 trap이 infra 정리
#   - ④ Docker 불가 메시지를 FAIL 의미로 정정(SKIP 표기 제거)
#
# 사용:
#   ./run-e2e.sh            # 정적+유닛만 (§1~§5)
#   ./run-e2e.sh --dynamic  # 정적+유닛+실제 동적 기동 (§1~§6)
#
# 규칙:
#   - 실패 시 코드를 고치지 않는다 — 로그만 기록하고 종료한다.
#   - 형제 repo(../hub, ../script-agent, ../infra)는 절대 수정하지 않는다.
#   - script-agent 상태 파일(.agent_id/.agent_state)은 e2e/.run-tmp/로 우회한다.
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
# 인자 파싱
# ---------------------------------------------------------------------------
DYNAMIC_MODE=false
for arg in "$@"; do
    case "$arg" in
        --dynamic) DYNAMIC_MODE=true ;;
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
# §6. 동적 검증 — --dynamic 인자 있을 때만 실제 기동
# ---------------------------------------------------------------------------
echo ""
echo "=== §6 동적 검증 (Docker) ==="

# 동적 모드가 아닐 경우 SKIP
if [ "${DYNAMIC_MODE}" = "false" ]; then
    log_skip "동적 E2E 기동 시나리오: --dynamic 인자 없음 — 정적+유닛 검증만 수행. 동적 기동은 --dynamic 인자 전달 시 실행됨."
else
    # --dynamic 모드: 실제 기동 오케스트레이션
    echo "[INFO] --dynamic 모드 활성 — 실제 인프라/서비스 기동 시작"

    # Docker 가용성 확인
    if ! docker info --format "{{.ServerVersion}}" > /dev/null 2>&1; then
        log_fail "Docker 데몬 불가 — --dynamic 모드는 Docker 필수이므로 동적 검증 수행 불가(FAIL)."
    else
        DOCKER_VER=$(docker info --format "{{.ServerVersion}}" 2>/dev/null)
        log_info "Docker 데몬 가용 (버전: ${DOCKER_VER})"

        # 임시 작업 폴더 — script-agent 상태 파일 우회용
        RUN_TMP="${SCRIPT_DIR}/.run-tmp"
        mkdir -p "${RUN_TMP}/state"

        HUB_RUN_LOG="${RESULTS_DIR}/${TIMESTAMP}-hub-run.log"
        AGENT_RUN_LOG="${RESULTS_DIR}/${TIMESTAMP}-agent-run.log"
        COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"

        # [수정 ①] 형제 infra(기본 compose 프로젝트명 'infra')의 볼륨을 건드리지 않도록
        # E2E 전용 프로젝트명으로 격리한다. 이로써 down -v는 이 e2e 스택의 볼륨만 삭제하고
        # 개발자가 따로 띄운 infra 프로젝트의 데이터는 절대 건드리지 않는다.
        # (단 호스트 포트 9092/14318은 공유 — 기존 infra가 가동 중이면 포트 충돌로 기동 실패할 수 있음.)
        E2E_PROJECT="monitoring-e2e"
        dc() { docker compose -p "${E2E_PROJECT}" -f "${COMPOSE_FILE}" "$@"; }

        HUB_PID=""
        AGENT_PID=""
        HUB_APP_WINPID=""     # /health 시점의 8080 소유 PID(=이번 run의 hub) — teardown 정밀 종료용
        AGENT_APP_WINPID=""   # 기동 후 새로 등장한 agent.exe PID(=이번 run의 agent) — teardown 정밀 종료용
        DYNAMIC_STARTED=false

        # ── Windows 프로세스 종료 헬퍼 (Git Bash/MSYS) ──
        # $!는 MSYS PID라 `kill`은 그 PID만 죽이고, mvn/go run이 fork한 실제
        # JVM(HubApplication)·agent.exe는 트리·재부모화로 살아남는다(→ 8080 점유 잔존).
        # 그래서 (a) launcher 트리는 win_tree_kill로 정리하고, (b) 실제 앱은 기동 시점에
        # 포착한 그 PID만 정밀 종료한다([수정 ②] — 임의 동명/동포트 프로세스 무차별 종료 방지).

        # launcher(서브셸/mvn/go run) 트리 종료: /proc/<msys_pid>/winpid → taskkill //T
        win_tree_kill() {
            local msys_pid="$1"
            [ -z "${msys_pid}" ] && return 0
            local winpid
            winpid=$(cat "/proc/${msys_pid}/winpid" 2>/dev/null || true)
            if [ -n "${winpid}" ]; then
                taskkill //PID "${winpid}" //T //F >/dev/null 2>&1 || true
            fi
            kill "${msys_pid}" 2>/dev/null || true
        }

        # 특정 포트를 LISTEN 중인 PID 1개 반환(없으면 빈 문자열) — '우리 hub' 식별용.
        resolve_port_owner() {
            powershell -NoProfile -Command \
                "(Get-NetTCPConnection -LocalPort $1 -State Listen -ErrorAction SilentlyContinue).OwningProcess" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | head -1 || true
        }

        # 현재 살아있는 agent.exe(이미지명) PID 목록을 공백 구분으로 반환 — 신규 PID diff용.
        list_agent_pids() {
            powershell -NoProfile -Command \
                "(Get-Process agent -ErrorAction SilentlyContinue).Id" \
                2>/dev/null | tr -d '\r' | grep -E '^[0-9]+$' | tr '\n' ' ' || true
        }

        # teardown — EXIT trap에 등록 (어떤 실패에서도 정리 보장)
        teardown() {
            echo "[INFO] teardown 시작..."
            # agent: 이번 run이 포착한 실제 바이너리 PID만 정밀 종료 + launcher 트리 ([수정 ②])
            if [ -n "${AGENT_APP_WINPID}" ]; then
                taskkill //PID "${AGENT_APP_WINPID}" //T //F >/dev/null 2>&1 || true
            fi
            if [ -n "${AGENT_PID}" ]; then
                win_tree_kill "${AGENT_PID}"
                echo "[INFO] script-agent 종료 (app winpid=${AGENT_APP_WINPID:-none})"
            fi
            # hub: /health 시점에 포착한 8080 소유 PID(=이번 run hub)만 종료 + launcher 트리 ([수정 ②])
            if [ -n "${HUB_APP_WINPID}" ]; then
                taskkill //PID "${HUB_APP_WINPID}" //T //F >/dev/null 2>&1 || true
            fi
            if [ -n "${HUB_PID}" ]; then
                win_tree_kill "${HUB_PID}"
                echo "[INFO] hub 종료 (app winpid=${HUB_APP_WINPID:-none})"
            fi
            # infra: e2e 전용 프로젝트만 정리 — 형제 infra 볼륨 불간섭 ([수정 ①])
            if [ "${DYNAMIC_STARTED}" = "true" ]; then
                echo "[INFO] infra(${E2E_PROJECT}) docker compose down -v ..."
                dc down -v 2>/dev/null || true
            fi
            # 임시 폴더 삭제
            rm -rf "${RUN_TMP}" 2>/dev/null || true
            echo "[INFO] teardown 완료"
        }
        trap teardown EXIT

        # §6-1: kafka 클린 시작 — e2e 전용 프로젝트의 잔존 볼륨/메시지만 제거 후 기동
        # [버그 B 수정 + 수정 ①] dc()로 e2e 전용 프로젝트에 한정 → 형제 infra 볼륨 불간섭
        echo "[INFO] §6-1: 이전 e2e 세션 정리 (${E2E_PROJECT} down -v)..."
        dc down -v 2>&1 || true
        log_info "클린 시작: e2e 전용 kafka 볼륨/토픽 제거 완료 — offset 0부터 시작 예정"

        # [수정 ③] up 호출 '직전'부터 cleanup 대상으로 표시 — up이 일부 컨테이너만 만들고
        # 실패(set -e 종료)해도 trap teardown이 DYNAMIC_STARTED=true를 보고 down -v로 정리한다.
        echo "[INFO] §6-1: infra docker compose up -d (${E2E_PROJECT})..."
        DYNAMIC_STARTED=true
        dc up -d 2>&1

        # kafka healthy 대기 (healthcheck interval=5s, retries=12, start_period=10s → 최대 90s)
        echo "[INFO] kafka healthy 대기 (최대 90s)..."
        KAFKA_WAIT=0
        KAFKA_READY=false
        while [ ${KAFKA_WAIT} -lt 90 ]; do
            # docker inspect 방식으로 체크
            KAFKA_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' \
                "$(dc ps -q kafka 2>/dev/null)" 2>/dev/null || echo "unknown")
            if [ "${KAFKA_HEALTH}" = "healthy" ]; then
                KAFKA_READY=true
                log_info "kafka healthy 확인 (${KAFKA_WAIT}s 경과)"
                break
            fi
            sleep 5
            KAFKA_WAIT=$((KAFKA_WAIT + 5))
        done

        if [ "${KAFKA_READY}" = "false" ]; then
            log_fail "kafka가 90s 내 healthy 상태 미도달 — 동적 검증 중단"
            # teardown은 trap이 처리
        else
            # §6-2: hub 기동 (DEBUG 레벨 env로 켜기, hub kafka는 localhost 그대로 — JVM IPv4 선호)
            echo "[INFO] §6-2: hub 기동 (spring-boot:run + DEBUG env)..."
            (
                cd "${HUB_DIR}"
                LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_KAFKA=DEBUG \
                LOGGING_LEVEL_COM_MONITORING_HUB_INGEST_HEARTBEAT=DEBUG \
                mvn spring-boot:run --no-transfer-progress 2>&1
            ) > "${HUB_RUN_LOG}" 2>&1 &
            HUB_PID=$!
            log_info "hub PID=${HUB_PID}, 로그=${HUB_RUN_LOG}"

            # hub /health 폴링 (최대 120s — Spring 부팅+mvn)
            echo "[INFO] hub /health 폴링 (최대 120s)..."
            HUB_WAIT=0
            HUB_READY=false
            while [ ${HUB_WAIT} -lt 120 ]; do
                if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
                    HUB_READY=true
                    log_info "hub /health 응답 확인 (${HUB_WAIT}s 경과)"
                    # [수정 ②] 지금 8080을 LISTEN 중인 PID = 방금 우리가 띄운 hub.
                    # 이 PID만 teardown에서 정밀 종료한다(임의 8080 점유 프로세스 무차별 종료 방지).
                    HUB_APP_WINPID="$(resolve_port_owner 8080)"
                    if [ -n "${HUB_APP_WINPID}" ]; then
                        log_info "hub 앱 winpid=${HUB_APP_WINPID} (8080 소유 — teardown 정밀 종료 대상)"
                    fi
                    break
                fi
                # hub 프로세스가 죽었는지 확인
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
                # §6-3: script-agent 기동
                # [버그 A 수정] localhost → 127.0.0.1 명시로 Go IPv6([::1]) 해석 우회
                # [수정 ②] 기동 전 기존 agent.exe PID 집합을 기록 → 기동 후 새로 등장한
                # PID만 '이번 run이 띄운 agent'로 식별(무관한 agent.exe 무차별 종료 방지).
                AGENT_PIDS_BEFORE="$(list_agent_pids)"
                echo "[INFO] §6-3: script-agent 기동 (OTLP=http://127.0.0.1:14318, KAFKA=127.0.0.1:9092, interval=2s)..."
                (
                    cd "${AGENT_DIR}"
                    OTLP_ENDPOINT=http://127.0.0.1:14318 \
                    KAFKA_BROKERS=127.0.0.1:9092 \
                    HEARTBEAT_INTERVAL_SECONDS=2 \
                    AGENT_ID_PATH="${RUN_TMP}/.agent_id" \
                    LOG_STATE_DIR="${RUN_TMP}/state" \
                    go run ./cmd/agent 2>&1
                ) > "${AGENT_RUN_LOG}" 2>&1 &
                AGENT_PID=$!
                log_info "script-agent PID=${AGENT_PID}, 로그=${AGENT_RUN_LOG}"

                # [수정 ②] go run이 컴파일·fork한 실제 agent.exe(재부모화돼 launcher 종료로는
                # 안 죽음)의 PID를 포착 — 기동 전 집합에 없던 새 PID만 우리 것으로 식별.
                ACAP=0
                while [ ${ACAP} -lt 20 ]; do
                    for p in $(list_agent_pids); do
                        case " ${AGENT_PIDS_BEFORE} " in
                            *" ${p} "*) ;;
                            *) AGENT_APP_WINPID="${p}" ;;
                        esac
                    done
                    if [ -n "${AGENT_APP_WINPID}" ]; then break; fi
                    sleep 2; ACAP=$((ACAP + 2))
                done
                if [ -n "${AGENT_APP_WINPID}" ]; then
                    log_info "script-agent 앱 winpid=${AGENT_APP_WINPID} (teardown 정밀 종료 대상)"
                fi

                # §6-4: 판정 — hub-run.log 폴링 (최대 75s)
                # PASS 조건:
                #   (1) heartbeats 토픽 실제 레코드 수신 라인 출현
                #       패턴: ntainer#1-0-C-1 스레드에서 KafkaMessageListenerContainer가 출력한
                #       "Received: N records" (N >= 1). 클린 시작이므로 최초 수신은 agent 발행분.
                #       제외: KafkaListenerAnnotationBeanPostProcessor / partitions assigned /
                #              Subscribed to topic / 0 records (빈 poll)
                #   (2) "failed to decode heartbeat payload" WARN 부재
                #   (3) "no agent.heartbeat data points" DEBUG 부재
                #
                # [버그 C 수정] 기존 grep이 초기화 라인에 오인 매칭하던 문제 해결:
                #   - 실제 레코드 수신: "ntainer#1-0-C-1.*KafkaMessageListenerContainer.*Received: [1-9]"
                #   - 클린 시작 후 agent agent 가 보낸 메시지만 수신되므로 N>=1이면 실제 수신
                echo "[INFO] §6-4: hub 로그 폴링으로 heartbeat 수신 판정 (최대 75s)..."
                POLL_WAIT=0
                HEARTBEAT_RECEIVED=false
                RECV_LINE=""
                while [ ${POLL_WAIT} -lt 75 ]; do
                    # ntainer#1-0-C-1: heartbeats 컨테이너 스레드 (경험적 확인)
                    # "Received: N records" (N>=1) 라인만 양성
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
                    # 부재 조건 확인
                    # [버그 수정] grep -c는 매치 0건일 때 "0"을 출력하면서 exit 1을 반환한다.
                    # 기존 `|| echo "0"`는 grep이 찍은 "0"에 더해 한 번 더 "0"을 찍어
                    # 변수값이 "0\n0"(멀티라인)이 되고 정상 비교가 깨졌다.
                    # `|| true`로 exit 0만 보장하면 grep이 출력한 단일 "0"이 그대로 들어간다.
                    DECODE_FAIL=$(grep -c "failed to decode heartbeat payload" "${HUB_RUN_LOG}" 2>/dev/null || true)
                    NO_DATAPOINTS=$(grep -c "no agent.heartbeat data points" "${HUB_RUN_LOG}" 2>/dev/null || true)
                    DECODE_FAIL=${DECODE_FAIL:-0}
                    NO_DATAPOINTS=${NO_DATAPOINTS:-0}

                    if [ "${DECODE_FAIL}" = "0" ] && [ "${NO_DATAPOINTS}" = "0" ]; then
                        log_pass "§6 동적 E2E: heartbeat 수신 + 디코드 성공 확인. 수신 라인: [${RECV_LINE}]"
                        # 보조 코로보레이션: hub UI agent ONLINE 확인 (판정 게이트 아님)
                        UI_CHECK=$(curl -sf http://localhost:8080/ 2>/dev/null | grep -i "ONLINE\|online" | head -1 || true)
                        if [ -n "${UI_CHECK}" ]; then
                            log_info "코로보레이션: hub UI(/)에서 ONLINE 상태 감지 — [${UI_CHECK}]"
                        else
                            log_info "코로보레이션: hub UI(/) ONLINE 상태 미감지 (판정 게이트 아님)"
                        fi
                    else
                        log_fail "§6 동적 E2E: heartbeat 수신됐으나 디코드 실패 감지. decode_fail=${DECODE_FAIL}, no_datapoints=${NO_DATAPOINTS}. 수신 라인: [${RECV_LINE}]"
                        # 관련 로그 라인 기록
                        FAIL_LINES=$(grep -E "failed to decode|no agent.heartbeat" "${HUB_RUN_LOG}" 2>/dev/null | head -5 || true)
                        log_info "디코드 실패 로그: ${FAIL_LINES}"
                    fi
                else
                    log_fail "§6 동적 E2E: 75s 내 heartbeats 토픽 실제 레코드 수신 라인 미출현 — timeout"
                    # 진단용 로그 tail
                    HUB_LAST=$(tail -15 "${HUB_RUN_LOG}" 2>/dev/null || echo "로그 없음")
                    AGENT_LAST=$(tail -10 "${AGENT_RUN_LOG}" 2>/dev/null || echo "로그 없음")
                    log_info "hub 로그 마지막 15줄: ${HUB_LAST}"
                    log_info "agent 로그 마지막 10줄: ${AGENT_LAST}"
                fi
            fi
        fi
        # teardown은 EXIT trap이 처리
    fi
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

# 동적 모드 여부를 메타에 기록
DYNAMIC_LABEL="비활성 (--dynamic 미전달)"
[ "${DYNAMIC_MODE}" = "true" ] && DYNAMIC_LABEL="활성 (--dynamic 전달)"

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
    echo "- ADR-0002 C-1 빅뱅 컷오버 정합 (infra otlp_proto ↔ hub ByteArrayDeserializer + proto 디코더)"
    echo "- 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 (metric name / agent_id / service.name / value / time_unix_nano)"
    echo "- envelope 예외 위상 (heartbeats-topic: OTLP 위임군 → envelope 헤더 검사 없음)"
    echo "- hub mvn test / script-agent go test ./..."
    echo "- 주석 drift 관측"
    echo "- 동적 E2E 시나리오 (Docker) — ${DYNAMIC_LABEL}"
    echo ""
    echo "## 하네스 수정 이력"
    echo ""
    echo "v3 (실 기동 안정화):"
    echo "- 버그 A (IPv6 우회): script-agent OTLP_ENDPOINT=http://127.0.0.1:14318, KAFKA_BROKERS=127.0.0.1:9092 명시"
    echo "- 버그 B (kafka 클린 시작): up -d 전 down -v 실행으로 잔존 볼륨/메시지 제거"
    echo "- 버그 C (grep 정교화): ntainer#1-0-C-1 스레드의 'Received: N records' (N>=1) 패턴으로 실제 수신만 판정"
    echo "  - 제외: KafkaListenerAnnotationBeanPostProcessor / partitions assigned / Subscribed to topic / 0 records"
    echo ""
    echo "v4 (안전성 — 코드 리뷰 반영):"
    echo "- 수정 ①: compose 프로젝트를 '${E2E_PROJECT}'로 격리 → down -v가 형제 infra 볼륨을 건드리지 않음"
    echo "- 수정 ②: 무차별 종료 제거 — hub는 /health 시점 8080 소유 PID, agent는 기동 후 신규 agent.exe PID만 정밀 종료"
    echo "- 수정 ③: DYNAMIC_STARTED를 up -d 직전에 설정 → 부분 실패 시에도 trap이 infra 정리"
    echo "- 수정 ④: Docker 불가 시 메시지를 FAIL 의미로 정정(SKIP 표기 제거)"
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
    echo "- 스크립트: \`e2e/run-e2e.sh\` (baseline v4, --dynamic opt-in)"
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

# 비정상 종료 시에도 결과 파일은 남긴다
if [ "${OVERALL_STATUS}" = "failed" ]; then
    exit 1
fi
exit 0

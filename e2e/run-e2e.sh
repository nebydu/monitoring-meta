#!/usr/bin/env bash
# run-e2e.sh — monitoring polyrepo 종단 검증 스크립트 (baseline v6)
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
#   7. [정적] phase1-002 x-source 가드 명시화 회귀 검증
#             — hub EnvelopeHeaders 신설 + JobResultConsumer/AuditConsumer 가드 호출 + CommandPublisher 별칭 위임
#             — script-agent SourceFromHeaders 추가 + consumeCommands 관찰 결선 + envelope_test.go 6케이스
#   8. [정적] T4-1 토픽 재명명 R-A/R-B 회귀 검증 (ADR#5 규칙 B 최종 논리명)
#             — R-A: 메시지 흐름·payload·envelope 기반 동작 등가 (흐름 정합성)
#             — R-B: 신명 완전성(command-topic/audit-topic/heartbeats-topic) +
#                    구명(commands/audit-events/heartbeats) 런타임 경로 잔존 부재
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
# v5 변경사항 (phase1-002 x-source 가드 검증 추가):
#   - §7 신설: envelope §2.2·§2.3·§6 근거 정적 검증 9항목
#     hub: EnvelopeHeaders 신설(헤더 키 4종 + inspectSource), JobResultConsumer/AuditConsumer 가드 호출,
#          CommandPublisher 별칭 위임(값 불변 회귀 0), 헤더 키 문자열 현지화 검사
#     script-agent: SourceFromHeaders 추가, consumeCommands 관찰 결선, envelope_test.go 케이스 수
#
# v6 변경사항 (T4-1 토픽 재명명 R-A/R-B 검증 추가):
#   - §8 신설: ADR#5 규칙 B 최종 논리명 재명명 완전성 + 동작 등가 검증
#     R-B 재명명 완전성(12항목):
#       hub KafkaConfig.Topics 3상수 신명 확인 / 구명 리터럴 런타임 경로 부재 /
#       hub 전용 회귀 앵커 테스트(KafkaTopicConstantsRegressionTest) 존재 확인 /
#       AuditConsumerTest 픽스처 신명 확인 / UiControllerTest 구명 오탐 무해 확인
#       script-agent config.go getenv default 신명 확인(commands→command-topic, audit-events→audit-topic) /
#       구명 getenv default 잔존 부재 /
#       infra kafka-init 루프 신명 확인(command-topic/audit-topic/heartbeats-topic, job-results 유지) /
#       infra otel-collector exporter topic 신명 확인(heartbeats-topic)
#     R-A 동작 등가(7항목):
#       hub 흐름 상수 단일 진실 확인(상수 통해 발행/구독 — 리터럴 없음) /
#       spec §1.1 흐름 4종 토픽 모두 단일 진실 확인 /
#       heartbeats-topic 동시 컷오버(infra otel exporter ↔ hub consumer 동명) 확인 /
#       audit/command 흐름 단절 위험 부재 확인 /
#       job-results 유지(T4-2 미결, 현행명 보존) 확인 /
#       envelope 4종 헤더는 토픽명 독립(재명명 영향 없음) 관찰 기록 /
#       하네스(e2e/run-e2e.sh) 토픽명 하드코딩 비교 부재 — false-fail 아님 관찰
#
# 사용:
#   ./run-e2e.sh            # 정적+유닛만 (§1~§5, §7~§8)
#   ./run-e2e.sh --dynamic  # 정적+유닛+실제 동적 기동 (§1~§8)
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
#   handoff/adr-002-{infra,hub,script-agent}.md
#   handoff/phase1-040-000-impact.md  (T4-1 영향 분석)
#   docs/kafka-payloads.md (heartbeats-topic)
#   docs/envelope.md §2.2·§2.3·§4.2·§6 (OTLP 위임군 예외, x-source 가드)
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
            # [리뷰 ① 반영] hub 기동 '전' 8080 소유자를 기록한다. /health 200이 우리 hub가
            # 아니라 기존에 8080에 떠 있던 다른 서비스에서 올 수 있으므로, 기동 후 '새로 8080을
            # 잡은 PID'만 우리 hub로 인정한다(기존 PID는 readiness로도, teardown 대상으로도 제외).
            HUB_OWNER_PRE="$(resolve_port_owner 8080)"
            if [ -n "${HUB_OWNER_PRE}" ]; then
                log_info "주의: hub 기동 전 이미 8080 점유(PID=${HUB_OWNER_PRE}) — 이 PID는 우리 hub로 인정하지 않고 teardown 대상에서도 제외"
            fi

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
                    # [수정 ② + 리뷰 ①] 8080을 '새로' 잡은 PID(기동 전 소유자와 다른)만 우리 hub로
                    # 인정한다. 기존 서비스가 8080에서 /health 200을 주더라도 그 PID는 잡지 않는다
                    # (readiness 미인정 → 계속 대기 → 우리 hub가 바인딩 실패하면 timeout/프로세스 종료로 FAIL).
                    CUR_OWNER="$(resolve_port_owner 8080)"
                    if [ -n "${CUR_OWNER}" ] && [ "${CUR_OWNER}" != "${HUB_OWNER_PRE}" ]; then
                        HUB_READY=true
                        HUB_APP_WINPID="${CUR_OWNER}"
                        log_info "hub /health 응답 확인 (${HUB_WAIT}s 경과), 앱 winpid=${HUB_APP_WINPID} (신규 8080 소유 — teardown 정밀 종료 대상)"
                        break
                    fi
                    # 소유자 미확인 또는 기존 서비스(=우리 hub 아직 미바인딩) → 계속 대기
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

# §7-A: hub — EnvelopeHeaders 클래스 신설 확인 (헤더 키 단일 진실 지점)
if [ -f "${ENVELOPE_HEADERS}" ]; then
    log_pass "hub/messaging/EnvelopeHeaders.java: 파일 존재 확인 (헤더 키 단일 진실 지점 신설)"
else
    log_fail "hub/messaging/EnvelopeHeaders.java: 파일 없음 — phase1-002-hub 미반영"
fi

# §7-B: hub — EnvelopeHeaders 헤더 키 4종 값 검증 (spec §2.2 값 불변 회귀 0)
if file_contains "${ENVELOPE_HEADERS}" '"x-message-id"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-message-version"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-source"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-trace-id"'; then
    log_pass "hub/EnvelopeHeaders.java: 헤더 키 4종(x-message-id/x-message-version/x-source/x-trace-id) 값 확인 (spec §2.2 회귀 0)"
else
    log_fail "hub/EnvelopeHeaders.java: 헤더 키 4종 중 하나 이상 누락 — spec §2.2 위반"
fi

# §7-C: hub — EnvelopeHeaders.inspectSource() 메서드 존재 (가드 메서드)
if file_contains "${ENVELOPE_HEADERS}" "inspectSource"; then
    log_pass "hub/EnvelopeHeaders.java: inspectSource() 가드 메서드 확인"
else
    log_fail "hub/EnvelopeHeaders.java: inspectSource() 없음 — x-source 가드 미구현"
fi

# §7-D: hub — inspectSource가 reject/throw 없이 관찰 전용인지 확인
#   inspectSource 메서드 본문만 추출(awk: 메서드 시작~4칸 들여쓰기 닫는 중괄호)해
#   Javadoc/주석(//)을 제거한 뒤 throw/reject 코드가 있는지 검사한다.
#   단 null/header=null 에 대한 early return(bare return)은 허용(가드 안전성).
ISRC_BODY=$(awk '/public static void inspectSource/{f=1} f{print} f&&/^    }/{exit}' "${ENVELOPE_HEADERS}" 2>/dev/null | sed 's://.*$::')
if [ -z "${ISRC_BODY}" ]; then
    log_fail "hub/EnvelopeHeaders.java: inspectSource 본문 추출 실패 — 메서드 부재 또는 시그니처 변경"
elif echo "${ISRC_BODY}" | grep -qE 'throw |IllegalArgumentException|IllegalStateException|reject'; then
    log_fail "hub/EnvelopeHeaders.java: inspectSource 본문에 throw/reject 로직 포함 — §2.3 위반(미지 x-source에 깨지면 안 됨)"
else
    log_pass "hub/EnvelopeHeaders.java: inspectSource 본문 throw/reject 없음 확인 (관찰 전용 가드 — §2.3 준수)"
fi

# §7-E: hub — JobResultConsumer가 inspectSource 호출하는지 확인
if file_contains "${JOB_RESULT_CONSUMER}" "inspectSource"; then
    log_pass "hub/JobResultConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인"
else
    log_fail "hub/JobResultConsumer.java: inspectSource() 호출 없음 — phase1-002-hub 미반영"
fi

# §7-F: hub — AuditConsumer가 inspectSource 호출하는지 확인
if file_contains "${AUDIT_CONSUMER}" "inspectSource"; then
    log_pass "hub/AuditConsumer.java: EnvelopeHeaders.inspectSource() 호출 확인"
else
    log_fail "hub/AuditConsumer.java: inspectSource() 호출 없음 — phase1-002-hub 미반영"
fi

# §7-G: hub — CommandPublisher 헤더 키 상수가 EnvelopeHeaders 별칭 위임인지 확인
#   HEADER_MESSAGE_ID = EnvelopeHeaders.X_MESSAGE_ID 형태여야 함(값 불변 회귀 0)
if file_contains "${CMD_PUBLISHER}" "EnvelopeHeaders" && file_contains "${CMD_PUBLISHER}" "X_MESSAGE_ID"; then
    log_pass "hub/CommandPublisher.java: 헤더 키 상수를 EnvelopeHeaders 별칭 위임으로 선언 확인 (Phase 0 회귀 0)"
else
    log_fail "hub/CommandPublisher.java: EnvelopeHeaders 별칭 위임 없음 — 헤더 키가 중복 정의 상태일 수 있음"
fi

# §7-H: script-agent — SourceFromHeaders 함수 존재 (가드 읽기 헬퍼)
if file_contains "${AGENT_ENVELOPE_GO}" "SourceFromHeaders"; then
    log_pass "script-agent/kafka/envelope.go: SourceFromHeaders() 추가 확인"
else
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders() 없음 — phase1-002-script-agent 미반영"
fi

# §7-I: script-agent — SourceFromHeaders가 폐쇄 enum / allowlist 검증 없이
#   값+존재여부만 반환하는지 확인 (§2.3 비규범 목록 준수)
#   함수 본문만 추출(awk: 함수 시작~col0 닫는 중괄호) + 주석(//) 제거 후 검사.
#   주석에 "allowlist 검증을 하지 않는다" 설명이 있어 파일 전체 grep은 오탐.
SFH_BODY=$(awk '/^func SourceFromHeaders/{f=1} f{print} f&&/^}/{exit}' "${AGENT_ENVELOPE_GO}" 2>/dev/null | sed 's://.*$::')
if [ -z "${SFH_BODY}" ]; then
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders 본문 추출 실패 — 함수 부재 또는 시그니처 변경"
elif echo "${SFH_BODY}" | grep -qE 'allowlist|KNOWN_SOURCES|reject|[Ee]rrUnknown|errors\.|fmt\.Errorf|return[^,]*err'; then
    log_fail "script-agent/kafka/envelope.go: SourceFromHeaders 본문에 allowlist/reject/error 로직 포함 — §2.3 위반"
else
    log_pass "script-agent/kafka/envelope.go: SourceFromHeaders 본문 allowlist/reject 없음 확인 (값+존재여부만 반환 — §2.3 준수)"
fi

# §7-J: script-agent — envelope_test.go에 SourceFromHeaders 테스트 케이스 존재 확인
if file_contains "${AGENT_ENVELOPE_TEST}" "TestSourceFromHeaders"; then
    TEST_COUNT=$(grep -c "^func TestSourceFromHeaders" "${AGENT_ENVELOPE_TEST}" 2>/dev/null || echo "0")
    log_pass "script-agent/kafka/envelope_test.go: TestSourceFromHeaders 케이스 ${TEST_COUNT}개 확인"
else
    log_fail "script-agent/kafka/envelope_test.go: TestSourceFromHeaders 없음 — 회귀 자산 미확보"
fi

# §7-K: script-agent — model/envelope.go에 HeaderSource 상수 존재 (model 상수 불변 회귀 0)
if file_contains "${AGENT_MODEL_ENVELOPE}" 'HeaderSource\s*=\s*"x-source"'; then
    log_pass "script-agent/model/envelope.go: HeaderSource=\"x-source\" 상수 불변 확인 (Phase 0 회귀 0)"
else
    log_fail "script-agent/model/envelope.go: HeaderSource=\"x-source\" 없음 — 헤더 키 값 변경 가능성"
fi

# §7-L: script-agent — BuildHeaders(producer) 불변 확인
#   model.HeaderSource · model.MessageVersion · model.SourceAgent 사용 유지
if file_contains "${AGENT_ENVELOPE_GO}" "model\.HeaderSource" && \
   file_contains "${AGENT_ENVELOPE_GO}" "model\.MessageVersion" && \
   file_contains "${AGENT_ENVELOPE_GO}" "model\.SourceAgent"; then
    log_pass "script-agent/kafka/envelope.go: BuildHeaders producer 경로 model 상수 사용 불변 (Phase 0 회귀 0)"
else
    log_fail "script-agent/kafka/envelope.go: BuildHeaders model 상수 참조 변경 감지 — Phase 0 회귀 가능성"
fi

# ---------------------------------------------------------------------------
# §8. 정적 검증 — T4-1 토픽 재명명 R-B 완전성 + R-A 동작 등가
#     근거: adr/0005-topic-naming.md §2.2.1 (최종 논리명 표)
#           handoff/phase1-040-000-impact.md §3.3 (R-A/R-B 정의)
# ---------------------------------------------------------------------------
echo ""
echo "=== §8 T4-1 토픽 재명명 회귀 검증 (R-B 완전성 + R-A 동작 등가) ==="

HUB_KAFKA_CFG="${HUB_DIR}/src/main/java/com/monitoring/hub/config/KafkaConfig.java"
HUB_TOPIC_REGRESSION="${HUB_DIR}/src/test/java/com/monitoring/hub/config/KafkaTopicConstantsRegressionTest.java"
HUB_AUDIT_TEST="${HUB_DIR}/src/test/java/com/monitoring/hub/ingest/audit/AuditConsumerTest.java"
HUB_UI_TEST="${HUB_DIR}/src/test/java/com/monitoring/hub/web/UiControllerTest.java"
AGENT_CONFIG_GO="${AGENT_DIR}/internal/config/config.go"
INFRA_COMPOSE="${INFRA_DIR}/docker-compose.yml"
INFRA_OTEL_CFG="${INFRA_DIR}/otel-collector-config.yml"

# ----- R-B: 재명명 완전성 (신명 확인 + 구명 런타임 경로 잔존 부재) -----

echo "[INFO] §8 R-B: 재명명 완전성 검사 시작"

# §8-RB-1: hub KafkaConfig.Topics.COMMANDS = "command-topic"
if file_contains "${HUB_KAFKA_CFG}" 'COMMANDS\s*=\s*"command-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.COMMANDS = \"command-topic\" 확인 (T4-1 신명)"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.COMMANDS 값이 \"command-topic\"이 아님 — T4-1 재명명 미반영 또는 회귀"
fi

# §8-RB-2: hub KafkaConfig.Topics.AUDIT_EVENTS = "audit-topic"
if file_contains "${HUB_KAFKA_CFG}" 'AUDIT_EVENTS\s*=\s*"audit-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.AUDIT_EVENTS = \"audit-topic\" 확인 (T4-1 신명)"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.AUDIT_EVENTS 값이 \"audit-topic\"이 아님 — T4-1 재명명 미반영 또는 회귀"
fi

# §8-RB-3: hub KafkaConfig.Topics.HEARTBEATS = "heartbeats-topic"
if file_contains "${HUB_KAFKA_CFG}" 'HEARTBEATS\s*=\s*"heartbeats-topic"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.HEARTBEATS = \"heartbeats-topic\" 확인 (T4-1 신명)"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.HEARTBEATS 값이 \"heartbeats-topic\"이 아님 — T4-1 재명명 미반영 또는 회귀"
fi

# §8-RB-4: hub KafkaConfig.Topics.JOB_RESULTS = "job-results" (T4-2 미변경 가드)
if file_contains "${HUB_KAFKA_CFG}" 'JOB_RESULTS\s*=\s*"job-results"'; then
    log_pass "§8 R-B: hub/KafkaConfig.Topics.JOB_RESULTS = \"job-results\" 유지 확인 (T4-2 미결 — 현행명 보존 정상)"
else
    log_fail "§8 R-B: hub/KafkaConfig.Topics.JOB_RESULTS 값이 \"job-results\"가 아님 — T4-2 범위 침범 또는 오변경"
fi

# §8-RB-5: hub 소스 런타임 경로에 구명 리터럴 잔존 여부
#   UiController.java의 모델 attribute 키("heartbeats","commands")는 토픽명이 아니라 UI 변수명이므로
#   src/main/java 전체에서 검사하되 UiController.java는 별도 오탐 기록으로 처리한다.
#   JobResults/AuditEvent/Command Kafka 상수 경로(KafkaConfig.java) 외에 구명 리터럴이 있으면 위반.
OLD_TOPIC_MAIN=$(grep -rn '"commands"\|"audit-events"\|"heartbeats"' \
    "${HUB_DIR}/src/main/java" 2>/dev/null \
    | grep -v "UiController\.java" \
    | grep -v "\.class" \
    | head -5 || true)
if [ -z "${OLD_TOPIC_MAIN}" ]; then
    log_pass "§8 R-B: hub/src/main/java 런타임 경로에 구명(commands/audit-events/heartbeats) 리터럴 잔존 없음"
else
    log_fail "§8 R-B: hub/src/main/java 런타임 경로에 구명 리터럴 잔존 감지 — 해당 라인: ${OLD_TOPIC_MAIN}"
fi

# §8-RB-5b: UiController.java에서 오탐 확인 — 모델 attribute 키이므로 무해함을 기록
if file_contains "${HUB_DIR}/src/main/java/com/monitoring/hub/web/UiController.java" '"heartbeats"\|"commands"'; then
    log_info "§8 R-B 오탐 확인: hub/UiController.java의 \"heartbeats\"/\"commands\"는 UI 모델 attribute 키(변수명)로 Kafka 토픽명이 아님 — 변경 불요(impact.md §2.1 확인)"
fi

# §8-RB-6: hub 토픽 상수 회귀 앵커 테스트 파일 존재 확인
if [ -f "${HUB_TOPIC_REGRESSION}" ]; then
    log_pass "§8 R-B: hub/KafkaTopicConstantsRegressionTest.java 존재 확인 — T4-1 토픽 상수 값 회귀 앵커"
else
    log_fail "§8 R-B: hub/KafkaTopicConstantsRegressionTest.java 없음 — 회귀 앵커 테스트 미존재"
fi

# §8-RB-7: hub AuditConsumerTest 픽스처 신명 확인
if file_contains "${HUB_AUDIT_TEST}" '"audit-topic"'; then
    log_pass "§8 R-B: hub/AuditConsumerTest.java: TOPIC=\"audit-topic\" 픽스처 신명 확인"
else
    log_fail "§8 R-B: hub/AuditConsumerTest.java: TOPIC이 \"audit-topic\"이 아님 — 테스트 픽스처 구명 잔존 가능성"
fi

# §8-RB-8: script-agent config.go — KAFKA_TOPIC_COMMANDS default = "command-topic"
if file_contains "${AGENT_CONFIG_GO}" 'getenv\("KAFKA_TOPIC_COMMANDS",\s*"command-topic"\)'; then
    log_pass "§8 R-B: script-agent/config.go: KAFKA_TOPIC_COMMANDS default=\"command-topic\" 확인 (T4-1 신명)"
else
    log_fail "§8 R-B: script-agent/config.go: KAFKA_TOPIC_COMMANDS default가 \"command-topic\"이 아님 — T4-1 재명명 미반영 또는 회귀"
fi

# §8-RB-9: script-agent config.go — KAFKA_TOPIC_AUDIT_EVENTS default = "audit-topic"
if file_contains "${AGENT_CONFIG_GO}" 'getenv\("KAFKA_TOPIC_AUDIT_EVENTS",\s*"audit-topic"\)'; then
    log_pass "§8 R-B: script-agent/config.go: KAFKA_TOPIC_AUDIT_EVENTS default=\"audit-topic\" 확인 (T4-1 신명)"
else
    log_fail "§8 R-B: script-agent/config.go: KAFKA_TOPIC_AUDIT_EVENTS default가 \"audit-topic\"이 아님 — T4-1 재명명 미반영 또는 회귀"
fi

# §8-RB-10: script-agent config.go — 구명("commands"/"audit-events") getenv default 잔존 부재
#   config.go에서 getenv 두 번째 인자로 구명이 남아있으면 runtime에서 구 토픽으로 발행된다.
OLD_AGENT_DEFAULT=$(grep -n 'getenv.*"commands"\|getenv.*"audit-events"' "${AGENT_CONFIG_GO}" 2>/dev/null || true)
if [ -z "${OLD_AGENT_DEFAULT}" ]; then
    log_pass "§8 R-B: script-agent/config.go: 구명(\"commands\"/\"audit-events\") getenv default 잔존 없음"
else
    log_fail "§8 R-B: script-agent/config.go: 구명 getenv default 잔존 감지 — 런타임에서 구 토픽으로 발행될 위험: ${OLD_AGENT_DEFAULT}"
fi

# §8-RB-11: infra docker-compose.yml kafka-init 루프 신명 확인
#   기대: for t in command-topic job-results audit-topic heartbeats-topic
if file_contains "${INFRA_COMPOSE}" 'command-topic.*job-results.*audit-topic.*heartbeats-topic'; then
    log_pass "§8 R-B: infra/docker-compose.yml kafka-init 루프: command-topic/audit-topic/heartbeats-topic 신명 + job-results 유지 확인"
elif file_contains "${INFRA_COMPOSE}" 'command-topic' && \
     file_contains "${INFRA_COMPOSE}" 'audit-topic' && \
     file_contains "${INFRA_COMPOSE}" 'heartbeats-topic' && \
     file_contains "${INFRA_COMPOSE}" 'job-results'; then
    log_pass "§8 R-B: infra/docker-compose.yml kafka-init: 4개 토픽명 모두 존재 확인 (신명 3 + job-results 유지)"
else
    COMPOSE_TOPIC_LINE=$(grep -n "for t in\|command-topic\|audit-topic\|heartbeats-topic\|commands\|audit-events\|heartbeats" \
        "${INFRA_COMPOSE}" 2>/dev/null | head -10 || true)
    log_fail "§8 R-B: infra/docker-compose.yml kafka-init 루프에서 신명 4종 미확인 — 현황: ${COMPOSE_TOPIC_LINE}"
fi

# §8-RB-11b: infra docker-compose.yml에서 구명 토픽 생성 루프 잔존 부재
OLD_COMPOSE_TOPICS=$(grep -n '"commands"\|"audit-events"\|"heartbeats"\b' "${INFRA_COMPOSE}" 2>/dev/null \
    | grep -v "heartbeats-topic" || true)
if [ -z "${OLD_COMPOSE_TOPICS}" ]; then
    log_pass "§8 R-B: infra/docker-compose.yml: 구명(commands/audit-events/heartbeats) 토픽 생성 잔존 없음"
else
    log_fail "§8 R-B: infra/docker-compose.yml: 구명 토픽 생성 라인 잔존 감지: ${OLD_COMPOSE_TOPICS}"
fi

# §8-RB-12: infra otel-collector-config.yml kafka exporter topic = heartbeats-topic
if file_contains "${INFRA_OTEL_CFG}" 'topic:\s*heartbeats-topic'; then
    log_pass "§8 R-B: infra/otel-collector-config.yml: kafka exporter topic=\"heartbeats-topic\" 확인 (T4-1 신명)"
else
    OTEL_TOPIC=$(grep -n "topic:" "${INFRA_OTEL_CFG}" 2>/dev/null || echo "없음")
    log_fail "§8 R-B: infra/otel-collector-config.yml: kafka exporter topic이 heartbeats-topic이 아님 — 현황: ${OTEL_TOPIC}"
fi

# ----- R-A: 동작 등가 (메시지 흐름·payload·envelope·발행순서 보존) -----

echo "[INFO] §8 R-A: 동작 등가 검사 시작"

# §8-RA-1: hub — 토픽 상수 단일 진실 확인 (producer/consumer가 상수 참조, 리터럴 없음)
#   CommandPublisher가 KafkaConfig.Topics.COMMANDS를 참조하는지 확인
HUB_CMD_PUBLISHER="${HUB_DIR}/src/main/java/com/monitoring/hub/producer/CommandPublisher.java"
if file_contains "${HUB_CMD_PUBLISHER}" "KafkaConfig\.Topics\.COMMANDS|Topics\.COMMANDS"; then
    log_pass "§8 R-A: hub/CommandPublisher.java: KafkaConfig.Topics.COMMANDS 상수 참조 확인 (리터럴 없음 — 단일 진실)"
else
    log_fail "§8 R-A: hub/CommandPublisher.java: Topics.COMMANDS 상수 참조 없음 — 리터럴 직접 참조 가능성"
fi

# §8-RA-2: hub AuditConsumer가 KafkaConfig.Topics.AUDIT_EVENTS 상수 참조하는지
if file_contains "${AUDIT_CONSUMER}" "KafkaConfig\.Topics\.AUDIT_EVENTS|Topics\.AUDIT_EVENTS|Topics\.AUDIT"; then
    log_pass "§8 R-A: hub/AuditConsumer.java: Topics.AUDIT_EVENTS 상수 참조 확인 (단일 진실 추종)"
else
    log_fail "§8 R-A: hub/AuditConsumer.java: Topics.AUDIT_EVENTS 상수 참조 없음 — 리터럴 직접 참조 가능성"
fi

# §8-RA-3: heartbeats-topic 동시 컷오버 정합 확인
#   infra otel-collector exporter topic(heartbeats-topic) ↔ hub consumer(HEARTBEATS="heartbeats-topic")
#   이 두 이름이 일치해야 heartbeat 수신 흐름이 성립한다(ADR#2 + T4-1 핵심 단절 위험).
OTEL_TOPIC_VAL=$(grep 'topic:' "${INFRA_OTEL_CFG}" 2>/dev/null | awk '{print $2}' | tr -d '\r' | head -1)
HUB_HB_CONST=$(grep 'HEARTBEATS\s*=' "${HUB_KAFKA_CFG}" 2>/dev/null | grep -oE '"[^"]+"' | head -1)
if [ "${OTEL_TOPIC_VAL}" = "heartbeats-topic" ] && [ "${HUB_HB_CONST}" = '"heartbeats-topic"' ]; then
    log_pass "§8 R-A: heartbeats-topic 동시 컷오버 정합 — infra otel exporter(${OTEL_TOPIC_VAL}) ↔ hub consumer(HEARTBEATS=${HUB_HB_CONST}) 이름 일치. heartbeat 수신 흐름 단절 없음"
else
    log_fail "§8 R-A: heartbeats-topic 동시 컷오버 불일치 감지 — infra otel exporter topic=[${OTEL_TOPIC_VAL}] vs hub HEARTBEATS=[${HUB_HB_CONST}]. 이름이 다르면 heartbeat 수신 단절됨"
fi

# §8-RA-4: audit/command 흐름 단절 위험 부재 확인
#   script-agent config.go default와 hub KafkaConfig.Topics 신명이 일치하는지 교차 확인
AGENT_CMD_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_COMMANDS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"command-topic"' | head -1 || true)
AGENT_AUDIT_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_AUDIT_EVENTS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"audit-topic"' | head -1 || true)
if [ "${AGENT_CMD_DEFAULT}" = '"command-topic"' ] && [ "${AGENT_AUDIT_DEFAULT}" = '"audit-topic"' ]; then
    log_pass "§8 R-A: script-agent 기본 토픽명 신명 확인 — COMMANDS default=command-topic, AUDIT default=audit-topic. hub 상수(KafkaConfig.Topics)와 이름 일치 — 흐름 단절 없음"
else
    log_fail "§8 R-A: script-agent ↔ hub 토픽명 불일치 위험 — agent COMMANDS=[${AGENT_CMD_DEFAULT:-미확인}], AUDIT=[${AGENT_AUDIT_DEFAULT:-미확인}]. hub 신명과 다르면 메시지 흐름 단절됨"
fi

# §8-RA-5: job-results 현행명 보존 확인 (T4-2 미결 — 흐름 연속성)
#   job-results는 spec §1.1 흐름의 일부이며 T4-2 대기 중이므로 현행 "job-results"가 유지돼야 한다.
AGENT_JR_DEFAULT=$(grep 'getenv.*KAFKA_TOPIC_JOB_RESULTS' "${AGENT_CONFIG_GO}" 2>/dev/null | grep -oE '"job-results"' | head -1 || true)
if [ "${AGENT_JR_DEFAULT}" = '"job-results"' ]; then
    log_pass "§8 R-A: script-agent/config.go: KAFKA_TOPIC_JOB_RESULTS default=\"job-results\" 유지 — T4-2 미결, 흐름 연속성 보존"
else
    log_fail "§8 R-A: script-agent/config.go: KAFKA_TOPIC_JOB_RESULTS default가 \"job-results\"가 아님 — T4-2 범위 침범 또는 오변경으로 job-results 흐름 단절 위험"
fi

# §8-RA-6: envelope 4종 헤더가 토픽명과 독립적임을 관찰 기록
#   (adr/0005 §2.1, envelope.md §4.1 주: envelope 적용은 토픽명·zone suffix와 무관)
#   x-source, x-message-id 등 헤더는 재명명 후에도 동일하게 발행/수신됨 → FAIL 가능성 없음.
if file_contains "${ENVELOPE_HEADERS}" '"x-message-id"' && \
   file_contains "${ENVELOPE_HEADERS}" '"x-source"'; then
    log_info "§8 R-A: envelope 4종 헤더(x-message-id/x-message-version/x-source/x-trace-id)는 토픽명과 독립적. 재명명이 envelope 동작에 영향 없음(adr/0005 §2.1, envelope.md §4.1 주) — 관찰 기록"
fi

# §8-RA-7: 하네스(e2e/run-e2e.sh) 토픽명 하드코딩 비교 여부 확인
#   현재 하네스는 토픽명을 직접 비교하지 않고 hub 로그 패턴(ntainer#1-0-C-1 ... Received: N records)으로 판정.
#   만약 토픽명을 직접 grep/비교하는 라인이 있다면 구명 기준이면 false-fail, 신명이면 OK임을 명시해야 한다.
THIS_SCRIPT="${SCRIPT_DIR}/run-e2e.sh"
HARDCODED_OLD=$(grep -n '"commands"\|"audit-events"\|"heartbeats"' "${THIS_SCRIPT}" 2>/dev/null \
    | grep -v "^[0-9]*:#\|주석\|comment" || true)
if [ -z "${HARDCODED_OLD}" ]; then
    log_pass "§8 R-A: 하네스(run-e2e.sh): 구 토픽명(commands/audit-events/heartbeats) 하드코딩 비교 없음 — false-fail 없음. 토픽명 독립 판정(로그 패턴 기반) 유지"
else
    log_info "§8 R-A 주의: 하네스(run-e2e.sh)에 구 토픽명 리터럴 등장 라인 감지: ${HARDCODED_OLD}. 동작 비교가 아닌 주석이면 무해하나 내용 확인 권고"
    add_blocker "하네스 run-e2e.sh에 구 토픽명 리터럴 감지 — 코드 비교로 쓰이면 false-fail 발생 가능. 주석/정보성 여부 확인 필요(수정 여부는 사람 판단)"
fi

# ----- §8 R-A / R-B 소계 -----
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
    echo "- §1 ADR-0002 C-1 빅뱅 컷오버 정합 (infra otlp_proto ↔ hub ByteArrayDeserializer + proto 디코더)"
    echo "- §2 데모 spec v0.2.1 §5.4 논리 계약 회귀 0 (metric name / agent_id / service.name / value / time_unix_nano)"
    echo "- §3 envelope 예외 위상 (heartbeats-topic: OTLP 위임군 → envelope 헤더 검사 없음)"
    echo "- §4 hub mvn test / script-agent go test ./..."
    echo "- §5 주석 drift 관측"
    echo "- §6 동적 E2E 시나리오 (Docker) — ${DYNAMIC_LABEL}"
    echo "- §7 phase1-002 x-source 가드 명시화 회귀 (EnvelopeHeaders 신설 · consumer 가드 호출 · CommandPublisher 별칭 위임 · SourceFromHeaders 추가)"
    echo "- §8 T4-1 토픽 재명명 R-B 완전성 + R-A 동작 등가 (ADR#5 규칙 B 최종 논리명)"
    echo "  - R-B 완전성: hub Topics 3상수 신명 / hub 런타임 구명 부재 / 회귀 앵커 테스트 / AuditConsumerTest 픽스처 / script-agent config.go 신명 / infra 카프카 init + otel exporter"
    echo "  - R-A 동작 등가: hub 단일 진실 상수 참조 / heartbeats-topic 동시 컷오버 정합 / command·audit 흐름 단절 부재 / job-results 유지 / envelope 독립 관찰 / 하네스 false-fail 부재"
    echo ""
    echo "## 근거 문서"
    echo ""
    echo "- docs/envelope.md §2.2·§2.3·§6 (헤더 키 · x-source 가드 · OTLP 예외)"
    echo "- docs/phase0-snapshot/monitoring-demo-message-spec-v0.2.1.md §2.2·§5.4 (Phase 0 ground truth)"
    echo "- adr/0002-heartbeat-otlp-proto.md (A-1/B-1/C-1)"
    echo "- adr/0005-topic-naming.md §2.2.1 (D-4(1) Accepted — 최종 논리명 표)"
    echo "- handoff/phase1-040-000-impact.md §3.3 (R-A/R-B 회귀 기준 정의)"
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
    echo "- 수정 ①: compose 프로젝트를 'monitoring-e2e'로 격리 → down -v가 형제 infra 볼륨을 건드리지 않음"
    echo "- 수정 ②: 무차별 종료 제거 — hub는 /health 시점 8080 소유 PID, agent는 기동 후 신규 agent.exe PID만 정밀 종료"
    echo "- 수정 ③: DYNAMIC_STARTED를 up -d 직전에 설정 → 부분 실패 시에도 trap이 infra 정리"
    echo "- 수정 ④: Docker 불가 시 메시지를 FAIL 의미로 정정(SKIP 표기 제거)"
    echo ""
    echo "v5 (phase1-002 x-source 가드 검증 추가):"
    echo "- §7 신설: EnvelopeHeaders 신설 + consumer 가드 호출 + CommandPublisher 별칭 위임 + SourceFromHeaders 회귀 검증"
    echo "- 근거 문서 섹션 추가 (envelope.md §2.2·§2.3·§6)"
    echo ""
    echo "v6 (T4-1 토픽 재명명 R-A/R-B 검증 추가):"
    echo "- §8 신설: ADR#5 규칙 B 최종 논리명 재명명 완전성(R-B) 12항목 + 동작 등가(R-A) 7항목"
    echo "- R-B: hub/KafkaConfig.Topics 3상수 신명 리터럴 단언 / 런타임 구명 부재 / KafkaTopicConstantsRegressionTest 존재 / AuditConsumerTest 픽스처 신명 / script-agent config.go getenv default 신명 / 구명 default 잔존 부재 / infra compose kafka-init 루프 신명 4종 / otel-collector exporter topic 신명"
    echo "- R-A: CommandPublisher Topics 상수 참조(단일 진실) / heartbeats-topic 동시 컷오버 정합(otel↔hub consumer 이름 일치) / script-agent↔hub 토픽명 교차 확인 / job-results 유지 / envelope 독립 관찰 / 하네스 false-fail 부재 확인"
    echo "- 근거 문서 추가: adr/0005-topic-naming.md §2.2.1 / handoff/phase1-040-000-impact.md §3.3"
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
    echo "- 스크립트: \`e2e/run-e2e.sh\` (baseline v6, --dynamic opt-in)"
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

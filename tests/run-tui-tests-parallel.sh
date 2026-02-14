#!/bin/bash

# run-tui-tests-parallel.sh - Run TUI tests in parallel with concurrency limit
# Each test is fully isolated (unique tmux session via PID, unique temp dir),
# so they can safely run concurrently.

# Maximum number of tests running at the same time
CONCURRENCY=16

# Maximum time in seconds a single test is allowed to run before being killed
TEST_TIMEOUT=30

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Guard TUI Parallel Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if guard binary exists
if [ ! -f "./guard" ] && ! command -v guard &> /dev/null; then
    echo -e "${RED}Error: guard binary not found${NC}"
    echo "Please build the guard binary first:"
    echo "  just build"
    echo "  or"
    echo "  go build -o guard ./cmd/guard"
    exit 1
fi

# Run CLI tests first — abort early if any fail (skip if caller already ran them)
if [ "${SKIP_CLI_PREREQ:-}" != "1" ]; then
    echo -e "${BLUE}Running CLI tests first...${NC}"
    echo ""
    if ! "$SCRIPT_DIR/run-cli-tests-sequential.sh"; then
        echo -e "${RED}CLI tests failed — skipping TUI tests${NC}"
        exit 1
    fi
    echo ""
fi

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is required for TUI tests but is not installed${NC}"
    echo "Please install tmux to run TUI integration tests"
    exit 1
fi

# Discover TUI test files
TEST_FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "test-*.sh" -type f | sort)
TEST_FILES=$(echo "$TEST_FILES" | grep -v "test-assertions-and-framework.sh" | grep -v "test-guardfile-parsers.sh")
TUI_TEST_FILES=$(echo "$TEST_FILES" | grep -i '/[^/]*tui[^/]*$' || true)

if [ -z "$TUI_TEST_FILES" ]; then
    echo -e "${RED}No TUI test files found${NC}"
    exit 1
fi

# Load test files into an array
declare -a ALL_TESTS
while IFS= read -r line; do
    ALL_TESTS+=("$line")
done <<< "$TUI_TEST_FILES"

test_count=${#ALL_TESTS[@]}
echo -e "Found ${BLUE}${test_count}${NC} TUI test files (concurrency: ${CONCURRENCY})"
echo ""

# Create temp directory for per-test output logs
LOG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/guard-tui-parallel.XXXXXX")

# Record start time
start_time=$(date +%s)

# Arrays indexed by test number
declare -a PIDS
declare -a TEST_NAMES
declare -a LOG_FILES
declare -a EXIT_CODES
declare -a START_TIMES
declare -a TIMED_OUT

# Track currently active test indices
declare -a ACTIVE

# Cleanup handler for runner interruption (Ctrl+C, CI timeout)
cleanup_runner() {
    echo ""
    echo -e "${RED}Runner interrupted — cleaning up...${NC}"
    for i in "${ACTIVE[@]}"; do
        kill "${PIDS[$i]}" 2>/dev/null || true
        tmux kill-session -t "guard_tui_test_${PIDS[$i]}" 2>/dev/null || true
        rm -f "/tmp/_gt${PIDS[$i]}" 2>/dev/null || true
    done
    # Catch any sessions not tracked in ACTIVE (race condition)
    tmux list-sessions 2>/dev/null | grep "guard_tui_test_" | cut -d: -f1 | while read -r s; do
        tmux kill-session -t "$s" 2>/dev/null || true
    done
    # Keep logs for debugging on interrupt; only clean on successful completion
    echo -e "Logs preserved at: ${LOG_DIR}"
    exit 130
}
trap cleanup_runner INT TERM

failed=0
completed=0
next_test=0

# Launch a test by index
launch_test() {
    local i=$1
    local test_file="${ALL_TESTS[$i]}"
    local test_name=$(basename "$test_file")
    local log_file="${LOG_DIR}/${test_name}.log"

    TEST_NAMES[$i]="$test_name"
    LOG_FILES[$i]="$log_file"

    bash "$test_file" > "$log_file" 2>&1 &
    PIDS[$i]=$!
    START_TIMES[$i]=$(date +%s)

    echo -e "  ${BLUE}Launching${NC} ${test_name}"
}

# Try to launch the next queued test if any remain
try_launch_next() {
    if [ $next_test -lt $test_count ]; then
        launch_test $next_test
        new_active+=("$next_test")
        ((next_test++))
        sleep 0.1
    fi
}

# Launch initial batch
while [ $next_test -lt $test_count ] && [ ${#ACTIVE[@]} -lt $CONCURRENCY ]; do
    launch_test $next_test
    ACTIVE+=("$next_test")
    ((next_test++))
    sleep 0.1
done

# Poll for finished tests, launching new ones as slots open
while [ $completed -lt $test_count ]; do
    now=$(date +%s)
    new_active=()
    for i in "${ACTIVE[@]}"; do
        elapsed_test=$((now - ${START_TIMES[$i]}))
        if [ $elapsed_test -gt $TEST_TIMEOUT ]; then
            # Kill the hanging test and its tmux session
            kill "${PIDS[$i]}" 2>/dev/null
            wait "${PIDS[$i]}" 2>/dev/null
            tmux kill-session -t "guard_tui_test_${PIDS[$i]}" 2>/dev/null || true
            rm -f "/tmp/_gt${PIDS[$i]}" 2>/dev/null || true
            EXIT_CODES[$i]=124
            TIMED_OUT[$i]=1
            echo -e "  ${RED}TIMEOUT${NC}    ${TEST_NAMES[$i]} (killed after ${TEST_TIMEOUT}s)"
            ((completed++))
            ((failed++))
            try_launch_next
        elif ! kill -0 "${PIDS[$i]}" 2>/dev/null; then
            wait "${PIDS[$i]}"
            EXIT_CODES[$i]=$?
            if [ "${EXIT_CODES[$i]}" -eq 0 ]; then
                echo -e "  ${GREEN}Completed${NC} ${TEST_NAMES[$i]}"
            else
                echo -e "  ${RED}Failed${NC}    ${TEST_NAMES[$i]}"
            fi
            ((completed++))
            if [ "${EXIT_CODES[$i]}" -ne 0 ]; then
                ((failed++))
            fi
            try_launch_next
        else
            new_active+=("$i")
        fi
    done
    ACTIVE=("${new_active[@]}")
    sleep 0.1
done

# Record end time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

# Print results
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Results${NC}"
echo -e "${BLUE}========================================${NC}"

passed=0
for j in "${!TEST_NAMES[@]}"; do
    if [ "${EXIT_CODES[$j]}" -eq 0 ]; then
        echo -e "${GREEN}✓ ${TEST_NAMES[$j]}${NC}"
        ((passed++))
    else
        if [ "${TIMED_OUT[$j]:-}" = "1" ]; then
            echo -e "${RED}✗ ${TEST_NAMES[$j]} (TIMEOUT after ${TEST_TIMEOUT}s)${NC}"
        else
            echo -e "${RED}✗ ${TEST_NAMES[$j]} (exit code ${EXIT_CODES[$j]})${NC}"
        fi
    fi
done

# Print captured output for failed tests
if [ "$failed" -gt 0 ]; then
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Failed Test Output${NC}"
    echo -e "${RED}========================================${NC}"

    for j in "${!TEST_NAMES[@]}"; do
        if [ "${EXIT_CODES[$j]}" -ne 0 ]; then
            echo ""
            if [ "${TIMED_OUT[$j]:-}" = "1" ]; then
                echo -e "${RED}--- ${TEST_NAMES[$j]} (TIMEOUT after ${TEST_TIMEOUT}s) ---${NC}"
                echo -e "${RED}Test file: ${ALL_TESTS[$j]}${NC}"
            else
                echo -e "${RED}--- ${TEST_NAMES[$j]} ---${NC}"
            fi
            cat "${LOG_FILES[$j]}"
            echo -e "${RED}--- end ${TEST_NAMES[$j]} ---${NC}"
        fi
    done
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total:  ${test_count}"
echo -e "Passed: ${GREEN}${passed}${NC}"
if [ "$failed" -gt 0 ]; then
    echo -e "Failed: ${RED}${failed}${NC}"
fi
echo -e "Time:   ${elapsed}s"
echo -e "${BLUE}========================================${NC}"

trap - INT TERM

# Clean up log directory on success, keep on failure for inspection
if [ "$failed" -eq 0 ]; then
    rm -rf "$LOG_DIR"
    echo ""
    echo -e "${GREEN}All TUI tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}${failed} test(s) failed.${NC}"
    echo -e "Logs preserved at: ${LOG_DIR}"
    exit 1
fi

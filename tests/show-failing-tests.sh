#!/bin/bash
# show-failing-tests.sh
#
# Run every Go unit test and every shell-based test (CLI + TUI) one at a time.
# Each test runs in quiet mode: only the test name is announced on stdout.
# On a clean pass nothing else is emitted. On failure the captured output of
# the failing test is written to stderr and the runner moves on to the next
# test — failures do NOT abort the run. At the end the list of failing test
# files is printed. The exit code is non-zero only when at least one test
# failed.
#
# Tests are discovered exactly like the official runners
# (run-cli-tests-sequential.sh / run-tui-tests-parallel.sh) and iterated with a
# `for` loop. A `for` loop is required: TUI tests read from stdin (tmux), so a
# `while read < <(find ...)` loop would have its remaining input drained by the
# first TUI test and silently skip the rest.

# Intentionally no `set -e`: we must run every test even after earlier failures.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Build a fresh binary; bail out if the build itself fails — there is nothing
# to test without one.
if ! BUILD_OUT=$(just build 2>&1); then
    echo "✗ Build failed — cannot run tests" >&2
    echo "$BUILD_OUT" >&2
    exit 1
fi
cp bin/guard ./guard
chmod +x tests/*.sh 2>/dev/null || true

# TUI tests can hang; mirror the 30s ceiling used by run-tui-tests-parallel.sh.
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout 30"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout 30"
else
    TIMEOUT_CMD=""
fi

failed_tests=()
total=0
START_TIME=$(date +%s)

run_one() {
    local name="$1"; shift
    total=$((total + 1))
    echo "▶ ${name}"
    local out
    # Redirect stdin from /dev/null so a test cannot consume input meant for
    # the surrounding loop.
    if ! out=$("$@" </dev/null 2>&1); then
        failed_tests+=("$name")
        echo "✗ ${name} failed" >&2
        printf '%s\n' "$out" >&2
    fi
}

# Go unit tests — one invocation per package so a single failing package does
# not mask the rest.
for pkg in $(go list ./...); do
    run_one "$pkg" go test -count=1 "$pkg"
done

# Discover shell tests exactly like the CLI/TUI runners: all test-*.sh minus the
# two manual helper files, then split on whether the basename contains "tui".
TEST_FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "test-*.sh" -type f | sort)
TEST_FILES=$(echo "$TEST_FILES" | grep -v "test-assertions-and-framework.sh" | grep -v "test-guardfile-parsers.sh")
CLI_TEST_FILES=$(echo "$TEST_FILES" | grep -iv '/[^/]*tui[^/]*$' || true)
TUI_TEST_FILES=$(echo "$TEST_FILES" | grep -i  '/[^/]*tui[^/]*$' || true)

# CLI shell tests.
for tf in $CLI_TEST_FILES; do
    run_one "$(basename "$tf")" bash "$tf"
done

# TUI shell tests — wrapped in a timeout so a hung tmux session cannot stall the
# runner.
for tf in $TUI_TEST_FILES; do
    name=$(basename "$tf")
    if [ -n "$TIMEOUT_CMD" ]; then
        run_one "$name" $TIMEOUT_CMD bash "$tf"
    else
        run_one "$name" bash "$tf"
    fi
done

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ "${#failed_tests[@]}" -eq 0 ]; then
    echo "✓ ${total} tests passed in ${ELAPSED}s"
    exit 0
else
    echo "✗ ${#failed_tests[@]} of ${total} tests failed in ${ELAPSED}s" >&2
    echo "" >&2
    echo "Failing tests:" >&2
    for name in "${failed_tests[@]}"; do
        echo "  - ${name}" >&2
    done
    exit 1
fi

#!/bin/bash

# test-output-specs-013.sh - VERSION COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary (use absolute path to work from temp directories)
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif command -v guard &> /dev/null; then
    GUARD_BIN="guard"
else
    echo "Error: guard binary not found. Please build it first."
    exit 1
fi

# ============================================================================
# VERSION COMMAND OUTPUT TESTS
# ============================================================================
test_version_output_format() {
    log_test "test_version_output_format" \
             "Verify version output format: 'guard version X.Y.Z'"

    # Run
    set +e
    output=$($GUARD_BIN version 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for format: "guard version X.Y.Z" or "guard version vX.Y.Z..." (dev builds) or "guard version dev" or "guard version <git-hash>"
    # Accepts: "guard version 1.2.3", "guard version v0.0.0-82-ga7cb90a-dirty", "guard version dev", or "guard version d14f6fd"
    if echo "$output" | grep -qE "^guard version (v?[0-9]+\.[0-9]+\.[0-9]+|dev|[0-9a-f]{7,40}(-dirty)?)"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'guard version X.Y.Z' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'guard version X.Y.Z' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_version_output_format
print_test_summary 1

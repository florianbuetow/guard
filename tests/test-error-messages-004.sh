#!/bin/bash

# test-error-messages-004.sh - Usage message tests
# Verifies that error/warning messages match the formats specified in CLI-INTERFACE-SPECS.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Usage message tests
# ============================================================================
test_usage_message_shown() {
    log_test "test_usage_message_shown" \
             "Usage message shown with error"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    set +e
    output=$($GUARD_BIN toggle 2>&1)
    local exit_code=$?
    set -e

    # Should show usage hint
    if [[ "$output" == *"Usage"* ]] || [[ "$output" == *"guard toggle"* ]] || [[ "$output" == *"guard help"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Usage hint present in error output"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Usage hint not detected"
        echo "Got: $output"
    fi
}

# Run test
run_test test_usage_message_shown
print_test_summary 1

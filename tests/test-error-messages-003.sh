#!/bin/bash

# test-error-messages-003.sh - WARNING MESSAGE FORMAT TESTS
# Verifies that error/warning messages match the formats specified in CLI-INTERFACE-SPECS.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# WARNING MESSAGE FORMAT TESTS
# ============================================================================
test_warning_empty_folder() {
    log_test "test_warning_empty_folder" \
             "Warning message format: Empty folder"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    mkdir -p emptydir

    output=$($GUARD_BIN toggle folder emptydir 2>&1)
    local exit_code=$?

    # Per spec: Should warn about empty folder
    if [[ "$output" == *"empty"* ]] || [[ "$output" == *"no files"* ]] || [[ "$output" == *"Warning"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Empty folder warning present"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Empty folder warning not detected"
        echo "Got: $output"
    fi
}

# Run test
run_test test_warning_empty_folder
print_test_summary 1

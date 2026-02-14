#!/bin/bash

# test-output-specs-011.sh - SHOW FILE COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW FILE COMMAND OUTPUT TESTS
# ============================================================================
test_show_file_success_output() {
    log_test "test_show_file_success_output" \
             "Verify show file output format: [G/-] filename (collections)"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt
    $GUARD_BIN add file1.txt > /dev/null 2>&1
    $GUARD_BIN create docs > /dev/null 2>&1
    $GUARD_BIN update docs add file1.txt > /dev/null 2>&1
    $GUARD_BIN enable file file1.txt > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN show file file1.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for format: "G file1.txt (docs)"
    if echo "$output" | grep -qE "^G file1\.txt \(docs\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'G filename (collections)' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'G file1.txt (docs)' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_file_success_output
print_test_summary 1

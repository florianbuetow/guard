#!/bin/bash

# test-output-specs-012.sh - SHOW COLLECTION COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW COLLECTION COMMAND OUTPUT TESTS
# ============================================================================
test_show_collection_success_all() {
    log_test "test_show_collection_success_all" \
             "Verify show collection (all) output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt
    $GUARD_BIN create docs configs > /dev/null 2>&1
    $GUARD_BIN update docs add file1.txt > /dev/null 2>&1
    $GUARD_BIN enable collection docs > /dev/null 2>&1

    # Run - no arguments shows all collections
    set +e
    output=$($GUARD_BIN show collection 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for format: "[G/-] collection: name (N files)"
    if echo "$output" | grep -qE "^[G-] collection: docs \([0-9]+ files?\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches '[G/-] collection: name (N files)' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match '[G/-] collection: docs (N files)' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for summary line
    if echo "$output" | grep -qE "^[0-9]+ collection\(s\) total: [0-9]+ guarded, [0-9]+ unguarded$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output includes summary line"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should include 'N collection(s) total: X guarded, Y unguarded'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_collection_success_all
print_test_summary 1

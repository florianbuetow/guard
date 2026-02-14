#!/bin/bash

# test-update-004.sh - UPDATE REMOVE OUTPUT COUNT TESTS (Verify remove also uses delta)
# Tests modifying collection membership with: guard update <collection> add|remove <files>...
# Replaces: guard add file ... to ... and guard remove file ... from ...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UPDATE REMOVE OUTPUT COUNT TESTS (Verify remove also uses delta)
# ============================================================================
test_update_remove_single_file_output_count() {
    log_test "test_update_remove_single_file_output_count" \
             "Remove single file should show 'Removed 1 file(s)'"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt file3.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt file3.txt > /dev/null 2>&1

    # Run: Remove 1 file
    set +e
    output=$($GUARD_BIN update mycoll remove file1.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "Should succeed"

    # Should show "Removed 1 file(s)"
    if echo "$output" | grep -q "Removed 1 file(s) from collection 'mycoll'"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Removed 1 file(s)' (correct delta)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Removed 1 file(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_update_remove_single_file_output_count
print_test_summary 1

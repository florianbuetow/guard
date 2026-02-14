#!/bin/bash

# test-update-003.sh - UPDATE ADD OUTPUT COUNT TESTS (Bug fix: show delta, not cumulative)
# Tests modifying collection membership with: guard update <collection> add|remove <files>...
# Replaces: guard add file ... to ... and guard remove file ... from ...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UPDATE ADD OUTPUT COUNT TESTS (Bug fix: show delta, not cumulative)
# ============================================================================
test_update_add_single_file_output_count() {
    log_test "test_update_add_single_file_output_count" \
             "Add single file should show 'Added 1 file(s)', not cumulative total"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycoll

    # Run
    set +e
    output=$($GUARD_BIN update mycoll add file1.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "Should succeed"

    # Should show "Added 1 file(s)" - exactly 1, not any other number
    if echo "$output" | grep -q "Added 1 file(s) to collection 'mycoll'"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Added 1 file(s)' (correct count)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Added 1 file(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_update_add_single_file_output_count
print_test_summary 1

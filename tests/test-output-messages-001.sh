#!/bin/bash

# test-output-messages-001.sh - REMOVE FILE OUTPUT TESTS (edge cases only)
# Tests enable/disable/uninstall operation messages

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# REMOVE FILE OUTPUT TESTS (edge cases only)
# ============================================================================
test_output_no_message_when_file_not_in_collection() {
    log_test "test_output_no_message_when_file_not_in_collection" \
             "Verify NO 'Removed' message when file not in collection"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt other.txt
    # OLD: $GUARD_BIN add file file1.txt to alice > /dev/null 2>&1
    # OLD: $GUARD_BIN add file other.txt > /dev/null 2>&1
    # NEW:
    $GUARD_BIN create alice
    $GUARD_BIN update alice add file1.txt
    $GUARD_BIN add file other.txt

    # Run: Remove file not in collection using new syntax
    set +e
    output=$($GUARD_BIN update alice remove other.txt 2>&1)
    local exit_code=$?
    set -e

    # Should have NO "Removed" message (file wasn't in collection, so removed count = 0)
    if echo "$output" | grep -q "Removed"; then
        echo -e "${RED}✗ FAIL${NC}: Should not show 'Removed' message when no files removed"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASS${NC}: No 'Removed' message (correct behavior)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

# Run test
run_test test_output_no_message_when_file_not_in_collection
print_test_summary 1

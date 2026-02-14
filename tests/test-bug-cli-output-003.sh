#!/bin/bash

# test-bug-cli-output-003.sh - BUG #9: guard update doesn't display message for already-contained files
#
# This file tests the following bugs from docs/BUGS.md:
#
# Bug #7: guard toggle collection doesn't display output
# Bug #8: guard enable/disable collection output order is wrong
# Bug #9: guard update doesn't display message for already-contained files
#
# Tests are designed to FAIL when bugs exist, PASS when fixed.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# BUG #9: guard update doesn't display message for already-contained files
# ============================================================================
test_update_add_shows_already_contained_count() {
    log_test "test_update_add_shows_already_contained_count" \
             "BUG #9: Update add should show '[n] file(s) already contained in the collection'"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt > /dev/null 2>&1

    # Try to add same files again
    set +e
    output=$($GUARD_BIN update mycoll add file1.txt file2.txt 2>&1)
    set -e

    # Check for "already contained" message
    if echo "$output" | grep -qiE "[0-9]+ file\(s\) already (contained|in)"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows files already contained message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: BUG #9 - No 'already contained' message for duplicate files"
        echo -e "  Expected: '[n] file(s) already contained in the collection'"
        echo -e "  Actual output: '$output'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_update_add_shows_already_contained_count
print_test_summary 1

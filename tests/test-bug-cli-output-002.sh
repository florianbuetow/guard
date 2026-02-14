#!/bin/bash

# test-bug-cli-output-002.sh - BUG #8: guard enable/disable collection output order is wrong
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
# BUG #8: guard enable/disable collection output order is wrong
# ============================================================================
test_enable_collection_output_files_before_summary() {
    log_test "test_enable_collection_output_files_before_summary" \
             "BUG #8: Enable collection should show files first, then collection summary"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN create fruits
    $GUARD_BIN update fruits add apple.txt banana.txt cherry.txt

    # Enable collection
    set +e
    output=$($GUARD_BIN enable collection fruits 2>&1)
    set -e

    # Find line numbers for files and collection summary
    local first_file_line=0
    local summary_line=0
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))
        # Check for file names
        if [[ "$line" =~ apple\.txt|banana\.txt|cherry\.txt ]] && [ $first_file_line -eq 0 ]; then
            first_file_line=$line_num
        fi
        # Check for collection summary (contains "collection" and "fruits" or "enabled")
        if [[ "$line" =~ [Cc]ollection.*fruits ]] || [[ "$line" =~ fruits.*[Ee]nabled ]] || [[ "$line" =~ [Ee]nabled.*collection ]]; then
            summary_line=$line_num
        fi
    done <<< "$output"

    if [ $first_file_line -gt 0 ] && [ $summary_line -gt 0 ]; then
        if [ $first_file_line -lt $summary_line ]; then
            echo -e "${GREEN}✓ PASS${NC}: Files listed before collection summary"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: BUG #8 - Collection summary appears before files"
            echo -e "  First file at line: $first_file_line, Summary at line: $summary_line"
            echo -e "  Output:\n$output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: BUG #8 - Could not find expected output components"
        echo -e "  First file line: $first_file_line, Summary line: $summary_line"
        echo -e "  Output:\n$output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_enable_collection_output_files_before_summary
print_test_summary 1

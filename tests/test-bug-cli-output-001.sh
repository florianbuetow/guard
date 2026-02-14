#!/bin/bash

# test-bug-cli-output-001.sh - BUG #7: guard toggle collection doesn't display output
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
# BUG #7: guard toggle collection doesn't display output
# ============================================================================
test_toggle_collection_displays_enabled_disabled() {
    log_test "test_toggle_collection_displays_enabled_disabled" \
             "BUG #7: Toggle collection should display whether guard was enabled or disabled"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch doc1.txt doc2.txt
    $GUARD_BIN create docs
    $GUARD_BIN update docs add doc1.txt doc2.txt

    # First toggle: should enable and display "enabled"
    set +e
    output1=$($GUARD_BIN toggle collection docs 2>&1)
    set -e

    if echo "$output1" | grep -qi "enabled"; then
        echo -e "${GREEN}✓ PASS${NC}: First toggle displays 'enabled'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: BUG #7 - First toggle should display 'enabled'"
        echo -e "  Actual output: '$output1'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Second toggle: should disable and display "disabled"
    set +e
    output2=$($GUARD_BIN toggle collection docs 2>&1)
    set -e

    if echo "$output2" | grep -qi "disabled"; then
        echo -e "${GREEN}✓ PASS${NC}: Second toggle displays 'disabled'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: BUG #7 - Second toggle should display 'disabled'"
        echo -e "  Actual output: '$output2'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_toggle_collection_displays_enabled_disabled
print_test_summary 1

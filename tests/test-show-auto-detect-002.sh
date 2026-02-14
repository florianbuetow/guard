#!/bin/bash

# test-show-auto-detect-002.sh - SHOW AUTO-DETECTION TESTS - COLLECTION ONLY
# Tests auto-detection of files vs collections: guard show <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW AUTO-DETECTION TESTS - COLLECTION ONLY
# ============================================================================
test_show_auto_detect_single_collection() {
    log_test "test_show_auto_detect_single_collection" \
             "Auto-detect: show single collection when only collection exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt

    # Run show without 'collection' keyword
    set +e
    output=$($GUARD_BIN show mycoll 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "guard show should succeed"

    # Check that output contains collection info
    if [[ "$output" == *"mycoll"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Collection info displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Collection info not displayed"
        echo "Got: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_auto_detect_single_collection
print_test_summary 1

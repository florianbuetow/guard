#!/bin/bash

# test-show-auto-detect-001.sh - SHOW AUTO-DETECTION TESTS - FILE ONLY
# Tests auto-detection of files vs collections: guard show <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW AUTO-DETECTION TESTS - FILE ONLY
# ============================================================================
test_show_auto_detect_single_file() {
    log_test "test_show_auto_detect_single_file" \
             "Auto-detect: show single file when only file exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt
    $GUARD_BIN add file myfile.txt

    # Run show without 'file' keyword
    set +e
    output=$($GUARD_BIN show myfile.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "guard show should succeed"

    # Check that output contains file info
    if [[ "$output" == *"myfile.txt"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: File info displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File info not displayed"
        echo "Got: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_auto_detect_single_file
print_test_summary 1

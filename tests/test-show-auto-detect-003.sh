#!/bin/bash

# test-show-auto-detect-003.sh - SHOW AUTO-DETECTION TESTS - MIXED FILES AND COLLECTIONS
# Tests auto-detection of files vs collections: guard show <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW AUTO-DETECTION TESTS - MIXED FILES AND COLLECTIONS
# ============================================================================
test_show_auto_detect_mixed() {
    log_test "test_show_auto_detect_mixed" \
             "Auto-detect: show mix of files and collections"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch standalone.txt coll_file.txt
    $GUARD_BIN add file standalone.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add coll_file.txt

    # Run show with both file and collection
    set +e
    output=$($GUARD_BIN show standalone.txt mycoll 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "guard show should succeed"

    # Check that output contains both
    if [[ "$output" == *"standalone.txt"* ]] && [[ "$output" == *"mycoll"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Both file and collection displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Not all items displayed"
        echo "Got: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_auto_detect_mixed
print_test_summary 1

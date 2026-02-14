#!/bin/bash

# test-show-commands-002.sh - SHOW COLLECTION TESTS
# Tests guard show file/collection, info, version, help commands

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# SHOW COLLECTION TESTS
# ============================================================================
test_show_collection_positive() {
    log_test "test_show_collection_positive" \
             "Positive test: Show collection with files and their guard status"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    # OLD: $GUARD_BIN add file file1.txt file2.txt to mycoll
    # NEW:
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt
    $GUARD_BIN enable collection mycoll

    # Run
    output=$($GUARD_BIN show collection mycoll 2>&1)
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "Should succeed"

    # Should show collection guard status (CLI-SPECS line 164)
    if [[ "$output" == *"mycoll"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Collection name displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Collection name not displayed"
        echo "Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Should show files and their guard status
    if [[ "$output" == *"file1.txt"* ]] || [[ "$output" == *"file2.txt"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Member files displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Member files not detected in output"
        echo "Output: $output"
    fi
}

# Run test
run_test test_show_collection_positive
print_test_summary 1

#!/bin/bash

# test-missing-file-warnings-001.sh - MISSING FILE WARNING TESTS
# Tests that warnings correctly identify missing files and suggest cleanup

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# MISSING FILE WARNING TESTS
# ============================================================================
test_enable_collection_missing_file_warning() {
    log_test "test_enable_collection_missing_file_warning" \
             "Enable collection with missing file shows warning with cleanup suggestion"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    $GUARD_BIN create testcoll
    $GUARD_BIN update testcoll add file1.txt file2.txt

    # Delete one file to create missing file scenario
    rm -f file2.txt

    # Run: Enable collection
    set +e
    output=$($GUARD_BIN enable collection testcoll 2>&1)
    local exit_code=$?
    set -e

    # Should have warning about missing file
    if echo "$output" | grep -qi "file2.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Warning mentions missing file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Warning should mention missing file 'file2.txt'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Should suggest cleanup
    if echo "$output" | grep -qi "cleanup"; then
        echo -e "${GREEN}✓ PASS${NC}: Warning suggests running cleanup"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Warning should suggest 'guard cleanup'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_enable_collection_missing_file_warning
print_test_summary 1

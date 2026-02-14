#!/bin/bash

# test-edge-cases-002.sh - SPECIAL SCENARIOS
# Tests special scenarios, error conditions, and system limits

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# SPECIAL SCENARIOS
# ============================================================================
test_file_in_multiple_collections() {
    log_test "test_file_in_multiple_collections" \
             "Files can be in multiple collections with different guard states"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    # OLD: $GUARD_BIN add file file1.txt to coll1 coll2
    # NEW:
    $GUARD_BIN create coll1 coll2
    $GUARD_BIN update coll1 add file1.txt
    $GUARD_BIN update coll2 add file1.txt

    # Enable only coll1
    $GUARD_BIN enable collection coll1

    # Assert: file1 is guarded
    local guard_flag=$(get_guard_flag "$(pwd)/file1.txt")
    assert_equals "true" "$guard_flag" "File should be guarded"

    # Assert: file1 still in both collections (CLI-SPECS line 207)
    if file_in_collection "$(pwd)/file1.txt" "coll1"; then
        echo -e "${GREEN}✓ PASS${NC}: File still in coll1"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File not in coll1"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_collection "$(pwd)/file1.txt" "coll2"; then
        echo -e "${GREEN}✓ PASS${NC}: File still in coll2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File not in coll2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_file_in_multiple_collections
print_test_summary 1

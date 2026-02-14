#!/bin/bash

# test-create-001.sh - CREATE COLLECTION TESTS
# Tests creating collections with: guard create <collection>...
# Replaces: guard add collection <collection>...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CREATE COLLECTION TESTS
# ============================================================================
test_create_positive() {
    log_test "test_create_positive" \
             "Positive test: Create new collection with guard create"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Run
    $GUARD_BIN create mygroup
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard create should succeed"

    if collection_exists_in_registry "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: Collection exists in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Collection not in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    local guard_flag=$(get_collection_guard_flag "mygroup")
    assert_equals "false" "$guard_flag" "Collection guard flag should be false"
}

# Run test
run_test test_create_positive
print_test_summary 1

#!/bin/bash

# test-clear-006.sh - EDGE CASE TESTS
# The clear command:
# 1. Disables guard on the collection(s) and all files in them
# 2. Removes all files from the collection(s) (collections become empty)
# 3. Collections remain in the registry (now empty)
# 4. Files remain registered in guard (not unregistered)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# EDGE CASE TESTS
# ============================================================================
test_clear_mixed_existing_nonexisting() {
    log_test "test_clear_mixed_existing_nonexisting" \
             "Clear with mix of existing and non-existing collections"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    chmod 644 file1.txt

    # OLD: $GUARD_BIN add file file1.txt to existing
    # NEW:
    $GUARD_BIN create existing
    $GUARD_BIN update existing add file1.txt
    $GUARD_BIN enable collection existing

    # Clear both existing and non-existing
    set +e
    output=$($GUARD_BIN clear existing nonexisting 2>&1)
    local exit_code=$?
    set -e

    # Should succeed (warnings for non-existing)
    assert_exit_code $exit_code 0 "Clear with mixed collections should succeed"

    # Should have warning for non-existing
    if [[ "$output" == *"arning"* ]] || [[ "$output" == *"nonexisting"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Warning for non-existing collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Warning not detected"
    fi

    # Existing collection should be cleared
    if ! file_in_collection "$(pwd)/file1.txt" "existing"; then
        echo -e "${GREEN}✓ PASS${NC}: File removed from existing collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File still in existing collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_clear_mixed_existing_nonexisting
print_test_summary 1

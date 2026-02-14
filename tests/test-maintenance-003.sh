#!/bin/bash

# test-maintenance-003.sh - UNINSTALL TESTS
# Tests guard cleanup, reset, uninstall commands

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# UNINSTALL TESTS
# ============================================================================
test_uninstall_sequence() {
    log_test "test_uninstall_sequence" \
             "Uninstall should run reset, cleanup, and delete .guardfile"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    # OLD: $GUARD_BIN add file file1.txt to mycoll
    # OLD: $GUARD_BIN add collection empty_coll
    # NEW:
    $GUARD_BIN create mycoll empty_coll
    $GUARD_BIN update mycoll add file1.txt
    $GUARD_BIN enable collection mycoll

    # Delete file2 to create cleanup target
    rm -f file2.txt

    # Verify .guardfile exists
    assert_guardfile_exists "Setup: .guardfile should exist"

    # Run uninstall
    $GUARD_BIN uninstall
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "Uninstall should succeed"

    # .guardfile should be deleted
    if [ ! -f ".guardfile" ]; then
        echo -e "${GREEN}✓ PASS${NC}: .guardfile deleted"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: .guardfile still exists"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Guards should be disabled (check file permissions)
    if [ -f "file1.txt" ]; then
        local perms=$(get_file_permissions "file1.txt")
        # Permissions should be restored (not 000)
        if [ "$perms" != "000" ]; then
            echo -e "${GREEN}✓ PASS${NC}: File permissions restored before deletion"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ FAIL${NC}: File permissions not restored"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
}

# Run test
run_test test_uninstall_sequence
print_test_summary 1

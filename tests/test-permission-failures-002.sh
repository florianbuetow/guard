#!/bin/bash

# test-permission-failures-002.sh - GUARD RESET - PERMISSION RESTORE FAILURE TESTS
# Tests error handling when permission operations fail
#
# Approach: Remove execute permission from parent directory to make files
# inaccessible. This causes chmod to fail with "permission denied" because
# the kernel can't traverse to the file.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# GUARD RESET - PERMISSION RESTORE FAILURE TESTS
# ============================================================================
test_reset_permission_restore_failure() {
    log_test "test_reset_permission_restore_failure" \
             "Reset should error when permission restore fails"

    local current_user=$(get_current_user)
    local current_group=$(get_current_group)

    # Setup
    mkdir -p restricted_dir
    touch restricted_dir/protected.txt

    $GUARD_BIN init 000 "$current_user" "$current_group"
    $GUARD_BIN add restricted_dir/protected.txt
    $GUARD_BIN enable file restricted_dir/protected.txt

    # Remove execute permission from directory
    chmod 600 restricted_dir

    # Run reset
    set +e
    output=$($GUARD_BIN reset 2>&1)
    local exit_code=$?
    set -e

    # Restore permissions
    chmod 755 restricted_dir

    # Assert: Should fail with exit code 1
    assert_exit_code $exit_code 1 "Reset should fail when permission restore fails"

    # Assert: Error message format
    if echo "$output" | grep -q "^Error:.*[Ff]ailed.*restore.*permission"; then
        echo -e "${GREEN}✓ PASS${NC}: Error message mentions failed permission restore"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Error message should mention failed permission restore"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert: Error message includes filename
    if echo "$output" | grep -q "protected.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Error message includes filename"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Error message should include filename"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_reset_permission_restore_failure
print_test_summary 1

#!/bin/bash

# test-bug-save-registry-rollback-001.sh - SaveRegistry failure should rollback file changes
#
# If SaveRegistry fails, filesystem changes should be rolled back to avoid
# inconsistent state (file permissions changed but registry unchanged).

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif command -v guard &> /dev/null; then
    GUARD_BIN="guard"
else
    echo "Error: guard binary not found. Please build it first."
    exit 1
fi

# ============================================================================
# ROLLBACK TEST
# ============================================================================

test_save_registry_failure_rolls_back_permissions() {
    log_test "test_save_registry_failure_rolls_back_permissions" \
             "SaveRegistry failure should rollback guarded file permissions"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt
    chmod 644 testfile.txt
    $GUARD_BIN add testfile.txt

    # Make .guardfile read-only to force SaveRegistry failure
    chmod 400 .guardfile

    # Attempt to enable guard (should fail)
    set +e
    output=$($GUARD_BIN enable file testfile.txt 2>&1)
    exit_code=$?
    set -e

    if [ $exit_code -eq 0 ]; then
        echo -e "${RED}✗ FAIL${NC}: enable should fail when .guardfile is not writable"
        echo -e "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return
    fi
    echo -e "${GREEN}✓ PASS${NC}: enable failed as expected"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    # Permissions should be rolled back to original 644
    perms=$(get_file_permissions "testfile.txt")
    if [ "$perms" = "644" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Permissions rolled back to 644"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Permissions not rolled back (got $perms)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_save_registry_failure_rolls_back_permissions
print_test_summary 1

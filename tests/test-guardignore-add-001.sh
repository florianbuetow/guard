#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-add-001"

test_add_skips_ignored_files() {
    log_test "$TEST_NAME" "guard add should warn and skip ignored files"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # Create .guardignore
    echo "*.log" > .guardignore

    # Create test files
    touch important.go debug.log

    # Add non-ignored file should work normally
    OUTPUT=$("$GUARD_BIN" add important.go 2>&1)
    assert_exit_code $? 0 "adding non-ignored file should succeed"

    # Add ignored file should warn
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "should warn about ignored file"

    # Verify debug.log was NOT added to registry
    if file_in_registry debug.log; then
        echo -e "${RED}✗ FAIL${NC}: debug.log should NOT be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASS${NC}: debug.log correctly not in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

run_test test_add_skips_ignored_files
exit $?

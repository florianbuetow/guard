#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-add-002"

test_add_force_overrides_ignore() {
    log_test "$TEST_NAME" "guard add --force should add ignored files"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    echo "*.log" > .guardignore
    touch debug.log

    # Force add should succeed
    OUTPUT=$("$GUARD_BIN" add --force debug.log 2>&1)
    assert_exit_code $? 0 "guard add --force should succeed for ignored file"

    # Verify debug.log WAS added to registry
    if file_in_registry debug.log; then
        echo -e "${GREEN}✓ PASS${NC}: debug.log is in registry after --force"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: debug.log should be in registry after --force"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

run_test test_add_force_overrides_ignore
exit $?

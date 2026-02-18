#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-init-001"

test_init_creates_guardignore() {
    log_test "$TEST_NAME" "guard init should create .guardignore with template comments"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    # Init guard
    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # .guardignore should exist
    if [ ! -f .guardignore ]; then
        echo -e "${RED}✗ FAIL${NC}: .guardignore was not created by guard init"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo -e "${GREEN}✓ PASS${NC}: .guardignore file was created"
    TESTS_PASSED=$((TESTS_PASSED + 1))

    # Check content
    CONTENT=$(cat .guardignore)
    assert_output_contains "$CONTENT" ".guardignore works like .gitignore" \
        ".guardignore should contain usage hint"
    assert_output_contains "$CONTENT" "use_gitignore" \
        ".guardignore should mention use_gitignore config"
    assert_output_contains "$CONTENT" "add your custom ignore rules below" \
        ".guardignore should contain custom rules hint"
}

run_test test_init_creates_guardignore
exit $?

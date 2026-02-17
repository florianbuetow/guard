#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-002"

test_ignore_config_flags_default_behavior() {
    log_test "$TEST_NAME" "Config flags use_gitignore and use_guardignore are persisted and active by default"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # Create both ignore files
    echo "*.log" > .gitignore
    echo "*.tmp" > .guardignore

    touch test.log test.tmp test.go

    # Default config: both ignore sources are enabled
    OUTPUT=$("$GUARD_BIN" add test.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "test.log should be ignored by .gitignore"

    OUTPUT=$("$GUARD_BIN" add test.tmp 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "test.tmp should be ignored by .guardignore"

    OUTPUT=$("$GUARD_BIN" add test.go 2>&1)
    assert_exit_code $? 0 "test.go should add normally (not ignored)"

    # Verify fields are persisted in .guardfile
    GUARDFILE_CONTENT=$(cat .guardfile)
    assert_output_contains "$GUARDFILE_CONTENT" "use_gitignore" \
        ".guardfile should contain use_gitignore field"
    assert_output_contains "$GUARDFILE_CONTENT" "use_guardignore" \
        ".guardfile should contain use_guardignore field"
}

run_test test_ignore_config_flags_default_behavior
exit $?

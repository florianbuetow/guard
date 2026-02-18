#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-init-002"

test_init_config_flags() {
    log_test "$TEST_NAME" "guard init should set use_gitignore and use_guardignore to true in .guardfile"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    GUARDFILE_CONTENT=$(cat .guardfile)
    assert_output_contains "$GUARDFILE_CONTENT" "use_gitignore: true" \
        ".guardfile should contain use_gitignore: true"
    assert_output_contains "$GUARDFILE_CONTENT" "use_guardignore: true" \
        ".guardfile should contain use_guardignore: true"
}

run_test test_init_config_flags
exit $?

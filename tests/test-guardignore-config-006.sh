#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-006"

# Test: guard config show displays use_gitignore and use_guardignore values

test_config_show_displays_ignore_flags() {
    log_test "$TEST_NAME" "guard config show should display use_gitignore and use_guardignore"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # Default state: both flags should be true
    OUTPUT=$("$GUARD_BIN" config show 2>&1)
    assert_output_contains "$OUTPUT" "use_gitignore" "config show should display use_gitignore"
    assert_output_contains "$OUTPUT" "use_guardignore" "config show should display use_guardignore"
    assert_output_contains "$OUTPUT" "true" "default values should be true"

    # Set use_gitignore to false via sed, then verify config show reflects it
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/use_gitignore: true/use_gitignore: false/' .guardfile
    else
        sed -i 's/use_gitignore: true/use_gitignore: false/' .guardfile
    fi

    OUTPUT=$("$GUARD_BIN" config show 2>&1)
    assert_output_contains "$OUTPUT" "false" "config show should reflect use_gitignore=false"
}

run_test test_config_show_displays_ignore_flags
exit $?

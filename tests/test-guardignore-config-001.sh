#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-001"

test_gitignore_disabled() {
    log_test "$TEST_NAME" "use_gitignore=false should disable .gitignore rule processing"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # Create ignore files
    echo "*.log" > .gitignore
    echo "*.tmp" > .guardignore

    touch debug.log temp.tmp main.go

    # Disable use_gitignore in .guardfile
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/use_gitignore: true/use_gitignore: false/' .guardfile
    else
        sed -i 's/use_gitignore: true/use_gitignore: false/' .guardfile
    fi

    # debug.log should NOT be ignored (gitignore disabled)
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1)
    assert_exit_code $? 0 "debug.log should add when use_gitignore=false"

    # temp.tmp should still be ignored (guardignore still active)
    OUTPUT=$("$GUARD_BIN" add temp.tmp 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "temp.tmp should still be ignored by .guardignore"
}

run_test test_gitignore_disabled
exit $?

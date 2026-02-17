#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-add-003"

test_add_stacked_ignore() {
    log_test "$TEST_NAME" "guard add should respect stacked .gitignore and .guardignore files"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # Create directory structure
    mkdir -p src/vendor

    # Root .gitignore ignores *.log
    echo "*.log" > .gitignore

    # src/.guardignore ignores *.dat
    echo "*.dat" > src/.guardignore

    # Create test files
    touch main.go debug.log
    touch src/app.go src/cache.dat
    touch src/vendor/lib.go

    # main.go should add fine (not ignored)
    OUTPUT=$("$GUARD_BIN" add main.go 2>&1)
    assert_exit_code $? 0 "main.go should add (not ignored)"

    # debug.log should be ignored (root .gitignore)
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "debug.log should be ignored by root .gitignore"

    # src/app.go should add fine (not ignored)
    OUTPUT=$("$GUARD_BIN" add src/app.go 2>&1)
    assert_exit_code $? 0 "src/app.go should add (not ignored)"

    # src/cache.dat should be ignored (src/.guardignore)
    OUTPUT=$("$GUARD_BIN" add src/cache.dat 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "src/cache.dat should be ignored by src/.guardignore"

    # src/vendor/lib.go should add fine (not ignored)
    OUTPUT=$("$GUARD_BIN" add src/vendor/lib.go 2>&1)
    assert_exit_code $? 0 "src/vendor/lib.go should add (not ignored)"
}

run_test test_add_stacked_ignore
exit $?

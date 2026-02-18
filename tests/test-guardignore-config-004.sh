#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-004"

# Same scenario as config-003 / config-005 (see config-003 for full layout docs).
#
# This test: use_gitignore=false, use_guardignore=false
# Expected: ALL ignore patterns inactive. Every file adds. No warnings.

test_stacked_both_off() {
    log_test "$TEST_NAME" "use_gitignore=false, use_guardignore=false: stacked directory scenario"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # --- Build directory structure ---
    mkdir -p src vendor

    echo "*.log"   >  .gitignore
    echo "vendor/" >> .gitignore

    printf '*.tmp\n!vendor/important.go\n' > .guardignore

    echo "*.bak"   > src/.gitignore
    echo "*.cache" > src/.guardignore

    touch main.go debug.log temp.tmp
    touch src/app.go src/backup.bak src/store.cache src/trace.log
    touch vendor/dep.go vendor/important.go

    # --- Flip config ---
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/use_gitignore: true/use_gitignore: false/' .guardfile
        sed -i '' 's/use_guardignore: true/use_guardignore: false/' .guardfile
    else
        sed -i 's/use_gitignore: true/use_gitignore: false/' .guardfile
        sed -i 's/use_guardignore: true/use_guardignore: false/' .guardfile
    fi

    # --- Assertions: every file should add, no warnings ---

    # main.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add main.go 2>&1)
    assert_exit_code $? 0 "main.go should add"

    # debug.log: *.log pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1)
    assert_exit_code $? 0 "debug.log should add (gitignore disabled)"

    # temp.tmp: *.tmp pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add temp.tmp 2>&1)
    assert_exit_code $? 0 "temp.tmp should add (guardignore disabled)"

    # src/app.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add src/app.go 2>&1)
    assert_exit_code $? 0 "src/app.go should add"

    # src/backup.bak: *.bak pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add src/backup.bak 2>&1)
    assert_exit_code $? 0 "src/backup.bak should add (gitignore disabled)"

    # src/store.cache: *.cache pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add src/store.cache 2>&1)
    assert_exit_code $? 0 "src/store.cache should add (guardignore disabled)"

    # src/trace.log: *.log cascade inactive → adds
    OUTPUT=$("$GUARD_BIN" add src/trace.log 2>&1)
    assert_exit_code $? 0 "src/trace.log should add (gitignore cascade disabled)"

    # vendor/dep.go: vendor/ pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add vendor/dep.go 2>&1)
    assert_exit_code $? 0 "vendor/dep.go should add (gitignore disabled)"

    # vendor/important.go: vendor/ pattern inactive → adds
    OUTPUT=$("$GUARD_BIN" add vendor/important.go 2>&1)
    assert_exit_code $? 0 "vendor/important.go should add (both disabled)"

    # --- Verify no "ignored" warnings in any output ---
    ALL_OUTPUT=$("$GUARD_BIN" add main.go 2>&1 || true)  # already registered, but shouldn't say "ignored"
    if [[ "$ALL_OUTPUT" == *"ignored"* ]]; then
        echo -e "${RED}✗ FAIL${NC}: output should never contain 'ignored' when both sources disabled"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASS${NC}: no 'ignored' warnings with both sources disabled"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi

    # --- Verify final registry state ---
    # Should contain all 9 files
    local count=$(count_files_in_registry)
    assert_equals "9" "$count" "all 9 files should be in registry"
}

run_test test_stacked_both_off
exit $?

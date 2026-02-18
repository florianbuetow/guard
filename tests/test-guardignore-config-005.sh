#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-005"

# Same scenario as config-003 / config-004 (see config-003 for full layout docs).
#
# This test: use_gitignore=false, use_guardignore=true
# Expected: gitignore patterns inactive, guardignore patterns active.
#   - *.log NOT blocked (gitignore disabled)
#   - vendor/ NOT blocked (gitignore disabled)
#   - *.bak NOT blocked (src/.gitignore disabled)
#   - *.tmp blocked (guardignore active)
#   - *.cache blocked (src/.guardignore active)
#   - !vendor/important.go negation present but nothing to negate (vendor/ not blocked)

test_stacked_gitignore_off_guardignore_on() {
    log_test "$TEST_NAME" "use_gitignore=false, use_guardignore=true: stacked directory scenario"
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
    else
        sed -i 's/use_gitignore: true/use_gitignore: false/' .guardfile
    fi

    # --- Assertions ---

    # main.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add main.go 2>&1)
    assert_exit_code $? 0 "main.go should add (not ignored)"

    # debug.log: *.log from .gitignore → NOT blocked (gitignore disabled)
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1)
    assert_exit_code $? 0 "debug.log should add (gitignore disabled)"
    if file_in_registry debug.log; then
        echo -e "${GREEN}✓ PASS${NC}: debug.log is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: debug.log should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # temp.tmp: *.tmp from .guardignore → blocked
    OUTPUT=$("$GUARD_BIN" add temp.tmp 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "temp.tmp blocked by root .guardignore *.tmp"

    # src/app.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add src/app.go 2>&1)
    assert_exit_code $? 0 "src/app.go should add (not ignored)"

    # src/backup.bak: *.bak from src/.gitignore → NOT blocked (gitignore disabled)
    OUTPUT=$("$GUARD_BIN" add src/backup.bak 2>&1)
    assert_exit_code $? 0 "src/backup.bak should add (gitignore disabled)"
    if file_in_registry src/backup.bak; then
        echo -e "${GREEN}✓ PASS${NC}: src/backup.bak is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: src/backup.bak should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # src/store.cache: *.cache from src/.guardignore → blocked
    OUTPUT=$("$GUARD_BIN" add src/store.cache 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "src/store.cache blocked by src/.guardignore *.cache"

    # src/trace.log: *.log from root .gitignore → NOT blocked (gitignore disabled)
    OUTPUT=$("$GUARD_BIN" add src/trace.log 2>&1)
    assert_exit_code $? 0 "src/trace.log should add (gitignore cascade disabled)"
    if file_in_registry src/trace.log; then
        echo -e "${GREEN}✓ PASS${NC}: src/trace.log is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: src/trace.log should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # vendor/dep.go: vendor/ from .gitignore → NOT blocked (gitignore disabled)
    OUTPUT=$("$GUARD_BIN" add vendor/dep.go 2>&1)
    assert_exit_code $? 0 "vendor/dep.go should add (gitignore disabled)"
    if file_in_registry vendor/dep.go; then
        echo -e "${GREEN}✓ PASS${NC}: vendor/dep.go is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: vendor/dep.go should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # vendor/important.go: vendor/ from .gitignore disabled, negation in .guardignore
    # is present but has nothing to negate → adds
    OUTPUT=$("$GUARD_BIN" add vendor/important.go 2>&1)
    assert_exit_code $? 0 "vendor/important.go should add (gitignore disabled, negation is no-op)"
    if file_in_registry vendor/important.go; then
        echo -e "${GREEN}✓ PASS${NC}: vendor/important.go is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: vendor/important.go should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # --- Verify final registry state ---
    # Blocked: temp.tmp, src/store.cache  (2 files)
    # Added: main.go, debug.log, src/app.go, src/backup.bak, src/trace.log,
    #        vendor/dep.go, vendor/important.go  (7 files)
    local count=$(count_files_in_registry)
    assert_equals "7" "$count" "exactly 7 files should be in registry"
}

run_test test_stacked_gitignore_off_guardignore_on
exit $?

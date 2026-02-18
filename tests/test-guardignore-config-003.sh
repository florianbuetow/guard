#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-003"

# Shared scenario used across config-003, config-004, config-005.
# Same directory structure and ignore files, different config flags,
# different expected outcomes.
#
# Directory layout:
#   .gitignore        *.log, vendor/
#   .guardignore      *.tmp, !vendor/important.go  (negates gitignore vendor/ for one file)
#   src/.gitignore    *.bak
#   src/.guardignore  *.cache
#
# Files:
#   main.go                  not matched by any pattern
#   debug.log                matched by root .gitignore  *.log
#   temp.tmp                 matched by root .guardignore *.tmp
#   src/app.go               not matched by any pattern
#   src/backup.bak           matched by src/.gitignore   *.bak
#   src/store.cache          matched by src/.guardignore *.cache
#   src/trace.log            matched by root .gitignore  *.log  (cascades into src/)
#   vendor/dep.go            matched by root .gitignore  vendor/
#   vendor/important.go      matched by root .gitignore  vendor/, negated by root .guardignore !vendor/important.go
#
# This test: use_gitignore=true, use_guardignore=false
# Expected: gitignore patterns active, guardignore patterns inactive.
#   - *.log blocked (gitignore)
#   - vendor/ blocked (gitignore)
#   - *.bak blocked (src/.gitignore)
#   - *.tmp NOT blocked (guardignore disabled)
#   - *.cache NOT blocked (guardignore disabled)
#   - !vendor/important.go negation NOT active (guardignore disabled) → vendor/important.go stays blocked by gitignore

test_stacked_gitignore_on_guardignore_off() {
    log_test "$TEST_NAME" "use_gitignore=true, use_guardignore=false: stacked directory scenario"
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
        sed -i '' 's/use_guardignore: true/use_guardignore: false/' .guardfile
    else
        sed -i 's/use_guardignore: true/use_guardignore: false/' .guardfile
    fi

    # --- Assertions ---

    # main.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add main.go 2>&1)
    assert_exit_code $? 0 "main.go should add (not ignored)"

    # debug.log: *.log from root .gitignore → blocked
    OUTPUT=$("$GUARD_BIN" add debug.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "debug.log blocked by root .gitignore *.log"

    # temp.tmp: *.tmp from root .guardignore → NOT blocked (guardignore disabled)
    OUTPUT=$("$GUARD_BIN" add temp.tmp 2>&1)
    assert_exit_code $? 0 "temp.tmp should add (guardignore disabled)"
    if file_in_registry temp.tmp; then
        echo -e "${GREEN}✓ PASS${NC}: temp.tmp is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: temp.tmp should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # src/app.go: not matched → adds
    OUTPUT=$("$GUARD_BIN" add src/app.go 2>&1)
    assert_exit_code $? 0 "src/app.go should add (not ignored)"

    # src/backup.bak: *.bak from src/.gitignore → blocked
    OUTPUT=$("$GUARD_BIN" add src/backup.bak 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "src/backup.bak blocked by src/.gitignore *.bak"

    # src/store.cache: *.cache from src/.guardignore → NOT blocked (guardignore disabled)
    OUTPUT=$("$GUARD_BIN" add src/store.cache 2>&1)
    assert_exit_code $? 0 "src/store.cache should add (guardignore disabled)"
    if file_in_registry src/store.cache; then
        echo -e "${GREEN}✓ PASS${NC}: src/store.cache is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: src/store.cache should be in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # src/trace.log: *.log from root .gitignore cascades → blocked
    OUTPUT=$("$GUARD_BIN" add src/trace.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "src/trace.log blocked by root .gitignore cascade"

    # vendor/dep.go: vendor/ from root .gitignore → blocked
    OUTPUT=$("$GUARD_BIN" add vendor/dep.go 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "vendor/dep.go blocked by root .gitignore vendor/"

    # vendor/important.go: vendor/ from .gitignore, negation !vendor/important.go from
    # .guardignore is DISABLED → stays blocked
    OUTPUT=$("$GUARD_BIN" add vendor/important.go 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "vendor/important.go blocked (guardignore negation disabled)"

    # --- Verify final registry state ---
    # Should contain: main.go, temp.tmp, src/app.go, src/store.cache  (4 files)
    local count=$(count_files_in_registry)
    assert_equals "4" "$count" "exactly 4 files should be in registry"
}

run_test test_stacked_gitignore_on_guardignore_off
exit $?

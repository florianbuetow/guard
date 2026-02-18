#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"

TEST_NAME="guardignore-config-007"

# Test: guard config set use_gitignore / use_guardignore

test_config_set_ignore_flags() {
    log_test "$TEST_NAME" "guard config set use_gitignore/use_guardignore with true/false values"
    find_guard_binary
    CURRENT_USER=$(get_current_user)
    CURRENT_GROUP=$(get_current_group)

    "$GUARD_BIN" init 0644 "$CURRENT_USER" "$CURRENT_GROUP"

    # --- Set use_gitignore to false ---
    OUTPUT=$("$GUARD_BIN" config set use_gitignore false 2>&1)
    assert_exit_code $? 0 "config set use_gitignore false should succeed"
    assert_output_contains "$OUTPUT" "use_gitignore" "output should mention use_gitignore"
    assert_output_contains "$OUTPUT" "false" "output should confirm false"

    # Verify it persisted in .guardfile
    GUARDFILE_CONTENT=$(cat .guardfile)
    assert_output_contains "$GUARDFILE_CONTENT" "use_gitignore: false" \
        "use_gitignore: false should be persisted in .guardfile"

    # --- Set use_guardignore to false ---
    OUTPUT=$("$GUARD_BIN" config set use_guardignore false 2>&1)
    assert_exit_code $? 0 "config set use_guardignore false should succeed"
    assert_output_contains "$OUTPUT" "use_guardignore" "output should mention use_guardignore"

    GUARDFILE_CONTENT=$(cat .guardfile)
    assert_output_contains "$GUARDFILE_CONTENT" "use_guardignore: false" \
        "use_guardignore: false should be persisted in .guardfile"

    # --- Set both back to true ---
    OUTPUT=$("$GUARD_BIN" config set use_gitignore true 2>&1)
    assert_exit_code $? 0 "config set use_gitignore true should succeed"

    OUTPUT=$("$GUARD_BIN" config set use_guardignore true 2>&1)
    assert_exit_code $? 0 "config set use_guardignore true should succeed"

    GUARDFILE_CONTENT=$(cat .guardfile)
    assert_output_contains "$GUARDFILE_CONTENT" "use_gitignore: true" \
        "use_gitignore: true should be persisted after re-enable"
    assert_output_contains "$GUARDFILE_CONTENT" "use_guardignore: true" \
        "use_guardignore: true should be persisted after re-enable"

    # --- Invalid value should fail ---
    OUTPUT=$("$GUARD_BIN" config set use_gitignore maybe 2>&1 || true)
    assert_output_contains "$OUTPUT" "Error" "invalid boolean value should produce an error"

    OUTPUT=$("$GUARD_BIN" config set use_guardignore 123 2>&1 || true)
    assert_output_contains "$OUTPUT" "Error" "numeric non-boolean value should produce an error"

    # --- Verify the flag actually affects behavior ---
    echo "*.log" > .gitignore
    echo "*.tmp" > .guardignore
    touch test.log test.tmp test.go

    # With both enabled (default), both should be ignored
    OUTPUT=$("$GUARD_BIN" add test.log 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "test.log should be ignored with use_gitignore=true"

    OUTPUT=$("$GUARD_BIN" add test.tmp 2>&1 || true)
    assert_output_contains "$OUTPUT" "ignored" "test.tmp should be ignored with use_guardignore=true"

    # Disable gitignore via config set, then test.log should add
    "$GUARD_BIN" config set use_gitignore false 2>&1
    OUTPUT=$("$GUARD_BIN" add test.log 2>&1)
    assert_exit_code $? 0 "test.log should add after use_gitignore set to false"

    # Re-enable gitignore, disable guardignore, then test.tmp should add
    "$GUARD_BIN" config set use_gitignore true 2>&1
    "$GUARD_BIN" config set use_guardignore false 2>&1
    "$GUARD_BIN" remove test.log 2>&1  # clean up for clarity
    OUTPUT=$("$GUARD_BIN" add test.tmp 2>&1)
    assert_exit_code $? 0 "test.tmp should add after use_guardignore set to false"
}

run_test test_config_set_ignore_flags
exit $?

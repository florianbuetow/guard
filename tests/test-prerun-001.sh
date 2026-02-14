#!/bin/bash

# test-prerun-001.sh - PersistentPreRunE edge cases
# Tests that version/completion work without .guardfile and that
# missing .guardfile produces an error (not usage dump) for regular commands.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TEST: version works without .guardfile
# ============================================================================
test_version_without_guardfile() {
    log_test "test_version_without_guardfile" \
             "guard version succeeds without a .guardfile"

    # No .guardfile in the temp dir
    output=$($GUARD_BIN version 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "version should exit 0 without .guardfile"
}

# ============================================================================
# TEST: completion bash works without .guardfile
# ============================================================================
test_completion_bash_without_guardfile() {
    log_test "test_completion_bash_without_guardfile" \
             "guard completion bash succeeds without a .guardfile (parent chain check)"

    output=$($GUARD_BIN completion bash 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "completion bash should exit 0 without .guardfile"
}

# ============================================================================
# TEST: completion zsh works without .guardfile
# ============================================================================
test_completion_zsh_without_guardfile() {
    log_test "test_completion_zsh_without_guardfile" \
             "guard completion zsh succeeds without a .guardfile (parent chain check)"

    output=$($GUARD_BIN completion zsh 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "completion zsh should exit 0 without .guardfile"
}

# ============================================================================
# TEST: missing .guardfile gives error, not usage dump
# ============================================================================
test_missing_guardfile_no_usage() {
    log_test "test_missing_guardfile_no_usage" \
             "guard show without .guardfile errors without printing usage"

    output=$($GUARD_BIN show 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 1 "show should fail without .guardfile"
    assert_output_contains "$output" "Error" "Should print error message"
}

# Run tests
run_test test_version_without_guardfile
run_test test_completion_bash_without_guardfile
run_test test_completion_zsh_without_guardfile
run_test test_missing_guardfile_no_usage
print_test_summary 4

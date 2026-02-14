#!/bin/bash

# test-init-prompts-001.sh - CONFIRMATION PROMPT FORMAT TESTS
# Tests the interactive prompt format when arguments are missing
# Spec (CLI-INTERFACE-SPECS.md lines 111-114):
#   "No <missing_param> specified. Use current user's <param>? [Y/n]:"

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CONFIRMATION PROMPT FORMAT TESTS
# ============================================================================
test_init_prompt_for_owner() {
    log_test "test_init_prompt_for_owner" \
             "Init with mode only should prompt for owner with correct format"

    local current_user=$(get_current_user)
    local current_group=$(get_current_group)

    # Run init with only mode, provide 'y' for owner prompt and 'y' for group prompt
    set +e
    output=$(echo -e "y\ny" | timeout 5 $GUARD_BIN init 0640 2>&1)
    local exit_code=$?
    set -e

    # Check for owner prompt format per spec
    # Expected: "No owner specified. Use current user's owner? [Y/n]:"
    if echo "$output" | grep -qiE "No.*owner.*specified.*\[Y/n\]"; then
        echo -e "${GREEN}✓ PASS${NC}: Prompt asks about owner with correct format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Should prompt for owner with format: No owner specified. Use current user's owner? [Y/n]:"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_init_prompt_for_owner
print_test_summary 1

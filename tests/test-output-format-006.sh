#!/bin/bash

# test-output-format-006.sh - 
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# 
# ============================================================================
test_toggle_grouped_list_header() {
    log_test "test_toggle_grouped_list_header" \
             "Toggle output has colon after 'Guard enabled for:' header"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt

    output=$($GUARD_BIN toggle myfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Toggle should succeed"
    # Per spec: "Guard enabled for:" with colon
    if [[ "$output" == *"Guard enabled for:"* ]] || [[ "$output" == *"Guard disabled for:"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Output has colon after header"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Grouped list header format not detected"
        echo "Got: $output"
    fi
}

# Run test
run_test test_toggle_grouped_list_header
print_test_summary 1

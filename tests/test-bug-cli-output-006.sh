#!/bin/bash

# test-bug-cli-output-006.sh - BUG: toggle two collections output order
#
# From docs/todo/BUGS.md:
# "For multiple collections with opposing guard states being toggled at the same time:
#  1. First list all files that change their state (grouped by collection with header)
#  2. At the very end, list all collections and how they changed their state"
#
# This test toggles two collections with opposing guard states and checks output order.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif command -v guard &> /dev/null; then
    GUARD_BIN="guard"
else
    echo "Error: guard binary not found. Please build it first."
    exit 1
fi

# ==========================================================================
# BUG: toggle two collections output order
# ==========================================================================

test_toggle_two_collections_output_order() {
    log_test "test_toggle_two_collections_output_order" \
             "Toggle two collections should list grouped files first, then summaries at end"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"
    touch alpha2.txt alpha1.txt beta2.txt beta1.txt

    $GUARD_BIN create alpha
    $GUARD_BIN create beta
    $GUARD_BIN update alpha add alpha2.txt alpha1.txt
    $GUARD_BIN update beta add beta2.txt beta1.txt

    # Make opposing guard states
    $GUARD_BIN enable collection alpha

    # Toggle both collections
    set +e
    output=$($GUARD_BIN toggle collection alpha beta 2>&1)
    set -e

    lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$output"

    local header_alpha=0
    local header_beta=0
    local alpha1_line=0
    local alpha2_line=0
    local beta1_line=0
    local beta2_line=0
    local summary_alpha=0
    local summary_beta=0

    for i in "${!lines[@]}"; do
        line="${lines[$i]}"
        line_no=$((i+1))
        if [[ "$line" == "toggling guarded state for files in collection: alpha" ]]; then
            header_alpha=$line_no
        fi
        if [[ "$line" == "toggling guarded state for files in collection: beta" ]]; then
            header_beta=$line_no
        fi
        if [[ "$line" == "Guard disabled for alpha1.txt" ]]; then
            alpha1_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for alpha2.txt" ]]; then
            alpha2_line=$line_no
        fi
        if [[ "$line" == "Guard enabled for beta1.txt" ]]; then
            beta1_line=$line_no
        fi
        if [[ "$line" == "Guard enabled for beta2.txt" ]]; then
            beta2_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for collection alpha" ]]; then
            summary_alpha=$line_no
        fi
        if [[ "$line" == "Guard enabled for collection beta" ]]; then
            summary_beta=$line_no
        fi
    done

    if [ $header_alpha -gt 0 ] && [ $header_beta -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Headers for both collections present"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing one or more collection headers"
        ((TESTS_FAILED++))
    fi

    if [ $alpha1_line -gt 0 ] && [ $alpha2_line -gt 0 ] && [ $beta1_line -gt 0 ] && [ $beta2_line -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: File lines present for both collections"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing one or more file lines"
        ((TESTS_FAILED++))
    fi

    if [ $alpha1_line -gt 0 ] && [ $alpha2_line -gt 0 ] && [ $alpha1_line -lt $alpha2_line ]; then
        echo -e "${GREEN}✓ PASS${NC}: Alpha files sorted"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Alpha files not sorted"
        ((TESTS_FAILED++))
    fi

    if [ $beta1_line -gt 0 ] && [ $beta2_line -gt 0 ] && [ $beta1_line -lt $beta2_line ]; then
        echo -e "${GREEN}✓ PASS${NC}: Beta files sorted"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Beta files not sorted"
        ((TESTS_FAILED++))
    fi

    local last_file_line=$alpha2_line
    if [ $beta2_line -gt $last_file_line ]; then
        last_file_line=$beta2_line
    fi

    local first_summary_line=$summary_alpha
    if [ $summary_beta -gt 0 ] && { [ $first_summary_line -eq 0 ] || [ $summary_beta -lt $first_summary_line ]; }; then
        first_summary_line=$summary_beta
    fi

    if [ $last_file_line -gt 0 ] && [ $first_summary_line -gt 0 ] && [ $last_file_line -lt $first_summary_line ]; then
        echo -e "${GREEN}✓ PASS${NC}: Summaries appear after all file lines"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Summaries should appear after file list"
        ((TESTS_FAILED++))
    fi

    if [ $last_file_line -gt 0 ]; then
        local blank_index=$((last_file_line+1))
        local blank_line="${lines[$((blank_index-1))]}"
        if [[ -z "${blank_line// /}" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: Blank line between file list and summaries"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAIL${NC}: Missing blank line before summaries"
            ((TESTS_FAILED++))
        fi
    fi

    if [ $summary_alpha -gt 0 ] && [ $summary_beta -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Summary lines present for both collections"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing one or more summary lines"
        ((TESTS_FAILED++))
    fi

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "  Output:\n$output"
    fi
}

# Run test
run_test test_toggle_two_collections_output_order
print_test_summary 1

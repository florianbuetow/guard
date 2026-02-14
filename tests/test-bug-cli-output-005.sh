#!/bin/bash

# test-bug-cli-output-005.sh - BUG: disable collection output order and header
#
# From docs/todo/BUGS.md:
# "guard enable/disable collection shows output in wrong order"
# Expected for a collection:
# 1. Print: "toggling guarded state for files in collection: <name>"
# 2. List all files that change state (sorted)
# 3. Empty line
# 4. Line stating collection guard enabled/disabled

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ==========================================================================
# BUG: disable collection output order
# ==========================================================================

test_disable_collection_output_header_and_order() {
    log_test "test_disable_collection_output_header_and_order" \
             "Disable collection should print header, sorted files, blank line, then summary"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN create fruits
    $GUARD_BIN update fruits add banana.txt apple.txt cherry.txt
    $GUARD_BIN enable collection fruits

    # Disable collection
    set +e
    output=$($GUARD_BIN disable collection fruits 2>&1)
    set -e

    lines=()
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$output"

    local header_line=0
    local apple_line=0
    local banana_line=0
    local cherry_line=0
    local summary_line=0

    for i in "${!lines[@]}"; do
        line="${lines[$i]}"
        line_no=$((i+1))
        if [[ "$line" == "toggling guarded state for files in collection: fruits" ]]; then
            header_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for apple.txt" ]]; then
            apple_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for banana.txt" ]]; then
            banana_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for cherry.txt" ]]; then
            cherry_line=$line_no
        fi
        if [[ "$line" == "Guard disabled for collection fruits" ]]; then
            summary_line=$line_no
        fi
    done

    if [ $header_line -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Header line present"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing header line"
        ((TESTS_FAILED++))
    fi

    if [ $apple_line -gt 0 ] && [ $banana_line -gt 0 ] && [ $cherry_line -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: File lines present"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing one or more file lines"
        ((TESTS_FAILED++))
    fi

    if [ $apple_line -gt 0 ] && [ $banana_line -gt 0 ] && [ $cherry_line -gt 0 ] && \
       [ $apple_line -lt $banana_line ] && [ $banana_line -lt $cherry_line ]; then
        echo -e "${GREEN}✓ PASS${NC}: File lines sorted (apple, banana, cherry)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: File lines not sorted"
        ((TESTS_FAILED++))
    fi

    if [ $header_line -gt 0 ] && [ $apple_line -gt 0 ] && [ $header_line -lt $apple_line ]; then
        echo -e "${GREEN}✓ PASS${NC}: Header appears before file list"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Header should appear before file list"
        ((TESTS_FAILED++))
    fi

    if [ $cherry_line -gt 0 ]; then
        local blank_index=$((cherry_line+1))
        local blank_line="${lines[$((blank_index-1))]}"
        if [[ -z "${blank_line// /}" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: Blank line after file list"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAIL${NC}: Missing blank line after file list"
            ((TESTS_FAILED++))
        fi

        if [ $summary_line -eq $((blank_index+1)) ]; then
            echo -e "${GREEN}✓ PASS${NC}: Summary line appears after blank line"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}✗ FAIL${NC}: Summary line not immediately after blank line"
            ((TESTS_FAILED++))
        fi
    fi

    if [ $summary_line -gt 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Summary line present"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Missing summary line for collection"
        ((TESTS_FAILED++))
    fi

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "  Output:\n$output"
    fi
}

# Run test
run_test test_disable_collection_output_header_and_order
print_test_summary 1

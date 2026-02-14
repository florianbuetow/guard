#!/bin/bash

# test-tutorial1-001.sh - TUTORIAL 1 COMPREHENSIVE TEST
# Adapted from README.md Tutorial 1 for no-sudo environment
# Tests the complete workflow: init, add, toggle (enable), toggle (disable)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TUTORIAL 1 COMPREHENSIVE TEST
# ============================================================================
test_tutorial1_complete_sequence() {
    log_test "test_tutorial1_complete_sequence" \
             "Complete Tutorial 1 workflow: init, add, toggle on, toggle off"

    echo "================================"
    echo "Step 1: Initialize guard system"
    echo "================================"

    # Step 1: guard init 000 <user> <group> (adapted from root/wheel)
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    local init_exit=$?
    assert_exit_code $init_exit 0 "Step 1: guard init should succeed"

    # Verify .guardfile created
    assert_guardfile_exists "Step 1: .guardfile should be created"

    # Verify config values
    local mode=$(get_guard_mode_from_config)
    assert_equals "0000" "$mode" "Step 1: guard_mode should be 0000"

    echo ""
    echo "================================"
    echo "Step 2: Create test file"
    echo "================================"

    # Step 2: touch test.txt
    touch test.txt
    if [ ! -f "test.txt" ]; then
        echo -e "${RED}✗ FAIL${NC}: Step 2: test.txt not created"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Record initial permissions
    local initial_perms=$(get_file_permissions "test.txt")
    echo "Initial permissions: $initial_perms"

    # Sanity check: Initial perms should be different from guard mode (000)
    if [ "$initial_perms" = "000" ]; then
        echo -e "${YELLOW}Warning${NC}: Initial permissions are 000, adjusting to 644..."
        chmod 644 test.txt
        initial_perms=$(get_file_permissions "test.txt")
    fi

    assert_not_equals "000" "$initial_perms" "Step 2: Initial perms should differ from guard mode (sanity check)"

    echo ""
    echo "================================"
    echo "Step 3: Add file to registry"
    echo "================================"

    # Step 3: guard add file test.txt
    $GUARD_BIN add file test.txt
    local add_exit=$?
    assert_exit_code $add_exit 0 "Step 3: guard add file should succeed"

    # Verify file is registered
    if file_in_registry "$(pwd)/test.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Step 3: File registered in .guardfile"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Step 3: File not registered"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Verify guard flag is false (unguarded)
    local guard_flag_after_add=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "false" "$guard_flag_after_add" "Step 3: Guard flag should be false after add"

    # Verify file permissions unchanged
    local perms_after_add=$(get_file_permissions "test.txt")
    assert_equals "$initial_perms" "$perms_after_add" "Step 3: File permissions should be unchanged"

    echo ""
    echo "================================"
    echo "Step 4: First toggle (enable)"
    echo "================================"

    # Step 4: guard toggle file test.txt (first toggle - enables)
    $GUARD_BIN toggle file test.txt
    local toggle1_exit=$?
    assert_exit_code $toggle1_exit 0 "Step 4: First toggle should succeed"

    # Verify guard flag is now true
    local guard_flag_after_toggle1=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "true" "$guard_flag_after_toggle1" "Step 4: Guard flag should be true after first toggle"

    # Verify file permissions changed to 000
    local perms_after_toggle1=$(get_file_permissions "test.txt")
    assert_equals "000" "$perms_after_toggle1" "Step 4: File permissions should be 000 when guarded"

    # Verify owner/group unchanged (should be flo/staff)
    local owner_after_guard=$(get_file_owner "test.txt")
    local group_after_guard=$(get_file_group "test.txt")

    if [ "$owner_after_guard" = "flo" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Step 4: Owner unchanged (flo)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Owner is $owner_after_guard (expected flo)"
        # Not failing since owner might vary in test environment
    fi

    if [ "$group_after_guard" = "staff" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Step 4: Group unchanged (staff)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Group is $group_after_guard (expected staff)"
        # Not failing since group might vary in test environment
    fi

    echo ""
    echo "================================"
    echo "Step 5: Verify .guardfile state"
    echo "================================"

    # Step 5: Verify guard: true in .guardfile
    local guard_flag_in_file=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "true" "$guard_flag_in_file" "Step 5: .guardfile should show guard: true"

    echo ""
    echo "================================"
    echo "Step 6: Second toggle (disable)"
    echo "================================"

    # Step 6: guard toggle file test.txt (second toggle - disables)
    $GUARD_BIN toggle file test.txt
    local toggle2_exit=$?
    assert_exit_code $toggle2_exit 0 "Step 6: Second toggle should succeed"

    # Verify guard flag is now false
    local guard_flag_after_toggle2=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "false" "$guard_flag_after_toggle2" "Step 6: Guard flag should be false after second toggle"

    # Verify file permissions restored to original
    local perms_after_toggle2=$(get_file_permissions "test.txt")
    assert_equals "$initial_perms" "$perms_after_toggle2" "Step 6: File permissions should be restored to original"

    echo ""
    echo "================================"
    echo "Step 7: Verify .guardfile state"
    echo "================================"

    # Step 7: Verify guard: false in .guardfile
    local guard_flag_final=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "false" "$guard_flag_final" "Step 7: .guardfile should show guard: false"

    echo ""
    echo "================================"
    echo "Tutorial 1 Test Complete"
    echo "================================"
}

# Run test
run_test test_tutorial1_complete_sequence
print_test_summary 1

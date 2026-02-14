#!/bin/bash

# test-folder-toggle-004.sh - FOLDER DISABLE TESTS
# Verifies that folder operations create a folder entry in .guardfile,
# register all immediate files (non-recursive), and sync guard state.
#
# Based on CLI-INTERFACE-SPECS.md folder management section.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FOLDER DISABLE TESTS
# ============================================================================
test_disable_folder_creates_entry() {
    log_test "test_disable_folder_creates_entry" \
             "Disable folder creates entry and unguards all files"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create folder with 2 files
    mkdir -p myfolder
    touch myfolder/file1.txt myfolder/file2.txt

    # First enable the folder (so we can disable it)
    $GUARD_BIN enable folder myfolder

    # === ACTION: Disable folder ===
    $GUARD_BIN disable folder myfolder
    local exit_code=$?
    assert_exit_code $exit_code 0 "Disable folder should succeed"

    # Assert: Folder entry exists
    folder_exists_in_registry "@myfolder"
    local folder_exists=$?
    assert_equals "0" "$folder_exists" "Folder @myfolder should exist in registry"

    # Assert: Folder guard is false
    local folder_guard=$(get_folder_guard_flag "@myfolder")
    assert_equals "false" "$folder_guard" "Folder guard should be false"

    # Assert: Both files are unguarded
    local file1_guard=$(get_guard_flag "myfolder/file1.txt")
    local file2_guard=$(get_guard_flag "myfolder/file2.txt")
    assert_equals "false" "$file1_guard" "file1.txt should be unguarded"
    assert_equals "false" "$file2_guard" "file2.txt should be unguarded"
}

# Run test
run_test test_disable_folder_creates_entry
print_test_summary 1

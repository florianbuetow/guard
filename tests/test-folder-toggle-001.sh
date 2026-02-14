#!/bin/bash

# test-folder-toggle-001.sh - FOLDER TOGGLE TESTS
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
# FOLDER TOGGLE TESTS
# ============================================================================
test_toggle_folder_creates_entry() {
    log_test "test_toggle_folder_creates_entry" \
             "Toggle folder creates entry in .guardfile with correct name and path"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create folder with 2 files
    mkdir -p myfolder
    touch myfolder/file1.txt myfolder/file2.txt

    # Verify no folder entry before toggle
    local folder_count_before=$(count_folders_in_registry)
    assert_equals "0" "$folder_count_before" "No folders should exist before toggle"

    # === ACTION: Toggle folder ===
    $GUARD_BIN toggle folder myfolder
    local exit_code=$?
    assert_exit_code $exit_code 0 "Toggle folder should succeed"

    # Assert: Folder entry exists with @prefix
    folder_exists_in_registry "@myfolder"
    local folder_exists=$?
    assert_equals "0" "$folder_exists" "Folder @myfolder should exist in registry"

    # Assert: Folder path is correct
    local folder_path=$(get_folder_path "@myfolder")
    assert_equals "./myfolder" "$folder_path" "Folder path should be './myfolder'"

    # Assert: Folder guard is true (first toggle enables)
    local folder_guard=$(get_folder_guard_flag "@myfolder")
    assert_equals "true" "$folder_guard" "Folder guard should be true after first toggle"

    # Assert: Both files are registered and guarded
    local file1_guard=$(get_guard_flag "myfolder/file1.txt")
    local file2_guard=$(get_guard_flag "myfolder/file2.txt")
    assert_equals "true" "$file1_guard" "file1.txt should be guarded"
    assert_equals "true" "$file2_guard" "file2.txt should be guarded"
}

# Run test
run_test test_toggle_folder_creates_entry
print_test_summary 1

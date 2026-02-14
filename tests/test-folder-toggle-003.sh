#!/bin/bash

# test-folder-toggle-003.sh - FOLDER ENABLE TESTS
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
# FOLDER ENABLE TESTS
# ============================================================================
test_enable_folder_creates_entry() {
    log_test "test_enable_folder_creates_entry" \
             "Enable folder creates entry and guards all files"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create folder with 2 files
    mkdir -p myfolder
    touch myfolder/file1.txt myfolder/file2.txt

    # === ACTION: Enable folder ===
    $GUARD_BIN enable folder myfolder
    local exit_code=$?
    assert_exit_code $exit_code 0 "Enable folder should succeed"

    # Assert: Folder entry exists
    folder_exists_in_registry "@myfolder"
    local folder_exists=$?
    assert_equals "0" "$folder_exists" "Folder @myfolder should exist in registry"

    # Assert: Folder guard is true
    local folder_guard=$(get_folder_guard_flag "@myfolder")
    assert_equals "true" "$folder_guard" "Folder guard should be true"

    # Assert: Both files are guarded
    local file1_guard=$(get_guard_flag "myfolder/file1.txt")
    local file2_guard=$(get_guard_flag "myfolder/file2.txt")
    assert_equals "true" "$file1_guard" "file1.txt should be guarded"
    assert_equals "true" "$file2_guard" "file2.txt should be guarded"
}

# Run test
run_test test_enable_folder_creates_entry
print_test_summary 1

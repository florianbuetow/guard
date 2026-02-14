#!/bin/bash

# test-folder-toggle-005.sh - 
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
# 
# ============================================================================
test_autodetect_directory_as_folder() {
    log_test "test_autodetect_directory_as_folder" \
             "Directory on disk is auto-detected as folder in toggle"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create directory with file
    mkdir -p myfolder
    touch myfolder/file.txt

    # === ACTION: Toggle with just directory name (no keyword) ===
    $GUARD_BIN toggle myfolder
    local exit_code=$?
    assert_exit_code $exit_code 0 "Toggle should auto-detect directory as folder"

    # Assert: Folder entry created
    folder_exists_in_registry "@myfolder"
    local folder_exists=$?
    assert_equals "0" "$folder_exists" "Folder @myfolder should exist (auto-detected)"

    # Assert: File in folder is guarded
    local file_guard=$(get_guard_flag "myfolder/file.txt")
    assert_equals "true" "$file_guard" "File should be guarded"
}

# Run test
run_test test_autodetect_directory_as_folder
print_test_summary 1

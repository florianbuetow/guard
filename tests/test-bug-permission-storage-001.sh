#!/bin/bash

# test-bug-permission-storage-001.sh - BUG #6: Adding already registered files overwrites stored permissions
#
# This file tests the following bug from docs/BUGS.md:
#
# Bug #6: Adding already registered files overwrites their stored permissions
#
# From BUGS.md:
# "If we have a folder that contains some files that are guarded and now we add
# those files again to a collection, we're overwriting the original read-write
# ownership permissions with the ones of the guarded state. So this must never
# happen. There must not be any way to update the permissions of a file in the
# .guard file after the file has been added."
#
# "I suggest that what we do is compare the current owner, group, and permissions
# of a file to be added with the default guarded state configured in the guard
# file. If they are the same, we should display a warning and say that we are
# not adding this file since it already contains the same permissions as the
# guarded state."
#
# Tests are designed to FAIL when the bug exists, PASS when fixed.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# Helper: Get stored mode from .guardfile for a file
get_stored_mode() {
    local filepath="$1"

    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    local in_files=0
    local found_file=0
    local result=""

    while IFS= read -r line; do
        if [[ "$line" == "files:" ]]; then
            in_files=1
            continue
        fi
        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "files:" ]]; then
            in_files=0
        fi
        if [ $in_files -eq 1 ]; then
            if [[ "$line" =~ path:.*$filepath ]]; then
                found_file=1
            fi
            if [ $found_file -eq 1 ] && [[ "$line" =~ mode:[[:space:]]*\"?([0-9]+)\"? ]]; then
                result="${BASH_REMATCH[1]}"
                break
            fi
            # Reset if we hit next file entry
            if [ $found_file -eq 1 ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path: ]]; then
                break
            fi
        fi
    done < .guardfile

    echo "$result"
}

# ============================================================================
# BUG #6: Adding already registered files overwrites stored permissions
# ============================================================================
test_add_guarded_file_to_collection_preserves_permissions() {
    log_test "test_add_guarded_file_to_collection_preserves_permissions" \
             "BUG #6: Adding guarded file to collection should NOT overwrite stored permissions"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create file with specific permissions (644)
    touch testfile.txt
    chmod 644 testfile.txt
    local original_perms=$(get_file_permissions "testfile.txt")
    assert_equals "644" "$original_perms" "Setup: file should have 644 permissions"

    # Register the file (captures original 644 permissions)
    $GUARD_BIN add testfile.txt

    # Enable guard (changes actual permissions to 000)
    $GUARD_BIN enable file testfile.txt

    # Verify file is now guarded with 000 permissions
    local guarded_perms=$(get_file_permissions "testfile.txt")
    assert_equals "000" "$guarded_perms" "File should have guarded 000 permissions"

    # Check stored mode in .guardfile (should be 644)
    local stored_mode_before=$(get_stored_mode "testfile.txt")
    echo "Stored mode before adding to collection: $stored_mode_before"

    # Create collection and add the ALREADY GUARDED file
    # THIS IS WHERE THE BUG MANIFESTS
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add testfile.txt

    # Disable guard to restore permissions
    $GUARD_BIN disable file testfile.txt

    # Check what permissions were restored
    local restored_perms=$(get_file_permissions "testfile.txt")

    # THE KEY CHECK:
    # If bug exists: restored_perms = "000" (guarded state was saved as "original")
    # If fixed: restored_perms = "644" (true original was preserved)

    if [ "$restored_perms" = "644" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Permissions correctly restored to original 644"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: BUG #6 CONFIRMED - Permissions should be 644 but got $restored_perms"
        echo -e "  Adding guarded file to collection overwrote stored original permissions"
        echo -e "  with the guarded state permissions."
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_add_guarded_file_to_collection_preserves_permissions
print_test_summary 1

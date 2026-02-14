#!/bin/bash

# test-enable-auto-detect-003.sh - ENABLE AUTO-DETECTION TESTS - MIXED FILES AND COLLECTIONS
# Tests auto-detection of files vs collections: guard enable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ENABLE AUTO-DETECTION TESTS - MIXED FILES AND COLLECTIONS
# ============================================================================
test_enable_auto_detect_mixed() {
    log_test "test_enable_auto_detect_mixed" \
             "Auto-detect: enable mix of files and collections"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch standalone.txt coll_file.txt
    $GUARD_BIN add file standalone.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add coll_file.txt

    # Run enable with both file and collection
    $GUARD_BIN enable standalone.txt mycoll
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard enable should succeed"

    local file_flag=$(get_guard_flag "$(pwd)/standalone.txt")
    assert_equals "true" "$file_flag" "standalone.txt should be guarded"

    local coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "true" "$coll_flag" "mycoll should be guarded"
}

# Run test
run_test test_enable_auto_detect_mixed
print_test_summary 1

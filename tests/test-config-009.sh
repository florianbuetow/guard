

#!/bin/bash

# test-config-009.sh - Test 9: Config set with guarded files (Warning test)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 9: Config set with guarded files (Warning test)
# ============================================================================
test_config_set_with_guarded_files() {
    log_test "test_config_set_with_guarded_files" \
             "Warning test: guard config set warns when files are guarded"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Add and enable a file
    touch testfile.txt
    $GUARD_BIN add file testfile.txt > /dev/null 2>&1
    $GUARD_BIN enable file testfile.txt > /dev/null 2>&1

    # Set config (should show warning)
    local output=$($GUARD_BIN config set mode 0600 2>&1)
    local exit_code=$?

    # Assert exit code 0 (warnings don't cause failure)
    assert_exit_code $exit_code 0 "guard config set should succeed with warning"

    # Assert warning message appears
    assert_contains "$output" "Warning:" "Output should contain warning"
    assert_contains "$output" "currently guarded" "Output should mention guarded files"

    # Cleanup
    $GUARD_BIN disable file testfile.txt > /dev/null 2>&1
    $GUARD_BIN remove file testfile.txt > /dev/null 2>&1
    rm -f testfile.txt
}

# Run test
run_test test_config_set_with_guarded_files
print_test_summary 1

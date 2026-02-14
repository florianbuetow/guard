
#!/bin/bash

# test-config-008.sh - Test 8: Config set with empty owner (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 8: Config set with empty owner (Positive)
# ============================================================================
test_config_set_empty_owner() {
    log_test "test_config_set_empty_owner" \
             "Positive test: guard config set owner can set empty owner"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set empty owner
    $GUARD_BIN config set owner "" > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set owner '' should succeed"

    # Verify output shows (empty)
    local output=$($GUARD_BIN config show 2>&1)
    assert_contains "$output" "(empty)" "Output should contain (empty) for owner"
}

# Run test
run_test test_config_set_empty_owner
print_test_summary 1

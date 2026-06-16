#!/bin/bash

# test-init-validate-owner-001.sh
# Tests that `guard init` WARNS (but does not fail) when the owner does not
# exist on the system.
#
# init still succeeds and writes the .guardfile, but the user is warned up
# front that the configured owner is bogus. Without the warning, every later
# chown fails silently.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

find_guard_binary

BOGUS_OWNER="zz_no_such_user_xyz123"

test_init_warns_nonexistent_owner() {
    log_test "test_init_warns_nonexistent_owner" \
             "guard init must warn (not fail) when the owner does not exist"

    set +e
    output=$($GUARD_BIN init 0700 "$BOGUS_OWNER" "$(get_current_group)" 2>&1)
    exit_code=$?
    set -e

    assert_exit_code $exit_code 0 "init must still succeed when owner does not exist"
    assert_contains "$output" "$BOGUS_OWNER" "warning must name the bad owner"
    assert_contains "$output" "does not exist" "init must warn that the owner does not exist"
    assert_guardfile_exists ".guardfile must still be created"
}

run_test test_init_warns_nonexistent_owner
print_test_summary 1

#!/bin/bash

# test-init-validate-group-001.sh
# Tests that `guard init` WARNS (but does not fail) when the group does not
# exist on the system.
#
# init still succeeds and writes the .guardfile, but the user is warned up
# front that the configured group is bogus. Without the warning, every later
# chgrp fails silently (e.g., guarding never completes, the TUI shows [-]
# instead of [G] with no indication anything went wrong).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

find_guard_binary

# Pick a group name that does not exist on any system.
BOGUS_GROUP="zz_no_such_group_xyz123"

test_init_warns_nonexistent_group() {
    log_test "test_init_warns_nonexistent_group" \
             "guard init must warn (not fail) when the group does not exist"

    set +e
    output=$($GUARD_BIN init 0700 "$(get_current_user)" "$BOGUS_GROUP" 2>&1)
    exit_code=$?
    set -e

    assert_exit_code $exit_code 0 "init must still succeed when group does not exist"
    assert_contains "$output" "$BOGUS_GROUP" "warning must name the bad group"
    assert_contains "$output" "does not exist" "init must warn that the group does not exist"
    assert_guardfile_exists ".guardfile must still be created"
}

run_test test_init_warns_nonexistent_group
print_test_summary 1

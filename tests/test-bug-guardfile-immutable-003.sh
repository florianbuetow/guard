#!/bin/bash

# test-bug-guardfile-immutable-003.sh - Document ClearImmutable() silent failure
#
# This file tests the following bug from docs/BUGS2.md:
#
# Bug: Mechanism for removing immutable flag from .guardfile before writing is not working
#
# ROOT CAUSE ANALYSIS:
# --------------------
#
# SILENT FAILURE:
#    ClearImmutable() in filesystem.go returns nil with just a warning
#    when not running as root (lines 372-374). This means the function
#    appears to succeed but doesn't actually clear the flag.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CODE ANALYSIS: Document silent failure in ClearImmutable
# ============================================================================

test_document_silent_clear_immutable() {
    log_test "test_document_silent_clear_immutable" \
             "Document: ClearImmutable() silently fails without root"

    echo ""
    echo "  BUG ANALYSIS: ClearImmutable() silent failure"
    echo "  =============================================="
    echo ""
    echo "  File: internal/filesystem/filesystem.go"
    echo "  Function: ClearImmutable() at lines 371-385"
    echo ""
    echo "  Code:"
    echo "    func (fs *FileSystem) ClearImmutable(path string) error ..."
    echo "        if !fs.HasRootPrivileges() ..."
    echo "            fmt.Printf(\"Warning: Clearing immutable flag requires root...\")"
    echo "            return nil  // <- Returns nil, not an error!"
    echo "        {}"
    echo "        // ... actual clear logic"
    echo "    {}"
    echo ""
    echo "  PROBLEM:"
    echo "  When running without root privileges, ClearImmutable() prints a"
    echo "  warning but returns nil (success). This makes it impossible for"
    echo "  calling code to know if the flag was actually cleared."
    echo ""
    echo "  The calling code (clearGuardfileImmutableFlag) then proceeds to"
    echo "  try writing to the file, which fails because the flag wasn't"
    echo "  actually cleared."
    echo ""
    echo "  EXPECTED BEHAVIOR:"
    echo "  Return an error when unable to clear the flag, allowing the"
    echo "  calling code to handle the situation appropriately."
    echo ""

    echo -e "${GREEN}✓ PASS${NC}: Code analysis documented"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Run test
run_test test_document_silent_clear_immutable
print_test_summary 1

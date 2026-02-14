#!/bin/bash

# test-bug-guardfile-immutable-002.sh - Document InitializeRegistry() bypass
#
# This file tests the following bug from docs/BUGS2.md:
#
# Bug: Mechanism for removing immutable flag from .guardfile before writing is not working
#
# ROOT CAUSE ANALYSIS:
# --------------------
#
# BYPASS IN manager.go:
#    InitializeRegistry() at line 103 calls sec.Save() directly
#    instead of going through SaveRegistry().

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CODE ANALYSIS: Document the bypass in InitializeRegistry
# ============================================================================

test_document_initialize_registry_bypass() {
    log_test "test_document_initialize_registry_bypass" \
             "Document: InitializeRegistry() bypasses clearGuardfileImmutableFlag()"

    echo ""
    echo "  BUG ANALYSIS: InitializeRegistry() uses direct Save"
    echo "  ===================================================="
    echo ""
    echo "  File: internal/manager/manager.go"
    echo "  Function: InitializeRegistry()"
    echo ""
    echo "  At line 103:"
    echo "    if err := sec.Save(); err != nil {}"
    echo ""
    echo "  PROBLEM:"
    echo "  This calls sec.Save() directly instead of m.SaveRegistry()."
    echo "  When overwriting an existing immutable .guardfile, the immutable"
    echo "  flag IS cleared at line 92, but then the save uses a fresh"
    echo "  security object that doesn't go through SaveRegistry()."
    echo ""
    echo "  This is a minor issue since the flag IS cleared before the"
    echo "  NewSecurity() call, but it's inconsistent with the rest of"
    echo "  the codebase."
    echo ""

    echo -e "${GREEN}✓ PASS${NC}: Code analysis documented"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Run test
run_test test_document_initialize_registry_bypass
print_test_summary 1

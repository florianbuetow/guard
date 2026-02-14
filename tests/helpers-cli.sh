#!/bin/bash
set -e

# helpers-cli.sh - Shared helper functions for guard CLI tests
# This file contains utilities for file system operations, .guardfile parsing,
# assertions, and test framework functionality

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test state tracking
TESTS_PASSED=0
TESTS_FAILED=0
TEST_DIR=""

# ============================================================================
# Current User/Group Helpers
# ============================================================================

# Get current username
# Usage: get_current_user
# Returns: username string
get_current_user() {
    echo "${USER:-$(whoami)}"
}

# Get current user's primary group
# Usage: get_current_group
# Returns: group name string
get_current_group() {
    id -gn
}

# ============================================================================
# Guard Binary Discovery
# ============================================================================

# Find the guard binary (./guard or on PATH), set GUARD_BIN, or exit 1
# Usage: find_guard_binary  (sets GUARD_BIN global)
find_guard_binary() {
    GUARD_BIN=""
    if [ -f "./guard" ]; then
        GUARD_BIN="$(pwd)/guard"
    elif [ -f "./bin/guard" ]; then
        GUARD_BIN="$(pwd)/bin/guard"
    elif command -v guard &> /dev/null; then
        GUARD_BIN="guard"
    else
        echo "Error: guard binary not found. Please build it first."
        exit 1
    fi
}

# ============================================================================
# File System Helpers
# ============================================================================

# Get octal permissions for a file (e.g., "644")
# Usage: get_file_permissions <filepath>
# Returns: "XXX" or "" if file doesn't exist
get_file_permissions() {
    local filepath="$1"
    if [ ! -e "$filepath" ]; then
        echo ""
        return 1
    fi

    # Use stat to get permissions (macOS and Linux compatible)
    local perms=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        perms=$(stat -f "%Lp" "$filepath" 2>/dev/null || echo "")
    else
        # Linux
        perms=$(stat -c "%a" "$filepath" 2>/dev/null || echo "")
    fi

    # Pad to 3 digits with leading zeros (e.g., "0" -> "000", "64" -> "064")
    if [ -n "$perms" ]; then
        printf "%03d" "$perms"
    else
        echo ""
    fi
}

# Get file owner
# Usage: get_file_owner <filepath>
# Returns: owner name or "" if file doesn't exist
get_file_owner() {
    local filepath="$1"
    if [ ! -e "$filepath" ]; then
        echo ""
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        stat -f "%Su" "$filepath" 2>/dev/null || echo ""
    else
        # Linux
        stat -c "%U" "$filepath" 2>/dev/null || echo ""
    fi
}

# Get file group
# Usage: get_file_group <filepath>
# Returns: group name or "" if file doesn't exist
get_file_group() {
    local filepath="$1"
    if [ ! -e "$filepath" ]; then
        echo ""
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        stat -f "%Sg" "$filepath" 2>/dev/null || echo ""
    else
        # Linux
        stat -c "%G" "$filepath" 2>/dev/null || echo ""
    fi
}

# Check if file exists
# Usage: file_exists <filepath>
# Returns: 0 if exists, 1 if not
file_exists() {
    local filepath="$1"
    [ -e "$filepath" ]
}

# ============================================================================
# Guardfile Parsing Helpers
# ============================================================================

# Get guard flag value for a file from .guardfile
# Usage: get_guard_flag <filepath>
# Returns: "true" or "false" or "" if not in guardfile
get_guard_flag() {
    local filepath="$1"

    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    # Convert to relative path from current directory
    # .guardfile now stores relative paths (security layer implementation)
    local search_path="$filepath"
    if [[ "$filepath" == /* ]]; then
        # Absolute path - convert to relative
        local current_dir="$(pwd)"
        # Remove current dir prefix if path is under it
        if [[ "$filepath" == "$current_dir"/* ]]; then
            search_path="${filepath#$current_dir/}"
        else
            # Path is outside current directory - won't be in guardfile
            echo ""
            return 1
        fi
    fi

    # Search for the file entry and extract guard flag
    # YAML structure: files section with path and guard fields
    local in_files_section=0
    local found_file=0
    local result=""

    while IFS= read -r line; do
        # Check if we're entering files section
        if [[ "$line" == "files:" ]]; then
            in_files_section=1
            continue
        fi

        # Exit files section if we hit another top-level section
        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "files:" ]]; then
            in_files_section=0
        fi

        if [ $in_files_section -eq 1 ]; then
            # Check for path match
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*\"?(.+)\"?$ ]]; then
                local file_path="${BASH_REMATCH[1]}"
                file_path="${file_path%\"}"  # Remove trailing quote if present
                file_path="${file_path#\"}"  # Remove leading quote if present

                if [ "$file_path" = "$search_path" ]; then
                    found_file=1
                fi
            fi

            # If we found our file, look for the guard flag
            if [ $found_file -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*guard:[[:space:]]*(true|false) ]]; then
                    result="${BASH_REMATCH[1]}"
                    break
                fi

                # Reset if we hit the next file entry
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path: ]] && [ -n "$result" ]; then
                    break
                fi
            fi
        fi
    done < .guardfile

    echo "$result"
}

# Get guard flag for a collection from .guardfile
# Usage: get_collection_guard_flag <collection_name>
# Returns: "true" or "false" or "" if not in guardfile
get_collection_guard_flag() {
    local collection_name="$1"

    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    local in_collections_section=0
    local found_collection=0
    local result=""

    while IFS= read -r line; do
        # Check if we're entering collections section
        if [[ "$line" == "collections:" ]]; then
            in_collections_section=1
            continue
        fi

        # Exit collections section if we hit another top-level section
        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "collections:" ]]; then
            in_collections_section=0
        fi

        if [ $in_collections_section -eq 1 ]; then
            # Check for name match
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*\"?(.+)\"?$ ]]; then
                local coll_name="${BASH_REMATCH[1]}"
                coll_name="${coll_name%\"}"
                coll_name="${coll_name#\"}"

                if [ "$coll_name" = "$collection_name" ]; then
                    found_collection=1
                fi
            fi

            # If we found our collection, look for the guard flag
            if [ $found_collection -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*guard:[[:space:]]*(true|false) ]]; then
                    result="${BASH_REMATCH[1]}"
                    break
                fi

                # Reset if we hit the next collection entry
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]] && [ -n "$result" ]; then
                    break
                fi
            fi
        fi
    done < .guardfile

    echo "$result"
}

# Check if file is registered in .guardfile
# Usage: file_in_registry <filepath>
# Returns: 0 if registered, 1 if not
file_in_registry() {
    local filepath="$1"
    local guard_flag=$(get_guard_flag "$filepath")

    if [ -n "$guard_flag" ]; then
        return 0
    else
        return 1
    fi
}

# Check if collection exists in .guardfile
# Usage: collection_exists_in_registry <collection_name>
# Returns: 0 if exists, 1 if not
collection_exists_in_registry() {
    local collection_name="$1"

    if [ ! -f ".guardfile" ]; then
        return 1
    fi

    # Search for collection name in collections section
    local in_collections_section=0

    while IFS= read -r line; do
        if [[ "$line" == "collections:" ]]; then
            in_collections_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "collections:" ]]; then
            in_collections_section=0
        fi

        if [ $in_collections_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*\"?(.+)\"?$ ]]; then
                local coll_name="${BASH_REMATCH[1]}"
                coll_name="${coll_name%\"}"
                coll_name="${coll_name#\"}"

                if [ "$coll_name" = "$collection_name" ]; then
                    return 0
                fi
            fi
        fi
    done < .guardfile

    return 1
}

# Check if file is member of a collection
# Usage: file_in_collection <filepath> <collection_name>
# Returns: 0 if member, 1 if not
file_in_collection() {
    local filepath="$1"
    local collection_name="$2"

    if [ ! -f ".guardfile" ]; then
        return 1
    fi

    # Convert to relative path from current directory
    # .guardfile now stores relative paths (security layer implementation)
    local search_path="$filepath"
    if [[ "$filepath" == /* ]]; then
        # Absolute path - convert to relative
        local current_dir="$(pwd)"
        # Remove current dir prefix if path is under it
        if [[ "$filepath" == "$current_dir"/* ]]; then
            search_path="${filepath#$current_dir/}"
        else
            # Path is outside current directory - won't be in guardfile
            return 1
        fi
    fi

    local in_collections_section=0
    local found_collection=0
    local in_files_list=0

    while IFS= read -r line; do
        if [[ "$line" == "collections:" ]]; then
            in_collections_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "collections:" ]]; then
            in_collections_section=0
        fi

        if [ $in_collections_section -eq 1 ]; then
            # Check for collection name match
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*\"?(.+)\"?$ ]]; then
                local coll_name="${BASH_REMATCH[1]}"
                coll_name="${coll_name%\"}"
                coll_name="${coll_name#\"}"

                if [ "$coll_name" = "$collection_name" ]; then
                    found_collection=1
                    in_files_list=0
                else
                    found_collection=0
                    in_files_list=0
                fi
            fi

            # If we found our collection, check if we're in the files list
            if [ $found_collection -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*files:$ ]]; then
                    in_files_list=1
                    continue
                fi

                # Check for file path in the list
                if [ $in_files_list -eq 1 ]; then
                    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"?(.+)\"?$ ]]; then
                        local file_path="${BASH_REMATCH[1]}"
                        file_path="${file_path%\"}"
                        file_path="${file_path#\"}"

                        if [ "$file_path" = "$search_path" ]; then
                            return 0
                        fi
                    fi

                    # Exit files list if we hit another field
                    if [[ "$line" =~ ^[[:space:]]*[a-z_]+:$ ]]; then
                        in_files_list=0
                    fi
                fi
            fi
        fi
    done < .guardfile

    return 1
}

# Count total files in .guardfile
# Returns: number of files
count_files_in_registry() {
    if [ ! -f ".guardfile" ]; then
        echo "0"
        return
    fi

    local count=0
    local in_files_section=0

    while IFS= read -r line; do
        if [[ "$line" == "files:" ]]; then
            in_files_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "files:" ]]; then
            in_files_section=0
        fi

        if [ $in_files_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path: ]]; then
                ((count++))
            fi
        fi
    done < .guardfile

    echo "$count"
}

# Count total collections in .guardfile
# Returns: number of collections
count_collections_in_registry() {
    if [ ! -f ".guardfile" ]; then
        echo "0"
        return
    fi

    local count=0
    local in_collections_section=0

    while IFS= read -r line; do
        if [[ "$line" == "collections:" ]]; then
            in_collections_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "collections:" ]]; then
            in_collections_section=0
        fi

        if [ $in_collections_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]]; then
                ((count++))
            fi
        fi
    done < .guardfile

    echo "$count"
}

# Get guard_mode from .guardfile config
# Returns: mode string (e.g., "0000")
get_guard_mode_from_config() {
    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    local in_config_section=0

    while IFS= read -r line; do
        if [[ "$line" == "config:" ]]; then
            in_config_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "config:" ]]; then
            in_config_section=0
        fi

        if [ $in_config_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*guard_mode:[[:space:]]*\"?([0-9]+)\"?$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            fi
        fi
    done < .guardfile

    echo ""
    return 1
}

# ============================================================================
# Assertion Helpers
# ============================================================================

# Assert two values are equal
# Usage: assert_equals <expected> <actual> <message>
# Prints PASS or FAIL
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected: '$expected'"
        echo -e "  Actual:   '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert two values are not equal
# Usage: assert_not_equals <not_expected> <actual> <message>
assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$not_expected" != "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Should not equal: '$not_expected'"
        echo -e "  But got:          '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert file has specific permissions
# Usage: assert_file_permissions <filepath> <expected_mode> <message>
assert_file_permissions() {
    local filepath="$1"
    local expected_mode="$2"
    local message="$3"

    local actual_mode=$(get_file_permissions "$filepath")

    if [ "$expected_mode" = "$actual_mode" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  File: $filepath"
        echo -e "  Expected perms: $expected_mode"
        echo -e "  Actual perms:   $actual_mode"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert file has specific guard flag
# Usage: assert_guard_flag <filepath> <expected_flag> <message>
assert_guard_flag() {
    local filepath="$1"
    local expected_flag="$2"
    local message="$3"

    local actual_flag=$(get_guard_flag "$filepath")

    if [ "$expected_flag" = "$actual_flag" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  File: $filepath"
        echo -e "  Expected guard flag: $expected_flag"
        echo -e "  Actual guard flag:   $actual_flag"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert command exit code
# Usage: run_command; assert_exit_code $? <expected> <message>
assert_exit_code() {
    local actual_code="$1"
    local expected_code="$2"
    local message="$3"

    if [ "$expected_code" -eq "$actual_code" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected exit code: $expected_code"
        echo -e "  Actual exit code:   $actual_code"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert .guardfile exists
# Returns: 0 if exists, 1 and prints FAIL if not
assert_guardfile_exists() {
    local message="$1"

    if [ -f ".guardfile" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  .guardfile does not exist"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert .guardfile does not exist
# Returns: 0 if doesn't exist, 1 and prints FAIL if exists
assert_guardfile_not_exists() {
    local message="$1"

    if [ ! -f ".guardfile" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  .guardfile exists but shouldn't"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert string contains substring
# Usage: assert_contains <haystack> <needle> <message>
# Returns: 0 if found, 1 and prints FAIL if not found
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected to find: '$needle'"
        echo -e "  In output: '$haystack'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ============================================================================
# Test Framework Helpers
# ============================================================================

# Setup: Create test directory, cd into it
# Creates: test_XXXXXX/ directory
# Sets: TEST_DIR variable
setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/guard_test.XXXXXX")

    # Save original directory
    ORIGINAL_DIR=$(pwd)

    # Change to test directory
    cd "$TEST_DIR"

    # Reset test counters for this test
    TESTS_PASSED=0
    TESTS_FAILED=0
}

# Cleanup: Remove test directory and all contents
# Removes .guardfile and all test files
teardown_test_env() {
    # Return to original directory
    if [ -n "$ORIGINAL_DIR" ]; then
        cd "$ORIGINAL_DIR"
    fi

    # Remove test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Log test name and description
# Usage: log_test "Test Name" "Description of what this test validates"
log_test() {
    local test_name="$1"
    local test_description="$2"

    echo ""
    echo "========================================"
    echo "TEST: $test_name"
    echo "========================================"
    echo "Description: $test_description"
    echo ""
}

# Run a test function with setup/teardown
# Usage: run_test <test_function_name>
run_test() {
    local test_function="$1"

    # Setup
    setup_test_env

    # Run test (capture failures but continue)
    set +e
    $test_function
    local test_result=$?
    set -e

    # Teardown
    teardown_test_env

    # Print test summary
    if [ $test_result -eq 0 ] && [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}Test passed${NC} ($TESTS_PASSED assertions passed)"
        return 0
    else
        echo -e "\n${RED}Test failed${NC} ($TESTS_PASSED passed, $TESTS_FAILED failed)"
        return 1
    fi
}

# Print final test statistics
# With fail-fast behavior, if we reach this function, all test cases passed
print_test_summary() {
    local test_count="$1"

    echo ""
    echo "========================================"
    echo "TEST SUMMARY"
    echo "========================================"
    echo "Total test cases: $test_count"
    echo -e "${GREEN}All $test_count test cases passed${NC}"
    echo "========================================"

    return 0
}

# ============================================================================
# Folder Helpers (Dynamic Folder-Collections)
# ============================================================================

# Get guard flag for a folder from .guardfile
# Usage: get_folder_guard_flag <folder_name>
# Returns: "true" or "false" or "" if not in guardfile
get_folder_guard_flag() {
    local folder_name="$1"

    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    local in_folders_section=0
    local found_folder=0
    local result=""

    while IFS= read -r line; do
        # Check if we're entering folders section
        if [[ "$line" == "folders:" ]]; then
            in_folders_section=1
            continue
        fi

        # Exit folders section if we hit another top-level section
        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "folders:" ]]; then
            in_folders_section=0
        fi

        if [ $in_folders_section -eq 1 ]; then
            # Check for name match (handle both single and double quotes)
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*[\"\']*(.+)[\"\']*$ ]]; then
                local fld_name="${BASH_REMATCH[1]}"
                # Remove trailing/leading quotes (both single and double)
                fld_name="${fld_name%\'}"
                fld_name="${fld_name%\"}"
                fld_name="${fld_name#\'}"
                fld_name="${fld_name#\"}"

                if [ "$fld_name" = "$folder_name" ]; then
                    found_folder=1
                else
                    found_folder=0
                fi
            fi

            # If we found our folder, look for the guard flag
            if [ $found_folder -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*guard:[[:space:]]*(true|false) ]]; then
                    result="${BASH_REMATCH[1]}"
                    break
                fi

                # Reset if we hit the next folder entry
                if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]] && [ -n "$result" ]; then
                    break
                fi
            fi
        fi
    done < .guardfile

    echo "$result"
}

# Check if folder exists in .guardfile
# Usage: folder_exists_in_registry <folder_name>
# Returns: 0 if exists, 1 if not
folder_exists_in_registry() {
    local folder_name="$1"

    if [ ! -f ".guardfile" ]; then
        return 1
    fi

    local in_folders_section=0

    while IFS= read -r line; do
        if [[ "$line" == "folders:" ]]; then
            in_folders_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "folders:" ]]; then
            in_folders_section=0
        fi

        if [ $in_folders_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*[\"\']*(.+)[\"\']*$ ]]; then
                local fld_name="${BASH_REMATCH[1]}"
                # Remove trailing quotes (both single and double)
                fld_name="${fld_name%\'}"
                fld_name="${fld_name%\"}"
                fld_name="${fld_name#\'}"
                fld_name="${fld_name#\"}"

                if [ "$fld_name" = "$folder_name" ]; then
                    return 0
                fi
            fi
        fi
    done < .guardfile

    return 1
}

# Get folder path from .guardfile
# Usage: get_folder_path <folder_name>
# Returns: path string or "" if not found
get_folder_path() {
    local folder_name="$1"

    if [ ! -f ".guardfile" ]; then
        echo ""
        return 1
    fi

    local in_folders_section=0
    local found_folder=0
    local result=""

    while IFS= read -r line; do
        if [[ "$line" == "folders:" ]]; then
            in_folders_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "folders:" ]]; then
            in_folders_section=0
        fi

        if [ $in_folders_section -eq 1 ]; then
            # Check for name match (handle both single and double quotes)
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name:[[:space:]]*[\"\']*(.+)[\"\']*$ ]]; then
                local fld_name="${BASH_REMATCH[1]}"
                # Remove trailing/leading quotes (both single and double)
                fld_name="${fld_name%\'}"
                fld_name="${fld_name%\"}"
                fld_name="${fld_name#\'}"
                fld_name="${fld_name#\"}"

                if [ "$fld_name" = "$folder_name" ]; then
                    found_folder=1
                else
                    found_folder=0
                fi
            fi

            # If we found our folder, look for the path
            if [ $found_folder -eq 1 ]; then
                if [[ "$line" =~ ^[[:space:]]*path:[[:space:]]*[\"\']*(.+)[\"\']*$ ]]; then
                    result="${BASH_REMATCH[1]}"
                    # Remove trailing/leading quotes
                    result="${result%\'}"
                    result="${result%\"}"
                    result="${result#\'}"
                    result="${result#\"}"
                    break
                fi
            fi
        fi
    done < .guardfile

    echo "$result"
}

# Count folders in .guardfile
# Returns: number of folders
count_folders_in_registry() {
    if [ ! -f ".guardfile" ]; then
        echo "0"
        return
    fi

    local count=0
    local in_folders_section=0

    while IFS= read -r line; do
        if [[ "$line" == "folders:" ]]; then
            in_folders_section=1
            continue
        fi

        if [[ "$line" =~ ^[a-z_]+:$ ]] && [[ "$line" != "folders:" ]]; then
            in_folders_section=0
        fi

        if [ $in_folders_section -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*name: ]]; then
                ((count++))
            fi
        fi
    done < .guardfile

    echo "$count"
}


# Assert that output contains expected text
# Usage: assert_output_contains "$output" "expected text" "description"
assert_output_contains() {
    local output="$1"
    local expected="$2"
    local description="$3"

    if [[ "$output" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $description"
        echo "Expected to find: '$expected'"
        echo "In output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

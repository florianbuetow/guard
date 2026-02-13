#!/bin/bash

# helpers-tui.sh - Helper functions for TUI integration tests
# These helpers use tmux to control and test the Guard TUI
#
# Key behaviors:
# - Screenshots are taken after every action and on every failure
# - tmux sessions are always cleaned up, even on failures
# - Failures include path to the latest screenshot for debugging

# ============================================================================
# TUI Configuration
# ============================================================================

TUI_SESSION="guard_tui_test_$$"  # Unique session name per process
TUI_DEFAULT_WIDTH=80
TUI_DEFAULT_HEIGHT=30
TUI_RENDER_DELAY=0.3  # Time to wait for TUI to render after keystrokes
TUI_STARTUP_DELAY=4.0 # Time to wait for TUI to initialize

# Screenshot/logging configuration
TUI_SCREENSHOT_DIR=""           # Set per-test to ./reports/tui-tests/<testname>
TUI_SCREENSHOT_COUNTER=0        # Counter for screenshot numbering
TUI_SCREENSHOT_ENABLED=true     # Set to false to disable screenshots
TUI_LAST_SCREENSHOT=""          # Path to the most recent screenshot (for error messages)
TUI_CURRENT_TEST=""             # Name of the currently running test

# ============================================================================
# Screenshot/Logging Functions
# ============================================================================

# Take a screenshot and save it with description
# Usage: tui_screenshot <description>
# Sets: TUI_LAST_SCREENSHOT to the path of the screenshot
tui_screenshot() {
    local description="$1"

    if [ "$TUI_SCREENSHOT_ENABLED" != "true" ]; then
        return 0
    fi

    if [ -z "$TUI_SCREENSHOT_DIR" ]; then
        return 0
    fi

    ((TUI_SCREENSHOT_COUNTER++))

    local safe_desc=$(echo "$description" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local filename=$(printf "%02d_%s.txt" "$TUI_SCREENSHOT_COUNTER" "$safe_desc")
    local filepath="$TUI_SCREENSHOT_DIR/$filename"

    TUI_LAST_SCREENSHOT="$filepath"

    # Capture screen content
    {
        echo "=== Screenshot $TUI_SCREENSHOT_COUNTER: $description ==="
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Test: $TUI_CURRENT_TEST"
        echo "=================================================="
        echo ""
        tmux capture-pane -t "$TUI_SESSION" -p 2>/dev/null || echo "[Session not available]"
        echo ""
        echo "=== End Screenshot ==="
    } > "$filepath"

    # Also capture with ANSI codes for color debugging
    {
        echo "=== Screenshot $TUI_SCREENSHOT_COUNTER (with ANSI): $description ==="
        tmux capture-pane -t "$TUI_SESSION" -p -e 2>/dev/null || echo "[Session not available]"
    } > "${filepath%.txt}_ansi.txt"
}

# Finalize screenshots for a test
# Usage: tui_finalize_screenshots [result]
tui_finalize_screenshots() {
    local result="${1:-UNKNOWN}"

    if [ -z "$TUI_SCREENSHOT_DIR" ]; then
        return 0
    fi

    # Log test end
    {
        echo "Ended: $(date)"
        echo "Result: $result"
        echo "Total screenshots: $TUI_SCREENSHOT_COUNTER"
        echo "Last screenshot: $TUI_LAST_SCREENSHOT"
    } >> "$TUI_SCREENSHOT_DIR/00_test_info.txt"
}

# ============================================================================
# TUI Cleanup and Failure Handling
# ============================================================================

# Ensure tmux session is cleaned up
# Usage: tui_cleanup
# This should be called in trap handlers and on test completion
tui_cleanup() {
    # Kill tmux session if it exists
    tmux kill-session -t "$TUI_SESSION" 2>/dev/null || true

    # Clean up stderr file if it exists
    if [ -n "$TUI_STDERR_FILE" ] && [ -f "$TUI_STDERR_FILE" ]; then
        rm -f "$TUI_STDERR_FILE"
    fi

    # Clean up short link if it exists
    rm -f "/tmp/_gt$$" 2>/dev/null || true

    # Brief pause to ensure tmux session is fully terminated
    sleep 0.2
}

# Handle test failure: take screenshot, cleanup, and exit
# Usage: tui_fail <message>
# This function ALWAYS exits with code 1
tui_fail() {
    local message="$1"

    # Take failure screenshot
    tui_screenshot "FAILURE_${message}"

    echo -e "${RED}✗ TEST FAILED${NC}: $message"
    echo -e "  Last screenshot: $TUI_LAST_SCREENSHOT"
    echo -e "  Screenshot dir:  $TUI_SCREENSHOT_DIR"

    # Finalize screenshots
    tui_finalize_screenshots "FAIL"

    # Cleanup tmux
    tui_cleanup

    # Exit with error
    exit 1
}

# ============================================================================
# TUI Session Management
# ============================================================================

# Start the TUI in a tmux session with specified dimensions
# Usage: tui_start [width] [height]
# Returns: 0 on success, calls tui_fail on failure
tui_start() {
    local width="${1:-$TUI_DEFAULT_WIDTH}"
    local height="${2:-$TUI_DEFAULT_HEIGHT}"

    # Kill any existing session with same name and wait for it to terminate
    tmux kill-session -t "$TUI_SESSION" 2>/dev/null || true
    sleep 0.3

    # Verify session is gone before creating new one
    while tmux has-session -t "$TUI_SESSION" 2>/dev/null; do
        sleep 0.1
    done

    # Create new detached session with specific size
    if ! tmux new-session -d -s "$TUI_SESSION" -x "$width" -y "$height" 2>/dev/null; then
        tui_fail "Failed to create tmux session"
    fi

    # Change to current working directory in the tmux session
    # Use 'cd -P .' workaround to handle long paths in narrow terminals
    local current_dir="$(pwd)"
    # Create a symbolic link with a short name to avoid path wrapping
    local short_link="/tmp/_gt$$"
    ln -sfn "$current_dir" "$short_link"
    tmux send-keys -t "$TUI_SESSION" "cd $short_link" Enter
    sleep 0.5

    # Start guard TUI in the session
    tmux send-keys -t "$TUI_SESSION" "$GUARD_BIN -i" Enter

    # Wait for TUI to initialize
    sleep "$TUI_STARTUP_DELAY"

    # Take initial screenshot
    tui_screenshot "tui_start_${width}x${height}"

    return 0
}

# Start the TUI and capture stderr for error testing
# Usage: tui_start_capture_error [width] [height]
# Sets: TUI_STDERR_FILE with path to stderr capture file
tui_start_capture_error() {
    local width="${1:-$TUI_DEFAULT_WIDTH}"
    local height="${2:-$TUI_DEFAULT_HEIGHT}"

    TUI_STDERR_FILE=$(mktemp)

    # Kill any existing session
    tmux kill-session -t "$TUI_SESSION" 2>/dev/null || true

    # Create new session
    if ! tmux new-session -d -s "$TUI_SESSION" -x "$width" -y "$height" 2>/dev/null; then
        tui_fail "Failed to create tmux session for error capture"
    fi

    # Change to current directory
    tmux send-keys -t "$TUI_SESSION" "cd $(pwd)" Enter
    sleep 0.1

    # Start guard TUI with stderr redirect
    tmux send-keys -t "$TUI_SESSION" "$GUARD_BIN -i 2>$TUI_STDERR_FILE" Enter

    sleep "$TUI_STARTUP_DELAY"

    # Take screenshot
    tui_screenshot "tui_start_capture_error_${width}x${height}"

    return 0
}

# Stop the TUI by sending quit key and cleaning up tmux session
# Usage: tui_stop
tui_stop() {
    # Take final screenshot before quitting
    tui_screenshot "before_quit"

    # Try to quit gracefully first
    tmux send-keys -t "$TUI_SESSION" "q" 2>/dev/null || true
    sleep 0.2

    # Take screenshot after quit attempt
    tui_screenshot "after_quit"

    # Cleanup
    tui_cleanup
}

# Force stop without graceful quit (for tests where TUI may have crashed)
# Usage: tui_force_stop
tui_force_stop() {
    # Take screenshot before force stop
    tui_screenshot "before_force_stop"

    # Cleanup
    tui_cleanup
}

# ============================================================================
# Keystroke Sending
# ============================================================================

# Send keys to the TUI and wait for render
# Usage: tui_send_keys <keys>
tui_send_keys() {
    local keys="$1"

    if ! tmux send-keys -t "$TUI_SESSION" "$keys" 2>/dev/null; then
        tui_fail "Failed to send keys '$keys' - tmux session may have died"
    fi

    sleep "$TUI_RENDER_DELAY"

    # Take screenshot after action
    tui_screenshot "after_key_$keys"
}

# Send keys without waiting (for rapid key sequences)
# Usage: tui_send_keys_fast <keys>
tui_send_keys_fast() {
    local keys="$1"
    tmux send-keys -t "$TUI_SESSION" "$keys" 2>/dev/null || true
}

# Send multiple keys with delay between each
# Usage: tui_send_key_sequence <key1> <key2> ...
tui_send_key_sequence() {
    for key in "$@"; do
        tui_send_keys "$key"
    done
}

# Send a literal string (typed character by character)
# Usage: tui_type "text to type"
tui_type() {
    local text="$1"
    tmux send-keys -t "$TUI_SESSION" -l "$text" 2>/dev/null || true
    sleep "$TUI_RENDER_DELAY"

    # Take screenshot after typing
    tui_screenshot "after_type_text"
}

# ============================================================================
# Screen Capture
# ============================================================================

# Capture the current screen content
# Usage: screen=$(tui_capture)
tui_capture() {
    tmux capture-pane -t "$TUI_SESSION" -p 2>/dev/null || echo ""
}

# Capture screen content including ANSI escape codes (for color testing)
# Usage: screen=$(tui_capture_ansi)
tui_capture_ansi() {
    tmux capture-pane -t "$TUI_SESSION" -p -e 2>/dev/null || echo ""
}

# Get captured stderr content
# Usage: stderr=$(tui_get_stderr)
tui_get_stderr() {
    if [ -n "$TUI_STDERR_FILE" ] && [ -f "$TUI_STDERR_FILE" ]; then
        cat "$TUI_STDERR_FILE"
    fi
}

# ============================================================================
# TUI Assertions
# All assertions take a screenshot on failure and include the screenshot path
# ============================================================================

# Assert screen contains a specific string
# Usage: tui_assert_contains <needle> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_contains() {
    local needle="$1"
    local message="$2"
    local screen=$(tui_capture)

    if [[ "$screen" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_contains"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected to find: '$needle'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        echo -e "  Screen content (first 20 lines):"
        echo "$screen" | head -20 | sed 's/^/    /'
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert screen does NOT contain a specific string
# Usage: tui_assert_not_contains <needle> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_not_contains() {
    local needle="$1"
    local message="$2"
    local screen=$(tui_capture)

    if [[ "$screen" != *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_not_contains"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Did NOT expect to find: '$needle'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert screen contains text matching a regex pattern
# Usage: tui_assert_matches <pattern> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_matches() {
    local pattern="$1"
    local message="$2"
    local screen=$(tui_capture)

    if [[ "$screen" =~ $pattern ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_matches_pattern"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected to match pattern: '$pattern'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        echo -e "  Screen content (first 20 lines):"
        echo "$screen" | head -20 | sed 's/^/    /'
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert stderr contains a specific string (for error testing)
# Usage: tui_assert_stderr_contains <needle> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_stderr_contains() {
    local needle="$1"
    local message="$2"
    local stderr=$(tui_get_stderr)

    if [[ "$stderr" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_stderr_contains"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected stderr to contain: '$needle'"
        echo -e "  Stderr content: '$stderr'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert the TUI session is still running (not crashed/exited)
# Usage: tui_assert_running <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_running() {
    local message="$1"

    if tmux has-session -t "$TUI_SESSION" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Can't take screenshot if session died, but note the last one
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  TUI session is not running (crashed or exited unexpectedly)"
        echo -e "  Last screenshot before failure: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert the TUI has exited (returned to shell prompt)
# Usage: tui_assert_exited <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_exited() {
    local message="$1"

    # Give it a moment to exit
    sleep 0.3

    # Check if the session still exists
    if ! tmux has-session -t "$TUI_SESSION" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    fi

    # Session exists - check if TUI has exited by looking for shell prompt
    # The TUI is gone if we see a shell prompt (% or $) and no TUI elements
    local screen=$(tui_capture)

    # If screen doesn't contain TUI elements (Files/Collections headers) and has shell prompt, TUI exited
    if [[ "$screen" != *"● Files"* ]] && [[ "$screen" != *"○ Files"* ]] && [[ "$screen" == *"%"* || "$screen" == *"$"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take screenshot showing it's still running and exit immediately
        tui_screenshot "ASSERT_FAIL_should_have_exited"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  TUI is still running but should have exited"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        echo -e "  Screen content (first 10 lines):"
        echo "$screen" | head -10 | sed 's/^/    /'
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert two values are equal (TUI version - exits immediately on failure)
# Usage: tui_assert_equals <expected> <actual> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_equals"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected: '$expected'"
        echo -e "  Actual:   '$actual'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert screen contains ANSI escape code (for color testing)
# Usage: tui_assert_has_ansi_code <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_has_ansi_code() {
    local code="$1"
    local message="$2"
    local screen=$(tui_capture_ansi)

    if [[ "$screen" == *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_ansi_code"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected ANSI code: '$code'"
        echo -e "  Screenshot (with ANSI): ${TUI_LAST_SCREENSHOT%.txt}_ansi.txt"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert a specific row contains expected pattern
# Usage: tui_assert_row_contains <row_num> <pattern> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_row_contains() {
    local row_num="$1"
    local pattern="$2"
    local message="$3"
    local screen=$(tui_capture)
    local row=$(echo "$screen" | sed -n "${row_num}p")

    if [[ "$row" == *"$pattern"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_row_contains"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Row $row_num: '$row'"
        echo -e "  Expected to contain: '$pattern'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert a specific row does NOT contain a pattern
# Usage: tui_assert_row_not_contains <row_num> <pattern> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_row_not_contains() {
    local row_num="$1"
    local pattern="$2"
    local message="$3"
    local screen=$(tui_capture)
    local row=$(echo "$screen" | sed -n "${row_num}p")

    if [[ "$row" != *"$pattern"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_row_not_contains"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Row $row_num: '$row'"
        echo -e "  Did NOT expect to contain: '$pattern'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert a specific row contains an ANSI escape code (for color testing)
# Usage: tui_assert_row_has_ansi_code <row_num> <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_row_has_ansi_code() {
    local row_num="$1"
    local code="$2"
    local message="$3"
    local screen=$(tui_capture_ansi)
    local row=$(echo "$screen" | sed -n "${row_num}p")

    if [[ "$row" == *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_row_has_ansi_code"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Row $row_num does not contain ANSI code: '$code'"
        echo -e "  Row content: '$row'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert a specific row does NOT contain an ANSI escape code (for color testing)
# Usage: tui_assert_row_no_ansi_code <row_num> <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_row_no_ansi_code() {
    local row_num="$1"
    local code="$2"
    local message="$3"
    local screen=$(tui_capture_ansi)
    local row=$(echo "$screen" | sed -n "${row_num}p")

    if [[ "$row" != *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        # Take failure screenshot and exit immediately
        tui_screenshot "ASSERT_FAIL_row_no_ansi_code"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Row $row_num should NOT contain ANSI code: '$code'"
        echo -e "  Row content: '$row'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert left panel area contains an ANSI code (for split-panel color testing)
# Extracts content before the frame separator │ from content rows
# Usage: tui_assert_left_panel_has_ansi_code <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_left_panel_has_ansi_code() {
    local code="$1"
    local message="$2"
    local screen=$(tui_capture_ansi)
    # Extract left panel: everything before the last │ on lines that have │
    local left_content
    left_content=$(echo "$screen" | sed -n 's/\(.*\)│.*/\1/p')

    if [[ "$left_content" == *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        tui_screenshot "ASSERT_FAIL_left_panel_ansi"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected left panel to contain ANSI code: '$code'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert left panel area does NOT contain an ANSI code
# Usage: tui_assert_left_panel_no_ansi_code <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_left_panel_no_ansi_code() {
    local code="$1"
    local message="$2"
    local screen=$(tui_capture_ansi)
    local left_content
    left_content=$(echo "$screen" | sed -n 's/\(.*\)│.*/\1/p')

    if [[ "$left_content" != *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        tui_screenshot "ASSERT_FAIL_left_panel_no_ansi"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Left panel should NOT contain ANSI code: '$code'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert right panel area contains an ANSI code
# Usage: tui_assert_right_panel_has_ansi_code <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_right_panel_has_ansi_code() {
    local code="$1"
    local message="$2"
    local screen=$(tui_capture_ansi)
    # Extract right panel: everything after the last │ on lines that have │
    local right_content
    right_content=$(echo "$screen" | sed -n 's/.*│//p')

    if [[ "$right_content" == *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        tui_screenshot "ASSERT_FAIL_right_panel_ansi"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Expected right panel to contain ANSI code: '$code'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# Assert right panel area does NOT contain an ANSI code
# Usage: tui_assert_right_panel_no_ansi_code <code> <message>
# FAILS IMMEDIATELY on assertion failure (exits with code 1)
tui_assert_right_panel_no_ansi_code() {
    local code="$1"
    local message="$2"
    local screen=$(tui_capture_ansi)
    local right_content
    right_content=$(echo "$screen" | sed -n 's/.*│//p')

    if [[ "$right_content" != *"$code"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        tui_screenshot "ASSERT_FAIL_right_panel_no_ansi"
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo -e "  Right panel should NOT contain ANSI code: '$code'"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Wait for a specific text to appear on screen (with timeout)
# Usage: tui_wait_for <text> [timeout_seconds]
# Returns: 0 if text found, 1 if timeout
tui_wait_for() {
    local text="$1"
    local timeout="${2:-5}"
    local elapsed=0
    local interval=0.2

    while (( $(echo "$elapsed < $timeout" | bc -l) )); do
        local screen=$(tui_capture)
        if [[ "$screen" == *"$text"* ]]; then
            return 0
        fi
        sleep $interval
        elapsed=$(echo "$elapsed + $interval" | bc)
    done

    tui_screenshot "wait_for_timeout_${text}"
    return 1
}

# Wait for a specific text to disappear from screen (with timeout)
# Usage: tui_wait_for_gone <text> [timeout_seconds]
tui_wait_for_gone() {
    local text="$1"
    local timeout="${2:-5}"
    local elapsed=0
    local interval=0.2

    while (( $(echo "$elapsed < $timeout" | bc -l) )); do
        local screen=$(tui_capture)
        if [[ "$screen" != *"$text"* ]]; then
            return 0
        fi
        sleep $interval
        elapsed=$(echo "$elapsed + $interval" | bc)
    done

    tui_screenshot "wait_for_gone_timeout_${text}"
    return 1
}

# Get the current terminal dimensions of the TUI session
# Usage: dims=$(tui_get_dimensions)
tui_get_dimensions() {
    local width=$(tmux display-message -t "$TUI_SESSION" -p '#{pane_width}' 2>/dev/null || echo "0")
    local height=$(tmux display-message -t "$TUI_SESSION" -p '#{pane_height}' 2>/dev/null || echo "0")
    echo "${width}x${height}"
}

# Resize the TUI terminal
# Usage: tui_resize <width> <height>
tui_resize() {
    local width="$1"
    local height="$2"
    tmux resize-window -t "$TUI_SESSION" -x "$width" -y "$height" 2>/dev/null || true
    sleep "$TUI_RENDER_DELAY"
    tui_screenshot "after_resize_${width}x${height}"
}

# Get the exit code of the TUI process
# Usage: exit_code=$(tui_get_exit_code)
# Note: Must be called after TUI has exited. Returns the exit code from the tmux pane.
tui_get_exit_code() {
    # Check if session exists
    if tmux has-session -t "$TUI_SESSION" 2>/dev/null; then
        # Session still exists, try to get the last command exit code
        # This works by reading the shell's $? from the pane
        tmux send-keys -t "$TUI_SESSION" 'echo $?' Enter
        sleep 0.2
        local screen=$(tmux capture-pane -t "$TUI_SESSION" -p 2>/dev/null)
        # Get the last number in the output (should be the exit code)
        local exit_code=$(echo "$screen" | grep -E '^[0-9]+$' | tail -1)
        if [ -n "$exit_code" ]; then
            echo "$exit_code"
        else
            echo "-1"
        fi
    else
        # Session doesn't exist - can't get exit code
        echo "-1"
    fi
}

# Start TUI and capture exit code after it exits
# Usage: tui_start_for_exit_code
# Sets: TUI_EXIT_CODE_FILE with path to file that will contain exit code
tui_start_for_exit_code() {
    local width="${1:-$TUI_DEFAULT_WIDTH}"
    local height="${2:-$TUI_DEFAULT_HEIGHT}"

    TUI_EXIT_CODE_FILE=$(mktemp)

    # Kill any existing session
    tmux kill-session -t "$TUI_SESSION" 2>/dev/null || true

    # Create new session
    if ! tmux new-session -d -s "$TUI_SESSION" -x "$width" -y "$height" 2>/dev/null; then
        tui_fail "Failed to create tmux session for exit code capture"
    fi

    # Change to current directory
    tmux send-keys -t "$TUI_SESSION" "cd $(pwd)" Enter
    sleep 0.1

    # Start guard TUI and capture exit code after it exits
    tmux send-keys -t "$TUI_SESSION" "$GUARD_BIN -i; echo \$? > $TUI_EXIT_CODE_FILE" Enter

    sleep "$TUI_STARTUP_DELAY"

    # Take screenshot
    tui_screenshot "tui_start_for_exit_code_${width}x${height}"

    return 0
}

# Read the captured exit code
# Usage: exit_code=$(tui_read_exit_code)
# Must call tui_start_for_exit_code first, then quit TUI, then call this
tui_read_exit_code() {
    if [ -n "$TUI_EXIT_CODE_FILE" ] && [ -f "$TUI_EXIT_CODE_FILE" ]; then
        # Wait a moment for the file to be written
        sleep 0.3
        cat "$TUI_EXIT_CODE_FILE" 2>/dev/null || echo "-1"
    else
        echo "-1"
    fi
}

# ============================================================================
# Check Prerequisites
# ============================================================================

# Check if tmux is available
# Usage: tui_check_tmux
tui_check_tmux() {
    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}Error: tmux is required for TUI tests but is not installed${NC}"
        echo "Please install tmux to run TUI integration tests"
        return 1
    fi
    return 0
}

# ============================================================================
# TUI Test Runner (with screenshot support and guaranteed cleanup)
# ============================================================================

# Run a TUI test with screenshot logging and guaranteed tmux cleanup
# Usage: tui_run_test <test_function_name>
# Note: Tests exit immediately on first assertion failure
tui_run_test() {
    local test_function="$1"
    local report_base="${TUI_REPORT_BASE_DIR:-../reports/tui-tests}"

    TUI_CURRENT_TEST="$test_function"

    # Setup test environment (from helpers-cli.sh)
    setup_test_env

    # Initialize screenshots for this test
    # Use the original working directory for reports (not the temp test dir)
    local original_report_dir="$ORIGINAL_DIR/$report_base/$test_function"
    mkdir -p "$original_report_dir"

    TUI_SCREENSHOT_DIR="$original_report_dir"
    TUI_SCREENSHOT_COUNTER=0
    TUI_LAST_SCREENSHOT=""

    # Clear previous screenshots
    rm -f "$TUI_SCREENSHOT_DIR"/*.txt 2>/dev/null || true

    # Log test info
    {
        echo "Test: $test_function"
        echo "Started: $(date)"
        echo "Test dir: $TEST_DIR"
        echo "Report dir: $TUI_SCREENSHOT_DIR"
    } > "$TUI_SCREENSHOT_DIR/00_test_info.txt"

    # Set up trap to ensure cleanup on any exit
    trap 'tui_cleanup' EXIT

    # Disable set -e while running test to prevent ((TESTS_PASSED++)) from exiting
    # when counter is 0 (bash arithmetic returning 0 gives exit code 1)
    # Assertions call exit 1 directly on failure, so they still fail fast
    set +e
    $test_function
    local test_result=$?
    set -e

    # If test function returned non-zero (e.g., from a non-assertion failure), exit
    if [ $test_result -ne 0 ]; then
        echo -e "${RED}Test function returned non-zero exit code: $test_result${NC}"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        trap - EXIT
        exit 1
    fi

    # If we get here, the test passed
    # Ensure tmux is cleaned up (in case test didn't call tui_stop)
    tui_cleanup

    # Remove the trap
    trap - EXIT

    # Finalize screenshots
    {
        echo "Ended: $(date)"
        echo "Result: PASS"
        echo "Assertions passed: $TESTS_PASSED"
        echo "Total screenshots: $TUI_SCREENSHOT_COUNTER"
    } >> "$TUI_SCREENSHOT_DIR/00_test_info.txt"

    # Teardown test environment
    teardown_test_env

    # Print success
    echo -e "\n${GREEN}Test passed${NC} ($TESTS_PASSED assertions)"
    echo "  Screenshots: $TUI_SCREENSHOT_DIR"
    return 0
}

# Initialize the reports directory structure
# Usage: tui_init_reports_dir
tui_init_reports_dir() {
    local report_base="${TUI_REPORT_BASE_DIR:-../reports/tui-tests}"

    # Create base directory
    mkdir -p "$report_base"

    # Create index file
    {
        echo "TUI Milestone 1 Test Reports"
        echo "============================="
        echo "Generated: $(date)"
        echo ""
        echo "Each test has its own subdirectory with screenshots."
        echo "Screenshots are numbered in order of execution."
        echo "On failure, check the ASSERT_FAIL_* screenshots."
        echo ""
    } > "$report_base/00_index.txt"
}

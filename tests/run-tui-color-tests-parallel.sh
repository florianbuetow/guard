#!/bin/bash

# run-tui-color-tests-parallel.sh - Run only TUI tests with _color_ in the filename.
# Color tests assert color ANSI escape codes, so they require color output.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export TUI_COLOR_TEST_MODE=include
exec "$SCRIPT_DIR/run-tui-tests-parallel.sh"

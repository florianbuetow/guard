# File Input Piping Design

**Date:** 2026-02-01
**Status:** Approved

## Overview

Enable all file-accepting guard commands to read file paths from stdin, supporting common Unix pipeline workflows.

## Requirements

### R1: Whitespace Parsing
Accept file paths separated by any whitespace (spaces, tabs, newlines). Empty entries are filtered out.

### R2: Input Merging
Combine stdin paths with command-line arguments; process all together.
```bash
echo "file1.go" | guard add file2.go file3.go
# Processes: file1.go, file2.go, file3.go
```

### R3: Supported Commands
All file-accepting commands:
- `guard add`
- `guard remove`
- `guard toggle`
- `guard enable`
- `guard disable`
- `guard show`
- `guard update` (file operations)

### R4: Empty Input Handling
Error with "No files specified" when neither stdin nor CLI args provide files. Preserves current behavior for interactive use.

### R5: Silent Operation
No special output indicating stdin was used; normal command output only.

## Example Usage

```bash
# Find and add Go files
find . -name "*.go" | guard add

# Enable guard on files from a list
cat protected.txt | guard enable

# Mixed stdin and CLI args
echo "a.go b.go" | guard toggle c.go

# Git integration
git diff --name-only | guard disable

# Space-separated input
echo "file1.txt file2.txt file3.txt" | guard add
```

## Technical Approach

### New Utility Function

Create `internal/cli/stdin.go`:

```go
package cli

import (
    "bufio"
    "os"
    "strings"
)

// CollectFileArgs reads file paths from stdin (if piped) and merges with CLI args.
// Returns error if no files provided from either source.
func CollectFileArgs(args []string) ([]string, error) {
    var files []string

    // Check if stdin is a pipe (not a terminal)
    stat, _ := os.Stdin.Stat()
    isPiped := (stat.Mode() & os.ModeCharDevice) == 0

    if isPiped {
        scanner := bufio.NewScanner(os.Stdin)
        scanner.Split(bufio.ScanWords) // splits on whitespace
        for scanner.Scan() {
            word := strings.TrimSpace(scanner.Text())
            if word != "" {
                files = append(files, word)
            }
        }
    }

    // Merge with CLI args
    files = append(files, args...)

    return files, nil
}
```

### Stdin Detection

```go
stat, _ := os.Stdin.Stat()
isPiped := (stat.Mode() & os.ModeCharDevice) == 0
```

This detects whether stdin is connected to a pipe vs terminal, avoiding blocking on interactive use.

## Command Modifications

Each command's `Run` function changes from:
```go
// Before
if len(args) == 0 {
    fmt.Fprintln(os.Stderr, "Error: No files specified")
    os.Exit(1)
}
```

To:
```go
// After
files, err := cli.CollectFileArgs(args)
if err != nil {
    fmt.Fprintln(os.Stderr, "Error:", err)
    os.Exit(1)
}
if len(files) == 0 {
    fmt.Fprintln(os.Stderr, "Error: No files specified")
    os.Exit(1)
}
```

### Files to Modify

| File | Functions |
|------|-----------|
| `cmd/guard/commands/add.go` | `addFiles`, `newAddFileCmd` |
| `cmd/guard/commands/remove.go` | remove file handling |
| `cmd/guard/commands/toggle.go` | `NewToggleCmd`, `newToggleFileCmd` |
| `cmd/guard/commands/enable.go` | enable file handling |
| `cmd/guard/commands/disable.go` | disable file handling |
| `cmd/guard/commands/show.go` | show file handling |
| `cmd/guard/commands/update.go` | update collection add/remove files |

## File Structure

```
internal/
  cli/
    stdin.go       # New: CollectFileArgs utility
    stdin_test.go  # New: Unit tests
```

## Testing Strategy

### Unit Tests (`internal/cli/stdin_test.go`)

- Empty stdin + empty args → returns empty slice
- Stdin with newline-separated paths → parsed correctly
- Stdin with space-separated paths → parsed correctly
- Stdin with mixed whitespace → parsed correctly
- Stdin + CLI args → merged correctly
- Paths with trailing/leading whitespace → trimmed

### Shell Integration Tests

New test directory: `tests/stdin/`

```bash
# tests/stdin/test_stdin_add.sh
echo -e "file1.txt\nfile2.txt" | guard add
guard show file1.txt  # verify registered

# tests/stdin/test_stdin_toggle.sh
echo "file1.txt file2.txt" | guard toggle

# tests/stdin/test_stdin_combined.sh
echo "file1.txt" | guard add file2.txt
guard show file1.txt file2.txt  # both registered

# tests/stdin/test_stdin_empty.sh
echo "" | guard add  # should error
```

### Test Files to Add

- `tests/stdin/test_stdin_add.sh`
- `tests/stdin/test_stdin_toggle.sh`
- `tests/stdin/test_stdin_enable_disable.sh`
- `tests/stdin/test_stdin_combined.sh`

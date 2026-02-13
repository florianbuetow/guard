# Guard - AI Agent Instructions

## Project Overview

Guard is a Go CLI/TUI tool that protects files from unwanted modifications by AI coding agents. It manages Unix file permissions, ownership, and immutable flags via a `.guardfile` registry.

## Build & Run

```bash
just build          # Build binary to ./bin/guard
just install        # Install to $GOPATH/bin
just test           # Format, build, install, run all tests
just ci-quiet       # Full CI pipeline with minimal output
just fmt            # Format Go code
just lint           # Run linter (golangci-lint or go vet fallback)
just clean          # Remove build artifacts
```

## Testing

### Test types
- **Go unit tests**: `go test -v ./...` (internal packages)
- **CLI integration tests**: `tests/run-cli-tests-sequential.sh` (shell-based, test real CLI behavior)
- **TUI integration tests**: `tests/run-tui-tests-parallel.sh` (tmux-based, requires `tmux` installed)

### Test conventions
- CLI tests source `tests/helpers-cli.sh` for assertions and setup
- TUI tests source `tests/helpers-tui.sh` for tmux session management and screenshots
- Test files follow the pattern `test-<category>-<number>.sh`
- TUI tests use tmux to spawn sessions, send keystrokes, capture screen output, and assert content
- Each test creates its own temp directory and cleans up after itself
- Always run `just test` or `just ci-quiet` to verify changes before claiming they work

### Writing tests
- CLI tests: use `assert_output_contains`, `assert_exit_code`, `assert_file_mode` etc. from `helpers-cli.sh`
- TUI tests: use `tui_start`, `tui_send_keys`, `tui_assert_screen_contains` etc. from `helpers-tui.sh`
- Keep individual TUI tests under 30 seconds (parallel runner timeout)

## Architecture

```
cmd/guard/commands/  CLI layer (Cobra) - parsing, output formatting
internal/tui/        TUI layer (Bubble Tea) - terminal UI
internal/manager/    Orchestration - business logic, sequencing
internal/filesystem/ OS operations - chmod/chown, immutable flags
internal/security/   Path validation, tamper detection
internal/registry/   Data model, YAML serialization (.guardfile)
```

### Dependency rules (strictly enforced via `internal/architecture/layers_test.go`)
- `cmd/guard/*` -> `internal/manager` only
- `internal/tui/*` -> `internal/manager` only
- `internal/manager/*` -> `internal/security` + `internal/filesystem`
- `internal/security/*` -> `internal/registry`
- **Never**: UI layers directly importing filesystem, registry, or security

### Key design principles
- Manager owns all mutation sequencing and persistence
- UI layers (CLI and TUI) are pure clients of manager - they call use-cases and render results
- The manager never prints to stdout/stderr; it returns structured results and warnings
- Registry stores relative paths; filesystem operations use absolute paths
- Platform-specific code lives in `filesystem_darwin.go` / `filesystem_linux.go`

## Code Style

- Go standard formatting (`go fmt`)
- No direct `fmt.Print*` in manager/filesystem/registry/security layers
- Errors are returned, not printed - the CLI/TUI layer decides how to present them
- Prefer typed errors for special cases (e.g., root-required operations)

## Files to never edit directly

- `.guardfile` - managed by the guard tool at runtime
- `reports/` - generated test artifacts (gitignored)

## Common workflows

### Adding a new CLI command
1. Create `cmd/guard/commands/<command>.go` with Cobra command definition
2. Add corresponding manager method in `internal/manager/`
3. Write shell test in `tests/test-<command>-001.sh`
4. Run `just test` to verify

### Adding a TUI feature
1. Modify relevant files in `internal/tui/` (Bubble Tea Model/Update/View)
2. If new data is needed, add a manager query method - do not access filesystem or registry directly
3. Write tmux-based test in `tests/test-tui-<feature>-001.sh`
4. Run `just test` to verify

### Fixing a bug
1. Write a failing test first (`tests/test-bug-<area>-<number>.sh`)
2. Verify it fails with `just test`
3. Implement the fix
4. Verify it passes with `just test`

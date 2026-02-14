# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This repository does not currently use release tags, so entries are grouped by date and major update scope.

## [Unreleased]

### Added

- No unreleased changes yet.

## [2026-02-13]

### Fixed

- Fixed collections pane viewport being 4 lines too small, caused by `CollectionTree.SetSize()` subtracting 4 from height for scroll viewport while the panel already accounts for borders. At small terminal heights the viewport went negative and the collections pane showed nothing.
- Fixed scroll margin calculation pushing the cursor off-screen when the viewport is very small (1–3 lines). The scroll margin is no longer floor-clamped to 1, which previously exceeded the viewport size at small heights.

### Changed

- Updated TUI selection rendering so the active selection highlight appears only in the focused pane, improving active-pane clarity when switching with `Tab`.
- Replaced `run-all-tests.sh` with focused test runners: `run-cli-tests-sequential.sh`, `run-tui-tests-sequential.sh`, and `run-tui-tests-parallel.sh`.
- Parallel TUI test runner uses a worker pool with configurable concurrency (default 16), 30-second per-test timeout with automatic kill, and staggered launch to avoid tmux thundering herd.
- Split `test-bug-tui-resize-002.sh` (3 test cases, ~60s) into three individual test files (`002a`, `002b`, `002c`) so each fits within the parallel timeout.
- Updated `justfile` targets (`test`, `ci-quiet`) to use the new test runners.

### Added

- Added regression test for collections pane scroll at viewport size 1 with a nested 7-node collection hierarchy, verifying correct display when scrolling with Up/Down arrow keys.
- Added regression test coverage for active-pane visual indication in the TUI.
- Added `guard` binary to `.gitignore`.

## [2026-02-12]

### Fixed

- Fixed a TUI layout issue that left three blank lines above the status bar due to duplicate height/border accounting.
- Fixed test discovery in `tests/run-all-tests.sh` (since replaced by split CLI/TUI runners — see 2026-02-13) so `tui` matching no longer misclassifies tests based on directory names.

### Added

- Added a regression test for the TUI resize/status bar spacing bug.

## [2026-02-08]

### Added

- Added platform-specific immutable flag implementations in `internal/filesystem/filesystem_darwin.go` (macOS) and `internal/filesystem/filesystem_linux.go` (Linux).
- Added new manager support modules (`folder_toggle.go`, `fs_view.go`, `queries.go`, `immutable.go`) to isolate responsibilities.
- Added command output helper module (`cmd/guard/commands/output.go`) and expanded output-focused test coverage.
- Added architecture and planning documentation, including `docs/ARCHITECTURE.md`, feature request tracking, and design plans for file-input piping and TUI active-pane indicators.
- Added extensive regression tests for CLI output, TUI behavior, immutable handling, and registry rollback paths.

### Changed

- Refactored manager, filesystem, command, and TUI layers for clearer boundaries and improved state handling.
- Improved CLI output formatting and reduced duplicate status lookups in enable/disable/toggle flows.
- Improved build/test behavior for sandboxed and CI environments (cache handling, `GOBIN` fallback, and test classification behavior).
- Updated version-format tests to accept bare git hash output when no tags exist.

### Fixed

- Fixed Linux immutable flag writes by switching to the correct pointer-based ioctl call for `FS_IOC_SETFLAGS`.
- Fixed rollback consistency when registry save fails by restoring file permissions to avoid partial state.
- Fixed multiple command/control-flow error paths (including missing `continue` handling and error propagation from collection-display helpers).
- Fixed `FileExists` behavior on permission-denied errors so inaccessible paths are not treated as existing.
- Fixed additional review issues: collection membership handling on remove failures, stderr routing, case-insensitive directory sorting, and stale/broken documentation references.

## [2026-01-31]

### Added

- Initial release of the `guard` CLI and TUI application.
- Core command surface (`add`, `remove`, `enable`, `disable`, `toggle`, `show`, `config`, `init`, `update`, and related commands).
- Core internal architecture packages for manager, filesystem, registry, security, and TUI rendering/interaction.
- Comprehensive shell-based test suite across command behavior, guard-state handling, formatting, errors, and end-to-end workflows.
- Project documentation including tutorials, bug tracking, development log, and automation/planning artifacts.

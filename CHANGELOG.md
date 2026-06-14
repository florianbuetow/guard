# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This repository does not currently use release tags, so entries are grouped by date and major update scope.

## [Unreleased]

### Added

- Added `.guardignore` support: a `.gitignore`-style file for custom ignore patterns independent of git, parsed using the same gitignore pattern semantics (via `go-git`).
- Added `use_gitignore` and `use_guardignore` config flags to the registry, controlling whether `.gitignore` and `.guardignore` rules are applied when filtering the TUI file tree. Both default to `true`.
- Added `guard config set use_gitignore <true|false>` and `guard config set use_guardignore <true|false>` CLI commands.
- Added `guard config show` output for `use_gitignore` and `use_guardignore` flags.
- Added `IgnoreMatcher` package (`internal/guardignore`) that reads `.gitignore` and `.guardignore` files from each directory, caches patterns per directory, and evaluates ignore rules with proper directory-only semantics.
- Added ignore-aware filtering in `Manager.ReadDir`: gitignored files are hidden unless they are guard-registered; gitignored directories are hidden unless they contain registered descendants.
- Added `--force` flag to `guard add` to allow registering files that match ignore patterns.
- Added `.guardignore` template creation on `guard init`.
- Added `IsIgnored` field to `DirEntry` and `FileNode`, threading gitignore status from `Manager.ReadDir` through to the TUI renderer.
- Added light blue color (`ColorIgnored`, ANSI 256-color 117) for gitignored-but-visible items in the TUI, with `[g]` (lowercase) guard indicator to distinguish them from normal `[G]` items.
- Added `ItemIgnored` and `GuardIgnored` styles to the TUI style system.
- Added 9 TUI integration tests for guardignore filtering, toggle behavior on gitignored folders, `[g]` vs `[G]` indicators, `.guardfile` hiding, and light blue ANSI color rendering.
- Added 7 CLI integration tests for `guard config set/show use_gitignore` and `use_guardignore` including stacked scenarios.
- Added `guardignore` package to architecture layering tests.

### Fixed

- Fixed recursive TUI folder toggles to respect ignore scope, skipping gitignored and guardignored files.
- Fixed toggle guard on gitignored folders to only affect already-registered files, skipping ignored unregistered files.
- Fixed `ReadDir` to show gitignored directories that contain registered descendants instead of hiding them entirely.
- Fixed `.guardfile` appearing in the TUI when it is gitignored and `use_gitignore` is enabled.
- Removed bold styling from `GuardExplicit` indicator to maintain consistent weight across guard states.

### Changed

- Extracted `LoadRegistry` boilerplate from 14 command files (26 call sites) into a single `PersistentPreRunE` in `main.go`, passing the manager via command context.
- Replaced `Manager.GetFileSystem().CheckFilesExist()` calls in `enable.go`, `disable.go`, and `toggle.go` with `Manager.CheckFilesExist()`, removing the leaked filesystem accessor.
- Replaced `matchKeyBinding` with the existing `matchKey` helper in `CollectionTree`, removing a redundant function and an unused import.
- Extracted `padContentToFit()` helper in `frame.go`, deduplicating ~17 lines of identical padding logic from `FilesPanel.ContentLines()` and `CollectionsPanel.ContentLines()`.
- Replaced 10-line guard-binary lookup boilerplate across 199 test files with a shared `find_guard_binary` function in `helpers-cli.sh`.
- Moved duplicate `count_blank_content_lines_above_statusbar` out of three resize test files into `helpers-tui.sh`.

### Added

- Added `CheckFilesExist` method to `Manager`, delegating to the filesystem layer without exposing it.
- Added `SetManager`/`GetManager` context helpers in `cmd/guard/commands/context.go` for passing manager from `PersistentPreRunE` to command `Run` functions.
- Added `find_guard_binary` helper to `helpers-cli.sh` for consistent guard binary resolution across all test files. Also adds `./bin/guard` as a search path (matching the `just build` output directory), which was not present in the original per-test boilerplate.
- Added `padContentToFit` utility to `frame.go` for reusable panel content padding.
- Added Go unit tests for `CalculateScrollOffset`, `CalculateVisibleRange`, and `ScrollState` in `scroll_test.go`.
- Added fuzzy search to the TUI: press `/` to activate a search box that filters the file tree in real-time using fuzzy matching.
- Added focus cycling with `Tab` when search is active: Files → Collections → Search → Files.
- Added 22 TUI integration tests covering search activation, typing, filtering, escape, focus cycling, and edge cases.

### Fixed

- Fixed cursor blink not working in the search box. The `tea.Cmd` returned by `textInput.Focus()` was being discarded; it is now propagated through `SetActive()`, `Focus()`, and `cycleFocus()`.

### Changed

- Changed focused panel title styling from bold (`\e[1m`) to reverse video (`\e[7m`) for better visual distinction of the active panel.

### Removed

- Removed `Manager.GetFileSystem()` accessor that leaked the filesystem layer through the manager API.

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

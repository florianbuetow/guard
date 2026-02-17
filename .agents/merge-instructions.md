# Merge Instructions: origin/dev into local dev

## Your Task

You are performing a manual merge of `origin/dev` into the local `dev` branch of the Guard project. Both branches diverged from a common ancestor (`c454a93`). There will be conflicts. You must resolve every conflict manually, preserving the intent and functionality from BOTH sides.

**Working directory:** `/Users/flo/Developer/github/guard.git/dev`

## The Git Situation

```
Common ancestor: c454a93 (Merge PR #5 - feature-tui-improvements)

LOCAL dev (HEAD = 1edc20b) — 1 commit ahead:
  1edc20b  Deduplicate code, DRY CLI layer, and improve encapsulation (#6)

ORIGIN dev (FETCH_HEAD = 50b06dc) — 11 commits ahead:
  fd25665  Replace pull requests section with AI-driven bug report workflow
  f23779f  Minor README wording and formatting fixes
  aa57c34  Add textual description requirement to TUI bug report option
  99f9e42  Fix: off by one indentation error
  7dd446f  Fix premature scroll in files pane by removing scroll margin
  c2a2eaa  Fix cursor sticking to bottom edge when scrolling up
  38f376b  Merge PR #7 (bugs)
  6d937e3  Add git rule: never use git -C for other worktrees
  53e7c35  Remove deprecated stateless scroll functions
  c299cb9  Merge PR #8 (bugs)
  50b06dc  Add fuzzy search to TUI (#9)
```

## How to Research What Each Side Did

Before resolving any conflict, make sure you understand what both sides intended. Use these commands:

```bash
# See what LOCAL changed in a specific file vs common ancestor:
git diff c454a93..HEAD -- <file>

# See what ORIGIN changed in a specific file vs common ancestor:
git diff c454a93..FETCH_HEAD -- <file>

# See the full fuzzy search feature commit history (useful for understanding the feature):
git log --oneline feature-fuzzy-search

# See what origin/dev added (full diff):
git diff c454a93..FETCH_HEAD

# See what local dev added (full diff):
git diff c454a93..HEAD

# Check remote branches for additional context:
gh api repos/florianbuetow/guard/pulls?state=closed --jq '.[].title'

# Read the CHANGELOG on each side:
git show HEAD:CHANGELOG.md
git show FETCH_HEAD:CHANGELOG.md
```

## What LOCAL dev Added (commit 1edc20b) — PRESERVE ALL OF THIS

The local commit was a large refactoring that applied DRY, SOLID, and encapsulation principles. It touched 238 files. Here are the 7 categories of changes — all must be preserved in the merge result:

### 1. CLI Layer: DRY LoadRegistry into PersistentPreRunE
- Extracted 26 identical `LoadRegistry` boilerplate blocks from 14 command files into a single `PersistentPreRunE` on the root command in `cmd/guard/main.go`
- Created NEW file `cmd/guard/commands/context.go` with `SetManager`/`GetManager` helpers to pass Manager via command context
- Created NEW file `cmd/guard/commands/context_test.go` with unit tests
- Handles completion subcommand by walking parent chain in PersistentPreRunE
- Added `SilenceUsage` to prevent usage dump on PersistentPreRunE errors
- Each command's `Run` function now receives Manager from context instead of creating its own

### 2. CLI Layer: Fix Encapsulation Violation
- Replaced `Manager.GetFileSystem().CheckFilesExist()` calls with a new `Manager.CheckFilesExist()` delegation method
- Deleted the `GetFileSystem()` accessor that leaked internal layer through public API
- This affects `cmd/guard/commands/disable.go` and `cmd/guard/commands/enable.go`

### 3. TUI: Deduplicate Code
- Extracted `padContentToFit` helper to `internal/tui/frame.go`, simplifying both panel `ContentLines` methods
- Removed duplicate `matchKeyBinding` from `collection_tree.go`, reusing `matchKey` from `file_tree.go`
- Deduplicated `matchAppKey` with existing `matchKey` helper
- Removed dead `View()` methods (~130 lines) and unused imports from both panel files

### 4. TUI: Surface Errors Instead of Silently Discarding
- Surface `LoadRegistry` error in TUI `refresh()` via `ErrorModal` instead of discarding it
- Surface errors from `node.Expand()` and `RefreshChildren()` in TUI
- Prevent panel refresh with stale data after `LoadRegistry` failure
- Propagate `tea.Cmd` from `FilesPanel.Refresh()` to surface filesystem errors during tree refresh

### 5. TUI: Scroll Behavior Fix
- Changed scrolling to only scroll when cursor reaches top or bottom edge of current pane
- Fixed collection display issues in the collections panel
- NOTE: Origin/dev ALSO fixed scrolling (see below). You need to reconcile both — origin/dev's approach may be more targeted. Keep the best of both.

### 6. TUI: Unit Tests
- NEW file `internal/tui/scroll_test.go` — table-driven tests for `CalculateScrollOffset`, `CalculateVisibleRange`, `ScrollState`
- NEW file `internal/tui/frame_test.go` — 11 table-driven tests for `padContentToFit`
- Tightened `SetViewportSize` test to assert exact offset values

### 7. Test Infrastructure: Harden and Remove Boilerplate
- Switched all TUI tests from `run_test` to `tui_run_test` for proper tmux cleanup
- Replaced hardcoded `"flo staff"` with dynamic `get_current_user`/`get_current_group`
- Extracted `find_guard_binary` helper to `helpers-cli.sh`, replacing 10-line boilerplate in ~199 tests
- Extracted `count_blank_content_lines_above_statusbar` to `helpers-tui.sh`
- Fixed silent failures: replaced `|| true` / `|| echo ""` with `tui_fail`
- Factored `_tui_create_session` shared helper for all `tui_start` variants
- Added cleanup trap and `SKIP_CLI_PREREQ` support to parallel test runner
- NEW test files: `tests/test-error-messages-005.sh`, `tests/test-prerun-001.sh`

### 8. Misc Cleanup
- Removed empty `docs/BUGS.md` and outdated `docs/FEATURES_REQUESTED.md` (678 lines)
- Fixed `.gitignore`: changed `guard` to `/guard` so it only ignores the binary at repo root, not `cmd/guard/`
- Added `SKIP_CLI_PREREQ` to justfile

## What ORIGIN dev Added — ALSO PRESERVE ALL OF THIS

### Fuzzy Search Feature (PR #9, commit 50b06dc)
This is a major new TUI feature. The full development history is in the `feature-fuzzy-search` branch (available locally and remotely). Key new files and changes:
- NEW `internal/tui/fuzzy.go` — fuzzy matching algorithm
- NEW `internal/tui/fuzzy_test.go` — 316 lines of fuzzy matching tests
- NEW `internal/tui/search_box.go` — search input component (120 lines)
- NEW `internal/tui/search_box_test.go` — search box unit tests
- NEW `internal/tui/app_search_test.go` — integration tests for search in app
- NEW `internal/tui/file_tree_filter_test.go` — filter tests
- NEW `internal/tui/messages.go` — new TUI message types
- Modified `internal/tui/app.go` — search integration, key handling
- Modified `internal/tui/file_tree.go` — filtering support
- Modified `internal/tui/frame.go` — search box rendering in frame
- Modified `internal/tui/keys.go` — new key bindings for search
- Modified `internal/tui/scroll.go` — scroll improvements
- Modified `internal/tui/scroll_test.go` — scroll tests
- Modified `internal/tui/status_bar.go` — search mode status
- 22 NEW test files: `tests/test-tui-search-001.sh` through `tests/test-tui-search-022.sh`
- 2 NEW test files: `tests/test-tui-scroll-edge-001.sh`, `tests/test-tui-scroll-edge-002.sh`
- NEW dependencies in `go.mod`/`go.sum`

### Bug Fixes (PRs #7 and #8)
- `c2a2eaa` — Fixed cursor sticking to bottom edge when scrolling up
- `7dd446f` — Fixed premature scroll in files pane by removing scroll margin
- `53e7c35` — Removed deprecated stateless scroll functions
- `99f9e42` — Fixed off-by-one indentation error

### Documentation & Config
- `fd25665` — Replaced pull requests section with AI-driven bug report workflow in README
- `f23779f` — Minor README wording/formatting fixes
- `aa57c34` — Added textual description requirement to TUI bug report option
- `6d937e3` — Added git rule to AGENTS.md: never use `git -C` for other worktrees

## Merge Strategy

### Step 0: Start the merge
```bash
cd /Users/flo/Developer/github/guard.git/dev
git fetch origin dev
git merge FETCH_HEAD
```
This will create conflict markers. Now resolve them one by one.

### Step 1: Files with NO conflicts
Files that were only changed on one side will auto-merge. These include:
- All NEW files from origin/dev (fuzzy.go, search_box.go, new tests, etc.)
- All NEW files from local (context.go, context_test.go, test-error-messages-005.sh, test-prerun-001.sh)
- README.md, TUTORIAL-3.md, AGENTS.md (only changed on origin/dev)
- docs/BUGS.md, docs/FEATURES_REQUESTED.md (only deleted on local)

### Step 2: Files that WILL conflict — resolve with these rules

For each conflicting file, follow these principles:

1. **`cmd/guard/main.go`**: Keep LOCAL's `PersistentPreRunE` and context setup. This is the centerpiece of the DRY refactor.

2. **`cmd/guard/commands/*.go`** (disable.go, enable.go, toggle.go, etc.): Keep LOCAL's version which uses `GetManager(cmd.Context())` instead of inline `manager.NewManager()` + `LoadRegistry()`. Origin/dev made small changes to these files too (e.g., `GetFileSystem().CheckFilesExist` -> `CheckFilesExist` in disable.go/enable.go) — LOCAL already has the correct encapsulated version.

3. **`internal/tui/app.go`**: This is the hardest file. BOTH sides made significant changes:
   - LOCAL: error surfacing, dedup, dead code removal
   - ORIGIN: fuzzy search integration, key handling for search
   - You MUST preserve both. Use `git diff c454a93..HEAD -- internal/tui/app.go` and `git diff c454a93..FETCH_HEAD -- internal/tui/app.go` to understand both sides fully.

4. **`internal/tui/file_tree.go`**: BOTH sides changed this:
   - LOCAL: dedup, error surfacing
   - ORIGIN: filtering support for fuzzy search
   - Preserve both. The filter/search logic from origin is additive.

5. **`internal/tui/frame.go`**: BOTH sides changed this:
   - LOCAL: added `padContentToFit` helper
   - ORIGIN: added search box rendering in frame
   - Preserve both — they're independent additions.

6. **`internal/tui/scroll.go` and `internal/tui/scroll_test.go`**: BOTH sides changed scrolling:
   - LOCAL: scroll behavior fixes, unit tests
   - ORIGIN: removed deprecated functions, fixed scroll edge behavior, added tests
   - Origin/dev's scroll changes are more recent and targeted. Prefer origin/dev's scroll.go but keep LOCAL's additional test cases if they test different things.

7. **`internal/tui/keys.go`**: Origin added search keybindings. Local may have changed key matching. Merge both.

8. **`internal/tui/collections_panel.go` and `internal/tui/files_panel.go`**: LOCAL removed dead View() methods and simplified ContentLines with padContentToFit. Keep LOCAL's cleanup. If origin/dev added anything new to these files, integrate it into LOCAL's cleaned-up version.

9. **`internal/manager/manager.go`**: BOTH sides made changes:
   - LOCAL: added `CheckFilesExist` delegation method, removed `GetFileSystem()`
   - ORIGIN: also made changes (check diff)
   - Keep LOCAL's encapsulation fix and merge origin's additions.

10. **`tests/helpers-cli.sh` and `tests/helpers-tui.sh`**: Keep LOCAL's infrastructure improvements (find_guard_binary, dynamic user/group, tui_run_test, etc.). If origin added any new helpers, merge them in.

11. **`tests/run-tui-tests-parallel.sh`**: Keep LOCAL's improvements (cleanup trap, SKIP_CLI_PREREQ). Merge any origin changes.

12. **`CHANGELOG.md`**: Combine entries from both sides.

13. **`go.mod` and `go.sum`**: Keep origin/dev's new dependencies (needed for fuzzy search). Ensure LOCAL's changes are also present.

14. **`.gitignore`**: Keep LOCAL's fix (`/guard` instead of `guard`).

15. **`justfile`**: Keep LOCAL's `SKIP_CLI_PREREQ` addition and merge any origin changes.

16. **Shell test files (tests/test-*.sh)**: For existing tests that both sides modified — LOCAL typically only changed the boilerplate (find_guard_binary extraction, tui_run_test switch, dynamic user/group). Origin may have changed test logic. Keep BOTH: LOCAL's boilerplate cleanup + origin's logic changes.

### Step 3: After resolving all conflicts
```bash
# Stage all resolved files
git add -A

# Build and test
just build
just test

# If tests pass, commit the merge
git commit -m "Merge origin/dev: integrate fuzzy search with DRY/encapsulation refactor"
```

### Step 4: If tests fail
- Read the test output carefully
- Fix any issues caused by the merge
- Re-run `just test` until everything passes
- Then commit

## SAFETY RULES — READ FIRST

- You may ONLY operate on the LOCAL `dev` branch in `/Users/flo/Developer/github/guard.git/dev`
- NEVER push to any remote branch
- NEVER modify, force-push, or reset any remote branch
- NEVER checkout or modify the `feature-fuzzy-search` branch or the `main` branch — they are READ-ONLY references for context
- NEVER use `git -C` to access other worktrees (project rule)
- Do NOT attribute AI in git commits (project rule)
- The remote branches and `feature-fuzzy-search` branch are ONLY for reading context (git log, git show, git diff). Do not write to them.

## Important Reminders

- Do NOT discard changes from either side. The goal is to have BOTH sets of improvements in the final result.
- When in doubt about a conflict, check both diffs against the common ancestor (`c454a93`).
- The fuzzy search feature is well-documented in the `feature-fuzzy-search` branch — use it as READ-ONLY context: `git log --oneline feature-fuzzy-search`
- You can also check closed PRs on GitHub for additional context: `gh pr list --state closed`
- Run `just test` (not just `go test`) to verify — it runs Go unit tests, CLI integration tests, and TUI integration tests.
- If you are unsure about any conflict resolution, err on the side of keeping MORE code rather than deleting. It is easier to clean up later than to lose functionality.

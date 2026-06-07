# To-Do

## Improve architecture layer-test failure messages

**Problem:** The layer tests in `internal/architecture/layers_test.go` emit a bare
message: `"X contains forbidden string Y"`. This tells an agent *that* a rule was
violated but not *why* it's forbidden or *how* to fix it.

**Goal:** Make the hard guardrail also teach the fix — model it on the Semgrep rule
`registry-load-restricted` in `.semgrep.yml`, whose message explains the rationale
and gives the correct alternative. Each layer rule's failure should explain why the
boundary exists and what to do instead.

---

## Investigate: README incorrectly describes the `[g]` indicator

**Problem:** The README states that lowercase `[g]` is the *gitignore* indicator. This appears to be wrong.

**Evidence:**
- `README.md:43` — "Items that are gitignored but still visible (because they are guard-tracked) appear in light blue with a lowercase `[g]` indicator..."
- `README.md:31-32` — ASCII mockup shows `[g] dep.go` under a gitignored `vendor/`, labeled "(light blue)".

**Why it looks wrong:**
- `internal/tui/types.go:21-39` — `[g]` is the glyph for `GuardStateImplicit` (a *guard* state), `[G]` = `GuardStateExplicit`, `[~]` = `GuardStateMixed`. The lowercase `g` is a guard-state indicator, not a gitignore marker.
- `internal/tui/file_tree.go:208-209` — the actual gitignore signal is the **light-blue color** (`GuardIgnored` style), applied when `node.IsIgnored && node.GuardState == GuardStateExplicit`. The color is the git signal; the `[g]` glyph is overloaded.

**To investigate / fix:**
1. Confirm the intended semantics of `[g]` (implicit guard) vs. the light-blue overlay for ignored+explicit files.
2. Decide whether reusing `[g]` for ignored-but-explicit files at `file_tree.go:209` is intentional or a glyph collision that should be disambiguated.
3. Correct `README.md` lines 31-32 and 43 to describe the indicator accurately (light-blue *color* = gitignored; `[g]` = guard state).

---

## Fix: gitignored folders not rendered light-blue in the TUI

**Failing tests (3):**
- `tests/test-tui-guardignore-009.sh` — "gitignored folder vendor/ should render in light blue"
- `tests/test-tui-guard-states-004.sh`
- `tests/test-tui-guard-states-005.sh`

Not new regressions and unrelated to the test-workspace move — CI previously died at
the `chmod` step and never reached them.

**Symptom:** a gitignored folder (e.g. `vendor/` with a force-added file inside) is
*visible* in the tree but renders in the default color instead of light blue
(`ColorIgnored`, ANSI `38;5;117`).

**Root cause is in the TUI rendering path, NOT ignore detection.** The manager
correctly reports the folder as ignored (`guard add vendor` → "vendor is ignored by
.gitignore or .guardignore"), and detection is identical regardless of where the
test runs. So `node.IsIgnored` is ending up `false` for the folder node by render
time (`internal/tui/file_tree.go:234`). Start the investigation at:
- `internal/manager/fs_view.go:35` — `ignored := m.IsIgnored(entry.Path)` and the
  `HasRegisteredDescendants` branch (note the relative-vs-absolute path comparison
  at lines 64-71).
- `internal/manager/ignore.go:40-51` — `ToRelativePath` may fail when the TUI runs
  from the short-symlink cwd (`helpers-tui.sh:164`, `/tmp/_gt$$`), making
  `IsIgnored` return `false`.

**Repro:** `just ci-quiet` (or run the three tests directly).

---

## Add Enter key for deep recursive folder toggle and fix recursive guard state display

**Two changes needed:**
1. Add `Enter` as a keybinding for deep recursive toggle in `keys.go`
   (`toggleGuardRecursive` via `toggleFolderGuard` with `recursive=true`).
2. Fix `updateNodeGuardState` in `file_node.go` to use `CollectFilesRecursive`
   instead of `CollectImmediateFiles`, so folder guard state reflects all
   descendants, not just immediate children.

`Space` keeps its current shallow behavior. No existing tests should break.

**Acceptance test** (already written and previously verified failing):
`tests/test-tui-guard-states-005.sh` — asserts `Enter` cycles a subdirectory-only
folder through `[ ] -> [G] -> [-]`, while `Space` (shallow) is a no-op on such folders.

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

# Requested Features

Track feature requests and enhancement ideas for Guard.

---

## Feature Template

```markdown
### [Feature Name]

**Status:** Proposed | In Discussion | Approved | In Progress | Completed | Rejected
**Priority:** Low | Medium | High | Critical
**Requested By:** [Name/Source]
**Date:** YYYY-MM-DD

**Description:**
Brief description of the feature.

**Use Case:**
Why is this feature needed? What problem does it solve?

**Proposed Implementation:**
High-level approach or considerations.

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Notes:**
Any additional context or discussion points.

---
```

## Active Requests

### File Input Piping

**Status:** Approved
**Priority:** High
**Requested By:** Flo
**Date:** 2026-02-01

**Description:**
Enable all file-accepting guard commands to read file paths from stdin, supporting Unix pipeline workflows.

**Use Case:**
Integrate guard with standard Unix tools like `find`, `git diff --name-only`, `cat`, etc. Enables bulk operations without manually listing files.

**Proposed Implementation:**
See [design document](plans/2026-02-01-file-input-piping-design.md)

**Acceptance Criteria:**
- [ ] R1: Parse whitespace-separated input (spaces, tabs, newlines)
- [ ] R2: Merge stdin input with CLI arguments
- [ ] R3: Support in add, remove, toggle, enable, disable, show, update commands
- [ ] R4: Error when no files from either stdin or CLI args
- [ ] R5: Silent operation (no extra output about stdin)
- [ ] Unit tests for stdin parsing
- [ ] Shell integration tests

**Notes:**
Design approved 2026-02-01.

---

### TUI Active Pane Indicator

**Status:** Proposed
**Priority:** Medium
**Requested By:** Flo
**Date:** 2026-02-01

**Description:**
Add visual highlighting to indicate which pane is currently active/focused in the TUI interactive mode. The active pane's title in the top border should be highlighted using the same styling as the selected row (blue background, white foreground).

**Use Case:**
When using the TUI with Tab to switch between the Files and Collections panes, there's no visual feedback showing which pane has focus. Users must try navigating or toggling to discover which pane is active. This is especially confusing after switching panes or when returning to the TUI after looking away.

**Current Behavior:**
```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║ [G] src/                               │ [G] core-files                     ║
║   [G] main.go                          │ [-] test-files                     ║
```
Both titles render identically regardless of focus.

**Proposed Behavior:**
```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
   ^^^^^ (highlighted when active)            ^^^^^^^^^^^ (highlighted when active)
```
The active pane's title should use `ItemSelected` style (blue background, white foreground) - the same styling applied to the currently selected row in each pane.

**Proposed Implementation:**
See [design document](plans/2026-02-01-tui-active-pane-indicator-design.md)

**Acceptance Criteria:**
- [ ] Active pane title is highlighted with blue background and white text
- [ ] Inactive pane title uses default styling (bold white text)
- [ ] Highlighting updates immediately when Tab is pressed
- [ ] No visual artifacts or alignment issues in the top border
- [ ] TUI tests pass

**Notes:**
Low complexity change. Existing `ItemSelected` style can be reused. Consider adding a dedicated `PanelTitleActive` style if different styling is desired in the future.

---

### Restore Folder Open/Closed State in Interactive Mode

**Status:** Proposed
**Priority:** Medium
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
When reopening Guard in interactive mode (`guard -i`), restore the previous folder expansion/collapse state so users can continue where they left off.

**Use Case:**
Users working on large projects lose their navigation context every time they relaunch interactive mode. Restoring folder state removes friction and allows picking up exactly where they left off.

**Current Behavior:**
All folders start collapsed (or in default state) every time interactive mode is launched.

**Proposed Implementation:**
Persist folder open/closed structure between sessions. State could be stored in a session file (see IDEA-004 in Ideas section). Should handle gracefully when folders have been added/removed since last session.

**Acceptance Criteria:**
- [ ] Folder expansion state is saved on TUI exit
- [ ] Folder expansion state is restored on next TUI launch
- [ ] Removed folders are handled gracefully (no crash, no stale entries)

---

### Auto-Expand Folders Containing Guarded Files on Startup

**Status:** Proposed
**Priority:** Medium
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
When launching Guard in interactive mode, folders that contain guarded files should be expanded by default so users can immediately see which files are protected.

**Use Case:**
On first launch (or without session state), users have to manually expand folders to find guarded files. Auto-expanding gives immediate visibility into what's protected.

**Current Behavior:**
Folders start in their default collapsed state regardless of content.

**Proposed Implementation:**
On startup, traverse the file tree and expand any folder containing one or more guarded files. If persisted session state exists (see "Restore Folder State" feature above), persisted state takes priority over auto-expand on subsequent launches.

**Acceptance Criteria:**
- [ ] Folders with guarded files are expanded on first launch
- [ ] Persisted session state takes priority on subsequent launches
- [ ] Deeply nested guarded files cause all ancestor folders to expand

---

### Shortcut to Collect Ungrouped Guarded Files

**Status:** Proposed
**Priority:** Medium
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
Provide a shortcut (keyboard or command) that gathers all guarded files not currently belonging to any collection and adds them to a single collection.

**Use Case:**
After individually guarding many files, users want to quickly organize them into a collection for bulk management without manually adding each one.

**Current Behavior:**
Users must manually add individual guarded files to collections one at a time.

**Proposed Implementation:**
- Could prompt the user for a collection name or use a default (e.g., `ungrouped`).
- In interactive mode, this could be a keyboard shortcut.
- In CLI mode, this could be a new command (e.g., `guard collect`).

**Acceptance Criteria:**
- [ ] All guarded files not in any collection are identified
- [ ] User can assign them to a named collection in one action
- [ ] Works in both CLI and TUI modes

---

### Fuzzy Search for Files in Interactive Mode

**Status:** Proposed
**Priority:** High
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
Add a search box to the TUI that allows fuzzy-finding files in the file tree, similar to `fzf`. The search box applies only to the files pane (not collections).

**Use Case:**
In large projects, manually navigating the file tree to find a specific file is slow. Fuzzy search lets users jump to any file instantly.

**Proposed Implementation:**
- **Location:** Bottom of the screen, directly above the info footer.
- **Activation:** `Ctrl+F` (or `Cmd+F` on Mac) moves focus to the search box. `Tab` cycles focus between files pane, collections pane, and search box.
- As the user types, the file tree is filtered in real time using fuzzy matching (fzf-style: substring, case-insensitive, ranked by match quality).
- Folders containing matching files stay visible; everything else is hidden.
- When focus returns to the files pane (via `Tab`), the search filter stays active. Navigation is restricted to matching items.
- `Escape` while the search box is focused clears the search and restores the full tree.
- When no files match: display **"No matches found. Please clear search."** in the files pane.
- Search query is persisted in `.guardsession` and restored on next launch.
- In a multi-column layout, each column could have its own independent search query.

**Acceptance Criteria:**
- [ ] Search box appears above info footer
- [ ] `Ctrl+F`/`Cmd+F` activates search box
- [ ] Real-time fuzzy filtering of file tree
- [ ] Filter persists when navigating back to files pane
- [ ] `Escape` clears search and restores full tree
- [ ] "No matches found" warning when no results
- [ ] Search query persisted in session file

---

### Toggle Info Bar Visibility

**Status:** Proposed
**Priority:** Low
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
Allow users to show or hide the info/navigation bar at the very bottom of the TUI.

**Use Case:**
Experienced users who know the keyboard shortcuts may prefer to reclaim the screen space used by the info bar.

**Proposed Implementation:**
- **Toggle:** `Ctrl+I` (or `Cmd+I` on Mac).
- **Default:** Visible (shown).
- Visibility state is saved in `.guardsession` and restored on next launch.

**Acceptance Criteria:**
- [ ] `Ctrl+I`/`Cmd+I` toggles info bar visibility
- [ ] Info bar is visible by default
- [ ] Visibility state persisted in session file
- [ ] TUI layout adjusts correctly when info bar is hidden/shown

---

### Context-Dependent Info Bar Content

**Status:** Proposed
**Priority:** Medium
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
The info bar at the bottom of the TUI should display different help text depending on which element currently has focus.

**Use Case:**
The current static info bar shows all shortcuts at once, which is cluttered. Context-sensitive content shows only relevant shortcuts, reducing cognitive load and guiding new users.

**Current Behavior:**
The info bar always shows the same static navigation key reference.

**Proposed Implementation:**

| Active focus     | Info bar content                                                  |
|------------------|-------------------------------------------------------------------|
| Files pane       | Navigation keys relevant to file browsing (arrows, space, etc.)   |
| Collections pane | Navigation keys relevant to collection browsing                   |
| Search box       | Hint text, e.g. "Type to search... Escape to clear"              |

The info bar updates dynamically whenever focus changes.

**Acceptance Criteria:**
- [ ] Info bar content changes when focus switches between panes
- [ ] Files pane shows file-specific shortcuts
- [ ] Collections pane shows collection-specific shortcuts
- [ ] Search box shows search-specific hints
- [ ] Content updates immediately on focus change

---

### Magic Git Collections

**Status:** Proposed
**Priority:** High
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
When Guard detects it is running inside a Git repository, automatically provide read-only "magic" collections prefixed with `@git_` that correspond to Git file states. These collections are dynamically computed from `git status` (not stored in `.guardfile`).

**Use Case:**
Developers frequently want to guard files based on their Git state — e.g., guard all staged files before committing, or guard all modified files to prevent further AI changes. Magic collections make this a one-click operation.

**Proposed Implementation:**
- **Detection:** On startup, check if the working directory is inside a Git repository. If not, `@git_` collections are not shown.
- **Magic collections:**

| Collection          | Contains                                                        |
|---------------------|-----------------------------------------------------------------|
| `@git_staged`       | Files added to the index (staged for the next commit)           |
| `@git_modified`     | Tracked files with unstaged modifications                       |
| `@git_untracked`    | Files not tracked by Git                                        |
| `@git_tracked`      | All files tracked by Git (clean + modified + staged)            |
| `@git_committed`    | Tracked files with no modifications (clean working tree state)  |
| `@git_deleted`      | Files that were tracked but have been removed from the worktree |
| `@git_conflicted`   | Files with unresolved merge conflicts                           |

- Magic collections appear in the collections pane alongside user-defined collections, visually distinguished (e.g., different color or `@` prefix).
- Contents are computed on demand and refreshed on TUI refresh or manual trigger.
- Users can enable/disable/toggle guard on files through these collections.
- Magic collections cannot be renamed, deleted, or have files manually added/removed.
- In CLI mode: `guard enable collection @git_staged`.
- Requires `git` on `PATH`.
- Should handle large repos gracefully (cache `git status`, refresh on interval or explicit action).
- Files can appear in multiple magic collections simultaneously.

**Acceptance Criteria:**
- [ ] Git repository detection on startup
- [ ] All seven `@git_` collections are available when inside a Git repo
- [ ] Collections are dynamically computed from `git status`
- [ ] Guard operations work on magic collection members
- [ ] Magic collections are read-only (no rename, delete, manual add/remove)
- [ ] CLI support: `guard enable collection @git_staged`
- [ ] Graceful handling when `git` is not available
- [ ] Collections refresh on `R` key

---

### Preserve Selection and Folder State on Refresh

**Status:** Proposed
**Priority:** High
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
When the user presses `R` to refresh the file tree in interactive mode, the current selection, scroll position, and folder expansion state must be preserved.

**Use Case:**
After toggling guard on several files, a refresh currently loses the user's place in the tree. The refresh should feel seamless.

**Proposed Implementation:**
1. **Selection is preserved:** After refresh, the same file or folder that was highlighted before remains highlighted.
2. **Folders stay open:** All expanded folders remain expanded. Folders are only collapsed if they were removed from the filesystem.
3. **Handling removed items:** If the selected item (or its parent folder) no longer exists, the selection moves **upward** to the nearest surviving item. If no item exists above, select the first item in the tree.

| Before refresh (selected)      | After refresh                          | New selection              |
|--------------------------------|----------------------------------------|----------------------------|
| `src/main.go` (exists)        | `src/main.go` still exists             | `src/main.go` (unchanged)  |
| `src/old.go` (removed)        | `src/old.go` no longer exists          | Next item above `src/old.go` |
| `src/deleted_dir/foo.go`      | `src/deleted_dir/` removed entirely    | Next item above `src/deleted_dir/` |
| `src/deleted_dir/` (folder)   | `src/deleted_dir/` removed             | Next item above it         |

Scroll position should also be preserved (or adjusted minimally) so the viewport doesn't jump.

**Acceptance Criteria:**
- [ ] Selection stays on same file/folder after refresh if it still exists
- [ ] Expanded folders remain expanded after refresh
- [ ] Removed item causes selection to move upward to nearest surviving item
- [ ] Removed parent folder causes selection to move upward
- [ ] Scroll position is preserved or minimally adjusted
- [ ] No crash when all items are removed

---

### Recently Modified Files View

**Status:** Proposed
**Priority:** Medium
**Requested By:** Community
**Date:** 2026-02-07

**Description:**
Add an alternative view mode for the files pane that shows files sorted by modification time (most recent first) instead of the directory tree.

**Use Case:**
When an AI agent modifies files, the user needs to quickly find and guard those files. A time-sorted view surfaces recently touched files immediately, regardless of where they are in the directory tree.

**Proposed Implementation:**
- **Activation:** `Shift+Tab` while the files pane is focused cycles between view modes. Fallback: `Ctrl+Tab` or `Cmd+Tab`. Regular `Tab` still cycles focus between panes.
- **View modes:** 1) Directory tree (default) → 2) Recently modified files.
- Files are listed strictly by modification time (most recent first), **not** grouped by folder.
- Folder headings appear inline as context, repeated whenever the folder changes in the sorted order:

```
docs/
  README.md                          1 min ago
reports/
  quarterly.csv                     10 min ago
docs/
  TUTORIAL-1.md                     30 min ago
src/internal/
  manager.go                         1 hour ago
src/internal/
  registry.go                        2 hours ago
docs/
  BUGS.md                            3 hours ago
```

- The same folder can appear multiple times (files sorted by time, not grouped by directory).
- Folder headings are display-only and not selectable — only files are selectable.
- Guard state indicators (`[G]`, `[-]`, etc.) shown per file, same as tree view.
- Guard toggling works in this view.
- View updates on refresh (`R`), re-sorting by current modification times.
- Active view mode persisted in `.guardsession`.
- Search (fuzzy search feature) should also work in this view.

**Acceptance Criteria:**
- [ ] `Shift+Tab` (or fallback) cycles between tree and recently modified view
- [ ] Files sorted by modification time, most recent first
- [ ] Folder headings shown inline, repeated as needed
- [ ] Folder headings not selectable
- [ ] Guard indicators and toggling work
- [ ] Refresh re-sorts by current modification times
- [ ] View mode persisted in session file
- [ ] Fuzzy search works in this view

---

---

## Ideas

### IDEA-001: Horizontal Split Layout (files on top, collections on bottom)

**Status:** Idea
**Date:** 2026-02-07

Change the TUI layout from a vertical split (files left, collections right) to a horizontal split where the files panel is on top and the collections panel is on the bottom. A horizontal layout better matches how developers typically scan file trees (top to bottom) and gives each panel the full terminal width, which helps with long file paths.

---

### IDEA-002: Resizable Pane Divider

**Status:** Idea
**Date:** 2026-02-07

Allow users to reposition the horizontal divider between the files and collections panes to give more space to whichever panel they're focused on.

**Option A — Mouse:** Click and drag the divider line to resize.
**Option B — Keyboard:** `+` increases the size of the currently active pane, `-` decreases it.

Both options could coexist. The divider position should be persisted as part of the session (see IDEA-004).

---

### IDEA-003: Multi-Column Layout

**Status:** Idea
**Date:** 2026-02-07

Once the layout is horizontal (IDEA-001), support multiple side-by-side columns. Each column contains its own independent files panel (top) and collections panel (bottom). This allows users with wide monitors and large projects to browse different parts of their project simultaneously.

**Example layout (3 columns):**
```
┌─────────────────┬─────────────────┬─────────────────┐
│   Files (col 1) │   Files (col 2) │   Files (col 3) │
│                 │                 │                 │
├─────────────────┼─────────────────┼─────────────────┤
│ Collect. (col 1)│ Collect. (col 2)│ Collect. (col 3)│
│                 │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

Each column has its own independent scroll position, folder expansion state, active selection, and keyboard shortcut to switch focus between columns.

---

### IDEA-004: Session File (`.guardsession`)

**Status:** Idea
**Date:** 2026-02-07

Introduce a `.guardsession` file (separate from `.guardfile`) that persists all TUI state and layout information. Only relevant to interactive mode; does not affect CLI behavior.

**Stored state includes:**
- Folder open/closed state per column
- Number of columns and their widths
- Divider positions per column
- Active pane and cursor position per column
- Scroll positions
- Active search query per column
- Info bar visibility
- Active files view mode per column (tree or recently modified)

**Behavior:**
- Created automatically on first interactive mode launch.
- Updated on exit (or periodically).
- Falls back to defaults if missing or corrupt.
- Safe to delete — user just loses layout preferences.
- Consider adding `.guardsession` to `.gitignore` by default (user-specific state).

**Relationship to other items:**
- "Restore Folder State" feature becomes a subset of this.
- Search query, info bar visibility, view mode, divider positions, and multi-column layout are all persisted here.

---

---

## Completed Features

<!-- Move completed features here -->

---

## Rejected/Deferred

<!-- Document rejected or deferred features with reasoning -->

---

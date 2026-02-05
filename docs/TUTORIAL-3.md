<span>![Made by AI](https://img.shields.io/badge/Made%20with-AI-333333?labelColor=f00) ![Verified by Humans](https://img.shields.io/badge/Verified%20by-Humans-333333?labelColor=brightgreen)</span>


# Tutorial 3: Speed up your Workflow with Interactive Mode

__Navigation__

- [README](../README.md) - Overview
- [Tutorial 1](TUTORIAL-1.md) - Protecting individual files
- [Tutorial 2](TUTORIAL-2.md) - Protecting collection of files
- [Tutorial 3](TUTORIAL-3.md) - Speed up your Workflow with Interactive Mode

This tutorial builds on [Tutorial 1](TUTORIAL-1.md) and [Tutorial 2](TUTORIAL-2.md) and teaches you how to work with the TUI (Text User Interface) to quickly toggle the guard state of files and collections without typing commands.

## What You'll Learn

- Launching the TUI and understanding the dual-pane layout
- Navigating files and folders with arrow keys
- Expanding and collapsing folders
- Switching between the Files Panel and Collections Panel
- Toggling guard state on files and collections with a single keypress
- Refreshing the view when files change externally
- Understanding guard state indicators

## Prerequisites

Complete [Tutorial 1](TUTORIAL-1.md) first to understand basic Guard operations.

Complete [Tutorial 2](TUTORIAL-2.md) first to understand Guard collections operations.

---

## Step 1: Set Up the Scenario

Let's create a scenario similar to Tutorial 2 with two collections that share a file. Run these commands:

```bash
$ mkdir tui-demo && cd tui-demo
$ guard init 0600 root wheel
```

```
Initialized guard with mode=0600, owner=root, group=wheel
```

```bash
$ touch alice1.txt alice2.txt shared.txt bob1.txt
$ mkdir docs
$ touch docs/notes.txt
```

Now create the collections:

```bash
$ guard create alice
$ guard update alice add alice1.txt alice2.txt shared.txt
```

```
Created collection alice
Registered 3 file(s)
Added 3 file(s) to collection alice
```

```bash
$ guard create bob
$ guard update bob add bob1.txt shared.txt
```

```
Created collection bob
Registered 1 file(s)
Added 2 file(s) to collection bob
```

Enable guard on the alice collection:

```bash
$ sudo guard enable collection alice
```

```
Guard enabled for collection alice
Guard enabled for alice1.txt
Guard enabled for alice2.txt
Guard enabled for shared.txt
```

Verify the setup:

```bash
$ guard show collection
```

```
[G] collection: alice (3 files)
[-] collection: bob (2 files)
```

---

## Step 2: Launch the TUI

Start the TUI with sudo (required for permission changes):

```bash
$ sudo guard -i
```

You'll see a dual-pane interface:

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▶ docs                                 │ [G] alice                          ║
║   [G] alice1.txt                       │ [-] bob                            ║
║   [G] alice2.txt                       │                                    ║
║   [-] bob1.txt                         │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
║ ↑↓: Navigate  ←→: Collapse/Expand  Tab: Switch Panel  Space: Toggle Guard   ║
║ R: Refresh  Q/Esc: Quit                                                     ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

**Key observations**:
- **Files Panel** (left): Shows the directory tree with guard status indicators
- **Collections Panel** (right): Shows all collections with their guard state
- **Status Bar** (bottom): Shows available keyboard shortcuts
- The Files Panel is active (highlighted title)
- Folders appear first (▶ indicates collapsed), then files alphabetically

---

## Step 3: Navigate the Files Panel

Use the arrow keys to navigate:

| Key | Action |
|-----|--------|
| `↑` | Move selection up |
| `↓` | Move selection down |
| `→` | Expand folder (or select first child if already expanded) |
| `←` | Collapse folder (or go to parent) |

Try it:

1. Press `↓` several times to move through the file list
2. Press `↑` to move back up
3. Navigate to the `docs` folder and press `→` to expand it

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▼ docs                                 │ [G] alice                          ║
║ │ └─ [ ] notes.txt                     │ [-] bob                            ║
║   [G] alice1.txt                       │                                    ║
║   [G] alice2.txt                       │                                    ║
║   [-] bob1.txt                         │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
```

The `▼` indicates the folder is now expanded. Press `←` to collapse it again.

---

## Step 4: Toggle Guard on a File

Navigate to `bob1.txt` (which shows `[-]` - registered but not guarded) and press `Space`:

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▶ docs                                 │ [G] alice                          ║
║   [G] alice1.txt                       │ [~] bob                            ║
║   [G] alice2.txt                       │                                    ║
║   [G] bob1.txt                         │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
```

**What happened**:
- `bob1.txt` changed from `[-]` to `[G]` (now guarded)
- The `bob` collection changed from `[-]` to `[~]` (mixed state)

The `[~]` indicates that the bob collection has files with different guard states: `bob1.txt` is guarded but the collection's guard flag is still `false`.

Press `Space` again to toggle `bob1.txt` back to unguarded.

---

## Step 5: Switch to the Collections Panel

Press `Tab` to switch focus to the Collections Panel:

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▶ docs                                 │ [G] alice                          ║
║   [G] alice1.txt                       │ [-] bob                            ║
║   [G] alice2.txt                       │                                    ║
║   [-] bob1.txt                         │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
║ ↑↓: Navigate  Tab: Switch Panel  Space: Toggle Guard  R: Refresh  Q: Quit   ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

**Notice**:
- The Collections Panel title is now highlighted (active)
- The status bar no longer shows `←→: Collapse/Expand` (only applies to Files Panel)
- Use `↑↓` to navigate between collections

---

## Step 6: Toggle a Collection

Navigate to `bob` and press `Space`:

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▶ docs                                 │ [G] alice                          ║
║   [G] alice1.txt                       │ [G] bob                            ║
║   [G] alice2.txt                       │                                    ║
║   [G] bob1.txt                         │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
```

**What happened**:
- The `bob` collection changed from `[-]` to `[G]`
- Both `bob1.txt` and `shared.txt` are now guarded
- All files in the Files Panel now show `[G]`

When you toggle a collection, all files in that collection are affected.

---

## Step 7: Handle External File Changes

One powerful feature of the TUI is the ability to refresh when files change outside the TUI.

1. Press `Q` to exit the TUI
2. Create a new file:

```bash
$ touch newfile.txt
$ ls
```

```
alice1.txt  alice2.txt  bob1.txt  docs  newfile.txt  shared.txt
```

3. Relaunch the TUI:

```bash
$ sudo guard -i
```

**Notice**: `newfile.txt` is NOT visible in the Files Panel yet! The TUI shows the state from when it last loaded.

4. Press `R` to refresh:

```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║                                        │                                    ║
║ ▶ docs                                 │ [G] alice                          ║
║   [G] alice1.txt                       │ [G] bob                            ║
║   [G] alice2.txt                       │                                    ║
║   [G] bob1.txt                         │                                    ║
║   [ ] newfile.txt                      │                                    ║
║   [G] shared.txt                       │                                    ║
║                                        │                                    ║
╠════════════════════════════════════════╧════════════════════════════════════╣
```

**The new file appears!** It shows `[ ]` because it's not registered in Guard yet.

**Refresh behavior**:
- The `.guardfile` is re-read from disk
- The file tree is rescanned
- Both panels are updated with current state
- Your current selection is preserved if the item still exists

---

## Understanding Guard State Indicators

### File Indicators

| Indicator | Meaning |
|-----------|---------|
| `[ ]` | Not registered in the `.guardfile` |
| `[-]` | Registered but not guarded (guard flag is `false`) |
| `[G]` | Explicitly guarded (guard flag is `true`) |

### Folder Indicators

| Indicator | Meaning |
|-----------|---------|
| `[ ]` | No collection exists for this folder |
| `[-]` | Collection exists, all files unguarded |
| `[G]` | Collection exists, all files guarded |
| `[~]` | Mixed state (some files guarded, some not) |

### Collection Indicators

| Indicator | Meaning |
|-----------|---------|
| `[G]` | Collection is guarded, all files guarded |
| `[g]` | Collection flag is `false`, but all files are guarded (via another collection) |
| `[-]` | Collection is not guarded |
| `[~]` | Mixed state (some files guarded, some not) |

### Effective vs Stored State

- **Files** show their **direct** guard flag from the `.guardfile`
- **Folders and Collections** show their **effective** state computed from contained files
- A folder shows `[~]` when some files are guarded and others are not

---

## Step 8: Cleanup

Exit the TUI with `Q` and clean up:

```bash
$ guard uninstall
```

```
All guards disabled
Cleanup completed
.guardfile deleted
```

```bash
$ cd ..
$ rm -rf tui-demo
```

---

## Keyboard Shortcuts Reference

| Key | Files Panel | Collections Panel |
|-----|-------------|-------------------|
| `↑` / `↓` | Navigate files/folders | Navigate collections |
| `←` / `→` | Collapse/Expand folders | N/A |
| `Tab` | Switch to Collections Panel | Switch to Files Panel |
| `Space` | Toggle guard on file/folder | Toggle guard on collection |
| `Shift+Space` | Toggle guard recursively (folders) | N/A |
| `R` | Refresh from disk | Refresh from disk |
| `Q` / `Esc` | Quit | Quit |

---

## Next Steps

Star the [GitHub repository](https://github.com/florianbuetow/guard) to follow updates - many more features are planned!

---

## Key Takeaways

1. 🖥️ **Visual navigation** makes it easy to see your project structure and guard states at a glance
2. ⌨️ **Single keypress** toggles guard state without typing commands
3. 🔄 **Tab switching** lets you quickly move between files and collections
4. 🔃 **Refresh with R** keeps the TUI in sync when files change externally
5. 📊 **Guard indicators** show you exactly what's protected and what's not

The TUI provides a faster, more intuitive workflow for managing file protection, especially when working with AI agents that may try to modify multiple files.

---

[README](../README.md) | [Tutorial 1](TUTORIAL-1.md) | [Tutorial 2](TUTORIAL-2.md) | [Tutorial 3](TUTORIAL-3.md)


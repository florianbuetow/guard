<span>![Made by AI](https://img.shields.io/badge/Made%20with-AI-333333?labelColor=f00) ![Verified by Humans](https://img.shields.io/badge/Verified%20by-Humans-333333?labelColor=brightgreen)</span>


# Tutorial 2: How to Protect a Collection of Files

__Navigation__

- [README](../README.md) - Overview
- [Tutorial 1](TUTORIAL-1.md) - Protecting individual files
- [Tutorial 2](TUTORIAL-2.md) - Protecting collection of files
- [Tutorial 3](TUTORIAL-3.md) - Speed up your Workflow with Interactive Mode

This tutorial builds on [Tutorial 1](TUTORIAL-1.md) and teaches you how to work with **collections** - named groups of files that can be managed together. You'll learn how files can belong to multiple collections and how Guard handles files with different states across collections.

## What You'll Learn

- Creating and managing collections
- Adding files to collections
- Enabling/disabling guard on entire collections
- Understanding how files can belong to multiple collections
- Handling conflicts when collections share files
- Inspecting collection membership and states

## Prerequisites

Complete [Tutorial 1](TUTORIAL-1.md) first to understand basic Guard operations.

---

## Step 1: Initialize Guard

Let's start fresh with Guard configured to use mode `0600` (read/write for owner only), which provides maximum file protection.

```bash
$ guard init 0600 root wheel
```

```
Initialized guard with mode=0600, owner=root, group=wheel
```

---

## Step 2: Create Test Files

Create four test files that we'll organize into collections:

```bash
$ touch alice1.txt alice2.txt shared.txt bob1.txt
$ ls -alh *.txt
```

```
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 alice1.txt
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 alice2.txt
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 bob1.txt
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 shared.txt
```

**Note**: All files currently have standard permissions (`0644`) and are owned by the current user.

---

## Step 3: Create the "alice" Collection

Collections are named groups for organizing files. Let's create our first collection:

```bash
$ guard create alice
```

```
Created collection alice
```

Let's inspect the .guardfile to see the new collection:

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files: []
collections:
    - name: alice
      files: []
      guard: false
```

At this point, the collection exists but is empty. Let's verify:

```bash
$ guard show collection alice
```

```
[-] collection: alice (0 files)
```

---

## Step 4: Add Files to the "alice" Collection

Now let's add three files to the alice collection:

```bash
$ guard update alice add alice1.txt alice2.txt shared.txt
```

```
Registered 3 file(s)
Added 3 file(s) to collection alice
```

---

## Step 5: Inspect the .guardfile

Let's see how Guard tracks our collection:

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./shared.txt
      guard: false
```

**Key observations**:
- The `collections` section now exists with our "alice" collection
- All three files are listed under `alice` collection
- The collection's `guard: false` means it's currently disabled
- All files have `guard: false` (not protected yet)
- Files keep their original permissions (`mode`, `owner`, `group`)

---

## Step 6: View Collection Status

Use the `show collection` command to see the collection status:

```bash
$ guard show collection alice
```

```
[-] collection: alice (3 files)
  [-] alice1.txt
  [-] alice2.txt
  [-] shared.txt
```

**Note**: The `[-]` prefix indicates an unguarded file or collection (guard disabled). The guard state is enclosed in square brackets.

---

## Step 7: Enable Guard on the "alice" Collection

When you enable a collection, Guard applies protection to ALL files in that collection:

```bash
$ sudo guard enable collection alice
```

```
Guard enabled for collection alice
Guard enabled for alice1.txt
Guard enabled for alice2.txt
Guard enabled for shared.txt
```

**Note**: We use `sudo` because changing file ownership requires root privileges.

---

## Step 8: Inspect the .guardfile After Enabling

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./shared.txt
      guard: true
```

**Key observations**:
- Collection `alice` now has `guard: true`
- All three member files now have `guard: true`
- **Enabling the guard on a collection enables the guard on all of its files**

---

## Step 9: Verify File Permissions Changed

Let's verify that the actual file permissions on disk match our guard configuration:

```bash
$ ls -alh alice1.txt alice2.txt shared.txt
```

```
-rw-------  1 root  wheel     0B Jan 10 14:30 alice1.txt
-rw-------  1 root  wheel     0B Jan 10 14:30 alice2.txt
-rw-------  1 root  wheel     0B Jan 10 14:30 shared.txt
```

**Perfect!** All files now have:
- Mode `0600` (read/write for owner only)
- Owner `root`
- Group `wheel`

---

## Step 10: Create the "bob" Collection

Now let's create a second collection to demonstrate how files can belong to multiple collections:

```bash
$ guard create bob
```

```
Created collection bob
```

Let's view all collections to see the current state:

```bash
$ guard show collection
```

```
[G] collection: alice (3 files)
[-] collection: bob (0 files)
```

---

## Step 11: Add Files to the "bob" Collection

We'll add `bob1.txt` and `shared.txt` to the bob collection. Notice that `shared.txt` is already in the alice collection!

```bash
$ guard update bob add bob1.txt shared.txt
```

```
Registered 1 file(s)
Added 2 file(s) to collection bob
```

**Important**: `shared.txt` is now in BOTH alice and bob collections.

---

## Step 12: Inspect the .guardfile - Shared File

Let's see how Guard tracks a file that belongs to multiple collections:

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./bob1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./shared.txt
      guard: true
    - name: bob
      files:
          - ./bob1.txt
          - ./shared.txt
      guard: false
```

**Key observations**:
- `shared.txt` appears in BOTH alice and bob collections
- `shared.txt` has `guard: true` (from when we enabled alice)
- `bob1.txt` has `guard: false` (not protected yet)
- Collection bob has `guard: false` (newly created, disabled by default)

---

## Step 13: View All Collections

```bash
$ guard show collection
```

```
[G] collection: alice (3 files)
[-] collection: bob (2 files)
```

**Legend**:
- `[G]` = Guard enabled
- `[-]` = Guard disabled

---

## Step 14: Enable the "bob" Collection

Let's enable guard on the bob collection:

```bash
$ sudo guard enable collection bob
```

```
Guard enabled for collection bob
Guard enabled for bob1.txt
Guard enabled for shared.txt
```

---

## Step 15: Inspect the .guardfile - Both Collections Enabled

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./bob1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./shared.txt
      guard: true
    - name: bob
      files:
          - ./bob1.txt
          - ./shared.txt
      guard: true
```

**Current state**: Both collections are enabled, and all files are protected.

---

## Step 16: Disable the "alice" Collection

Now let's disable alice while keeping bob enabled. This demonstrates that **file guard state is independent** from collection membership:

```bash
$ sudo guard disable collection alice
```

```
Guard disabled for collection alice
Guard disabled for alice1.txt
Guard disabled for alice2.txt
Guard disabled for shared.txt
```

---

## Step 17: Inspect the .guardfile - Different Collection States

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./bob1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./shared.txt
      guard: false
    - name: bob
      files:
          - ./bob1.txt
          - ./shared.txt
      guard: true
```

**Critical observation**:
- Collection alice: `guard: false`
- Collection bob: `guard: true`
- File `shared.txt`: `guard: false` ← **Last operation wins!**
- Even though bob is still enabled, `shared.txt` was disabled by the alice operation

**Key concept**: When a file belongs to multiple collections, the **most recent operation** determines the file's guard state. File state is independent of collection membership.

---

## Step 18: Verify the File States

```bash
$ ls -alh alice1.txt alice2.txt bob1.txt shared.txt
```

```
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 alice1.txt
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 alice2.txt
-rw-------  1 root wheel     0B Jan 10 14:30 bob1.txt
-rw-r--r--  1 flo  staff     0B Jan 10 14:30 shared.txt
```

Notice:
- `alice1.txt`: Restored to original permissions (alice disabled)
- `alice2.txt`: Restored to original permissions (alice disabled)
- `bob1.txt`: Protected with 0600 and owned by root (bob enabled)
- `shared.txt`: Restored to original permissions (last disable operation from alice)

---

## Step 19: Attempt to Toggle Both Collections (Conflict!)

Current state:
- alice collection: `guard: false`
- bob collection: `guard: true`
- Both collections share `shared.txt`

What happens if we try to toggle both at once?

```bash
$ sudo guard toggle collection alice bob
```

```
Error: cannot toggle collections that share files with different guard states
Conflicting files: ./shared.txt
Collections alice (guard: false) and bob (guard: true) both contain ./shared.txt
```

**Guard detected a conflict!**

When you toggle multiple collections that:
1. Share one or more files
2. Have different guard states

Guard cannot determine the intended state for the shared files, so it **prevents the operation** and reports the conflict.

---

## Step 20: Understanding the Conflict

This conflict detection is a **safety feature**. Consider what would happen without it:

- Toggle alice (false → true): `shared.txt` should become guarded
- Toggle bob (true → false): `shared.txt` should become unguarded

**What should Guard do?** It's ambiguous!

Rather than guess, Guard:
1. Detects the conflict
2. Reports which files are conflicting
3. Prevents any changes
4. Requires you to be explicit

**Solution**: Toggle collections separately, remove the shared file from one collection, or manually set the file state first.

---

## Step 21: Resolving the Conflict

To resolve this conflict, we need to remove `shared.txt` from one of the collections. Let's remove it from the alice collection:

```bash
$ guard update alice remove shared.txt
```

```
Removed 1 file(s) from collection alice
```

Now let's retry the toggle operation:

```bash
$ sudo guard toggle collection alice bob
```

```
Guard enabled for collection alice
Guard enabled for alice1.txt
Guard enabled for alice2.txt
Guard disabled for collection bob
Guard disabled for bob1.txt
Guard disabled for shared.txt
```

**Success!** The operation completed because:
- Alice and bob no longer share any files
- There's no ambiguity about what should happen to each file
- Each file belongs to only one collection being toggled

---

## Step 22: View File Membership

Use `guard show file` to see which collections a file belongs to:

```bash
$ guard show file shared.txt
```

```
[-] file: ./shared.txt
  guard: false
  collections: bob
```

This clearly shows that `shared.txt` now only belongs to the bob collection (since we removed it from alice) and currently has guard disabled.

---

## Step 23: View Collection Overview

Get a quick overview of all collections:

```bash
$ guard show collection
```

```
[G] collection: alice (2 files)
[-] collection: bob (2 files)
```

And to see details of specific collections:

```bash
$ guard show collection alice
```

```
[G] collection: alice (2 files)
  [G] alice1.txt
  [G] alice2.txt
```

```bash
$ guard show collection bob
```

```
[-] collection: bob (2 files)
  [-] bob1.txt
  [-] shared.txt
```

**Note**: After the toggle operation in Step 21:
- Collection alice was toggled from disabled to enabled (now `[G]`)
- Collection bob was toggled from enabled to disabled (now `[-]`)
- The alice collection now only contains 2 files (alice1.txt and alice2.txt) since we removed shared.txt

---

## Step 24: Creating a Combined Collection

Now let's demonstrate how to create a new collection containing files from existing collections. This is useful for organizing your files in different ways.

First, let's create the "eve" collection:

```bash
$ guard create eve
```

```
Created collection eve
```

Now let's add all the files from both alice and bob to eve. We can do this by adding the files manually:

```bash
$ guard update eve add alice1.txt alice2.txt bob1.txt shared.txt
```

```
Added 4 file(s) to collection eve
```

Let's view the eve collection:

```bash
$ guard show collection eve
```

```
[-] collection: eve (4 files)
  [G] alice1.txt
  [G] alice2.txt
  [-] bob1.txt
  [-] shared.txt
```

**Key observations**:
- Collection eve is `[-]` (guard disabled) because it was just created
- Eve contains all 4 files from both alice and bob
- Each file maintains its individual guard state (alice files are [G], bob files are [-])
- The files are referenced - they're not duplicated in storage

Let's inspect the .guardfile to see the full picture:

```bash
$ cat .guardfile
```

```yaml
config:
    guard_mode: "0600"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./alice1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./alice2.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
    - path: ./bob1.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
    - path: ./shared.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
collections:
    - name: alice
      files:
          - ./alice1.txt
          - ./alice2.txt
      guard: true
    - name: bob
      files:
          - ./bob1.txt
          - ./shared.txt
      guard: false
    - name: eve
      files:
          - ./alice1.txt
          - ./alice2.txt
          - ./bob1.txt
          - ./shared.txt
      guard: false
```

**Note**: Files can belong to multiple collections. If you later add files to alice or bob, they won't automatically appear in eve - you would need to add them separately.

---

## Step 25: Cleanup

Let's clean up our tutorial environment:

```bash
$ guard uninstall
```

```
All guards disabled
Cleanup completed
.guardfile deleted
```

```bash
$ rm alice1.txt alice2.txt bob1.txt shared.txt
```

---

## Summary: What You Learned

### Collections
- **Collections are named groups** that help organize related files
- You create collections with `guard create <name>`
- You add files to collections with `guard update <collection> add <files...>`
- You remove files from collections with `guard update <collection> remove <files...>`
- Collections start with `guard: false` by default

### Collection Operations
- `guard create <name>` - Creates a new collection
- `guard destroy <name>` - Removes a collection (disables guard on files first)
- `guard update <collection> add <files...>` - Adds files to a collection
- `guard update <collection> remove <files...>` - Removes files from a collection
- `guard enable collection <name>` - Enables guard on the collection AND all member files
- `guard disable collection <name>` - Disables guard on the collection AND all member files
- `guard toggle collection <name>` - Toggles the collection and files (with conflict detection)
- `guard show collection <name>` - Displays collection status and membership

### Multiple Collection Membership
- **Files can belong to multiple collections**
- Each file appears only once in the `files:` section
- Each collection lists its member files in the `files:` array
- File guard state is **independent** of collection membership

### Last Operation Wins
- When a file belongs to multiple collections with different guard states
- The **most recent operation** determines the file's actual guard state
- This is independent of which collections the file belongs to

### Conflict Detection and Resolution
- Guard detects conflicts when you toggle multiple collections that:
  - Share one or more files
  - Have different guard states
- Guard prevents the ambiguous operation and reports the conflict
- **Solutions**:
  - Remove shared files from one of the collections
  - Operate on collections separately
  - Manually set file states before toggling

### The .guardfile Structure
```yaml
config:
    guard_mode: "0644"
    guard_owner: flo
    guard_group: wheel
files:
    - path: <file-path-1>
      mode: "<original-mode>"
      owner: <original-owner>
      group: <original-group>
      guard: <true|false>
    - path: <original-file-path-2>
      ...
collections:
    - name: <collection-name-1>
      files:
          - <file-path-1>
          - <file-path-2>
      guard: <true|false>
    - name: <collection-name-2>
      ...
```

---

## Next Steps

- **Tutorial 3**: Speed up your Workflow with Interactive Mode
- Explore the full command reference with `guard help`

---

## Key Takeaways

1. 📁 **Collections organize files** into logical groups
2. 🔄 **Files can belong to multiple collections** simultaneously
3. ⚡ **Collection operations cascade** to all member files
4. 🎯 **Last operation wins** for file guard state
5. 🛡️ **Conflict detection protects** against ambiguous operations
6. 👀 **Use show commands** to understand relationships and states

Collections make it easy to manage groups of related files, but understanding how file states work independently from collection membership is crucial for effective use of Guard.

---

[README](../README.md) | [Tutorial 1](TUTORIAL-1.md) | [Tutorial 2](TUTORIAL-2.md) | [Tutorial 3](TUTORIAL-3.md)


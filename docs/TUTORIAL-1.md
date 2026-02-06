<span>![Made by AI](https://img.shields.io/badge/Made%20with-AI-333333?labelColor=f00) ![Verified by Humans](https://img.shields.io/badge/Verified%20by-Humans-333333?labelColor=brightgreen)</span>


## Tutorial 1: How to Protect a Single File

__Navigation__

- [README](../README.md) - Overview
- [Tutorial 1](TUTORIAL-1.md) - Protecting individual files
- [Tutorial 2](TUTORIAL-2.md) - Protecting collection of files
- [Tutorial 3](TUTORIAL-3.md) - Speed up your Workflow with Interactive Mode

This is an onboarding tutorial that will help you understand the `.guardfile` and the basic mechanics of the tool. Later you will learn how you can work with `guard` much more effectively.

1. Initialize `guard` with default parameters for guarded files.

```bash
$ guard init 0644 root wheel
```

2. And register a single file.
```bash
$ touch test.txt
$ ls -alh test.txt
```

```bash
-rw-r--r--  1 flo  staff     0B Jan  7 20:11 test.txt
```

```bash
$ guard add file test.txt
```

```bash
Registered 1 file(s)
```

3. Inspect the created `.guardfile` to see the added file.
```bash
$ cat .guardfile
```

 We can also see the permission settings for guarded files and for the unguarded file.
```bash
config:
    guard_mode: "0644"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./test.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
collections: []
```
4. Let's try to guard the file.
```bash
$ guard toggle file test.txt
```
It fails because we (like the AI) don't have the privileges required to change the file ownership and permissions.
```bash
Error: failed to toggle test.txt: failed to change owner to root for ./test.txt: failed to set owner root for file ./test.txt: chown ./test.txt: operation not permitted
```
5. Let's try to do it with sudo.
```bash
$ sudo guard toggle file test.txt
```

```bash
Guard enabled for test.txt
```

```bash
$ ls -alh test.txt
```
Comparing the new `user`, `group` and `rwx` permissions, we can see that the ones specified in the `.guardfile` have been applied to the test file.
```bash
-rw-r--r--  1 root  wheel     0B Jan  7 20:11 test.txt
```

```bash
$ cat .guardfile
```
And the guardfile reflects the guarded state of the file.
```bash
config:
    guard_mode: "0644"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./test.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: true
collections: []
```

6. Let's toggle the guard (to off) and verify.
```bash
$ sudo guard toggle file test.txt
```

```bash
Guard disabled for test.txt
```

```bash
$ ls -alh test.txt
```
The file ownership and permissions have been restored from `.guardfile`
```bash
-rw-r--r--  1 flo  staff     0B Jan  7 20:11 test.txt
```

```bash
$ cat .guardfile
```
And the `.guardfile` reflects this change as well.
```bash
config:
    guard_mode: "0644"
    guard_owner: root
    guard_group: wheel
files:
    - path: ./test.txt
      mode: "0644"
      owner: flo
      group: staff
      guard: false
collections: []
```

---

[README](../README.md) | [Tutorial 1](TUTORIAL-1.md) | [Tutorial 2](TUTORIAL-2.md) | [Tutorial 3](TUTORIAL-3.md)

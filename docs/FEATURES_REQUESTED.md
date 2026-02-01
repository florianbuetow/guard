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

---

## Completed Features

<!-- Move completed features here -->

---

## Rejected/Deferred

<!-- Document rejected or deferred features with reasoning -->

---

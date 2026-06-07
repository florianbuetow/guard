# Guard — Architecture Notes

Layered dependency diagram. Arrows = "depends on / calls". The layers are
strict: each only talks to the one(s) below it.

```
        ┌─────────────────────────┐   ┌─────────────────────────┐
        │   cmd/guard/commands     │   │     internal/tui         │
        │   CLI layer (Cobra)      │   │   TUI layer (Bubble Tea) │
        │   parse args, print      │   │   terminal UI            │
        └────────────┬─────────────┘   └────────────┬────────────┘
                     │                               │
                     └───────────────┬───────────────┘
                                     │  (UI layers are pure clients)
                                     ▼
                      ┌──────────────────────────────┐
                      │      internal/manager         │
                      │  orchestration, sequencing,   │      ┌────────────────────┐
                      │  persistence — never prints   │─────▶│ internal/guardignore│
                      └───────┬───────────────┬───────┘      │  .gitignore /       │
                              │               │              │  .guardignore match │
                              ▼               ▼              │  (no internal deps) │
              ┌───────────────────┐  ┌──────────────────┐    └────────────────────┘
              │ internal/security │  │internal/filesystem│
              │ path validation,  │  │ chmod/chown,      │
              │ tamper detection  │  │ immutable flags   │
              └─────────┬─────────┘  └─────────┬─────────┘
                        │                      │
                        ▼                      ▼
              ┌───────────────────┐    ┌──────────────────┐
              │ internal/registry │    │   OS / syscalls   │
              │ data model, YAML  │    │ chflags, chattr,  │
              │  → .guardfile     │    │ (darwin/linux)    │
              └─────────┬─────────┘    └──────────────────┘
                        │
                        ▼
                  ┌───────────┐
                  │ .guardfile│  (YAML on disk, relative paths)
                  └───────────┘
```

## Core packages

| Layer         | Package                 | Role                                                  |
|---------------|-------------------------|-------------------------------------------------------|
| UI            | `cmd/guard/commands`    | CLI (Cobra) — parsing & output                        |
| UI            | `internal/tui`          | TUI (Bubble Tea) — terminal UI                        |
| Orchestration | `internal/manager`      | business logic, mutation sequencing, persistence      |
| Helper        | `internal/guardignore`  | gitignore/guardignore matching — isolated, no internal deps |
| Service       | `internal/security`     | path validation + tamper detection                    |
| Service       | `internal/filesystem`   | chmod/chown + immutable flags (darwin/linux)          |
| Data          | `internal/registry`     | `.guardfile` model + YAML serialization               |

## Key rules

- Dependency rules enforced by `internal/architecture/layers_test.go`:
  UI → manager **only**; manager → security + filesystem; security → registry.
- UI layers may **never** reach down to filesystem/security/registry directly.
- Registry stores **relative** paths; filesystem operates on **absolute** paths —
  the manager bridges that gap.
- The manager never prints; it returns structured results and warnings.

---

# Interview Q&A

## AI development & verification

**Q: You ship AI-written code with no manual code review. Why isn't that reckless?**
A: Code generation is no longer the bottleneck — review is. Instead of reviewing
*output*, we review *intent and contract*: humans author the requirements, the
failing acceptance tests, and the guardrails. The AI's code is accepted only if it
satisfies that human-authored contract. We replaced "a human reads the diff" with
"the code passes an executable specification."

**Q: The AI writes the tests too. What stops it writing a vacuous test that passes trivially?**
A: Two things. (1) *Scope*: a human specifies behavior precisely in natural language
(see the tutorials); translating a stated behavior into an assertion is a narrow,
low-variance task. (2) *Red-first as a vacuity check*: a test must be proven to fail
before the implementation exists — a vacuous test would pass against the unbuilt
feature and expose itself. Red-first isn't ritual; it's the mechanism that catches
tests that test nothing.

**Q: Is red-first mechanically enforced?**
A: No — it can't be enforced by a stateless check that runs every CI build, because
it's inherently temporal. It's a *workflow*: specify → write test → verify it fails →
lock the test with Guard (immutable, so the implementing agent can't weaken it) →
release the agent to implement. Red-green-refactor is never machine-enforced anywhere;
it's always process with a human steering.

**Q: Verifying a test fails — isn't that "reading code", which you said you never do?**
A: No. Verifying a `FAIL` status line is reading *output*, not source. I read the test
*result*, not the test *implementation*.

**Q: Then how do you catch a test that's green but meaningless, without reading it?**
A: I trust the test encodes the desired behavior because the behavior was specified in
detailed natural language, and frontier models are reliable at turning behavior into
sensible tests. This is bound-and-accept: the residual risk (a vacuous test that also
went red for an incidental reason) is rare, and the trust anchor is the model quality
+ spec precision. Caveat worth naming: that guarantee is only as strong as the model.

**Q: What does the "Verified by Humans" badge mean with no code review?**
A: Humans wrote the requirements and the acceptance tests / guardrails the AI's output
must pass. Verification is via the human-authored contract, not diff-reading.

## Threat model & security

**Q: The immutable flag needs sudo to remove, but the agent runs as you. What does it actually stop?**
A: A plain `chmod -w` is reversible by the owner — the agent just does `chmod +w`. The
OS immutable flag can only be cleared with `sudo`, which the agent doesn't have. The
sudo password is the human/agent boundary; there's no passwordless escalation.

**Q: How does Guard clear the flag to unguard, and doesn't that let the agent unlock too?**
A: I run Guard with sudo and enter a password. The agent can't — the password is the
separator.

**Q: How would you attack your own design?**
A: Tamper with the `.guardfile` (the registry) to make a re-guard a no-op, plus
social-engineer the human into running sudo. But the OS immutable flag is the backstop
that catches it — the attack only really works on filesystems that don't support the
flag.

**Q: Is the `.guardfile` itself integrity-protected?**
A: No cryptographic integrity — the security layer's "tamper detection" only validates
*paths* (relative, no `..`). But it doesn't matter: Guard is stateless and the OS flag
is the real enforcement, so tampering with the bookkeeping changes nothing where the
flag is supported. This is a theoretical attack; we engineer to the observed threat
model, not gold-plate against attacks unseen in the wild.

**Q: If the `.guardfile` (intent) and the filesystem (reality) disagree, which wins?**
A: Reality. Guard is stateless — every run reloads from disk and inspects the actual
filesystem (`GetFileStatus`). The registry is reconciled *to* the filesystem (via
`cleanup`/`reset`), never the other way around. The OS is the source of truth; the
`.guardfile` is declared intent.

## Architecture

**Q: A strict 6-layer architecture for a small CLI — isn't that over-engineering?**
A: No. With interwoven concerns, the AI kept tangling layers and couldn't localize a
change. Strict, test-enforced boundaries create a high-signal codebase, and a
high-signal codebase makes the agent's output better. Clean code begets clean code —
the architecture is a force multiplier on agent reliability, not aesthetics.

**Q: How are the layer boundaries enforced, vs. the `.Load()` rule?**
A: Import/token boundaries are enforced by a coarse substring-scanning Go test
(`internal/architecture/layers_test.go`) — good enough because import paths are unique
strings. The call-level rule ("only the security layer may call `registry.Load()`") is
enforced by a fine-grained, AST-aware Semgrep pattern. We use the cheapest tool precise
enough for each invariant.

**Q: Soft guardrails (prompts/docs) vs. hard guardrails (tests) — which matters?**
A: Both. Soft guardrails steer the agent and reduce the violation rate up front; hard
guardrails catch what slips through. Soft alone gets violated; hard alone lets the
agent flail. Defense in depth.

**Q: Should a guardrail failure message also teach the fix?**
A: Yes — model it on the Semgrep message, which states the rationale and the correct
alternative. But the invariant is *clarity, never verbosity*: state exactly the fact
and the fix in the fewest tokens that resolve the agent's next action. Noise costs
context, and context is what the clean architecture exists to protect.

## Testing

**Q: Why drive a real terminal with tmux instead of unit-testing the Bubble Tea model?**
A: End-to-end realism — we test what the user actually sees — plus transparency: it's
human-inspectable and debuggable, with no artifacts a test harness might introduce.

**Q: What does the tmux approach cost, and how do you manage it?**
A: It's slow (timed pauses between keystrokes), so we run the suite in parallel. Flaky
tests are debugged by varying timings; since the tool itself is deterministic,
flakiness almost always means dirty test setup, not a product bug — which is why each
test gets its own temp dir.

**Q: When are TUI screenshots taken?**
A: After every action *and* on every failure (`helpers-tui.sh`). Saved as numbered
`.txt` (plus an `_ansi.txt` with color codes) under `./reports/tui-tests/<testname>/`,
giving a frame-by-frame trace. Failure messages include the path to the latest
screenshot.

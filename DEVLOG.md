# Guard Development Log

This document chronicles the development journey of Guard, a file permission management tool designed to protect source code from unintended modifications by AI coding assistants.

---

## Project Overview

**Project:** Guard - Protecting your files against unwanted changes by AI coding agents
**Developer:** Florian Buetow
**Development Period:** January 8-30, 2026
**Hackathon:** Dynamous Kiro Hackathon (January 5-23, 2026)

### The Problem

> Yes you are absolutely right!

When working with AI coding assistants (Claude, Cursor, GitHub Copilot, etc.), developers frequently encounter a frustrating scenario: the AI attempts to modify unrelated files in an effort to "fix" cascading issues it created. This can lead to:
- Unwanted changes to stable, working code
- Corruption of configuration files
- Modifications to files outside the current task scope

### The Solution

Guard provides Unix-style file permission management that allows developers to "guard" files by changing their ownership and removing write permissions. Since AI assistants run under the user's account and typically cannot use `sudo`, guarded files become read-only and immutable to the AI while remaining fully accessible to the developer.

---

## Development Timeline

### Phase 1: Ideation (January 5-7) - 3 days

I spent the most time on this project planning features on the whiteboard, testing out different ideas, and getting feedback from potential users on how GuardTools should work and what internal structure the application needs for a clean design.

My three main areas of concern were:

1. User experience: How would this tool integrate into existing AI coding workflows?
2. Security: How can I make Guard safe to use given that it needs to run as sudo?
3. Application Architecture: AI coding agents are great for implementing code, but I didn't want to give the agent full control over the internal architecture of the application.
4. Proof of concept: The development of GuardTool itself should be driven by the principles of Guard. I wanted a full specification, including integration tests, before writing much of the codebase.

I used speech-to-text to document all of my ideas and consolidated them into requirements and specifications later.

#### Key Improvements:
- A cool logo and a clear use case 
- The decision to build it as a CLI tool with a bonus TUI interface.
- Clear UX design for CLI and TUI usage (look and feel)
- A command line argument structure that was consistent and self-explanatory
- Testing Kiro and generating some of the requirements documents.

### Phase 2: Exploration and Foundation (January 8-11) - 3 days

During that phase, I didn't yet have the KIRO Hackathon credits available and had to rely on other AI tools to help me research some of the foundational setups of this project. 

#### Day 1 (Jan 8): Project Initialization
- Created initial project structure
- Set up development infrastructure (justfile, Go module)
- Integratinoof of static code analysis tools into my testing/ci pipeline
- Added Creative Commons BY-NC-SA 4.0 license

#### Day 2-3 (Jan 9): Core Implementation and Experiments
- Implemented the core `registry.go` by hand which serves as the hart of the guard tool.
- Trying out different libraries for command line argument parsing
- Generating would-be system diagrams from my textual requirements.

#### Day 4 (Jan 11): Core Architecture

All of the experiments and tests of the previous days led me to the following architecture of the application:

**Architecture Plan:**
```
┌─────────────────────────────────────────────────────────┐
│                     CLI Layer (Cobra)                    │
│  - Command parsing and validation                        │
│  - Positional argument handling                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                   Guard Manager Layer                    │
│  - Command orchestration                                 │
│  - Business logic coordination                           │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌──────────────────┐    ┌──────────────────────┐
│ Filesystem Layer │    │   Registry Component │
│  - Permissions   │◄───┤  - YAML persistence  │
│  - Owner/Group   │    │  - Thread-safe ops   │
└──────────────────┘    └──────────────────────┘
```

#### Key Improvements:
- Added detailed output messages (info|warn|err) for all commands
- Created `just ci` target for continuous integration
- Implemented more fail-fast shell-based test
- Added Semgrep static analysis for security restrictions
- Added code complexity analyzers to `ci`
- Documentation of internal architecture


### Phase 3: Requirements Refinement (January 12) - 1 day

#### Day 5 (Jan 12): Core Architecture

#### Major Changes:
- Renamed some commands that didn't feel natural anymore. (`destroy` to `uninstall`)
- Added new commands: `create`, `destroy`, `update`, `clear`
- Simplified `add` and `remove` to become file-only operations
- Specified auto-detection logic for `enable`, `disable`, `toggle`, `show` commands, to disambiguate between files and collections.
- `file` keyword now optional in commands

**Technical Decision:** Auto-detection Priority
```
1. Check if argument is an existing file → treat as file
2. Check if argument is an existing collection → treat as collection
3. Check if argument is an existing folder → treat as folder
4. Fallback: treat as file (will error if not found)
```

This makes the CLI more intuitive: `guard enable myfile.txt` works without needing `guard enable file myfile.txt`.

**Test Updates:** Updated 54 test files to reflect new CLI syntax.

---

### Phase 4: Requirements for TUI (January 19-23) - 4 days

#### Day 6-10 (Jan 19-26): Core Architecture

In this phase I use ChatGPT a lot to draw me different diagram types and different text-based user interfaces to help me generate ideas and visualizations. I already knew that I wanted a Norton Commander-like text-based interface, but I just didn't know what it would look like. Mocking it with AI was a great way of tossing around ideas and reasoning about the best approach.

I also noticed that there must be a difference between the guard state inside the .guard file and the effective guard state of collections that might have a different internal guard state compared to what guard state the files in them have. 

You might wonder why I didn't write a lot of code until now. My experience, surprisingly, has been that reasoning deeply about an application before building it is a very different but satisfying experience compared to regular coding.

#### TUI Features Specified:
- Dual-pane interface (Files panel + Collections panel)
- Keyboard navigation (↑↓←→, Tab, Space, Q/Esc)
- Visual guard state indicators: `[G]`, `[-]`, `[~]`, `[g]`, `[ ]`
- Folder expansion/collapse
- Real-time guard toggling
- TUI Refresh capabilities

**Architecture Choice:** Used [Bubble Tea](https://github.com/charmbracelet/bubbletea) framework for the TUI, following the Elm Architecture pattern (Model-Update-View).

**Challenge: Effective vs Stored Guard States**

Files have a direct 1:1 mapping between stored state and display. But folders and collections required computing an "effective" state based on their contents:

| Indicator | Meaning |
|-----------|---------|
| `[G]` | All files guarded (collection flag true) |
| `[g]` | All files guarded (inherited, collection flag false) |
| `[~]` | Mixed state (some guarded, some not) |
| `[-]` | All files unguarded |
| `[ ]` | Not in registry |

**Challenge: TUI Testing**

I did a bunch of research on how to best test a text-based user interface with Golang, but then I settled for one of the simplest approaches that did not require a lot of extra tooling: `tmux` (terminal multiplexer).

Using TMAX allows me to capture the output of the GUARD tool as it is, without any frameworks getting into the way. All I have to do is spawn a session, remote control the session by sending keys to it to simulate user input, and then making assertions based on what is contained in the current view.

#### Tests Implemented:

- tmux-based automated testing
- Keystroke simulation
- Screen capture and assertion helpers
- Timing-sensitive synchronization


### Phase 5: Let the Agent Rip Through the Specs (2 days)


The final phase is the implementation phase where everything besides the core files and the project harness had to be implemented.

I grouped my requirements into individual implementable features so that I could implement them with `Kiro CLI`. I honestly started doing this too late, so I had to run the code generation up until the last hours before the end of the hackathon. 

With all of my tests in place, In my specifications written in text I used `Kiro CLI` To plan a new feature and then I would give it all of the requirements for that feature. I burned through a lot of tokens during that time and had to remind the AI to stay on track or to feed it with additional information when what I provided wasn't sufficient.

The automatic test harness and of course all of the shell based tests help me to check whether the AI was on track or not and could invoke corrective measures if it wasn't. 


#### Day 11 (Jan 29): Impelmentation


#### Day 12 (Jan 30): Refactoring 





---

## Technical Decisions and Rationale

### 1. Why Go?

- Single binary deployment (no dependencies)
- Excellent cross-platform support
- Strong standard library for file operations
- Good performance for CLI tools

### 2. Why Shell Tests Over Go Tests?

The project uses shell-based integration tests (54 test files, 640 test cases) rather than primarily Go unit tests. Rationale:
- Tests the actual CLI behavior end-to-end
- Catches issues with argument parsing, output formatting, exit codes
- More representative of real user interactions
- Easier to write and maintain for CLI tools

Go unit tests are still used for internal packages (registry, filesystem) with good coverage on the filesystem layer.

### 3. Why YAML for .guardfile?

- Human-readable and editable
- Good tooling support
- Sufficient for the data model (config + files + collections)
- Familiar to developers
- Power users should be able to mess with it

### 4. Why Bubble Tea for TUI?

- Well-maintained, popular Go TUI framework
- Elm Architecture provides clean state management
- Good documentation and examples
- Active community

---

## Challenges Faced and Solutions

### Challenge 1: Interactive rm Prompts in Tests

**Problem:** `rm` command prompts for confirmation when removing files with restricted permissions after `guard enable`.

**Solution:** Use `rm -f` in all test scripts to force deletion without prompting.

### Challenge 2: Flaky Tests Due to Timing

**Problem:** TUI tests occasionally failed due to race conditions between keystroke simulation and screen updates.

**Solution:**
- Added explicit wait/sync points in test helpers
- Improved exit detection timing
- Used tmux's `wait-for` feature for synchronization

### Challenge 3: Path Display in Output

**Problem:** Guard stored absolute paths but users expected relative paths in output.

**Solution:** Store relative paths in registry, convert to absolute only for filesystem operations.

### Challenge 4: Collection Toggle Semantics

**Problem:** Initial implementation toggled each file individually based on its current state, leading to unpredictable results when files had mixed states.

**Solution:** Collection toggle now:
1. Determines new collection state (opposite of current)
2. Sets ALL member files to that state
3. Updates collection flag

This ensures consistent behavior regardless of prior file states.


### Challenge 5: Test-Driven Development Discipline**

During this phase, we learned a critical lesson about TDD discipline. I used a BUGs.md file to capture every inconsistency I foudn that had to be added to the tests later

> **MISTAKE #1:** Claimed tests pass without running them through the test framework
> **MISTAKE #2:** Ignored that tests never actually executed (fail-fast stopped earlier)
> **MISTAKE #3:** Trusted documentation status over actual code verification

**Solution:** Established strict TDD protocol:
1. Write shell tests FIRST
2. Run `just test` to verify tests FAIL
3. Implement the fix
4. Run `just test` to verify tests PASS
5. Check test output shows YOUR tests executed

---

## Architectural Achievements

1. **Clean Layered Architecture** - Proper separation of concerns with dependency injection
2. **Type-Safe Design** - Enum-based warnings, structured errors, interface-driven components
3. **Cross-Platform Support** - Runtime OS detection for Darwin/Linux differences
4. **Comprehensive Testing** - Unit tests, integration tests, and TUI tests
5. **Production-Ready CLI** - Full Cobra integration with help, examples, and error handling
6. **Interactive TUI** - Bubble Tea interface for rapid file protection management

---

## Key Learnings

1. **Test-Driven Development Works** - Shell tests as executable specifications caught issues early
2. **API Discovery Before Implementation** - Using grep to find actual method signatures prevents assumptions
3. **Incremental Validation** - Building after each change catches errors faster
4. **Platform Testing Matters** - macOS vs Linux differences require explicit handling
5. **Type Safety Pays Off** - Enum-based systems catch errors at compile time

---

## AI Tool Usage

This project was developed with significant AI assistance, as indicated by the badges in the README:
- ![Made by AI](https://img.shields.io/badge/Made%20with-AI-333333?labelColor=f00)
- ![Verified by Humans](https://img.shields.io/badge/Verified%20by-Humans-333333?labelColor=brightgreen)

### AI Contributions
- Architecture design discussions
- Code generation and implementation
- Test case refinement
- Documentation writing
- Bug analysis and fixing

### Human Contributions
- Requirements definition
- Test and quality harness with static tests
- Testing, validation

---

## Quality assurance

### Lessons Learned About AI-Assisted Development

1. **TDD is essential** - AI can claim code works without verification. Always run the full test suite.

2. **Verify, don't trust** - AI may mark issues as "resolved" in documentation without implementing the fix.

3. **Minimal changes principle** - Guide AI to use existing code patterns rather than creating new abstractions.

4. **Clear specifications** - Detailed specs as text or tests significantly improve AI output quality.

## Known Issues

See `docs/BUGS.md` for current bug tracking.

---

## Conclusion

Guard was built to solve a real problem that developers face daily when working with AI coding assistants. The project demonstrates:

1. **Practical utility** - Addresses a genuine developer pain point
2. **Solid architecture** - Clean separation of concerns, testable design
3. **Comprehensive testing** - ~200 test cases ensuring reliability
4. **Good documentation** - Tutorials, specs, and this devlog
5. **AI-human collaboration** - Leveraging AI tools effectively while maintaining quality

The development journey reinforced the importance of test-driven development, especially when working with AI assistance, and showed how spec-driven development leads to more predictable outcomes.

---

*Last updated: January 30, 2026*


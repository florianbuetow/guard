
<span>![Made by AI](https://img.shields.io/badge/Made%20with-AI-333333?labelColor=f00) ![Verified by Humans](https://img.shields.io/badge/Verified%20by-Humans-333333?labelColor=brightgreen)</span>


![The Guard project logo](docs/guard-logo.png)

# What is this?

If you are a developer who uses AI, you ran into the problem that the AI suddenly tries to modify unrelated files in an attempt to "improve" the mess it started to create.

Guard is a tool that allows `you` to change file permissions on a whim so that the `AI` can't. Effectively preventing the AI from changing files or their permissions without yours.

Guard provides you the ability to toggle the `guard` of individual `files`, defined `collections of files` and provides an `interactive mode` for power users who need the `fastest workflow` possible to set and toggle file guards.

## What does it do?

1. [Protect individual files](docs/TUTORIAL-1.md)
2. [Protect collection of files](docs/TUTORIAL-2.md)
3. [Interactively protect files](docs/TUTORIAL-3.md)

Follow the onboarding guide below to make `guard` your own tool.

## How does it do it?

1. It remembers the mode of files (`owner`, `group` and `read/write/execute` permissions) in a `.guardfile`.
2. It changes the files `group` and `owner` and removes `write` permissions to guard a file against modifications by the AI.
3. It sets the immutable flag so that even the owner of the file cannot change its permissions without sudo.
4. It restores the original file settings when you are done.

# Star This Repository

If you find `guard` useful, please consider ⭐ starring this repository! It helps others discover the project and shows your appreciation for the work.

# System Requirements

## Supported Platforms

Guard is designed for **Unix-like systems** that support traditional file permissions and ownership like:

- **Linux**
- **macOS** 
- **BSD** variants (FreeBSD, OpenBSD, NetBSD)

## Why Not Windows?

Guard relies on Unix-style file permissions (read/write/execute for owner/group/other) and file ownership concepts that are fundamental to Unix-like systems. Windows uses a different permission model (ACLs - Access Control Lists) that doesn't map directly to the rwx permission system that Guard manages.

If you're on Windows, consider using:
- **WSL (Windows Subsystem for Linux)** - Run Guard inside a Linux environment
- **Docker** - Use a Linux container to run Guard
- **Virtual Machine** - Run a Linux VM for development work

## Critical Security Requirement for AI Development

**⚠️ IMPORTANT**: When using Guard with AI coding agents (Claude, Cursor, GitHub Copilot, etc.), the user account running the AI coding agent **MUST NOT** have sudo privileges or at the very least using sudo must require entering a password.

This is essential because:
- Guard uses `sudo` to change file ownership and permissions to protect files
- If your AI coding agent has automatic sudo access, it can override Guard's protection mechanisms
- The security model depends on the AI running under a user account that cannot silently escalate privileges

**Typical Setup**:
- Run your AI coding tools under a regular user account
- If your user account has sudo access, make sure using `sudo` requires entering a password
- Use `sudo guard` and `sudo guard -i` commands manually when you need to enable/disable file protection
- This ensures the AI cannot bypass Guard's file protection system

**Recommended Setup**:
- Create a dedicated user account specifically for running Guard operations
- Ensure your regular user account cannot modify the dedicated user's file permissions
- Open a separate terminal session as the dedicated user and use Guard from that terminal
- This provides complete isolation between AI operations and Guard's security mechanisms

If you don't know how to set this up, paste the above into your AI of choice to guide you.

# Installation

__Prerequsisites:__

You'll need a working installation of the `go` programming language, and the command runner `just` and the version control system `git`.

### Installing Go

1. Download the latest stable version from [https://go.dev/doc/install](https://go.dev/doc/install).
2. Follow your OS-specific instructions to install it.   
3. Verify your installation by running `go version` inside a terminal.

### Installing Just

1. Go to [https://github.com/casey/just](https://github.com/casey/just)
2. Follow your OS-specific instructions to install it. 
3. Verify your installation by running `just --version` inside a terminal.

### Installing Git

1. Go to [https://git-scm.com/install/](https://git-scm.com/install/)
2. Follow your OS-specific instructions to install it. 
3. Verify your installation by running ` git --version` inside a terminal.

### Installing Guard

1. Clone this repository.
```bash
git clone https://github.com/florianbuetow/guard.git
cd guard
```
2. Build the `guard` tool binary
```bash
just build 
```
3. Install the `guard` binary in $GOPATH/bin

```bash
just install
```

4. Verify the `guard` tool installation in a new terminal window.
```bash
guard --version
```

Note: When the guard tool is not found in the last step, you probably need to fix your GOPATH variable and re-run `just install`.


# Onboarding Guide

To become a master at using Guard, I highly recommend that you go through the tutorials. They are easy to follow and won't take up much of your time, I promise.

- **[Tutorial 1: How to Protect a Single File](docs/TUTORIAL-1.md)** - Learn the basics of protecting individual files with Guard

- **[Tutorial 2: How to Protect a (Static) Collection of Files](docs/TUTORIAL-2.md)** - Learn the basics of protecting collections of files with Guard

- **[Tutorial 3: Speed up your Workflow with Interactive Mode](docs/TUTORIAL-3.md)** - Tired of adding files manually? Learn how to use Guard in interactive mode to infinitely speed up your workflow while working with your AI agent(s) and guard.

# Command Reference

## Configuration Management
```bash
# Initialize guard with default settings
guard init <mode> <owner> <group>

# Show current configuration
guard config show

# Update multiple config values at once
guard config set [mode] [owner] [group]

# Update guard mode only
guard config set mode <mode>

# Update guard owner only
guard config set owner <owner>

# Update guard group only
guard config set group <group>
```

## File Operations
```bash
# Register files (captures current permissions)
guard add file <path>...

# Remove files from management
guard remove file <path>...

# Toggle protection on/off
guard toggle file <path>...

# Enable protection on files
guard enable file <path>...

# Disable protection on files
guard disable file <path>...

# Show file status and collection membership
guard show file <path>...
```

## Collection Operations
```bash
# Add files to a collection (auto-creates collection)
guard add file <path>... to <collection>...

# Remove files from a collection
guard remove file <path>... from <collection>...

# Show collection contents
guard show collection <name>

# List all collections
guard show collection

# Toggle protection for entire collection
guard toggle collection <name>

# Create empty collection(s)
guard add collection <name>...

# Remove collection(s) and disable guard on their files
guard remove collection <name>...

# Enable protection for all files in collection(s)
guard enable collection <name>...

# Disable protection for all files in collection(s)
guard disable collection <name>...

# Clear files from collection(s) (disable guard and remove files, keep collection)
guard clear <name>...

# Copy files from source collections to target collections
guard add collection <source>... to <target>...

# Remove files from target collections that exist in source collections
guard remove collection <source>... from <target>...
```

## Maintenance Operations
```bash
# Disable protection on all files (preserves registrations)
guard reset

# Remove stale registry entries for deleted files
guard cleanup

# Show version information
guard version

# Reset, cleanup, and delete .guardfile
guard uninstall
```

## Information and Help
```bash
# Show about information
guard info

# Show help for any command
guard help <command>

# Show general help (same as 'guard help')
guard
```

# Development

## Build Commands
```bash
# Check prerequisites and dependencies
just check

# Initialize development environment
just init

# Build the application
just build

# Install guard binary
just install

# Run all tests
just test

# Run basic tests (no sudo required)
just test-basic

# Run privileged tests (requires sudo)
just test-sudo

# Format code and run linter
just fmt
just lint

# Run Semgrep static analysis
just semgrep

# Run cyclomatic complexity check
just cyclo

# Run cognitive complexity check
just cognit

# Generate test coverage report
just coverage

# Clean build artifacts
just clean

# Show available commands
just help
```

## CI Dependencies

Run `just check` to verify your setup. The following tools are used by the CI pipeline:

**Required:** Go, Git, Bash

**Optional (auto-installed or with fallbacks):**
- `golangci-lint` - Linting (falls back to `go vet` if not installed)
- `semgrep` - Security analysis
- `gocyclo` - Cyclomatic complexity analysis
- `gocognit` - Cognitive complexity analysis
- `tmux` - Required for TUI tests

## Testing
Guard uses a comprehensive testing strategy:
- **Unit Tests**: Test individual components with mocked dependencies
- **Property-Based Tests**: Use gopter framework (minimum 100 iterations)
- **Integration Tests**: Test complete workflows with real filesystem operations

## Architecture Overview
- **CLI Interface**: Cobra-based command-line interface
- **Guard Manager**: Orchestrates operations between Registry and Filesystem components
- **Registry Component**: State management for `.guardfile` (thread-safe)
- **Filesystem Operations**: Handles file permission and ownership changes

# Troubleshooting

## Platform Compatibility

**Windows users**: Guard is not compatible with Windows due to fundamental differences in file permission systems. Use WSL, Docker, or a Linux VM instead.

**Permission system differences**: Guard expects Unix-style rwx permissions and user/group ownership. If you're seeing unexpected behavior, verify your system supports these concepts.

## Common Issues

**Permission denied errors**
- Some operations require elevated privileges (sudo)
- Use `sudo guard` for operations that change file ownership

**Registry corruption**
- Guard handles corrupted `.guardfile` gracefully
- Use `guard cleanup` to clean up stale entries

**Files not found**
- Use `guard cleanup` to remove registry entries for deleted files
- Verify file paths are correct and accessible

**Configuration issues**
- Verify file mode format (octal strings like "0644")
- Ensure user/group names exist on the system
- Check the `.guardfile` to verify current settings

# Contributing

We welcome contributions! Here's how you can help improve Guard:

## Feedback

Have suggestions or ideas? We'd love to hear from you! Please open an [issue](https://github.com/florianbuetow/guard/issues) with your feedback.

## Bug Reports

Found a bug? Please help us fix it by opening a [bug report](https://github.com/florianbuetow/guard/issues/new). Include as much detail as possible:
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Your environment (OS, Go version, etc.)

## Pull Requests

Want to contribute code? Great! Here's how:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a [Pull Request](https://github.com/florianbuetow/guard/pulls)

# License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. See the [LICENSE](LICENSE) file for details.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made
- **NonCommercial** — You may not use the material for commercial purposes
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license

For more information, visit: https://creativecommons.org/licenses/by-nc-sa/4.0/


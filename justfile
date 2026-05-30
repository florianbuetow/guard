# Guard — File Permission Management Tool
#
# ─── justfile conventions (keep these when editing) ─────────────────────────
#
# 1. Colored output uses `printf`, never `echo` — some terminals won't render
#    ANSI escapes passed to echo. Colors: blue \033[0;34m (section headers),
#    yellow \033[0;33m (help groups / warnings), green \033[0;32m (✓ success),
#    red \033[0;31m (✗ failure), reset \033[0m.
# 2. Wrap each target's command block in empty spacing lines — `@echo ""`
#    (or `echo ""` inside shebang recipes) before and after.
# 3. The default target is `help`, never `--list`. `_default` delegates to it.
# 4. `help` clears the screen, prints a blue project header, then lists targets
#    under yellow group headers using `printf "  %-38s %s\n" name description`.
# 5. Composite targets fail fast — shebang recipes use `set -e`/`set -euo pipefail`.
# 6. Every target ends with a clear status message: green `✓ …` on success,
#    red `✗ …` then `exit 1` on failure.
# 7. Targets appear in the file in the same order as in the help listing.
# 8. This comment block documents the rules for anyone editing the file.
# 9. Each target has a single-line `# Description` comment directly above it.
# ─────────────────────────────────────────────────────────────────────────────

shellcheck_flags := "--shell=bash --external-sources --source-path=SCRIPTDIR --severity=error --exclude=SC1128"

# Default recipe: show available commands
_default:
    @just help

# Display help information
help:
    @echo ""
    @clear
    @echo ""
    @printf "\033[0;34m=== Guard — File Permission Management Tool ===\033[0m\n"
    @echo ""
    @printf "\033[0;33mSetup & Lifecycle:\033[0m\n"
    @printf "  %-38s %s\n" "just check" "Check required and optional prerequisites"
    @printf "  %-38s %s\n" "just install" "Install guard to GOPATH/bin"
    @printf "  %-38s %s\n" "just uninstall" "Remove guard from GOPATH/bin"
    @printf "  %-38s %s\n" "just clean" "Remove build artifacts"
    @printf "  %-38s %s\n" "just help" "Show this help"
    @echo ""
    @printf "\033[0;33mBuild & Run:\033[0m\n"
    @printf "  %-38s %s\n" "just build" "Build the guard binary"
    @printf "  %-38s %s\n" "just run" "Build and run the guard binary"
    @echo ""
    @printf "\033[0;33mCode Quality:\033[0m\n"
    @printf "  %-38s %s\n" "just code-fmt" "Format Go code"
    @printf "  %-38s %s\n" "just code-lint" "Run linter (golangci-lint or go vet)"
    @printf "  %-38s %s\n" "just code-shellcheck" "Run ShellCheck over shell scripts"
    @printf "  %-38s %s\n" "just code-semgrep" "Run Semgrep static analysis"
    @printf "  %-38s %s\n" "just code-cyclo" "Check cyclomatic complexity"
    @printf "  %-38s %s\n" "just code-cognit" "Check cognitive complexity"
    @printf "  %-38s %s\n" "just code-tidy" "Tidy module dependencies"
    @echo ""
    @printf "\033[0;33mRelease & Versioning:\033[0m\n"
    @printf "  %-38s %s\n" "just version" "Print current version"
    @printf "  %-38s %s\n" "just deps" "Show dependencies"
    @printf "  %-38s %s\n" "just release" "Build optimized release binary for this platform"
    @printf "  %-38s %s\n" "just release-all" "Build optimized release binaries for all platforms"
    @printf "  %-38s %s\n" "just tag" "Interactive version bumping and tagging"
    @echo ""
    @printf "\033[0;33mCI & Testing:\033[0m\n"
    @printf "  %-38s %s\n" "just test" "Format, build, install, and run all tests"
    @printf "  %-38s %s\n" "just show-failing-tests" "Run every test individually and report only failures"
    @printf "  %-38s %s\n" "just ci" "Run all checks and tests (code checks and test)"
    @printf "  %-38s %s\n" "just ci-quiet" "Run all checks and tests with minimal output"
    @echo ""

# Check prerequisites
check:
    @echo ""
    @printf "\033[0;34m=== Checking Prerequisites ===\033[0m\n"
    @echo ""
    @printf "\033[0;33mChecking required dependencies...\033[0m\n"
    @echo ""
    @command -v go >/dev/null 2>&1 && printf "\033[0;32m✓ go %s\033[0m\n" "$(go version | awk '{print $3}')" || { printf "\033[0;31m✗ go not found - install from https://golang.org/\033[0m\n"; exit 1; }
    @command -v git >/dev/null 2>&1 && printf "\033[0;32m✓ git %s\033[0m\n" "$(git --version | awk '{print $3}')" || { printf "\033[0;31m✗ git not found - install from https://git-scm.com/\033[0m\n"; exit 1; }
    @command -v bash >/dev/null 2>&1 && printf "\033[0;32m✓ bash %s\033[0m\n" "$(bash --version | head -n1 | awk '{print $4}')" || { printf "\033[0;31m✗ bash not found\033[0m\n"; exit 1; }
    @command -v sed >/dev/null 2>&1 && printf "\033[0;32m✓ sed\033[0m\n" || { printf "\033[0;31m✗ sed not found\033[0m\n"; exit 1; }
    @command -v awk >/dev/null 2>&1 && printf "\033[0;32m✓ awk\033[0m\n" || { printf "\033[0;31m✗ awk not found\033[0m\n"; exit 1; }
    @command -v grep >/dev/null 2>&1 && printf "\033[0;32m✓ grep\033[0m\n" || { printf "\033[0;31m✗ grep not found\033[0m\n"; exit 1; }
    @command -v find >/dev/null 2>&1 && printf "\033[0;32m✓ find\033[0m\n" || { printf "\033[0;31m✗ find not found\033[0m\n"; exit 1; }
    @command -v sort >/dev/null 2>&1 && printf "\033[0;32m✓ sort\033[0m\n" || { printf "\033[0;31m✗ sort not found\033[0m\n"; exit 1; }
    @command -v mktemp >/dev/null 2>&1 && printf "\033[0;32m✓ mktemp\033[0m\n" || { printf "\033[0;31m✗ mktemp not found\033[0m\n"; exit 1; }
    @echo ""
    @printf "\033[0;33mChecking optional dependencies...\033[0m\n"
    @echo ""
    @command -v golangci-lint >/dev/null 2>&1 && printf "\033[0;32m✓ golangci-lint (optional)\033[0m\n" || printf "\033[0;33m⚠ golangci-lint not found (optional - will use go vet instead)\033[0m\n"
    @command -v shellcheck >/dev/null 2>&1 && printf "\033[0;32m✓ shellcheck (optional)\033[0m\n" || printf "\033[0;33m⚠ shellcheck not found (optional - required for just code-shellcheck/ci)\033[0m\n"
    @command -v semgrep >/dev/null 2>&1 && printf "\033[0;32m✓ semgrep (optional)\033[0m\n" || printf "\033[0;33m⚠ semgrep not found (optional - install with: pip3 install semgrep)\033[0m\n"
    @command -v gocyclo >/dev/null 2>&1 && printf "\033[0;32m✓ gocyclo (optional)\033[0m\n" || printf "\033[0;33m⚠ gocyclo not found (optional - will be auto-installed when needed)\033[0m\n"
    @command -v gocognit >/dev/null 2>&1 && printf "\033[0;32m✓ gocognit (optional)\033[0m\n" || printf "\033[0;33m⚠ gocognit not found (optional - will be auto-installed when needed)\033[0m\n"
    @command -v tmux >/dev/null 2>&1 && printf "\033[0;32m✓ tmux (required for TUI tests)\033[0m\n" || printf "\033[0;33m⚠ tmux not found (required for TUI tests - install with: brew install tmux)\033[0m\n"
    @echo ""
    @printf "\033[0;32m✓ All required dependencies are available!\033[0m\n"
    @echo ""

# Install guard to GOPATH/bin
install: build
    #!/usr/bin/env bash
    set -e
    echo ""
    printf "\033[0;34m=== Installing guard ===\033[0m\n"
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    mkdir -p "$INSTALL_BIN"
    echo "Installing guard to $INSTALL_BIN..."
    GOBIN="$INSTALL_BIN" go install -ldflags="-X main.version=$(git describe --tags --dirty 2>/dev/null || echo dev)" ./cmd/guard
    if [ "$(uname)" = "Darwin" ]; then codesign -fs - "$INSTALL_BIN/guard" 2>/dev/null || true; fi
    printf "\033[0;32m✓ Installed: %s/guard\033[0m\n" "$INSTALL_BIN"
    echo ""

# Remove guard from GOPATH/bin
uninstall:
    #!/usr/bin/env bash
    echo ""
    printf "\033[0;34m=== Uninstalling guard ===\033[0m\n"
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    GUARD_PATH="$INSTALL_BIN/guard"
    if [ -f "$GUARD_PATH" ]; then
        rm -f "$GUARD_PATH"
        printf "\033[0;32m✓ Uninstalled: %s\033[0m\n" "$GUARD_PATH"
    else
        echo "Not installed: $GUARD_PATH"
    fi
    echo ""

# Remove build artifacts
clean:
    @echo ""
    @printf "\033[0;34m=== Cleaning build artifacts ===\033[0m\n"
    rm -f guard
    rm -rf ./bin ./reports
    go clean ./...
    @printf "\033[0;32m✓ Clean completed\033[0m\n"
    @echo ""

# Build the guard binary
build:
    @echo ""
    @printf "\033[0;34m=== Building guard ===\033[0m\n"
    @mkdir -p bin
    @go build -ldflags="-X main.version=$(git describe --tags --dirty 2>/dev/null || echo dev)" -o bin/guard ./cmd/guard
    @[ "$(uname)" = "Darwin" ] && codesign -fs - bin/guard 2>/dev/null || true
    @printf "\033[0;32m✓ Built: ./bin/guard\033[0m\n"
    @echo ""

# Build and run the guard binary
# Pass arguments via: just run -- --flag
run: build
    @echo ""
    @printf "\033[0;34m=== Running guard ===\033[0m\n"
    ./bin/guard
    @echo ""

# Format Go code
code-fmt:
    @echo ""
    @printf "\033[0;34m=== Formatting Go code ===\033[0m\n"
    go fmt ./...
    @printf "\033[0;32m✓ Code formatted\033[0m\n"
    @echo ""

# Run linter
# Falls back to go vet if golangci-lint is not installed
code-lint:
    @echo ""
    @printf "\033[0;34m=== Running linter ===\033[0m\n"
    @command -v golangci-lint >/dev/null 2>&1 && \
        GOLANGCI_LINT_CACHE="${GOLANGCI_LINT_CACHE:-/tmp/golangci-lint-cache}" golangci-lint run || \
        go vet ./...
    @printf "\033[0;32m✓ Lint check passed\033[0m\n"
    @echo ""

# Run ShellCheck over shell scripts
code-shellcheck:
    @echo ""
    @printf "\033[0;34m=== Running ShellCheck ===\033[0m\n"
    @command -v shellcheck >/dev/null 2>&1 || { printf "\033[0;31m✗ shellcheck not found - install with: brew install shellcheck\033[0m\n"; exit 1; }
    @SCRIPT_COUNT=$(find tests -name '*.sh' -type f | wc -l | tr -d ' '); printf "Checking %s shell scripts under tests/\n" "$SCRIPT_COUNT"
    @printf "Options: %s\n" "{{shellcheck_flags}}"
    @find tests -name '*.sh' -type f -print0 | sort -z | xargs -0 shellcheck {{shellcheck_flags}}
    @printf "\033[0;32m✓ ShellCheck passed\033[0m\n"
    @echo ""

# Run Semgrep static analysis
# Installs Semgrep if not available and runs custom security rules
code-semgrep:
    @echo ""
    @printf "\033[0;34m=== Running Semgrep static analysis ===\033[0m\n"
    @command -v semgrep >/dev/null 2>&1 || { echo "Installing Semgrep..."; pip3 install semgrep 2>/dev/null || pip install semgrep; }
    @CA_BUNDLE="${SSL_CERT_FILE:-}"; \
        if [ -z "$CA_BUNDLE" ]; then \
            if [ -f /etc/ssl/cert.pem ]; then \
                CA_BUNDLE="/etc/ssl/cert.pem"; \
            elif [ -f /etc/ssl/certs/ca-certificates.crt ]; then \
                CA_BUNDLE="/etc/ssl/certs/ca-certificates.crt"; \
            elif [ "$(uname)" = "Darwin" ] && command -v security >/dev/null 2>&1; then \
                CA_BUNDLE="/tmp/guard-ca-bundle.pem"; \
                security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > "$CA_BUNDLE" || true; \
            fi; \
        fi; \
        SEMGREP_LOG_FILE="/tmp/semgrep.log"; \
        XDG_CONFIG_HOME="/tmp"; \
        XDG_CACHE_HOME="/tmp"; \
        if [ -n "$CA_BUNDLE" ] && [ -f "$CA_BUNDLE" ]; then \
            SSL_CERT_FILE="$CA_BUNDLE" SEMGREP_LOG_FILE="$SEMGREP_LOG_FILE" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" semgrep --config .semgrep.yml --error; \
        else \
            SEMGREP_LOG_FILE="$SEMGREP_LOG_FILE" XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" semgrep --config .semgrep.yml --error; \
        fi
    @printf "\033[0;32m✓ Semgrep check passed\033[0m\n"
    @echo ""

# Check cyclomatic complexity (threshold: 50)
# Measures the number of linearly independent paths through code
# High values indicate functions that are hard to test and maintain
# Note: Threshold set to baseline current codebase; lower over time (target: 15)
code-cyclo:
    @echo ""
    @printf "\033[0;34m=== Checking cyclomatic complexity ===\033[0m\n"
    @command -v gocyclo >/dev/null 2>&1 || { echo "Installing gocyclo..."; go install github.com/fzipp/gocyclo/cmd/gocyclo@latest; }
    @gocyclo -over 50 .
    @printf "\033[0;32m✓ Cyclomatic complexity check passed\033[0m\n"
    @echo ""

# Check cognitive complexity (threshold: 120)
# Measures how difficult code is for humans to understand
# Penalizes nesting, breaks in flow, and recursion
# Note: Threshold set to baseline current codebase; lower over time (target: 15)
code-cognit:
    @echo ""
    @printf "\033[0;34m=== Checking cognitive complexity ===\033[0m\n"
    @command -v gocognit >/dev/null 2>&1 || { echo "Installing gocognit..."; go install github.com/uudashr/gocognit/cmd/gocognit@latest; }
    @gocognit -over 120 .
    @printf "\033[0;32m✓ Cognitive complexity check passed\033[0m\n"
    @echo ""

# Tidy module dependencies
code-tidy:
    @echo ""
    @printf "\033[0;34m=== Tidying module dependencies ===\033[0m\n"
    go mod tidy
    @printf "\033[0;32m✓ Dependencies tidied\033[0m\n"
    @echo ""

# Print current version
version:
    @echo ""
    @git describe --tags --always --dirty
    @echo ""

# Show dependencies
deps:
    @echo ""
    go list -m all
    @echo ""

# Build optimized release binary for current platform
# Strips debug symbols (-s -w) and disables CGO for a smaller, more portable binary
# Output: ./bin/[version]/[os]-[arch]/guard
release:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    printf "\033[0;34m=== Building release binary ===\033[0m\n"
    VERSION=$(git describe --tags --always)
    OS=$(go env GOOS)
    ARCH=$(go env GOARCH)
    OUTPUT_DIR="./bin/${VERSION}/${OS}-${ARCH}"
    mkdir -p "${OUTPUT_DIR}"
    echo "Building guard ${VERSION} for ${OS}-${ARCH}..."
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o "${OUTPUT_DIR}/guard" ./cmd/guard
    printf "\033[0;32m✓ Built: %s/guard\033[0m\n" "${OUTPUT_DIR}"
    ls -lh "${OUTPUT_DIR}/guard"
    echo ""

# Build optimized release binaries for all platforms
# Strips debug symbols (-s -w) and disables CGO for smaller, portable binaries
# Output: ./bin/[version]/[os]-[arch]/guard for each platform
release-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    printf "\033[0;34m=== Building release binaries for all platforms ===\033[0m\n"
    VERSION=$(git describe --tags --always)

    # Define platforms to build for
    PLATFORMS=(
        "darwin/amd64"
        "darwin/arm64"
        "linux/amd64"
        "linux/arm64"
        "freebsd/amd64"
    )

    echo "Building guard ${VERSION} for all platforms..."
    echo ""

    for PLATFORM in "${PLATFORMS[@]}"; do
        OS="${PLATFORM%/*}"
        ARCH="${PLATFORM#*/}"
        OUTPUT_DIR="./bin/${VERSION}/${OS}-${ARCH}"
        mkdir -p "${OUTPUT_DIR}"

        echo "Building for ${OS}-${ARCH}..."
        CGO_ENABLED=0 GOOS="${OS}" GOARCH="${ARCH}" go build \
            -ldflags="-s -w -X main.version=${VERSION}" \
            -o "${OUTPUT_DIR}/guard" \
            ./cmd/guard

        printf "\033[0;32m✓ Built: %s/guard\033[0m\n" "${OUTPUT_DIR}"
    done

    echo ""
    printf "\033[0;32m✓ All binaries built successfully!\033[0m\n"
    echo "Output directory: ./bin/${VERSION}/"
    ls -lh ./bin/${VERSION}/*/guard
    echo ""

# Interactive version bumping and tagging
# Shows current version and prompts to bump major, minor, or patch
tag:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    printf "\033[0;34m=== Version bumping and tagging ===\033[0m\n"

    # Get current version from tags
    CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    if [ -z "$CURRENT" ]; then
        echo "No tags found. Current version: v0.0.0 (untagged)"
        MAJOR=0
        MINOR=0
        PATCH=0
    else
        # Extract version numbers (strip v prefix)
        VERSION=${CURRENT#v}

        # Parse major.minor.patch
        IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

        # Default to 0 if empty
        MAJOR=${MAJOR:-0}
        MINOR=${MINOR:-0}
        PATCH=${PATCH:-0}

        echo "Current version: v$MAJOR.$MINOR.$PATCH"
    fi

    echo ""
    echo "What would you like to bump?"
    echo "  1) Major version (v$MAJOR.$MINOR.$PATCH -> v$((MAJOR+1)).0.0)"
    echo "  2) Minor version (v$MAJOR.$MINOR.$PATCH -> v$MAJOR.$((MINOR+1)).0)"
    echo "  3) Patch version (v$MAJOR.$MINOR.$PATCH -> v$MAJOR.$MINOR.$((PATCH+1)))"
    echo "  4) Cancel"
    echo ""
    read -p "Enter choice [1-4]: " CHOICE

    case $CHOICE in
        1)
            NEW_VERSION="v$((MAJOR+1)).0.0"
            ;;
        2)
            NEW_VERSION="v$MAJOR.$((MINOR+1)).0"
            ;;
        3)
            NEW_VERSION="v$MAJOR.$MINOR.$((PATCH+1))"
            ;;
        4)
            echo "Cancelled"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac

    echo ""
    echo "New version will be: $NEW_VERSION"
    echo ""
    read -p "Enter release notes (or press Enter for default message): " NOTES
    if [ -z "$NOTES" ]; then
        NOTES="Release $NEW_VERSION"
    fi

    echo ""
    read -p "Create annotated tag '$NEW_VERSION'? [y/N]: " CONFIRM

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        git tag -a "$NEW_VERSION" -m "$NOTES"
        echo ""
        printf "\033[0;32m✓ Created tag: %s\033[0m\n" "$NEW_VERSION"
        echo ""
        echo "Next steps:"
        echo "  git push origin main"
        echo "  git push origin $NEW_VERSION"
    else
        echo "Cancelled"
    fi
    echo ""

# Run all tests (Go unit + CLI + TUI)
test: build install
    #!/usr/bin/env bash
    set -e
    echo ""
    printf "\033[0;34m=== Running Tests ===\033[0m\n"
    go fmt ./...
    go test -v ./...
    printf "\033[0;34m=== Running shell-based tests ===\033[0m\n"
    chmod +x tests/*.sh
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    export PATH="$INSTALL_BIN:$PATH"
    (cd tests && ./run-cli-tests-sequential.sh)
    (cd tests && SKIP_CLI_PREREQ=1 ./run-tui-tests-parallel.sh)
    printf "\033[0;32m✓ All tests passed\033[0m\n"
    echo ""

# Run every test individually and report only the failing ones
show-failing-tests:
    @echo ""
    @printf "\033[0;34m=== Reporting Failing Tests ===\033[0m\n"
    @chmod +x tests/show-failing-tests.sh
    ./tests/show-failing-tests.sh
    @echo ""

# Run all tests and checks (CI pipeline)
# Runs: code-fmt, code-lint, code-semgrep, complexity checks, test, and code-shellcheck
ci:
    #!/usr/bin/env bash
    set -euo pipefail
    export GOCACHE="${GOCACHE:-/tmp/go-build-cache}"
    export GOLANGCI_LINT_CACHE="${GOLANGCI_LINT_CACHE:-/tmp/golangci-lint-cache}"
    # Clear the shared test workspace so stale fixtures can't poison tooling.
    rm -rf .tmp
    echo ""
    printf "\033[0;34m=== Running CI Checks ===\033[0m\n"
    START_TIME=$(date +%s)
    just code-fmt
    just code-lint
    just code-semgrep
    just code-cyclo
    just code-cognit
    just test
    just code-shellcheck
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    printf "\033[0;32m✓ All CI checks passed!\033[0m\n"
    echo "Time elapsed: ${ELAPSED} seconds"
    echo ""

# Run all tests and checks with minimal output
# Only shows passed checks and error messages on failure
ci-quiet:
    #!/usr/bin/env bash
    set -euo pipefail
    # Clear the shared test workspace so stale fixtures can't poison tooling.
    rm -rf .tmp
    START_TIME=$(date +%s)
    echo ""
    printf "\033[0;34m=== Running CI Checks (Quiet Mode) ===\033[0m\n"

    # Run fmt
    if OUTPUT=$(go fmt ./... 2>&1); then
        printf "\033[0;32m✓ Format check passed\033[0m\n"
    else
        printf "\033[0;31m✗ Format check failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Run lint
    if command -v golangci-lint >/dev/null 2>&1; then
        if OUTPUT=$(golangci-lint run 2>&1); then
            printf "\033[0;32m✓ Lint check passed\033[0m\n"
        else
            printf "\033[0;31m✗ Lint check failed:\033[0m\n"
            echo "$OUTPUT"
            exit 1
        fi
    else
        if OUTPUT=$(go vet ./... 2>&1); then
            printf "\033[0;32m✓ Lint check passed\033[0m\n"
        else
            printf "\033[0;31m✗ Lint check failed:\033[0m\n"
            echo "$OUTPUT"
            exit 1
        fi
    fi

    # Run semgrep
    if ! command -v semgrep >/dev/null 2>&1; then
        echo "Installing Semgrep..."
        pip3 install semgrep 2>/dev/null || pip install semgrep
    fi
    if OUTPUT=$(semgrep --config .semgrep.yml --error --quiet 2>&1); then
        printf "\033[0;32m✓ Semgrep check passed\033[0m\n"
    else
        printf "\033[0;31m✗ Semgrep check failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Run cyclomatic complexity check
    if ! command -v gocyclo >/dev/null 2>&1; then
        echo "Installing gocyclo..."
        go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
    fi
    if OUTPUT=$(gocyclo -over 50 . 2>&1); then
        printf "\033[0;32m✓ Cyclomatic complexity check passed\033[0m\n"
    else
        printf "\033[0;31m✗ Cyclomatic complexity check failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Run cognitive complexity check
    if ! command -v gocognit >/dev/null 2>&1; then
        echo "Installing gocognit..."
        go install github.com/uudashr/gocognit/cmd/gocognit@latest
    fi
    if OUTPUT=$(gocognit -over 120 . 2>&1); then
        printf "\033[0;32m✓ Cognitive complexity check passed\033[0m\n"
    else
        printf "\033[0;31m✗ Cognitive complexity check failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Build
    if OUTPUT=$(just build 2>&1); then
        printf "\033[0;32m✓ Build passed\033[0m\n"
    else
        printf "\033[0;31m✗ Build failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Install
    if OUTPUT=$(just install 2>&1); then
        printf "\033[0;32m✓ Install passed\033[0m\n"
    else
        printf "\033[0;31m✗ Install failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Run Go tests
    if OUTPUT=$(go test -v ./... 2>&1 | grep -E '(PASS|FAIL|ok|FAIL)'); then
        FAIL_COUNT=$(echo "$OUTPUT" | grep -c "FAIL" || true)
        if [ "$FAIL_COUNT" -eq 0 ]; then
            printf "\033[0;32m✓ Go tests passed\033[0m\n"
        else
            printf "\033[0;31m✗ Go tests failed:\033[0m\n"
            echo "$OUTPUT"
            exit 1
        fi
    else
        printf "\033[0;31m✗ Go tests failed\033[0m\n"
        exit 1
    fi

    # Run shell tests
    chmod +x tests/*.sh
    if OUTPUT=$(cd tests && ./run-cli-tests-sequential.sh 2>&1); then
        printf "\033[0;32m✓ CLI tests passed\033[0m\n"
    else
        printf "\033[0;31m✗ CLI tests failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    if OUTPUT=$(cd tests && SKIP_CLI_PREREQ=1 ./run-tui-tests-parallel.sh 2>&1); then
        printf "\033[0;32m✓ TUI tests passed\033[0m\n"
    else
        printf "\033[0;31m✗ TUI tests failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    # Run ShellCheck last because scanning the shell test suite is comparatively slow.
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf "\033[0;31m✗ ShellCheck failed: shellcheck not found - install with: brew install shellcheck\033[0m\n"
        exit 1
    fi
    if OUTPUT=$(find tests -name '*.sh' -type f -print0 | sort -z | xargs -0 shellcheck {{shellcheck_flags}} 2>&1); then
        printf "\033[0;32m✓ ShellCheck passed\033[0m\n"
    else
        printf "\033[0;31m✗ ShellCheck failed:\033[0m\n"
        echo "$OUTPUT"
        exit 1
    fi

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    printf "\033[0;32m✓ All CI checks passed!\033[0m\n"
    echo "Time elapsed: ${ELAPSED} seconds"
    echo ""

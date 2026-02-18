# Guard - File Permission Management Tool

# Default recipe to display help
default:
    @just help

# Display help information
help:
    @echo ""
    @echo "Guard - File Permission Management Tool"
    @echo ""
    @echo "Commands:"
    @echo "  just build     - Build the guard binary"
    @echo "  just run       - Build and run the guard binary"
    @echo "  just test      - Format, build, install, and run tests with coverage"
    @echo "  just install   - Install guard to GOPATH/bin"
    @echo "  just uninstall - Remove guard from GOPATH/bin"
    @echo "  just clean     - Remove build artifacts"
    @echo "  just check     - Check prerequisites"
    @echo "  just fmt       - Format Go code"
    @echo "  just lint      - Run linter"
    @echo "  just semgrep   - Run Semgrep static analysis"
    @echo "  just cyclo     - Check cyclomatic complexity"
    @echo "  just cognit    - Check cognitive complexity"
    @echo "  just tidy      - Tidy module dependencies"
    @echo "  just ci        - Run all tests and checks (fmt, lint, semgrep, complexity, test)"
    @echo "  just ci-quiet  - Run all tests and checks with minimal output"
    @echo "  just release   - Build optimized release binary for current platform"
    @echo "  just release-all - Build optimized release binaries for all platforms"
    @echo "  just deps      - Show dependencies"
    @echo "  just version   - Print current version"
    @echo "  just tag       - Interactive version bumping and tagging"
    @echo ""

# Build the guard binary
build:
    @echo ""
    @echo "Building guard..."
    @mkdir -p bin
    @go build -ldflags="-X main.version=$(git describe --tags --dirty 2>/dev/null || echo dev)" -o bin/guard ./cmd/guard
    @[ "$(uname)" = "Darwin" ] && codesign -fs - bin/guard 2>/dev/null || true
    @echo "✓ Built: ./bin/guard"
    @echo ""

# Build and run the guard binary
# Pass arguments via: just run -- --flag
run: build
    @echo ""
    ./bin/guard
    @echo ""

# Run tests
test: build install
    #!/usr/bin/env bash
    set -e
    echo ""
    go fmt ./...
    go test -v ./...
    echo "Running shell-based tests..."
    chmod +x tests/*.sh
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    export PATH="$INSTALL_BIN:$PATH"
    (cd tests && ./run-cli-tests-sequential.sh)
    (cd tests && SKIP_CLI_PREREQ=1 ./run-tui-tests-parallel.sh)
    echo ""

# Install guard to GOPATH/bin
install: build
    #!/usr/bin/env bash
    set -e
    echo ""
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    mkdir -p "$INSTALL_BIN"
    echo "Installing guard to $INSTALL_BIN..."
    GOBIN="$INSTALL_BIN" go install -ldflags="-X main.version=$(git describe --tags --dirty 2>/dev/null || echo dev)" ./cmd/guard
    if [ "$(uname)" = "Darwin" ]; then codesign -fs - "$INSTALL_BIN/guard" 2>/dev/null || true; fi
    echo "✓ Installed: $INSTALL_BIN/guard"
    echo ""

# Remove guard from GOPATH/bin
uninstall:
    #!/usr/bin/env bash
    echo ""
    INSTALL_BIN="${GOBIN:-$(go env GOPATH)/bin}"
    if [ -z "${GOBIN:-}" ] && [ ! -w "$INSTALL_BIN" ]; then
        INSTALL_BIN="/tmp/guard-bin"
    fi
    GUARD_PATH="$INSTALL_BIN/guard"
    if [ -f "$GUARD_PATH" ]; then
        rm -f "$GUARD_PATH"
        echo "✓ Uninstalled: $GUARD_PATH"
    else
        echo "Not installed: $GUARD_PATH"
    fi
    echo ""

# Remove build artifacts
clean:
    @echo ""
    rm -f guard
    rm -rf ./bin ./reports
    go clean ./...
    @echo ""

# Check prerequisites
check:
    @echo ""
    @echo "Checking required dependencies..."
    @echo ""
    @command -v go >/dev/null 2>&1 && echo "✓ go $(go version | awk '{print $3}')" || { echo "✗ go not found - install from https://golang.org/"; exit 1; }
    @command -v git >/dev/null 2>&1 && echo "✓ git $(git --version | awk '{print $3}')" || { echo "✗ git not found - install from https://git-scm.com/"; exit 1; }
    @command -v bash >/dev/null 2>&1 && echo "✓ bash $(bash --version | head -n1 | awk '{print $4}')" || { echo "✗ bash not found"; exit 1; }
    @command -v sed >/dev/null 2>&1 && echo "✓ sed" || { echo "✗ sed not found"; exit 1; }
    @command -v awk >/dev/null 2>&1 && echo "✓ awk" || { echo "✗ awk not found"; exit 1; }
    @command -v grep >/dev/null 2>&1 && echo "✓ grep" || { echo "✗ grep not found"; exit 1; }
    @command -v find >/dev/null 2>&1 && echo "✓ find" || { echo "✗ find not found"; exit 1; }
    @command -v sort >/dev/null 2>&1 && echo "✓ sort" || { echo "✗ sort not found"; exit 1; }
    @command -v mktemp >/dev/null 2>&1 && echo "✓ mktemp" || { echo "✗ mktemp not found"; exit 1; }
    @echo ""
    @echo "Checking optional dependencies..."
    @echo ""
    @command -v golangci-lint >/dev/null 2>&1 && echo "✓ golangci-lint (optional)" || echo "⚠ golangci-lint not found (optional - will use go vet instead)"
    @command -v semgrep >/dev/null 2>&1 && echo "✓ semgrep (optional)" || echo "⚠ semgrep not found (optional - install with: pip3 install semgrep)"
    @command -v gocyclo >/dev/null 2>&1 && echo "✓ gocyclo (optional)" || echo "⚠ gocyclo not found (optional - will be auto-installed when needed)"
    @command -v gocognit >/dev/null 2>&1 && echo "✓ gocognit (optional)" || echo "⚠ gocognit not found (optional - will be auto-installed when needed)"
    @command -v tmux >/dev/null 2>&1 && echo "✓ tmux (required for TUI tests)" || echo "⚠ tmux not found (required for TUI tests - install with: brew install tmux)"
    @echo ""
    @echo "All required dependencies are available!"
    @echo ""

# Format Go code
fmt:
    @echo ""
    go fmt ./...
    @echo ""

# Run linter
# Falls back to go vet if golangci-lint is not installed
lint:
    @echo ""
    @command -v golangci-lint >/dev/null 2>&1 && \
        GOLANGCI_LINT_CACHE="${GOLANGCI_LINT_CACHE:-/tmp/golangci-lint-cache}" golangci-lint run || \
        go vet ./...
    @echo ""

# Run Semgrep static analysis
# Installs Semgrep if not available and runs custom security rules
semgrep:
    @echo ""
    @echo "Running Semgrep code analysis..."
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
    @echo ""

# Check cyclomatic complexity (threshold: 50)
# Measures the number of linearly independent paths through code
# High values indicate functions that are hard to test and maintain
# Note: Threshold set to baseline current codebase; lower over time (target: 15)
cyclo:
    @echo ""
    @echo "Running cyclomatic complexity analysis..."
    @command -v gocyclo >/dev/null 2>&1 || { echo "Installing gocyclo..."; go install github.com/fzipp/gocyclo/cmd/gocyclo@latest; }
    @gocyclo -over 50 .
    @echo "✓ Cyclomatic complexity check passed"
    @echo ""

# Check cognitive complexity (threshold: 120)
# Measures how difficult code is for humans to understand
# Penalizes nesting, breaks in flow, and recursion
# Note: Threshold set to baseline current codebase; lower over time (target: 15)
cognit:
    @echo ""
    @echo "Running cognitive complexity analysis..."
    @command -v gocognit >/dev/null 2>&1 || { echo "Installing gocognit..."; go install github.com/uudashr/gocognit/cmd/gocognit@latest; }
    @gocognit -over 120 .
    @echo "✓ Cognitive complexity check passed"
    @echo ""

# Tidy module dependencies
tidy:
    @echo ""
    go mod tidy
    @echo ""

# Run all tests and checks (CI pipeline)
# Runs: fmt, lint, semgrep, complexity checks, and test
ci:
    #!/usr/bin/env bash
    set -euo pipefail
    export GOCACHE="${GOCACHE:-/tmp/go-build-cache}"
    export GOLANGCI_LINT_CACHE="${GOLANGCI_LINT_CACHE:-/tmp/golangci-lint-cache}"
    START_TIME=$(date +%s)
    just fmt
    just lint
    just semgrep
    just cyclo
    just cognit
    just test
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    echo "✓ All CI checks passed!"
    echo "Time elapsed: ${ELAPSED} seconds"
    echo ""

# Run all tests and checks with minimal output
# Only shows passed checks and error messages on failure
ci-quiet:
    #!/usr/bin/env bash
    set -euo pipefail
    START_TIME=$(date +%s)
    echo ""

    # Run fmt
    if OUTPUT=$(go fmt ./... 2>&1); then
        echo "✓ Format check passed"
    else
        echo "✗ Format check failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Run lint
    if command -v golangci-lint >/dev/null 2>&1; then
        if OUTPUT=$(golangci-lint run 2>&1); then
            echo "✓ Lint check passed"
        else
            echo "✗ Lint check failed:"
            echo "$OUTPUT"
            exit 1
        fi
    else
        if OUTPUT=$(go vet ./... 2>&1); then
            echo "✓ Lint check passed"
        else
            echo "✗ Lint check failed:"
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
        echo "✓ Semgrep check passed"
    else
        echo "✗ Semgrep check failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Run cyclomatic complexity check
    if ! command -v gocyclo >/dev/null 2>&1; then
        echo "Installing gocyclo..."
        go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
    fi
    if OUTPUT=$(gocyclo -over 50 . 2>&1); then
        echo "✓ Cyclomatic complexity check passed"
    else
        echo "✗ Cyclomatic complexity check failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Run cognitive complexity check
    if ! command -v gocognit >/dev/null 2>&1; then
        echo "Installing gocognit..."
        go install github.com/uudashr/gocognit/cmd/gocognit@latest
    fi
    if OUTPUT=$(gocognit -over 120 . 2>&1); then
        echo "✓ Cognitive complexity check passed"
    else
        echo "✗ Cognitive complexity check failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Build
    if OUTPUT=$(just build 2>&1); then
        echo "✓ Build passed"
    else
        echo "✗ Build failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Install
    if OUTPUT=$(just install 2>&1); then
        echo "✓ Install passed"
    else
        echo "✗ Install failed:"
        echo "$OUTPUT"
        exit 1
    fi

    # Run Go tests
    if OUTPUT=$(go test -v ./... 2>&1 | grep -E '(PASS|FAIL|ok|FAIL)'); then
        FAIL_COUNT=$(echo "$OUTPUT" | grep -c "FAIL" || true)
        if [ "$FAIL_COUNT" -eq 0 ]; then
            echo "✓ Go tests passed"
        else
            echo "✗ Go tests failed:"
            echo "$OUTPUT"
            exit 1
        fi
    else
        echo "✗ Go tests failed"
        exit 1
    fi

    # Run shell tests
    chmod +x tests/*.sh
    if OUTPUT=$(cd tests && ./run-cli-tests-sequential.sh 2>&1); then
        echo "✓ CLI tests passed"
    else
        echo "✗ CLI tests failed:"
        echo "$OUTPUT"
        exit 1
    fi

    if OUTPUT=$(cd tests && SKIP_CLI_PREREQ=1 ./run-tui-tests-parallel.sh 2>&1); then
        echo "✓ TUI tests passed"
    else
        echo "✗ TUI tests failed:"
        echo "$OUTPUT"
        exit 1
    fi

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    echo ""
    echo "✓ All CI checks passed!"
    echo "Time elapsed: ${ELAPSED} seconds"
    echo ""

# Build optimized release binary for current platform
# Strips debug symbols (-s -w) and disables CGO for a smaller, more portable binary
# Output: ./bin/[version]/[os]-[arch]/guard
release:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
    VERSION=$(git describe --tags --always)
    OS=$(go env GOOS)
    ARCH=$(go env GOARCH)
    OUTPUT_DIR="./bin/${VERSION}/${OS}-${ARCH}"
    mkdir -p "${OUTPUT_DIR}"
    echo "Building guard ${VERSION} for ${OS}-${ARCH}..."
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o "${OUTPUT_DIR}/guard" ./cmd/guard
    echo "✓ Built: ${OUTPUT_DIR}/guard"
    ls -lh "${OUTPUT_DIR}/guard"
    echo ""

# Build optimized release binaries for all platforms
# Strips debug symbols (-s -w) and disables CGO for smaller, portable binaries
# Output: ./bin/[version]/[os]-[arch]/guard for each platform
release-all:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""
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

        echo "✓ Built: ${OUTPUT_DIR}/guard"
    done

    echo ""
    echo "All binaries built successfully!"
    echo "Output directory: ./bin/${VERSION}/"
    ls -lh ./bin/${VERSION}/*/guard
    echo ""

# Show dependencies
deps:
    @echo ""
    go list -m all
    @echo ""

# Print current version
version:
    @echo ""
    @git describe --tags --always --dirty
    @echo ""

# Interactive version bumping and tagging
# Shows current version and prompts to bump major, minor, or patch
tag:
    #!/usr/bin/env bash
    set -euo pipefail
    echo ""

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
        echo "✓ Created tag: $NEW_VERSION"
        echo ""
        echo "Next steps:"
        echo "  git push origin main"
        echo "  git push origin $NEW_VERSION"
    else
        echo "Cancelled"
    fi
    echo ""

package tui

import (
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/florianbuetow/guard/internal/manager"
)

// Run starts the TUI application
// It loads the .guardfile from the current directory and displays the interactive interface
func Run() error {
	// Get current working directory
	cwd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("failed to get current directory: %w", err)
	}

	// Check for .guardfile
	guardfilePath := filepath.Join(cwd, ".guardfile")
	if _, err := os.Stat(guardfilePath); os.IsNotExist(err) {
		return fmt.Errorf(".guardfile not found in current directory. Run 'guard init <mode> <owner> <group>' to initialize")
	}

	// Create manager and load registry
	mgr := manager.NewManager(guardfilePath)
	if err := mgr.LoadRegistry(); err != nil {
		return fmt.Errorf("failed to load registry: %w", err)
	}

	// Create the app
	app, err := NewApp(cwd, mgr)
	if err != nil {
		return fmt.Errorf("failed to create TUI: %w", err)
	}

	// Create the Bubble Tea program
	p := tea.NewProgram(
		app,
		tea.WithAltScreen(),       // Use alternate screen buffer
		tea.WithMouseCellMotion(), // Enable mouse support
	)

	// Run the program
	if _, err := p.Run(); err != nil {
		return fmt.Errorf("TUI error: %w", err)
	}

	return nil
}

// RunWithPath starts the TUI application with a specific root path
func RunWithPath(rootPath string) error {
	// Resolve absolute path
	absPath, err := filepath.Abs(rootPath)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}

	// Check if path exists
	info, err := os.Stat(absPath)
	if err != nil {
		return fmt.Errorf("path does not exist: %s", absPath)
	}

	// If it's a file, use its directory
	if !info.IsDir() {
		absPath = filepath.Dir(absPath)
	}

	// Check for .guardfile in the directory or parent directories
	guardfilePath, err := findGuardfile(absPath)
	if err != nil {
		return err
	}

	// Create manager and load registry
	mgr := manager.NewManager(guardfilePath)
	if err := mgr.LoadRegistry(); err != nil {
		return fmt.Errorf("failed to load registry: %w", err)
	}

	// Create the app (use guardfile directory as root)
	guardfileDir := filepath.Dir(guardfilePath)
	app, err := NewApp(guardfileDir, mgr)
	if err != nil {
		return fmt.Errorf("failed to create TUI: %w", err)
	}

	// Create the Bubble Tea program
	p := tea.NewProgram(
		app,
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)

	// Run the program
	if _, err := p.Run(); err != nil {
		return fmt.Errorf("TUI error: %w", err)
	}

	return nil
}

// findGuardfile searches for .guardfile in the given directory and parent directories
func findGuardfile(startPath string) (string, error) {
	current := startPath

	for {
		guardfilePath := filepath.Join(current, ".guardfile")
		if _, err := os.Stat(guardfilePath); err == nil {
			return guardfilePath, nil
		}

		parent := filepath.Dir(current)
		if parent == current {
			// Reached root
			break
		}
		current = parent
	}

	return "", fmt.Errorf(".guardfile not found in %s or any parent directory. Run 'guard init <mode> <owner> <group>' to initialize", startPath)
}

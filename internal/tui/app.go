package tui

import (
	"fmt"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/florianbuetow/guard/internal/manager"
)

// FocusTarget represents which element currently has keyboard focus.
type FocusTarget int

const (
	FocusFiles FocusTarget = iota
	FocusCollections
	FocusSearch
)

// App is the root Bubble Tea model for the Guard TUI
type App struct {
	filesPanel       FilesPanel
	collectionsPanel CollectionsPanel
	statusBar        StatusBar
	errorModal       ErrorModal
	searchBox        SearchBox

	activePanel Panel
	focus       FocusTarget
	width       int
	height      int
	styles      *Styles
	keys        KeyMap
	mgr         *manager.Manager
	rootPath    string

	quitting bool
}

// NewApp creates a new App model
func NewApp(rootPath string, mgr *manager.Manager) (App, error) {
	styles := DefaultStyles()
	keys := DefaultKeyMap()

	// Build the file tree
	root, err := BuildFileTree(rootPath, mgr)
	if err != nil {
		return App{}, fmt.Errorf("failed to build file tree: %w", err)
	}

	// Update guard states for all nodes (including collapsed folders)
	UpdateGuardStates(root, mgr)

	app := App{
		filesPanel:       NewFilesPanel(root, mgr, styles, keys),
		collectionsPanel: NewCollectionsPanel(mgr, styles, keys),
		statusBar:        NewStatusBar(styles, keys),
		errorModal:       NewErrorModal(styles),
		searchBox:        NewSearchBox(),
		activePanel:      PanelFiles,
		focus:            FocusFiles,
		styles:           styles,
		keys:             keys,
		mgr:              mgr,
		rootPath:         rootPath,
	}

	// Set initial focus
	app.filesPanel.SetFocused(true)
	app.collectionsPanel.SetFocused(false)

	return app, nil
}

// Init initializes the app
func (a App) Init() tea.Cmd {
	return tea.Batch(
		a.filesPanel.Init(),
		a.collectionsPanel.Init(),
		a.statusBar.Init(),
		a.errorModal.Init(),
		a.searchBox.Init(),
	)
}

// Update handles messages
func (a App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		a.width = msg.Width
		a.height = msg.Height

		// Update panel sizes
		a.updateLayout()

		// Forward to children
		sizeMsg := WindowSizeMsg{Width: msg.Width, Height: msg.Height}
		a.filesPanel, _ = a.filesPanel.Update(sizeMsg)
		a.collectionsPanel, _ = a.collectionsPanel.Update(sizeMsg)
		a.statusBar, _ = a.statusBar.Update(sizeMsg)
		a.errorModal, _ = a.errorModal.Update(sizeMsg)

	case tea.KeyMsg:
		// Priority 1: Error modal captures all keys
		if a.errorModal.IsVisible() {
			a.errorModal, _ = a.errorModal.Update(msg)
			return a, nil
		}

		// Priority 2: Tab always cycles focus (even when search is active)
		if matchAppKey(msg, a.keys.SwitchPanel) {
			cmd := a.cycleFocus()
			return a, cmd
		}

		// Priority 3: '/' activates search and gives it focus
		if matchAppKey(msg, a.keys.Search) && a.focus != FocusSearch {
			cmd := a.searchBox.SetActive(true)
			a.focus = FocusSearch
			a.filesPanel.SetFocused(false)
			a.collectionsPanel.SetFocused(false)
			return a, cmd
		}

		// Priority 4: If search box has focus, route keys to it
		if a.searchBox.IsActive() && a.focus == FocusSearch {
			var cmd tea.Cmd
			a.searchBox, cmd = a.searchBox.Update(msg)
			return a, cmd
		}

		// Priority 5: Normal global keys (when a panel has focus)
		switch {
		case matchAppKey(msg, a.keys.Quit):
			a.quitting = true
			return a, tea.Quit

		case matchAppKey(msg, a.keys.Refresh):
			a.refresh()
			refreshMsg := RefreshMsg{}
			a.filesPanel, _ = a.filesPanel.Update(refreshMsg)
			a.collectionsPanel, _ = a.collectionsPanel.Update(refreshMsg)
			a.statusBar, _ = a.statusBar.Update(refreshMsg)
			return a, nil
		}

		// Priority 6: Forward to active panel
		var cmd tea.Cmd
		if a.activePanel == PanelFiles {
			a.filesPanel, cmd = a.filesPanel.Update(msg)
		} else {
			a.collectionsPanel, cmd = a.collectionsPanel.Update(msg)
		}
		cmds = append(cmds, cmd)

	case FilterChangedMsg:
		// If search was deactivated (e.g., via ESC), reset focus to files panel.
		if !a.searchBox.IsActive() && a.focus == FocusSearch {
			a.focus = FocusFiles
			a.activePanel = PanelFiles
			a.filesPanel.SetFocused(true)
			a.collectionsPanel.SetFocused(false)
		}

		// Forward to files panel to apply file tree filtering.
		var cmd tea.Cmd
		a.filesPanel, cmd = a.filesPanel.Update(msg)
		cmds = append(cmds, cmd)

	case ErrorMsg:
		a.errorModal.Show(msg.Err)
		a.errorModal, _ = a.errorModal.Update(msg)

	case GuardToggledMsg:
		// Update status bar
		a.statusBar, _ = a.statusBar.Update(msg)
		// Refresh both panels
		a.filesPanel.Refresh()
		a.collectionsPanel.Refresh()

	case RefreshMsg:
		a.filesPanel, _ = a.filesPanel.Update(msg)
		a.collectionsPanel, _ = a.collectionsPanel.Update(msg)
		a.statusBar, _ = a.statusBar.Update(msg)

	default:
		// Forward to search box for non-key messages (e.g., cursor blink)
		var cmd tea.Cmd
		a.searchBox, cmd = a.searchBox.Update(msg)
		cmds = append(cmds, cmd)

		// Forward to both panels
		a.filesPanel, cmd = a.filesPanel.Update(msg)
		cmds = append(cmds, cmd)
		a.collectionsPanel, cmd = a.collectionsPanel.Update(msg)
		cmds = append(cmds, cmd)
	}

	return a, tea.Batch(cmds...)
}

// View renders the app
func (a App) View() string {
	if a.quitting {
		return ""
	}

	// Frame takes 3 chars: left border (1) + separator (1) + right border (1)
	// Status bar takes 4 lines: junction (1) + 2 content lines + bottom border (1)
	frameHorizontalOverhead := 3
	statusBarHeight := 4
	topBorderHeight := 1
	searchBarHeight := 0

	// When search is active, reserve 2 lines for search junction + input row
	if a.searchBox.IsActive() {
		searchBarHeight = 2
	}

	// Calculate panel dimensions
	// Each panel gets half the remaining width after frame overhead
	leftWidth := (a.width - frameHorizontalOverhead) / 2
	rightWidth := a.width - frameHorizontalOverhead - leftWidth

	// Content height excludes top border, status bar, and search bar
	contentHeight := a.height - topBorderHeight - statusBarHeight - searchBarHeight

	if leftWidth < 1 {
		leftWidth = 1
	}
	if rightWidth < 1 {
		rightWidth = 1
	}
	if contentHeight < 1 {
		contentHeight = 1
	}

	// Set panel sizes (content area only, no borders)
	a.filesPanel.SetSize(leftWidth, contentHeight)
	a.collectionsPanel.SetSize(rightWidth, contentHeight)
	a.statusBar.SetWidth(a.width)

	// Get content lines from each panel
	leftContent := a.filesPanel.ContentLines()
	rightContent := a.collectionsPanel.ContentLines()
	statusLines := a.statusBar.ContentLines()
	leftTitle := a.filesPanel.Title()
	rightTitle := a.collectionsPanel.Title()
	if a.filesPanel.IsFocused() {
		leftTitle = "\033[7m" + leftTitle + "\033[0m"
	}
	if a.collectionsPanel.IsFocused() {
		rightTitle = "\033[7m" + rightTitle + "\033[0m"
	}

	// Prepare search line (empty string when inactive)
	searchLine := ""
	if a.searchBox.IsActive() {
		totalInnerWidth := leftWidth + rightWidth + 1 // +1 for separator column
		a.searchBox.SetWidth(totalInnerWidth)
		searchLine = a.searchBox.View()
	}

	// Render the unified frame
	content := RenderFrame(
		leftTitle,
		rightTitle,
		leftContent,
		rightContent,
		statusLines,
		leftWidth,
		rightWidth,
		contentHeight,
		searchLine,
	)

	// Overlay error modal if visible
	if a.errorModal.IsVisible() {
		// For simplicity, just append the modal
		// A proper implementation would overlay it
		content += "\n" + a.errorModal.View()
	}

	return content
}

// switchPanel switches the active panel
func (a *App) switchPanel() {
	if a.activePanel == PanelFiles {
		a.activePanel = PanelCollections
		a.filesPanel.SetFocused(false)
		a.collectionsPanel.SetFocused(true)
	} else {
		a.activePanel = PanelFiles
		a.filesPanel.SetFocused(true)
		a.collectionsPanel.SetFocused(false)
	}
}

// cycleFocus cycles keyboard focus between panels and search box.
// When search is active: Files -> Collections -> Search -> Files -> ...
// When search is not active: Files -> Collections -> Files -> ...
func (a *App) cycleFocus() tea.Cmd {
	if a.searchBox.IsActive() {
		switch a.focus {
		case FocusSearch:
			a.focus = FocusFiles
			a.activePanel = PanelFiles
			a.filesPanel.SetFocused(true)
			a.collectionsPanel.SetFocused(false)
			a.searchBox.Blur()
		case FocusFiles:
			a.focus = FocusCollections
			a.activePanel = PanelCollections
			a.filesPanel.SetFocused(false)
			a.collectionsPanel.SetFocused(true)
		case FocusCollections:
			a.focus = FocusSearch
			a.filesPanel.SetFocused(false)
			a.collectionsPanel.SetFocused(false)
			return a.searchBox.Focus()
		}
		return nil
	}

	a.switchPanel()
	if a.activePanel == PanelFiles {
		a.focus = FocusFiles
	} else {
		a.focus = FocusCollections
	}
	return nil
}

// refresh reloads the registry and refreshes both panels
func (a *App) refresh() {
	// Reload registry
	if a.mgr != nil {
		_ = a.mgr.LoadRegistry()
	}

	// Refresh panels
	a.filesPanel.Refresh()
	a.collectionsPanel.Refresh()
}

// updateLayout updates the layout based on current dimensions
func (a *App) updateLayout() {
	panelWidth := a.width / 2
	panelHeight := a.height - 1

	if panelWidth < 1 {
		panelWidth = 1
	}
	if panelHeight < 1 {
		panelHeight = 1
	}

	a.filesPanel.SetSize(panelWidth, panelHeight)
	a.collectionsPanel.SetSize(a.width-panelWidth, panelHeight)
	a.statusBar.SetWidth(a.width)
	a.errorModal.SetSize(a.width, a.height)
}

// matchAppKey checks if a key message matches a key binding
func matchAppKey(msg tea.KeyMsg, binding key.Binding) bool {
	for _, k := range binding.Keys() {
		if msg.String() == k {
			return true
		}
	}
	return false
}

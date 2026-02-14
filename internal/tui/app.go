package tui

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/florianbuetow/guard/internal/manager"
)

// App is the root Bubble Tea model for the Guard TUI
type App struct {
	filesPanel       FilesPanel
	collectionsPanel CollectionsPanel
	statusBar        StatusBar
	errorModal       ErrorModal

	activePanel Panel
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
		activePanel:      PanelFiles,
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
		// If error modal is visible, let it handle the key
		if a.errorModal.IsVisible() {
			a.errorModal, _ = a.errorModal.Update(msg)
			return a, nil
		}

		// Global key bindings
		switch {
		case matchKey(msg, a.keys.Quit):
			a.quitting = true
			return a, tea.Quit

		case matchKey(msg, a.keys.SwitchPanel):
			a.switchPanel()
			return a, nil

		case matchKey(msg, a.keys.Refresh):
			a.refresh()
			// Only forward refresh to panels if registry loaded successfully
			if !a.errorModal.IsVisible() {
				refreshMsg := RefreshMsg{}
				a.filesPanel, _ = a.filesPanel.Update(refreshMsg)
				a.collectionsPanel, _ = a.collectionsPanel.Update(refreshMsg)
				a.statusBar, _ = a.statusBar.Update(refreshMsg)
			}
			return a, nil
		}

		// Forward to active panel
		var cmd tea.Cmd
		if a.activePanel == PanelFiles {
			a.filesPanel, cmd = a.filesPanel.Update(msg)
		} else {
			a.collectionsPanel, cmd = a.collectionsPanel.Update(msg)
		}
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
		// Forward to both panels
		var cmd tea.Cmd
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

	// Calculate panel dimensions
	// Each panel gets half the remaining width after frame overhead
	leftWidth := (a.width - frameHorizontalOverhead) / 2
	rightWidth := a.width - frameHorizontalOverhead - leftWidth

	// Content height excludes top border and status bar area
	contentHeight := a.height - topBorderHeight - statusBarHeight

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

	// Render the unified frame
	content := RenderFrame(
		a.filesPanel.Title(),
		a.collectionsPanel.Title(),
		leftContent,
		rightContent,
		statusLines,
		leftWidth,
		rightWidth,
		contentHeight,
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

// refresh reloads the registry and refreshes both panels
func (a *App) refresh() {
	// Reload registry
	if a.mgr != nil {
		if err := a.mgr.LoadRegistry(); err != nil {
			a.errorModal.Show(err)
			return
		}
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

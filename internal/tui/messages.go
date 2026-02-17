package tui

// ErrorMsg is sent when an error occurs
type ErrorMsg struct {
	Err error
}

// RefreshMsg is sent when the TUI should refresh its state
type RefreshMsg struct{}

// GuardToggledMsg is sent when a guard state has been toggled
type GuardToggledMsg struct {
	Path          string // File path or collection name
	IsCollection  bool
	NewGuardState bool
	AffectedFiles int // Number of files affected by the toggle
}

// FileRegisteredMsg is sent when a file has been registered
type FileRegisteredMsg struct {
	Path string
}

// PanelSwitchedMsg is sent when the active panel changes
type PanelSwitchedMsg struct {
	NewPanel Panel
}

// WindowSizeMsg is sent when the window size changes
type WindowSizeMsg struct {
	Width  int
	Height int
}

// QuitMsg is sent to quit the application
type QuitMsg struct{}

// RegistryLoadedMsg is sent when the registry has been loaded
type RegistryLoadedMsg struct{}

// RegistrySavedMsg is sent when the registry has been saved
type RegistrySavedMsg struct{}

// FolderExpandedMsg is sent when a folder is expanded
type FolderExpandedMsg struct {
	Path string
}

// FolderCollapsedMsg is sent when a folder is collapsed
type FolderCollapsedMsg struct {
	Path string
}

// CursorMovedMsg is sent when the cursor position changes
type CursorMovedMsg struct {
	Index int
}

// FilterChangedMsg is sent when the search filter query changes
type FilterChangedMsg struct {
	Query string
}

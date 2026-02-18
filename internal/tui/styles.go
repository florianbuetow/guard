package tui

import (
	"github.com/charmbracelet/lipgloss"
)

// Colors used in the TUI
var (
	ColorPrimary     = lipgloss.Color("4")   // Blue
	ColorSecondary   = lipgloss.Color("8")   // Gray
	ColorSuccess     = lipgloss.Color("2")   // Green
	ColorWarning     = lipgloss.Color("3")   // Yellow
	ColorError       = lipgloss.Color("1")   // Red
	ColorHighlight   = lipgloss.Color("15")  // White
	ColorDim         = lipgloss.Color("240") // Dark gray
	ColorSymlink     = lipgloss.Color("240") // Gray for symlinks
	ColorEmpty       = lipgloss.Color("240") // Gray for empty collections
	ColorPanelBorder = lipgloss.Color("8")   // Gray
	ColorSelected    = lipgloss.Color("4")   // Blue
	ColorIgnored     = lipgloss.Color("117") // Light blue for gitignored items
)

// Styles holds all the styles used in the TUI
type Styles struct {
	// Panel styles
	PanelActive   lipgloss.Style
	PanelInactive lipgloss.Style
	PanelTitle    lipgloss.Style

	// Item styles
	ItemNormal   lipgloss.Style
	ItemSelected lipgloss.Style
	ItemSymlink  lipgloss.Style
	ItemEmpty    lipgloss.Style
	ItemFolder   lipgloss.Style
	ItemFile     lipgloss.Style

	// Guard state styles
	GuardExplicit lipgloss.Style
	GuardImplicit lipgloss.Style
	GuardMixed    lipgloss.Style
	GuardOff      lipgloss.Style
	GuardNone     lipgloss.Style

	// Ignored item styles
	ItemIgnored  lipgloss.Style
	GuardIgnored lipgloss.Style

	// Tree styles
	TreePrefix lipgloss.Style

	// Status bar styles
	StatusBar   lipgloss.Style
	StatusKey   lipgloss.Style
	StatusValue lipgloss.Style

	// Error modal styles
	ErrorTitle   lipgloss.Style
	ErrorMessage lipgloss.Style
	ErrorBorder  lipgloss.Style
}

// DefaultStyles returns the default style configuration
func DefaultStyles() *Styles {
	return &Styles{
		// Panel styles
		PanelActive: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorPrimary),
		PanelInactive: lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorPanelBorder),
		PanelTitle: lipgloss.NewStyle().
			Bold(true).
			Foreground(ColorHighlight),

		// Item styles
		ItemNormal: lipgloss.NewStyle(),
		ItemSelected: lipgloss.NewStyle().
			Background(ColorSelected).
			Foreground(ColorHighlight),
		ItemSymlink: lipgloss.NewStyle().
			Foreground(ColorSymlink).
			Italic(true),
		ItemEmpty: lipgloss.NewStyle().
			Foreground(ColorEmpty).
			Italic(true),
		ItemFolder: lipgloss.NewStyle().
			Bold(true),
		ItemFile: lipgloss.NewStyle(),

		// Guard state styles
		GuardExplicit: lipgloss.NewStyle().
			Foreground(ColorSuccess),
		GuardImplicit: lipgloss.NewStyle().
			Foreground(ColorSuccess),
		GuardMixed: lipgloss.NewStyle().
			Foreground(ColorWarning),
		GuardOff: lipgloss.NewStyle().
			Foreground(ColorSecondary),
		GuardNone: lipgloss.NewStyle().
			Foreground(ColorDim),

		// Ignored item styles
		ItemIgnored: lipgloss.NewStyle().
			Foreground(ColorIgnored),
		GuardIgnored: lipgloss.NewStyle().
			Foreground(ColorIgnored),

		// Tree styles
		TreePrefix: lipgloss.NewStyle().
			Foreground(ColorSecondary),

		// Status bar styles
		StatusBar: lipgloss.NewStyle().
			Background(lipgloss.Color("236")).
			Foreground(ColorHighlight),
		StatusKey: lipgloss.NewStyle().
			Foreground(ColorPrimary).
			Bold(true),
		StatusValue: lipgloss.NewStyle().
			Foreground(ColorSecondary),

		// Error modal styles
		ErrorTitle: lipgloss.NewStyle().
			Foreground(ColorError).
			Bold(true),
		ErrorMessage: lipgloss.NewStyle().
			Foreground(ColorHighlight),
		ErrorBorder: lipgloss.NewStyle().
			Border(lipgloss.DoubleBorder()).
			BorderForeground(ColorError).
			Padding(1, 2),
	}
}

// RenderGuardState renders the guard state with appropriate styling
func (s *Styles) RenderGuardState(state GuardState) string {
	indicator := state.String()
	switch state {
	case GuardStateExplicit:
		return s.GuardExplicit.Render(indicator)
	case GuardStateImplicit:
		return s.GuardImplicit.Render(indicator)
	case GuardStateMixed:
		return s.GuardMixed.Render(indicator)
	case GuardStateUnguarded:
		return s.GuardOff.Render(indicator)
	case GuardStateNotRegistered, GuardStateNoCollection:
		return s.GuardNone.Render(indicator)
	default:
		return s.GuardNone.Render(indicator)
	}
}

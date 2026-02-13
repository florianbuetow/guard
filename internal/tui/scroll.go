package tui

// CalculateVisibleRange calculates the start and end indices of visible items
// given the current cursor position, total item count, and viewport height.
// Returns (startIndex, endIndex) where endIndex is exclusive.
func CalculateVisibleRange(cursor, totalItems, viewportHeight int) (int, int) {
	if totalItems == 0 || viewportHeight <= 0 {
		return 0, 0
	}

	if totalItems <= viewportHeight {
		return 0, totalItems
	}

	// Calculate scroll offset to keep cursor visible
	offset := CalculateScrollOffset(cursor, totalItems, viewportHeight)
	endIndex := offset + viewportHeight
	if endIndex > totalItems {
		endIndex = totalItems
	}

	return offset, endIndex
}

// CalculateScrollOffset calculates the scroll offset needed to keep the cursor visible
func CalculateScrollOffset(cursor, totalItems, viewportHeight int) int {
	if totalItems <= viewportHeight {
		return 0
	}

	// Keep the cursor at least scrollMargin lines from the top/bottom when possible
	scrollMargin := viewportHeight / 4

	// Calculate minimum offset to keep cursor visible with margin
	minOffset := cursor - viewportHeight + scrollMargin + 1
	if minOffset < 0 {
		minOffset = 0
	}

	// Clamp to valid range
	maxPossibleOffset := totalItems - viewportHeight
	if maxPossibleOffset < 0 {
		maxPossibleOffset = 0
	}

	// Use the minimum offset that satisfies the constraints
	offset := minOffset
	if offset > maxPossibleOffset {
		offset = maxPossibleOffset
	}

	return offset
}

// ScrollState tracks the scroll position for a list
type ScrollState struct {
	Offset       int // Current scroll offset
	ViewportSize int // Number of visible items
	TotalItems   int // Total number of items
	CursorIndex  int // Current cursor position
}

// NewScrollState creates a new ScrollState
func NewScrollState(viewportSize int) *ScrollState {
	return &ScrollState{
		ViewportSize: viewportSize,
	}
}

// Update updates the scroll state based on the current cursor and total items
func (s *ScrollState) Update(cursor, totalItems int) {
	s.CursorIndex = cursor
	s.TotalItems = totalItems
	s.Offset = CalculateScrollOffset(cursor, totalItems, s.ViewportSize)
}

// GetVisibleRange returns the range of visible items
func (s *ScrollState) GetVisibleRange() (int, int) {
	return CalculateVisibleRange(s.CursorIndex, s.TotalItems, s.ViewportSize)
}

// SetViewportSize updates the viewport size
func (s *ScrollState) SetViewportSize(size int) {
	s.ViewportSize = size
	// Recalculate offset with new viewport size
	s.Offset = CalculateScrollOffset(s.CursorIndex, s.TotalItems, s.ViewportSize)
}

// IsAtTop returns true if scrolled to the top
func (s *ScrollState) IsAtTop() bool {
	return s.Offset == 0
}

// IsAtBottom returns true if scrolled to the bottom
func (s *ScrollState) IsAtBottom() bool {
	if s.TotalItems <= s.ViewportSize {
		return true
	}
	return s.Offset >= s.TotalItems-s.ViewportSize
}

// CanScrollUp returns true if there are items above the visible area
func (s *ScrollState) CanScrollUp() bool {
	return s.Offset > 0
}

// CanScrollDown returns true if there are items below the visible area
func (s *ScrollState) CanScrollDown() bool {
	return s.Offset+s.ViewportSize < s.TotalItems
}

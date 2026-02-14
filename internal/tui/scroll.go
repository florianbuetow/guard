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

	// Scroll only when cursor reaches the viewport edge (no margin)
	minOffset := cursor - viewportHeight + 1
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

// Update updates the scroll state based on the current cursor and total items.
// The offset only changes when the cursor would leave the visible area.
func (s *ScrollState) Update(cursor, totalItems int) {
	s.CursorIndex = cursor
	s.TotalItems = totalItems

	if totalItems <= s.ViewportSize {
		s.Offset = 0
		return
	}

	// Scroll down: cursor below viewport
	if cursor >= s.Offset+s.ViewportSize {
		s.Offset = cursor - s.ViewportSize + 1
	}

	// Scroll up: cursor above viewport
	if cursor < s.Offset {
		s.Offset = cursor
	}

	// Clamp offset to valid range
	maxOffset := totalItems - s.ViewportSize
	if s.Offset > maxOffset {
		s.Offset = maxOffset
	}
	if s.Offset < 0 {
		s.Offset = 0
	}
}

// GetVisibleRange returns the range of visible items using the stored offset
func (s *ScrollState) GetVisibleRange() (int, int) {
	if s.TotalItems == 0 || s.ViewportSize <= 0 {
		return 0, 0
	}
	if s.TotalItems <= s.ViewportSize {
		return 0, s.TotalItems
	}
	end := s.Offset + s.ViewportSize
	if end > s.TotalItems {
		end = s.TotalItems
	}
	return s.Offset, end
}

// SetViewportSize updates the viewport size and re-clamps the offset
func (s *ScrollState) SetViewportSize(size int) {
	if s.ViewportSize == size {
		return
	}
	s.ViewportSize = size
	// Re-run stateful update to clamp offset for new viewport size
	s.Update(s.CursorIndex, s.TotalItems)
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

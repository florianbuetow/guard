package tui

import "testing"

func TestCalculateScrollOffset_EdgeOnly(t *testing.T) {
	tests := []struct {
		name           string
		cursor         int
		totalItems     int
		viewportHeight int
		wantOffset     int
	}{
		{
			name:           "cursor at top of viewport - no scroll",
			cursor:         0,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     0,
		},
		{
			name:           "cursor in middle of viewport - no scroll",
			cursor:         5,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     0,
		},
		{
			name:           "cursor at last visible line - no scroll yet",
			cursor:         9,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     0,
		},
		{
			name:           "cursor one past viewport - scroll by 1",
			cursor:         10,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     1,
		},
		{
			name:           "cursor further down - offset keeps cursor at bottom edge",
			cursor:         15,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     6,
		},
		{
			name:           "cursor at last item - max offset",
			cursor:         29,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     20,
		},
		{
			name:           "fewer items than viewport - no scroll",
			cursor:         5,
			totalItems:     8,
			viewportHeight: 10,
			wantOffset:     0,
		},
		{
			name:           "cursor 4 lines above bottom - NO scroll (currently fails due to margin)",
			cursor:         6,
			totalItems:     30,
			viewportHeight: 10,
			wantOffset:     0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := CalculateScrollOffset(tt.cursor, tt.totalItems, tt.viewportHeight)
			if got != tt.wantOffset {
				t.Errorf("CalculateScrollOffset(%d, %d, %d) = %d, want %d",
					tt.cursor, tt.totalItems, tt.viewportHeight, got, tt.wantOffset)
			}
		})
	}
}

func TestScrollState_CursorFloatsFreely(t *testing.T) {
	// Simulates cursor moving down past viewport, then back up.
	// The cursor should float freely within the viewport without scrolling.
	// Scrolling should only happen when cursor would leave the visible area.
	s := NewScrollState(10) // viewport of 10 items
	totalItems := 30

	// Move cursor down from 0 to 14 (scrolling kicks in at cursor 10)
	for i := 0; i <= 14; i++ {
		s.Update(i, totalItems)
	}
	// Cursor at 14, viewport should show [5..14], offset=5
	if s.Offset != 5 {
		t.Errorf("after scrolling down to 14: offset = %d, want 5", s.Offset)
	}

	// Now move cursor UP to 13 - still within viewport [5..14], offset should stay 5
	s.Update(13, totalItems)
	if s.Offset != 5 {
		t.Errorf("cursor at 13 (within viewport): offset = %d, want 5 (no scroll)", s.Offset)
	}

	// Move cursor UP to 10 - still within viewport [5..14], offset should stay 5
	s.Update(10, totalItems)
	if s.Offset != 5 {
		t.Errorf("cursor at 10 (within viewport): offset = %d, want 5 (no scroll)", s.Offset)
	}

	// Move cursor UP to 5 - at top edge of viewport [5..14], offset should stay 5
	s.Update(5, totalItems)
	if s.Offset != 5 {
		t.Errorf("cursor at 5 (top edge of viewport): offset = %d, want 5 (no scroll)", s.Offset)
	}

	// Move cursor UP to 4 - above viewport, offset should decrease to 4
	s.Update(4, totalItems)
	if s.Offset != 4 {
		t.Errorf("cursor at 4 (above viewport): offset = %d, want 4 (scroll up)", s.Offset)
	}

	// Move cursor UP to 0 - offset should follow cursor
	s.Update(0, totalItems)
	if s.Offset != 0 {
		t.Errorf("cursor at 0: offset = %d, want 0", s.Offset)
	}
}

func TestScrollState_GetVisibleRange_Stateful(t *testing.T) {
	s := NewScrollState(10)
	totalItems := 30

	// Scroll down to cursor 14 (offset should be 5)
	for i := 0; i <= 14; i++ {
		s.Update(i, totalItems)
	}

	start, end := s.GetVisibleRange()
	if start != 5 || end != 15 {
		t.Errorf("after scrolling to 14: range = (%d, %d), want (5, 15)", start, end)
	}

	// Move cursor up to 10 (still within viewport), range should not change
	s.Update(10, totalItems)
	start, end = s.GetVisibleRange()
	if start != 5 || end != 15 {
		t.Errorf("cursor at 10 (within viewport): range = (%d, %d), want (5, 15)", start, end)
	}
}

func TestCalculateVisibleRange_EdgeOnly(t *testing.T) {
	tests := []struct {
		name           string
		cursor         int
		totalItems     int
		viewportHeight int
		wantStart      int
		wantEnd        int
	}{
		{
			name:           "cursor at top - shows first viewport",
			cursor:         0,
			totalItems:     30,
			viewportHeight: 10,
			wantStart:      0,
			wantEnd:        10,
		},
		{
			name:           "cursor at bottom edge - scrolls to show cursor",
			cursor:         15,
			totalItems:     30,
			viewportHeight: 10,
			wantStart:      6,
			wantEnd:        16,
		},
		{
			name:           "cursor at last item - shows last viewport",
			cursor:         29,
			totalItems:     30,
			viewportHeight: 10,
			wantStart:      20,
			wantEnd:        30,
		},
		{
			name:           "all items fit in viewport",
			cursor:         3,
			totalItems:     5,
			viewportHeight: 10,
			wantStart:      0,
			wantEnd:        5,
		},
		{
			name:           "empty list",
			cursor:         0,
			totalItems:     0,
			viewportHeight: 10,
			wantStart:      0,
			wantEnd:        0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			start, end := CalculateVisibleRange(tt.cursor, tt.totalItems, tt.viewportHeight)
			if start != tt.wantStart || end != tt.wantEnd {
				t.Errorf("CalculateVisibleRange(%d, %d, %d) = (%d, %d), want (%d, %d)",
					tt.cursor, tt.totalItems, tt.viewportHeight, start, end, tt.wantStart, tt.wantEnd)
			}
		})
	}
}

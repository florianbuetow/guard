package tui

import "testing"

func TestScrollState_UpdateOffset(t *testing.T) {
	tests := []struct {
		name           string
		cursor         int
		totalItems     int
		viewportHeight int
		want           int
	}{
		// Items fit in viewport: no scroll needed.
		{"all items fit", 0, 5, 10, 0},
		{"exact fit", 0, 10, 10, 0},
		{"cursor at start, large list", 0, 20, 10, 0},
		{"cursor just below viewport", 10, 20, 10, 1},
		{"cursor at end", 19, 20, 10, 10},

		// Small viewports.
		{"viewport 1, cursor 0", 0, 7, 1, 0},
		{"viewport 1, cursor 3", 3, 7, 1, 3},
		{"viewport 1, cursor 6 (last)", 6, 7, 1, 6},
		{"viewport 2, cursor 0", 0, 7, 2, 0},
		{"viewport 2, cursor 1", 1, 7, 2, 0},
		{"viewport 2, cursor 3", 3, 7, 2, 2},
		{"viewport 2, cursor 6 (last)", 6, 7, 2, 5},
		{"viewport 3, cursor 0", 0, 7, 3, 0},
		{"viewport 3, cursor 2", 2, 7, 3, 0},
		{"viewport 3, cursor 3", 3, 7, 3, 1},
		{"viewport 3, cursor 6 (last)", 6, 7, 3, 4},
		{"viewport 4, cursor 0", 0, 7, 4, 0},
		{"viewport 4, cursor 3", 3, 7, 4, 0},
		{"viewport 4, cursor 6 (last)", 6, 7, 4, 3},
		{"one item, viewport 1", 0, 1, 1, 0},
		{"two items, viewport 1, cursor 1", 1, 2, 1, 1},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := NewScrollState(tt.viewportHeight)
			s.Update(tt.cursor, tt.totalItems)
			got := s.Offset
			if got != tt.want {
				t.Errorf("offset(cursor=%d, totalItems=%d, viewport=%d) = %d, want %d",
					tt.cursor, tt.totalItems, tt.viewportHeight, got, tt.want)
			}
		})
	}
}

func TestScrollState_CalculateVisibleRange(t *testing.T) {
	tests := []struct {
		name           string
		cursor         int
		totalItems     int
		viewportHeight int
		wantStart      int
		wantEnd        int
	}{
		{"empty list", 0, 0, 10, 0, 0},
		{"zero viewport", 0, 5, 0, 0, 0},
		{"all items fit", 0, 5, 10, 0, 5},
		{"exact fit", 2, 10, 10, 0, 10},
		{"viewport 1, start", 0, 7, 1, 0, 1},
		{"viewport 1, middle", 3, 7, 1, 3, 4},
		{"viewport 1, end", 6, 7, 1, 6, 7},
		{"larger list, cursor at end", 19, 20, 10, 10, 20},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := NewScrollState(tt.viewportHeight)
			s.Update(tt.cursor, tt.totalItems)
			start, end := s.GetVisibleRange()
			if start != tt.wantStart || end != tt.wantEnd {
				t.Errorf("visibleRange(cursor=%d, totalItems=%d, viewport=%d) = (%d, %d), want (%d, %d)",
					tt.cursor, tt.totalItems, tt.viewportHeight, start, end, tt.wantStart, tt.wantEnd)
			}
		})
	}
}

func TestScrollState(t *testing.T) {
	t.Run("basic navigation", func(t *testing.T) {
		s := NewScrollState(10)
		s.Update(0, 20)

		if !s.IsAtTop() {
			t.Error("expected IsAtTop at cursor 0")
		}
		if s.IsAtBottom() {
			t.Error("unexpected IsAtBottom at cursor 0")
		}
		if !s.CanScrollDown() {
			t.Error("expected CanScrollDown with 20 items in viewport 10")
		}

		s.Update(19, 20)
		if s.IsAtTop() {
			t.Error("unexpected IsAtTop at cursor 19")
		}
		if !s.IsAtBottom() {
			t.Error("expected IsAtBottom at cursor 19")
		}
		if !s.CanScrollUp() {
			t.Error("expected CanScrollUp at cursor 19")
		}
	})

	t.Run("all items fit", func(t *testing.T) {
		s := NewScrollState(10)
		s.Update(0, 5)

		if !s.IsAtTop() {
			t.Error("expected IsAtTop")
		}
		if !s.IsAtBottom() {
			t.Error("expected IsAtBottom when all items fit")
		}
		if s.CanScrollDown() {
			t.Error("unexpected CanScrollDown when all items fit")
		}
		if s.CanScrollUp() {
			t.Error("unexpected CanScrollUp when all items fit")
		}
	})

	t.Run("SetViewportSize recalculates", func(t *testing.T) {
		s := NewScrollState(10)
		s.Update(15, 20)
		// viewport=10, cursor=15 => offset=6 (cursor kept at bottom edge)
		if s.Offset != 6 {
			t.Errorf("Offset before resize = %d, want 6", s.Offset)
		}

		s.SetViewportSize(5)
		if s.ViewportSize != 5 {
			t.Errorf("ViewportSize = %d, want 5", s.ViewportSize)
		}
		// viewport=5, cursor=15 => offset=11
		if s.Offset != 11 {
			t.Errorf("Offset after resize = %d, want 11", s.Offset)
		}
	})

	t.Run("GetVisibleRange", func(t *testing.T) {
		s := NewScrollState(10)
		s.Update(0, 20)
		start, end := s.GetVisibleRange()
		if start != 0 || end != 10 {
			t.Errorf("GetVisibleRange() = (%d, %d), want (0, 10)", start, end)
		}
	})
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

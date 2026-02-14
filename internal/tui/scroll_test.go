package tui

import "testing"

func TestCalculateScrollOffset(t *testing.T) {
	tests := []struct {
		name           string
		cursor         int
		totalItems     int
		viewportHeight int
		want           int
	}{
		// Items fit in viewport — no scroll needed
		{"all items fit", 0, 5, 10, 0},
		{"exact fit", 0, 10, 10, 0},

		// Cursor at start — no scroll needed
		{"cursor at start, large list", 0, 20, 10, 0},

		// Cursor at end
		{"cursor at end", 19, 20, 10, 10},

		// Cursor in middle
		{"cursor mid, margin pushes offset", 10, 20, 10, 3},

		// Small viewport (no floor-clamp on margin)
		// scrollMargin = viewportHeight / 4 (integer division)

		// viewport=1: margin=0, minOffset = cursor - 1 + 0 + 1 = cursor
		{"viewport 1, cursor 0", 0, 7, 1, 0},
		{"viewport 1, cursor 3", 3, 7, 1, 3},
		{"viewport 1, cursor 6 (last)", 6, 7, 1, 6},

		// viewport=2: margin=0, minOffset = cursor - 2 + 0 + 1 = cursor - 1
		{"viewport 2, cursor 0", 0, 7, 2, 0},
		{"viewport 2, cursor 1", 1, 7, 2, 0},
		{"viewport 2, cursor 3", 3, 7, 2, 2},
		{"viewport 2, cursor 6 (last)", 6, 7, 2, 5},

		// viewport=3: margin=0, minOffset = cursor - 3 + 0 + 1 = cursor - 2
		{"viewport 3, cursor 0", 0, 7, 3, 0},
		{"viewport 3, cursor 2", 2, 7, 3, 0},
		{"viewport 3, cursor 3", 3, 7, 3, 1},
		{"viewport 3, cursor 6 (last)", 6, 7, 3, 4},

		// viewport=4: margin=1, minOffset = cursor - 4 + 1 + 1 = cursor - 2
		{"viewport 4, cursor 0", 0, 7, 4, 0},
		{"viewport 4, cursor 3", 3, 7, 4, 1},
		{"viewport 4, cursor 6 (last)", 6, 7, 4, 3},

		// Edge cases
		{"one item, viewport 1", 0, 1, 1, 0},
		{"two items, viewport 1, cursor 1", 1, 2, 1, 1},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := CalculateScrollOffset(tt.cursor, tt.totalItems, tt.viewportHeight)
			if got != tt.want {
				t.Errorf("CalculateScrollOffset(%d, %d, %d) = %d, want %d",
					tt.cursor, tt.totalItems, tt.viewportHeight, got, tt.want)
			}
		})
	}
}

func TestCalculateVisibleRange(t *testing.T) {
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
			start, end := CalculateVisibleRange(tt.cursor, tt.totalItems, tt.viewportHeight)
			if start != tt.wantStart || end != tt.wantEnd {
				t.Errorf("CalculateVisibleRange(%d, %d, %d) = (%d, %d), want (%d, %d)",
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
		// viewport=10: margin=2, minOffset=15-10+2+1=8, offset=8
		if s.Offset != 8 {
			t.Errorf("Offset before resize = %d, want 8", s.Offset)
		}

		s.SetViewportSize(5)
		if s.ViewportSize != 5 {
			t.Errorf("ViewportSize = %d, want 5", s.ViewportSize)
		}
		// viewport=5: margin=1, minOffset=15-5+1+1=12, offset=12
		if s.Offset != 12 {
			t.Errorf("Offset after resize = %d, want 12", s.Offset)
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

package tui

import "testing"

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

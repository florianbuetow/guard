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

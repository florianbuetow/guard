package tui

import "testing"

func TestPadContentToFit(t *testing.T) {
	tests := []struct {
		name       string
		content    string
		width      int
		height     int
		wantLines  int
		wantWidths []int // nil means all lines should be width (or clamped width)
	}{
		{"empty content", "", 10, 5, 5, nil},
		{"fewer lines than height", "a\nb", 10, 5, 5, nil},
		{"exact lines", "a\nb\nc", 10, 3, 3, nil},
		{"more lines than height", "a\nb\nc\nd\ne", 10, 3, 3, nil},
		{"single line, single cell", "x", 1, 1, 1, nil},
		{"width clamped to 1", "abc", 0, 2, 2, []int{1, 1}},
		{"height clamped to 1", "abc", 10, 0, 1, nil},
		{"both clamped", "", -1, -5, 1, []int{1}},
		{"wide line truncated", "abcdefghij", 5, 2, 2, nil},
		{"narrow line padded", "ab", 5, 1, 1, nil},
		{"trailing newline", "a\n", 10, 3, 3, nil},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := padContentToFit(tt.content, tt.width, tt.height)
			if len(got) != tt.wantLines {
				t.Errorf("len = %d, want %d", len(got), tt.wantLines)
			}
			expectedWidth := tt.width
			if expectedWidth < 1 {
				expectedWidth = 1
			}
			for i, line := range got {
				wantW := expectedWidth
				if tt.wantWidths != nil && i < len(tt.wantWidths) {
					wantW = tt.wantWidths[i]
				}
				w := StringWidth(line)
				if w != wantW {
					t.Errorf("line[%d] width = %d, want %d (line=%q)", i, w, wantW, line)
				}
			}
		})
	}
}

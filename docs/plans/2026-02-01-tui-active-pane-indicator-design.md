# TUI Active Pane Indicator Design

**Date:** 2026-02-01
**Status:** Proposed

## Overview

Add visual highlighting to the active pane's title in the TUI top border, making it immediately clear which pane has keyboard focus.

## Requirements

### R1: Active Title Highlighting
The focused pane's title must be rendered with `ItemSelected` styling (blue background, white foreground) - matching the selected row highlighting.

### R2: Inactive Title Styling
The inactive pane's title must retain the current default styling (bold white text, no background).

### R3: Immediate Visual Feedback
Highlighting must update immediately when Tab is pressed to switch panels, with no perceptible delay.

### R4: Border Alignment Preservation
The highlighting must not break the top border alignment. The junction character `╤` must remain aligned with the content separator `│`.

## Current vs Proposed Rendering

### Current (no focus indication):
```
╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
║ [G] src/                               │ [G] core-files                     ║
```

### Proposed (Files pane active):
```
╔═[Files]════════════════════════════════╤═ Collections ══════════════════════╗
║ [G] src/                               │ [G] core-files                     ║
   ^^^^^^
   Blue background, white text
```

### Proposed (Collections pane active):
```
╔═ Files ════════════════════════════════╤═[Collections]══════════════════════╗
║ [G] src/                               │ [G] core-files                     ║
                                            ^^^^^^^^^^^^^
                                            Blue background, white text
```

## Technical Approach

### Modified Function Signatures

#### frame.go - RenderFrame
```go
// Before
func RenderFrame(
    leftTitle string,
    rightTitle string,
    leftContent []string,
    rightContent []string,
    statusLines []string,
    leftWidth int,
    rightWidth int,
    contentHeight int,
) string

// After
func RenderFrame(
    leftTitle string,
    rightTitle string,
    leftFocused bool,      // NEW
    rightFocused bool,     // NEW
    leftContent []string,
    rightContent []string,
    statusLines []string,
    leftWidth int,
    rightWidth int,
    contentHeight int,
    styles *Styles,        // NEW - for accessing ItemSelected style
) string
```

#### frame.go - renderTopBorder
```go
// Before
func renderTopBorder(leftTitle, rightTitle string, leftWidth, rightWidth int) string

// After
func renderTopBorder(
    leftTitle, rightTitle string,
    leftFocused, rightFocused bool,
    leftWidth, rightWidth int,
    styles *Styles,
) string
```

### Implementation in renderTopBorder

```go
func renderTopBorder(
    leftTitle, rightTitle string,
    leftFocused, rightFocused bool,
    leftWidth, rightWidth int,
    styles *Styles,
) string {
    var result strings.Builder

    // Style the titles based on focus
    styledLeftTitle := leftTitle
    styledRightTitle := rightTitle
    if leftFocused {
        styledLeftTitle = styles.ItemSelected.Render(leftTitle)
    }
    if rightFocused {
        styledRightTitle = styles.ItemSelected.Render(rightTitle)
    }

    // Build left panel portion: ╔═ Files ════...
    // Account for ANSI escape codes in width calculation
    leftPart := FrameHorizontal + " " + styledLeftTitle + " "
    leftPartDisplayWidth := 1 + 1 + StringWidth(leftTitle) + 1 // ═ + space + title + space

    result.WriteString(FrameTopLeft)
    result.WriteString(leftPart)

    // Fill remaining width (using display width, not string length)
    leftFillLen := max(0, leftWidth-leftPartDisplayWidth)
    result.WriteString(strings.Repeat(FrameHorizontal, leftFillLen))

    // Junction
    result.WriteString(FrameTopJunction)

    // Build right panel portion
    rightPart := FrameHorizontal + " " + styledRightTitle + " "
    rightPartDisplayWidth := 1 + 1 + StringWidth(rightTitle) + 1

    result.WriteString(rightPart)

    rightFillLen := max(0, rightWidth-rightPartDisplayWidth)
    result.WriteString(strings.Repeat(FrameHorizontal, rightFillLen))

    result.WriteString(FrameTopRight)

    return result.String()
}
```

**Key consideration:** The styled title contains ANSI escape codes for colors, so we must calculate fill width based on the *display width* of the original title, not the string length of the styled title.

### Caller Update in app.go

```go
// In App.View()
content := RenderFrame(
    a.filesPanel.Title(),
    a.collectionsPanel.Title(),
    a.activePanel == PanelFiles,      // NEW
    a.activePanel == PanelCollections, // NEW
    leftContent,
    rightContent,
    statusLines,
    leftWidth,
    rightWidth,
    contentHeight,
    a.styles,                          // NEW
)
```

## Files to Modify

| File | Changes |
|------|---------|
| `internal/tui/frame.go` | Update `RenderFrame()` and `renderTopBorder()` signatures and implementation |
| `internal/tui/app.go` | Pass focus state and styles to `RenderFrame()` |

## Testing Strategy

### Manual Testing
1. Launch TUI with `guard -i`
2. Verify Files pane title is highlighted on startup (default focus)
3. Press Tab - verify Collections title becomes highlighted, Files becomes unhighlighted
4. Press Tab again - verify Files title is highlighted again
5. Verify no border alignment issues at various terminal widths

### Automated TUI Tests
Update existing tmux-based TUI tests to verify:
- Initial state shows Files title highlighted
- After Tab press, Collections title is highlighted

Test file: `tests/tui/test_pane_indicator.sh`

```bash
#!/bin/bash
# Test: Active pane indicator visibility

# Setup test environment
setup_test_env

# Launch TUI
tmux send-keys "guard -i" Enter
sleep 0.5

# Capture initial screen - Files should be highlighted
capture_screen "initial"
assert_contains "initial" $'\e[44m'  # Blue background escape code near "Files"

# Switch to Collections pane
tmux send-keys Tab
sleep 0.2

# Capture after Tab - Collections should be highlighted
capture_screen "after_tab"
# Verify highlight moved to Collections

# Cleanup
cleanup_test_env
```

## Edge Cases

1. **Very narrow terminal**: Title may be truncated; highlighting should still apply to visible portion
2. **Very long title**: (Not applicable - titles are fixed strings "Files" and "Collections")
3. **Rapid Tab switching**: Should handle without visual glitches

## Rollout

1. Implement changes in `frame.go`
2. Update caller in `app.go`
3. Run existing TUI tests to verify no regressions
4. Add new test for pane indicator
5. Manual verification across terminal sizes

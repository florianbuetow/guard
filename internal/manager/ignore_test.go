package manager

import "testing"

func TestManager_IsIgnored_NotLoaded(t *testing.T) {
	mgr := NewManager("/nonexistent/.guardfile")
	if mgr.IsIgnored("somefile.log") {
		t.Fatal("IsIgnored should return false when registry not loaded")
	}
}

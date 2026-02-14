package commands

import (
	"context"
	"testing"

	"github.com/florianbuetow/guard/internal/manager"
)

func TestSetGetManager(t *testing.T) {
	mgr := manager.NewManager(".guardfile")
	ctx := SetManager(context.Background(), mgr)
	got := GetManager(ctx)
	if got != mgr {
		t.Fatal("GetManager did not return the manager stored by SetManager")
	}
}

func TestGetManagerPanicsWithoutSet(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("GetManager should panic when no Manager is in context")
		}
	}()
	GetManager(context.Background())
}

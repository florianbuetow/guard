package commands

import (
	"context"

	"github.com/florianbuetow/guard/internal/manager"
)

type contextKey struct{}

// SetManager stores a Manager in the context.
func SetManager(ctx context.Context, mgr *manager.Manager) context.Context {
	return context.WithValue(ctx, contextKey{}, mgr)
}

// GetManager retrieves the Manager from the context.
// Panics if no Manager was stored — callers rely on PersistentPreRunE having set it.
func GetManager(ctx context.Context) *manager.Manager {
	mgr, ok := ctx.Value(contextKey{}).(*manager.Manager)
	if !ok {
		panic("GetManager: no Manager in context — was PersistentPreRunE skipped?")
	}
	return mgr
}

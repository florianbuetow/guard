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
func GetManager(ctx context.Context) *manager.Manager {
	return ctx.Value(contextKey{}).(*manager.Manager)
}

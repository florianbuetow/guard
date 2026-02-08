package commands

import (
	"fmt"
	"os"

	"github.com/florianbuetow/guard/internal/manager"
)

func printWarnings(warnings []manager.Warning) {
	if len(warnings) == 0 {
		return
	}

	for _, msg := range manager.AggregateWarnings(warnings) {
		if msg != "" {
			fmt.Println(msg)
		}
	}
}

func printErrors(errors []string) {
	for _, msg := range errors {
		if msg != "" {
			fmt.Fprintln(os.Stderr, msg)
		}
	}
}

func displayPath(mgr *manager.Manager, path string) string {
	if mgr == nil {
		return path
	}
	status, err := mgr.GetFileStatus(path)
	if err != nil || status.Path == "" {
		return path
	}
	return status.Path
}

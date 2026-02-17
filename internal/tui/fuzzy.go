package tui

import (
	"strings"

	"github.com/sahilm/fuzzy"
)

// FuzzyResult holds a single fuzzy match result.
type FuzzyResult struct {
	Str   string
	Index int
	Score int
}

// FuzzyMatch performs fuzzy subsequence matching of query against candidates.
// Results are sorted by match quality (best first).
// An empty query returns all candidates unfiltered.
func FuzzyMatch(query string, candidates []string) []FuzzyResult {
	if query == "" {
		results := make([]FuzzyResult, len(candidates))
		for i, c := range candidates {
			results[i] = FuzzyResult{Str: c, Index: i, Score: 0}
		}
		return results
	}

	// Lowercase both query and candidates for case-insensitive matching.
	lowerQuery := strings.ToLower(query)
	lowerCandidates := make([]string, len(candidates))
	for i, c := range candidates {
		lowerCandidates[i] = strings.ToLower(c)
	}

	matches := fuzzy.Find(lowerQuery, lowerCandidates)

	results := make([]FuzzyResult, len(matches))
	for i, m := range matches {
		results[i] = FuzzyResult{
			Str:   candidates[m.Index],
			Index: m.Index,
			Score: m.Score,
		}
	}
	return results
}

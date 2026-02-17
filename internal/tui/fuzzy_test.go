package tui

import (
	"testing"
)

func TestFuzzyMatch_ExactMatch(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "app.go"}
	results := FuzzyMatch("main.go", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for exact match")
	}
	if results[0].Str != "main.go" {
		t.Errorf("expected best match to be 'main.go', got %q", results[0].Str)
	}
}

func TestFuzzyMatch_PrefixMatch(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "manifest.yaml"}
	results := FuzzyMatch("main", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for prefix match")
	}
	found := false
	for _, r := range results {
		if r.Str == "main.go" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'main.go' to be in results for prefix query 'main'")
	}
}

func TestFuzzyMatch_SubsequenceMatch(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "readme.md"}
	results := FuzzyMatch("mgo", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for subsequence match")
	}
	found := false
	for _, r := range results {
		if r.Str == "main.go" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'main.go' to match subsequence query 'mgo'")
	}
}

func TestFuzzyMatch_CaseInsensitive(t *testing.T) {
	candidates := []string{"readme.md", "main.go", "LICENSE"}
	results := FuzzyMatch("README", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for case-insensitive match")
	}
	found := false
	for _, r := range results {
		if r.Str == "readme.md" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'readme.md' to match case-insensitive query 'README'")
	}
}

func TestFuzzyMatch_NoMatch(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "app.go"}
	results := FuzzyMatch("zzzzz", candidates)

	if len(results) != 0 {
		t.Errorf("expected no results for non-matching query, got %d", len(results))
	}
}

func TestFuzzyMatch_EmptyQuery(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "app.go"}
	results := FuzzyMatch("", candidates)

	if len(results) != len(candidates) {
		t.Errorf("expected all %d candidates for empty query, got %d", len(candidates), len(results))
	}
	for i, r := range results {
		if r.Str != candidates[i] {
			t.Errorf("expected result[%d] to be %q, got %q", i, candidates[i], r.Str)
		}
		if r.Index != i {
			t.Errorf("expected result[%d].Index to be %d, got %d", i, i, r.Index)
		}
	}
}

func TestFuzzyMatch_PathMatching(t *testing.T) {
	candidates := []string{
		"internal/tui/file_tree.go",
		"internal/manager/manager.go",
		"cmd/guard/main.go",
		"internal/tui/app.go",
	}
	results := FuzzyMatch("tui/tree", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for path query 'tui/tree'")
	}
	if results[0].Str != "internal/tui/file_tree.go" {
		t.Errorf("expected best match to be 'internal/tui/file_tree.go', got %q", results[0].Str)
	}
}

// === Edge cases and adversarial tests ===

func TestFuzzyMatch_EmptyCandidates(t *testing.T) {
	results := FuzzyMatch("anything", []string{})
	if len(results) != 0 {
		t.Errorf("expected 0 results for empty candidates, got %d", len(results))
	}
}

func TestFuzzyMatch_EmptyQueryEmptyCandidates(t *testing.T) {
	results := FuzzyMatch("", []string{})
	if len(results) != 0 {
		t.Errorf("expected 0 results for empty query + empty candidates, got %d", len(results))
	}
}

func TestFuzzyMatch_SingleCharQuery(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "README.md", "app.go"}
	results := FuzzyMatch("g", candidates)

	// "g" should match all .go files (they all contain 'g')
	if len(results) < 3 {
		t.Errorf("expected at least 3 results for single char 'g', got %d", len(results))
	}
}

func TestFuzzyMatch_QueryLongerThanCandidates(t *testing.T) {
	candidates := []string{"a.go", "b.go"}
	results := FuzzyMatch("this_is_way_longer_than_any_candidate", candidates)
	if len(results) != 0 {
		t.Errorf("expected 0 results when query is longer than all candidates, got %d", len(results))
	}
}

func TestFuzzyMatch_DotFiles(t *testing.T) {
	candidates := []string{".gitignore", ".env", "config.yaml", ".guardfile"}
	results := FuzzyMatch(".git", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for '.git'")
	}
	found := false
	for _, r := range results {
		if r.Str == ".gitignore" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected '.gitignore' to match query '.git'")
	}
}

func TestFuzzyMatch_FileExtensionQuery(t *testing.T) {
	candidates := []string{"main.go", "utils.go", "README.md", "config.yaml"}
	results := FuzzyMatch(".go", candidates)

	// Both .go files should match
	goCount := 0
	for _, r := range results {
		if r.Str == "main.go" || r.Str == "utils.go" {
			goCount++
		}
	}
	if goCount < 2 {
		t.Errorf("expected both .go files to match '.go', found %d", goCount)
	}
}

func TestFuzzyMatch_MixedCaseQuery(t *testing.T) {
	candidates := []string{"Makefile", "main.go", "MANIFEST.yaml"}
	results := FuzzyMatch("MaKe", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for mixed case 'MaKe'")
	}
	found := false
	for _, r := range results {
		if r.Str == "Makefile" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected 'Makefile' to match mixed case query 'MaKe'")
	}
}

func TestFuzzyMatch_SpecialCharactersInQuery(t *testing.T) {
	candidates := []string{"file (copy).txt", "file-v2.txt", "file_backup.txt"}
	results := FuzzyMatch("(copy)", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for query with parens")
	}
	if results[0].Str != "file (copy).txt" {
		t.Errorf("expected 'file (copy).txt' as best match, got %q", results[0].Str)
	}
}

func TestFuzzyMatch_WhitespaceOnlyQuery(t *testing.T) {
	candidates := []string{"main.go", "read me.txt"}
	results := FuzzyMatch("   ", candidates)

	// Whitespace-only query: spaces are valid characters for fuzzy matching
	// "read me.txt" contains spaces so it might match; main.go won't
	// Either way, this should not panic
	_ = results
}

func TestFuzzyMatch_RepeatedCharacters(t *testing.T) {
	candidates := []string{"aardvark.txt", "banana.txt", "abacaba.txt"}
	results := FuzzyMatch("aaa", candidates)

	// "aaa" as subsequence: "aardvark.txt" has a,a,r,d,v,a,r,k -> matches (a,a,a)
	// "abacaba.txt" has a,b,a,c,a,b,a -> matches (a,a,a)
	if len(results) == 0 {
		t.Fatal("expected at least one result for repeated chars 'aaa'")
	}
}

func TestFuzzyMatch_IndexPreservation(t *testing.T) {
	candidates := []string{"zero.go", "one.go", "two.go", "three.go", "four.go"}
	results := FuzzyMatch("three", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}
	for _, r := range results {
		if r.Str == "three.go" && r.Index != 3 {
			t.Errorf("expected Index 3 for 'three.go', got %d", r.Index)
		}
	}
}

func TestFuzzyMatch_ExactMatchRanksHigherThanSubsequence(t *testing.T) {
	candidates := []string{"manager.go", "main.go", "m.go"}
	results := FuzzyMatch("main.go", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}
	if results[0].Str != "main.go" {
		t.Errorf("expected exact match 'main.go' to rank first, got %q", results[0].Str)
	}
}

func TestFuzzyMatch_DeeplyNestedPath(t *testing.T) {
	candidates := []string{
		"a/b/c/d/e/f/target.go",
		"x/y/z/other.go",
		"top.go",
	}
	results := FuzzyMatch("f/target", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result for deeply nested path")
	}
	if results[0].Str != "a/b/c/d/e/f/target.go" {
		t.Errorf("expected deeply nested path as best match, got %q", results[0].Str)
	}
}

func TestFuzzyMatch_OriginalCasePreserved(t *testing.T) {
	candidates := []string{"MyComponent.tsx", "myutil.go"}
	results := FuzzyMatch("mycomp", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}
	// The result should preserve the original casing
	found := false
	for _, r := range results {
		if r.Str == "MyComponent.tsx" {
			found = true
			break
		}
	}
	if !found {
		t.Error("expected original case 'MyComponent.tsx' to be preserved in results")
	}
}

func TestFuzzyMatch_SimilarNames(t *testing.T) {
	candidates := []string{
		"test_handler.go",
		"test_helper.go",
		"test_hasher.go",
	}
	results := FuzzyMatch("handler", candidates)

	if len(results) == 0 {
		t.Fatal("expected at least one result")
	}
	if results[0].Str != "test_handler.go" {
		t.Errorf("expected 'test_handler.go' as best match for 'handler', got %q", results[0].Str)
	}
}

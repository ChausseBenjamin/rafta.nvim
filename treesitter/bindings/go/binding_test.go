package tree_sitter_rafta_nvim_test

import (
	"testing"

	tree_sitter "github.com/tree-sitter/go-tree-sitter"
	tree_sitter_rafta_nvim "github.com/chaussebenjamin/rafta.nvim/bindings/go"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_rafta_nvim.Language())
	if language == nil {
		t.Errorf("Error loading Rafta - Neovim grammar")
	}
}

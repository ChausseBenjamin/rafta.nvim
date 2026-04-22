import XCTest
import SwiftTreeSitter
import TreeSitterRaftaNvim

final class TreeSitterRaftaNvimTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_rafta_nvim())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Rafta - Neovim grammar")
    }
}

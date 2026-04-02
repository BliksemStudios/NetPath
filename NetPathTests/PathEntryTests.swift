import XCTest
import SwiftData
@testable import NetPath

final class PathEntryTests: XCTestCase {
    func testFuzzyMatchExactPrefix() {
        let entry = PathEntry(uncPath: #"\\server\share\folder"#, server: "server")
        XCTAssertTrue(entry.fuzzyMatches(query: #"\\server"#))
    }

    func testFuzzyMatchCaseInsensitive() {
        let entry = PathEntry(uncPath: #"\\SERVER\Share"#, server: "SERVER")
        XCTAssertTrue(entry.fuzzyMatches(query: "server"))
    }

    func testFuzzyMatchPartialComponent() {
        let entry = PathEntry(uncPath: #"\\ggn.global\dfs\ICT\DEV"#, server: "ggn.global")
        XCTAssertTrue(entry.fuzzyMatches(query: "ICT"))
    }

    func testFuzzyMatchNoMatch() {
        let entry = PathEntry(uncPath: #"\\server\share"#, server: "server")
        XCTAssertFalse(entry.fuzzyMatches(query: "xyz"))
    }

    func testFuzzyMatchEmpty() {
        let entry = PathEntry(uncPath: #"\\server\share"#, server: "server")
        XCTAssertTrue(entry.fuzzyMatches(query: ""))
    }
}

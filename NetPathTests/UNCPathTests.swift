import XCTest
@testable import NetPath

final class UNCPathTests: XCTestCase {

    func testParseSimpleUNCPath() {
        let path = UNCPath(from: #"\\server\share\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testParseUNCPathWithMultipleComponents() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "ggn.global")
        XCTAssertEqual(path?.share, "dfs")
        XCTAssertEqual(path?.components, ["ICT", "DEV"])
    }

    func testParseServerOnly() {
        let path = UNCPath(from: #"\\server"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertNil(path?.share)
        XCTAssertEqual(path?.components, [])
    }

    func testParseServerAndShare() {
        let path = UNCPath(from: #"\\server\share"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, [])
    }

    func testSMBURLFromUNC() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://ggn.global/dfs/ICT/DEV")
    }

    func testSMBURLServerAndShare() {
        let path = UNCPath(from: #"\\server\share"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://server/share")
    }

    func testSMBURLServerOnly() {
        let path = UNCPath(from: #"\\server"#)!
        XCTAssertEqual(path.smbURL.absoluteString, "smb://server")
    }

    func testUNCStringRoundTrip() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT\DEV"#)!
        XCTAssertEqual(path.uncString, #"\\ggn.global\dfs\ICT\DEV"#)
    }

    func testParseSMBURL() {
        let path = UNCPath(from: "smb://server/share/folder")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testParseSMBURLServerOnly() {
        let path = UNCPath(from: "smb://server")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertNil(path?.share)
    }

    func testTrailingSlashStripped() {
        let path = UNCPath(from: #"\\server\share\"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, [])
    }

    func testDoubleBackslashesNormalized() {
        let path = UNCPath(from: #"\\\\server\\share\\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testMixedSlashesNormalized() {
        let path = UNCPath(from: #"\\server/share\folder"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
        XCTAssertEqual(path?.components, ["folder"])
    }

    func testSpacesInPath() {
        let path = UNCPath(from: #"\\server\share\folder with spaces\file.txt"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.components, ["folder with spaces", "file.txt"])
        XCTAssertTrue(path!.smbURL.absoluteString.contains("folder%20with%20spaces"))
    }

    func testIPAddress() {
        let path = UNCPath(from: #"\\192.168.1.100\share"#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "192.168.1.100")
    }

    func testSurroundingQuotesStripped() {
        let path = UNCPath(from: #""\\server\share""#)
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
        XCTAssertEqual(path?.share, "share")
    }

    func testEmptyStringReturnsNil() {
        XCTAssertNil(UNCPath(from: ""))
    }

    func testGarbageStringReturnsNil() {
        XCTAssertNil(UNCPath(from: "not a path"))
    }

    func testParentPath() {
        let path = UNCPath(from: #"\\server\share\a\b\c"#)!
        let parent = path.parentPath
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.components, ["a", "b"])
        XCTAssertEqual(parent?.uncString, #"\\server\share\a\b"#)
    }

    func testParentPathAtShare() {
        let path = UNCPath(from: #"\\server\share"#)!
        let parent = path.parentPath
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent?.server, "server")
        XCTAssertNil(parent?.share)
    }

    func testParentPathAtServerIsNil() {
        let path = UNCPath(from: #"\\server"#)!
        XCTAssertNil(path.parentPath)
    }

    func testDisplayPathEqualsUNCString() {
        let path = UNCPath(from: #"\\ggn.global\dfs\ICT"#)!
        XCTAssertEqual(path.displayPath, #"\\ggn.global\dfs\ICT"#)
    }

    func testAppendingComponent() {
        let path = UNCPath(from: #"\\server\share"#)!
        let child = path.appending(component: "subfolder")
        XCTAssertEqual(child.components, ["subfolder"])
        XCTAssertEqual(child.uncString, #"\\server\share\subfolder"#)
    }

    func testInvisibleUnicodeStripped() {
        let path = UNCPath(from: "\u{200B}\\\\server\\share")
        XCTAssertNotNil(path)
        XCTAssertEqual(path?.server, "server")
    }
}

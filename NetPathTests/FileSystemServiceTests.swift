import XCTest
@testable import NetPath

final class FileSystemServiceTests: XCTestCase {

    func testListDirectoryAtRoot() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: "/"))
        XCTAssertFalse(items.isEmpty)
    }

    func testListDirectoryItemsHaveNames() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()))
        for item in items {
            XCTAssertFalse(item.name.isEmpty)
        }
    }

    func testListDirectoryHidesHiddenByDefault() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: "/"), showHidden: false)
        let hiddenItems = items.filter { $0.name.hasPrefix(".") }
        XCTAssertTrue(hiddenItems.isEmpty)
    }

    func testListDirectoryShowsHiddenWhenRequested() throws {
        let service = FileSystemService()
        let items = try service.listDirectory(at: URL(fileURLWithPath: "/"), showHidden: true)
        let hiddenItems = items.filter { $0.name.hasPrefix(".") }
        XCTAssertFalse(hiddenItems.isEmpty)
    }

    func testListNonExistentDirectoryThrows() {
        let service = FileSystemService()
        XCTAssertThrowsError(
            try service.listDirectory(at: URL(fileURLWithPath: "/nonexistent_\(UUID())"))
        )
    }
}

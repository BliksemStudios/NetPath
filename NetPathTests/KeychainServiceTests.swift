import XCTest
@testable import NetPath

final class KeychainServiceTests: XCTestCase {
    let service = KeychainService.shared
    let testServer = "test-server-\(UUID().uuidString).example.com"

    override func tearDown() {
        super.tearDown()
        try? service.deleteCredential(for: testServer)
    }

    func testSaveAndRetrieveCredential() throws {
        let cred = ServerCredential(domain: "TEST", username: "admin", password: "secret123")
        try service.saveCredential(cred, for: testServer)
        let retrieved = try service.getCredential(for: testServer)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.domain, "TEST")
        XCTAssertEqual(retrieved?.username, "admin")
        XCTAssertEqual(retrieved?.password, "secret123")
    }

    func testGetNonExistentCredential() throws {
        let result = try service.getCredential(for: "nonexistent-\(UUID()).example.com")
        XCTAssertNil(result)
    }

    func testUpdateCredential() throws {
        let cred1 = ServerCredential(domain: "OLD", username: "user1", password: "pass1")
        try service.saveCredential(cred1, for: testServer)
        let cred2 = ServerCredential(domain: "NEW", username: "user2", password: "pass2")
        try service.saveCredential(cred2, for: testServer)
        let retrieved = try service.getCredential(for: testServer)
        XCTAssertEqual(retrieved?.domain, "NEW")
        XCTAssertEqual(retrieved?.username, "user2")
    }

    func testDeleteCredential() throws {
        let cred = ServerCredential(domain: "DEL", username: "u", password: "p")
        try service.saveCredential(cred, for: testServer)
        try service.deleteCredential(for: testServer)
        let result = try service.getCredential(for: testServer)
        XCTAssertNil(result)
    }

    func testListServers() throws {
        let server1 = "list-test-1-\(UUID()).example.com"
        let server2 = "list-test-2-\(UUID()).example.com"
        defer {
            try? service.deleteCredential(for: server1)
            try? service.deleteCredential(for: server2)
        }
        try service.saveCredential(
            ServerCredential(domain: "D", username: "u", password: "p"), for: server1)
        try service.saveCredential(
            ServerCredential(domain: "D", username: "u", password: "p"), for: server2)
        let servers = try service.listServers()
        XCTAssertTrue(servers.contains(server1))
        XCTAssertTrue(servers.contains(server2))
    }
}

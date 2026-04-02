import Foundation

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    @Published private(set) var isHelperConnected = false

    // NSXPCConnection is thread-safe but not Sendable; mark as such
    nonisolated(unsafe) private var connection: NSXPCConnection?

    private init() {}

    private func getConnection() -> NSXPCConnection {
        if let existing = connection {
            return existing
        }

        let conn = NSXPCConnection(machServiceName: AppConstants.helperMachService,
                                    options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: NetPathHelperProtocol.self)

        conn.invalidationHandler = { [weak self] in
            Task { @MainActor in
                self?.isHelperConnected = false
                self?.connection = nil
            }
        }

        conn.interruptionHandler = { [weak self] in
            Task { @MainActor in
                self?.isHelperConnected = false
            }
        }

        conn.resume()
        self.connection = conn
        self.isHelperConnected = true
        return conn
    }

    func mount(url: String, username: String?, password: String?) async throws -> String {
        let conn = getConnection()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let resumed = Resumed()

            // Set a timeout — if nothing responds in 15s, fail
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                if resumed.tryResume() {
                    continuation.resume(throwing: XPCError.connectionFailed)
                }
            }

            let proxy = conn.remoteObjectProxyWithErrorHandler { _ in
                if resumed.tryResume() {
                    continuation.resume(throwing: XPCError.connectionFailed)
                }
            } as? NetPathHelperProtocol

            guard let proxy else {
                if resumed.tryResume() {
                    continuation.resume(throwing: XPCError.connectionFailed)
                }
                return
            }

            proxy.mount(url: url, username: username, password: password) { mountPoint, status in
                if resumed.tryResume() {
                    if let mountPoint, status == 0 {
                        continuation.resume(returning: mountPoint)
                    } else {
                        continuation.resume(throwing: XPCError.mountFailed(status: status))
                    }
                }
            }
        }
    }

    func unmount(path: String) async -> Bool {
        let conn = getConnection()
        return await withCheckedContinuation { continuation in
            let resumed = Resumed()

            DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                if resumed.tryResume() {
                    continuation.resume(returning: false)
                }
            }

            let proxy = conn.remoteObjectProxyWithErrorHandler { _ in
                if resumed.tryResume() {
                    continuation.resume(returning: false)
                }
            } as? NetPathHelperProtocol

            guard let proxy else {
                if resumed.tryResume() {
                    continuation.resume(returning: false)
                }
                return
            }

            proxy.unmount(path: path) { success in
                if resumed.tryResume() {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func listMountedShares() async -> [String] {
        let conn = getConnection()
        return await withCheckedContinuation { continuation in
            let resumed = Resumed()

            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                if resumed.tryResume() {
                    continuation.resume(returning: [])
                }
            }

            let proxy = conn.remoteObjectProxyWithErrorHandler { _ in
                if resumed.tryResume() {
                    continuation.resume(returning: [])
                }
            } as? NetPathHelperProtocol

            guard let proxy else {
                if resumed.tryResume() {
                    continuation.resume(returning: [])
                }
                return
            }

            proxy.listMountedShares { shares in
                if resumed.tryResume() {
                    continuation.resume(returning: shares)
                }
            }
        }
    }

    func resetConnection() {
        connection?.invalidate()
        connection = nil
        isHelperConnected = false
    }
}

/// Thread-safe one-shot flag to prevent double-resuming continuations.
private final class Resumed: @unchecked Sendable {
    private var _resumed = false
    private let lock = NSLock()

    func tryResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if _resumed { return false }
        _resumed = true
        return true
    }
}

enum XPCError: Error, LocalizedError {
    case connectionFailed
    case mountFailed(status: Int32)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to NetPath Helper. The helper service is not running."
        case .mountFailed(let status):
            switch status {
            case Int32(EAUTH), -5045:
                return "Authentication failed. Please check your credentials."
            case Int32(ENOENT):
                return "Share not found. Check the path and try again."
            case Int32(ETIMEDOUT):
                return "Connection timed out. The server may be unreachable."
            default:
                return "Mount failed (error \(status)). Please try again."
            }
        }
    }

    var isAuthError: Bool {
        if case .mountFailed(let status) = self {
            return status == Int32(EAUTH) || status == -5045
        }
        return false
    }
}

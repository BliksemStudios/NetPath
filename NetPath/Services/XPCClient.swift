import Foundation

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    @Published private(set) var isHelperConnected = false

    private var connection: NSXPCConnection?

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

    private func getProxy() -> NetPathHelperProtocol? {
        let conn = getConnection()
        return conn.remoteObjectProxyWithErrorHandler { error in
            print("XPC proxy error: \(error)")
        } as? NetPathHelperProtocol
    }

    func mount(url: String, username: String?, password: String?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(throwing: XPCError.connectionFailed)
                return
            }
            proxy.mount(url: url, username: username, password: password) { mountPoint, status in
                if let mountPoint, status == 0 {
                    continuation.resume(returning: mountPoint)
                } else {
                    continuation.resume(throwing: XPCError.mountFailed(status: status))
                }
            }
        }
    }

    func unmount(path: String) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            proxy.unmount(path: path) { success in
                continuation.resume(returning: success)
            }
        }
    }

    func listMountedShares() async -> [String] {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: [])
                return
            }
            proxy.listMountedShares { shares in
                continuation.resume(returning: shares)
            }
        }
    }
}

enum XPCError: Error, LocalizedError {
    case connectionFailed
    case mountFailed(status: Int32)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to NetPath Helper. Make sure it is installed."
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

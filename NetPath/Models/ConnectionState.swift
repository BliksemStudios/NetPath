import Foundation

enum ConnectionState: Equatable, Sendable {
    case idle
    case connecting(server: String)
    case connected(mountPoint: String, subPath: [String])
    case error(message: String)
    case needsCredentials(server: String)

    var isConnecting: Bool {
        if case .connecting = self { return true }
        return false
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var mountPoint: String? {
        if case .connected(let path, _) = self { return path }
        return nil
    }

    var subPath: [String] {
        if case .connected(_, let sub) = self { return sub }
        return []
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}

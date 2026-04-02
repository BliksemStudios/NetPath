import Foundation
import NetFS

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    @Published private(set) var isHelperConnected = false

    private init() {}

    func mount(url: String, username: String?, password: String?) async throws -> String {
        // Mount directly using NetFS — works when running unsandboxed (dev builds)
        // In production sandboxed builds, this would go through the XPC helper
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let smbURL = URL(string: url) else {
                    continuation.resume(throwing: XPCError.mountFailed(status: Int32(EINVAL)))
                    return
                }

                let shareName = smbURL.pathComponents.filter { $0 != "/" }.joined(separator: "_")
                let mountName = "NetPath_\(shareName.isEmpty ? smbURL.host ?? "unknown" : shareName)"
                let mountPoint = "/Volumes/\(mountName)"

                try? FileManager.default.createDirectory(
                    atPath: mountPoint, withIntermediateDirectories: true)

                let mountOptions = NSMutableDictionary()
                mountOptions[kNetFSSoftMountKey] = true

                let openOptions = NSMutableDictionary()
                if username == nil && password == nil {
                    openOptions[kNetFSUseGuestKey] = true
                }
                openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

                var mountpoints: Unmanaged<CFArray>?

                let status = NetFSMountURLSync(
                    smbURL as CFURL,
                    URL(fileURLWithPath: mountPoint) as CFURL,
                    username as CFString?,
                    password as CFString?,
                    openOptions as CFMutableDictionary,
                    mountOptions as CFMutableDictionary,
                    &mountpoints
                )

                if status == 0 {
                    let actualMountPoint: String
                    if let points = mountpoints?.takeRetainedValue() as? [String],
                       let first = points.first {
                        actualMountPoint = first
                    } else {
                        actualMountPoint = mountPoint
                    }
                    continuation.resume(returning: actualMountPoint)
                } else {
                    try? FileManager.default.removeItem(atPath: mountPoint)
                    continuation.resume(throwing: XPCError.mountFailed(status: status))
                }
            }
        }
    }

    func unmount(path: String) async -> Bool {
        let result = Darwin.unmount(path, MNT_FORCE)
        return result == 0
    }

    func listMountedShares() async -> [String] {
        // List volumes mounted by NetPath
        let fm = FileManager.default
        guard let volumes = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: []) else { return [] }
        return volumes
            .map(\.path)
            .filter { $0.contains("NetPath_") }
    }

    func resetConnection() {
        // No persistent connection in direct mode
    }
}

enum XPCError: Error, LocalizedError {
    case connectionFailed
    case mountFailed(status: Int32)

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Could not connect to NetPath Helper."
        case .mountFailed(let status):
            switch status {
            case Int32(EAUTH), -5045:
                return "Authentication failed. Please check your credentials."
            case Int32(ENOENT):
                return "Share not found. Check the path and try again."
            case Int32(ETIMEDOUT):
                return "Connection timed out. The server may be unreachable."
            case -6600:
                return "Server not found. Check the hostname and try again."
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

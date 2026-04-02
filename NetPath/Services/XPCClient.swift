import Foundation
import NetFS

struct MountResult {
    let mountPoint: String
    let subPath: [String]
}

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    @Published private(set) var isHelperConnected = false

    private init() {}

    func mount(path: UNCPath, username: String?, password: String?) async throws -> MountResult {
        guard let share = path.share else {
            throw XPCError.mountFailed(status: Int32(EINVAL))
        }

        let subPath = path.components

        // First: check if already mounted
        if let existingMount = findExistingMount(server: path.server, share: share) {
            print("[NetPath] Reusing existing mount at \(existingMount)")
            return MountResult(mountPoint: existingMount, subPath: subPath)
        }

        // Mount the share — try with system UI allowed so macOS handles Kerberos/AD
        let shareURL = "smb://\(path.server)/\(share)"
        let mountPoint = try await performMount(
            url: shareURL, username: username, password: password)

        return MountResult(mountPoint: mountPoint, subPath: subPath)
    }

    /// Check if the share is already mounted (by Finder or previous NetPath mount)
    private func findExistingMount(server: String, share: String) -> String? {
        // Check /Volumes for existing mount matching this share
        let fm = FileManager.default
        guard let volumes = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeURLForRemountingKey],
            options: []) else { return nil }

        for volume in volumes {
            // Check the remount URL to match server/share
            if let values = try? volume.resourceValues(forKeys: [.volumeURLForRemountingKey]),
               let remountURL = values.volumeURLForRemounting {
                let remountStr = remountURL.absoluteString.lowercased()
                if remountStr.contains(server.lowercased()) &&
                   remountStr.contains("/\(share.lowercased())") {
                    return volume.path
                }
            }
        }

        // Fallback: check by path name
        let candidates = [
            "/Volumes/\(share)",
            "/Volumes/NetPath_\(share)",
        ]
        for candidate in candidates {
            if fm.fileExists(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    private func performMount(url: String, username: String?, password: String?) async throws -> String {
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
                mountOptions[kNetFSAllowSubMountsKey] = true

                let openOptions = NSMutableDictionary()
                // Allow system UI for auth — handles Kerberos, AD, NTLM automatically
                openOptions[kNAUIOptionKey] = kNAUIOptionAllowUI

                var mountpoints: Unmanaged<CFArray>?

                print("[NetPath] Mounting \(url) at \(mountPoint)")

                let status = NetFSMountURLSync(
                    smbURL as CFURL,
                    URL(fileURLWithPath: mountPoint) as CFURL,
                    username as CFString?,
                    password as CFString?,
                    openOptions as CFMutableDictionary,
                    mountOptions as CFMutableDictionary,
                    &mountpoints
                )

                print("[NetPath] Mount status: \(status)")

                if status == 0 {
                    let actualMountPoint: String
                    if let points = mountpoints?.takeRetainedValue() as? [String],
                       let first = points.first {
                        actualMountPoint = first
                    } else {
                        actualMountPoint = mountPoint
                    }
                    print("[NetPath] Mounted at: \(actualMountPoint)")
                    continuation.resume(returning: actualMountPoint)
                } else {
                    try? FileManager.default.removeItem(atPath: mountPoint)
                    print("[NetPath] Mount failed with status: \(status)")
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
        let fm = FileManager.default
        guard let volumes = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: []) else { return [] }
        return volumes
            .map(\.path)
            .filter { $0.contains("NetPath_") }
    }

    func resetConnection() {}
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
            case 80:
                return "Authentication required."
            case Int32(EPERM), 13:
                return "Permission denied. Check your credentials."
            default:
                return "Mount failed (error \(status)). Please try again."
            }
        }
    }

    var isAuthError: Bool {
        if case .mountFailed(let status) = self {
            return status == Int32(EAUTH) || status == -5045 || status == -5046
                || status == -5999 || status == 80
                || status == Int32(EPERM) || status == 13
        }
        return false
    }
}

import Foundation
import NetFS

struct MountResult {
    let mountPoint: String
    let subPath: [String]
}

@MainActor
final class XPCClient: ObservableObject {
    static let shared = XPCClient()

    private init() {}

    /// Mount a UNC path. Tries Kerberos first (zero-prompt for AD users),
    /// falls back to explicit credentials if provided.
    func mount(path: UNCPath, username: String?, password: String?) async throws -> MountResult {
        guard let share = path.share else {
            throw XPCError.mountFailed(status: Int32(EINVAL))
        }

        let subPath = path.components

        // Check for existing mount first
        if let existing = findExistingMount(server: path.server, share: share) {
            print("[NetPath] Reusing existing mount at \(existing)")
            return MountResult(mountPoint: existing, subPath: subPath)
        }

        let shareURL = "smb://\(path.server)/\(share)"
        let mountPoint = try await performMount(
            url: shareURL, username: username, password: password)

        return MountResult(mountPoint: mountPoint, subPath: subPath)
    }

    private func findExistingMount(server: String, share: String) -> String? {
        let fm = FileManager.default
        guard let volumes = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeURLForRemountingKey],
            options: []) else { return nil }

        for volume in volumes {
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
        for candidate in ["/Volumes/\(share)", "/Volumes/NetPath_\(share)"] {
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

                let mountOptions = NSMutableDictionary()
                mountOptions[kNetFSSoftMountKey] = true
                mountOptions[kNetFSAllowSubMountsKey] = true
                // MNT_DONTBROWSE prevents Finder from opening a window
                mountOptions[kNetFSMountFlagsKey] = Int32(0x00100000)

                let openOptions = NSMutableDictionary()
                // Always NoUI — never trigger the macOS system auth dialog.
                // Auth is handled by our in-app credential form.
                openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

                var mountpoints: Unmanaged<CFArray>?

                print("[NetPath] Mounting \(url) (credentials: \(username != nil ? "explicit" : "Kerberos"))")

                let status = NetFSMountURLSync(
                    smbURL as CFURL,
                    nil,  // let system choose mount point
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
                        actualMountPoint = "/Volumes/\(smbURL.lastPathComponent)"
                    }
                    print("[NetPath] Mounted at: \(actualMountPoint)")
                    continuation.resume(returning: actualMountPoint)
                } else {
                    print("[NetPath] Mount failed: \(status)")
                    continuation.resume(throwing: XPCError.mountFailed(status: status))
                }
            }
        }
    }

    func unmount(path: String) async -> Bool {
        Darwin.unmount(path, MNT_FORCE) == 0
    }

    func listMountedShares() async -> [String] {
        FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil, options: [])?
            .map(\.path)
            .filter { $0.contains("NetPath_") } ?? []
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
            case Int32(EAUTH), -5045, 80:
                return "Authentication failed. Please check your credentials."
            case Int32(ENOENT):
                return "Share not found. Check the path and try again."
            case Int32(ETIMEDOUT):
                return "Connection timed out. The server may be unreachable."
            case -128:
                return "Authentication was cancelled."
            default:
                return "Mount failed (error \(status)). Please try again."
            }
        }
    }

    var isAuthError: Bool {
        if case .mountFailed(let status) = self {
            return status == Int32(EAUTH) || status == -5045 || status == 80
                || status == Int32(EPERM) || status == 13 || status == -128
        }
        return false
    }
}

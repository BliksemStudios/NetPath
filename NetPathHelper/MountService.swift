import Foundation
import NetFS

final class MountService: NSObject, NetPathHelperProtocol {

    // XPC calls are serialized on the connection's queue, so this is safe
    nonisolated(unsafe) private var activeMounts: [String: Date] = [:]

    func mount(url: String, username: String?, password: String?,
               reply: @escaping (String?, Int32) -> Void) {
        guard let smbURL = URL(string: url) else {
            reply(nil, Int32(EINVAL))
            return
        }

        let shareName = smbURL.pathComponents.filter { $0 != "/" }.joined(separator: "_")
        let mountName = "NetPath_\(shareName.isEmpty ? smbURL.host ?? "unknown" : shareName)"
        let mountPoint = "/Volumes/\(mountName)"

        try? FileManager.default.createDirectory(
            atPath: mountPoint, withIntermediateDirectories: true)

        let mountPointURL = URL(fileURLWithPath: mountPoint) as CFURL
        let smbCFURL = smbURL as CFURL

        let mountOptions = NSMutableDictionary()
        mountOptions[kNetFSSoftMountKey] = true

        let openOptions = NSMutableDictionary()
        if username == nil && password == nil {
            openOptions[kNetFSUseGuestKey] = true
        }
        openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

        var mountpoints: Unmanaged<CFArray>?

        let status = NetFSMountURLSync(
            smbCFURL,
            mountPointURL,
            username as CFString?,
            password as CFString?,
            openOptions as CFMutableDictionary,
            mountOptions as CFMutableDictionary,
            &mountpoints
        )

        if status == 0 {
            let actualMountPoint: String
            if let points = mountpoints?.takeRetainedValue() as? [String], let first = points.first {
                actualMountPoint = first
            } else {
                actualMountPoint = mountPoint
            }
            activeMounts[actualMountPoint] = Date()
            reply(actualMountPoint, 0)
        } else {
            try? FileManager.default.removeItem(atPath: mountPoint)
            reply(nil, status)
        }
    }

    func unmount(path: String, reply: @escaping (Bool) -> Void) {
        let result = Darwin.unmount(path, MNT_FORCE)
        if result == 0 {
            activeMounts.removeValue(forKey: path)
            reply(true)
        } else {
            reply(false)
        }
    }

    func listMountedShares(reply: @escaping ([String]) -> Void) {
        reply(Array(activeMounts.keys))
    }

    func listSharesOnServer(host: String, username: String?, password: String?,
                            reply: @escaping ([String]?, Int32) -> Void) {
        guard let url = URL(string: "smb://\(host)") else {
            reply(nil, Int32(EINVAL))
            return
        }

        let openOptions = NSMutableDictionary()
        if username == nil && password == nil {
            openOptions[kNetFSUseGuestKey] = true
        }
        openOptions[kNAUIOptionKey] = kNAUIOptionNoUI

        var mountpoints: Unmanaged<CFArray>?

        let status = NetFSMountURLSync(
            url as CFURL,
            nil,
            username as CFString?,
            password as CFString?,
            openOptions as CFMutableDictionary,
            nil,
            &mountpoints
        )

        if status == 0, let points = mountpoints?.takeRetainedValue() as? [String] {
            reply(points, 0)
        } else {
            reply(nil, status)
        }
    }
}

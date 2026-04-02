import Foundation
import SwiftData

@Model
final class MountSession {
    var server: String
    var sharePath: String
    var mountPoint: String
    var connectedAs: String
    var connectedAt: Date
    var isActive: Bool

    init(server: String, sharePath: String, mountPoint: String, connectedAs: String) {
        self.server = server
        self.sharePath = sharePath
        self.mountPoint = mountPoint
        self.connectedAs = connectedAs
        self.connectedAt = Date()
        self.isActive = true
    }
}

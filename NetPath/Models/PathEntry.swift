import Foundation
import SwiftData

@Model
final class PathEntry {
    var uncPath: String
    var server: String
    var isPinned: Bool
    var visitCount: Int
    var lastVisited: Date
    var createdAt: Date

    init(uncPath: String, server: String, isPinned: Bool = false) {
        self.uncPath = uncPath
        self.server = server
        self.isPinned = isPinned
        self.visitCount = 1
        self.lastVisited = Date()
        self.createdAt = Date()
    }

    func recordVisit() {
        visitCount += 1
        lastVisited = Date()
    }

    func fuzzyMatches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return uncPath.localizedCaseInsensitiveContains(query)
    }
}

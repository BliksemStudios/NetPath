import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultDomain: String?
    var maxHistoryItems: Int
    var idleTimeoutMinutes: Int
    var showHiddenFiles: Bool
    var defaultViewMode: String

    init() {
        self.defaultDomain = nil
        self.maxHistoryItems = AppConstants.Defaults.maxHistoryItems
        self.idleTimeoutMinutes = AppConstants.Defaults.idleTimeoutMinutes
        self.showHiddenFiles = false
        self.defaultViewMode = AppConstants.Defaults.defaultViewMode
    }

    static func fetch(from context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}

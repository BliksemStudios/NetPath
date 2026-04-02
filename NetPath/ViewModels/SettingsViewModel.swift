import SwiftUI
import SwiftData
import ServiceManagement

@MainActor
@Observable
final class SettingsViewModel {
    var settings: AppSettings
    var storedServers: [(server: String, credential: ServerCredential)] = []
    var launchAtLogin: Bool = false {
        didSet { updateLoginItem() }
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settings = AppSettings.fetch(from: modelContext)
        self.launchAtLogin = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
        loadStoredServers()
    }

    func loadStoredServers() {
        guard let servers = try? KeychainService.shared.listServers() else {
            storedServers = []
            return
        }
        storedServers = servers.compactMap { server in
            guard let cred = try? KeychainService.shared.getCredential(for: server) else { return nil }
            return (server: server, credential: cred)
        }
    }

    func deleteCredential(for server: String) {
        try? KeychainService.shared.deleteCredential(for: server)
        loadStoredServers()
    }

    func saveSettings() {
        try? modelContext.save()
    }

    func clearHistory() {
        let descriptor = FetchDescriptor<PathEntry>(
            predicate: #Predicate { !$0.isPinned }
        )
        if let entries = try? modelContext.fetch(descriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }
        try? modelContext.save()
    }

    private func updateLoginItem() {
        UserDefaults.standard.set(launchAtLogin, forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}

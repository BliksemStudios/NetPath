import SwiftUI
import SwiftData

@MainActor
@Observable
final class LauncherViewModel {
    var inputText: String = "" {
        didSet { onInputChanged() }
    }
    var convertedPreview: String?
    var connectionState: ConnectionState = .idle
    var suggestions: [PathEntry] = []
    var selectedSuggestionIndex: Int = -1

    private let conversionService = PathConversionService()
    private let modelContext: ModelContext
    private let xpcClient = XPCClient.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func onInputChanged() {
        if inputText.isEmpty {
            convertedPreview = nil
        } else if let parsed = conversionService.parse(inputText) {
            convertedPreview = conversionService.toSMBURL(parsed)
        } else {
            convertedPreview = nil
        }
        updateSuggestions()
        selectedSuggestionIndex = -1
    }

    func updateSuggestions() {
        let query = inputText
        var descriptor = FetchDescriptor<PathEntry>()
        descriptor.fetchLimit = 10

        guard var entries = try? modelContext.fetch(descriptor) else {
            suggestions = []
            return
        }

        // Sort: pinned first, then by visit count, then recency
        entries.sort { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            if a.visitCount != b.visitCount { return a.visitCount > b.visitCount }
            return a.lastVisited > b.lastVisited
        }
        suggestions = entries.filter { $0.fuzzyMatches(query: query) }
    }

    func connect() async {
        guard let path = conversionService.parse(inputText) else { return }
        let smbURL = conversionService.toSMBURL(path)

        // Check for stored credentials
        let credential = try? KeychainService.shared.getCredential(for: path.server)

        // If no stored credentials, go straight to credential prompt
        guard let credential else {
            connectionState = .needsCredentials(server: path.server)
            return
        }

        connectionState = .connecting(server: path.server)

        let username = conversionService.buildCredentialString(
            domain: credential.domain, username: credential.username)
        let password = credential.password

        do {
            let mountPoint = try await xpcClient.mount(
                url: smbURL, username: username, password: password)

            recordVisit(path: path)
            connectionState = .connected(mountPoint: mountPoint)
        } catch let error as XPCError where error.isAuthError {
            // Stored credentials are bad — prompt for new ones
            connectionState = .needsCredentials(server: path.server)
        } catch {
            xpcClient.resetConnection()
            connectionState = .error(message: error.localizedDescription)
        }
    }

    func connectWithCredentials(domain: String, username: String,
                                 password: String, saveToKeychain: Bool) async {
        guard let path = conversionService.parse(inputText) else { return }
        let smbURL = conversionService.toSMBURL(path)

        connectionState = .connecting(server: path.server)

        let fullUsername = conversionService.buildCredentialString(
            domain: domain, username: username)

        do {
            let mountPoint = try await xpcClient.mount(
                url: smbURL, username: fullUsername, password: password)

            if saveToKeychain {
                try? KeychainService.shared.saveCredential(
                    ServerCredential(domain: domain, username: username, password: password),
                    for: path.server
                )
            }

            recordVisit(path: path)
            connectionState = .connected(mountPoint: mountPoint)
        } catch let error as XPCError where error.isAuthError {
            connectionState = .error(message: "Authentication failed. Check your credentials.")
        } catch {
            connectionState = .error(message: error.localizedDescription)
        }
    }

    func selectSuggestion(_ entry: PathEntry) {
        inputText = entry.uncPath
    }

    func moveSelectionUp() {
        if selectedSuggestionIndex > 0 {
            selectedSuggestionIndex -= 1
        }
    }

    func moveSelectionDown() {
        if selectedSuggestionIndex < suggestions.count - 1 {
            selectedSuggestionIndex += 1
        }
    }

    func confirmSelection() {
        if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
            selectSuggestion(suggestions[selectedSuggestionIndex])
        }
    }

    func reset() {
        inputText = ""
        connectionState = .idle
        suggestions = []
        selectedSuggestionIndex = -1
    }

    private func recordVisit(path: UNCPath) {
        let uncString = path.uncString
        let descriptor = FetchDescriptor<PathEntry>(
            predicate: #Predicate { $0.uncPath == uncString }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.recordVisit()
        } else {
            let entry = PathEntry(uncPath: uncString, server: path.server)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

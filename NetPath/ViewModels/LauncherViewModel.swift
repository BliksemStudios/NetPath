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

    /// Set to true when arrow keys change selection — prevents onInputChanged from resetting index
    private var selectionDrivenChange = false

    private let conversionService = PathConversionService()
    private let modelContext: ModelContext
    private let xpcClient = XPCClient.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Load suggestions immediately so they appear when launcher opens
        updateSuggestions()
    }

    private func onInputChanged() {
        if inputText.isEmpty {
            convertedPreview = nil
        } else if let parsed = conversionService.parse(inputText) {
            convertedPreview = conversionService.toSMBURL(parsed)
        } else {
            convertedPreview = nil
        }

        if selectionDrivenChange {
            selectionDrivenChange = false
        } else {
            updateSuggestions()
            selectedSuggestionIndex = -1
        }
    }

    func updateSuggestions() {
        let query = inputText
        var descriptor = FetchDescriptor<PathEntry>()
        descriptor.fetchLimit = 10

        guard var entries = try? modelContext.fetch(descriptor) else {
            suggestions = []
            return
        }

        entries.sort { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            if a.visitCount != b.visitCount { return a.visitCount > b.visitCount }
            return a.lastVisited > b.lastVisited
        }
        suggestions = entries.filter { $0.fuzzyMatches(query: query) }
    }

    func connect() async {
        guard let path = conversionService.parse(inputText) else { return }

        connectionState = .connecting(server: path.server)

        // Step 1: Try with stored credentials if available
        if let credential = try? KeychainService.shared.getCredential(for: path.server) {
            let username = conversionService.buildCredentialString(
                domain: credential.domain, username: credential.username)
            do {
                let result = try await xpcClient.mount(
                    path: path, username: username, password: credential.password)
                recordVisit(path: path)
                connectionState = .connected(mountPoint: result.mountPoint, subPath: result.subPath)
                return
            } catch {
                print("[NetPath] Stored credentials failed, trying Kerberos...")
            }
        }

        // Step 2: Try Kerberos (no credentials — uses AD login)
        do {
            let result = try await xpcClient.mount(
                path: path, username: nil, password: nil)
            recordVisit(path: path)
            connectionState = .connected(mountPoint: result.mountPoint, subPath: result.subPath)
        } catch {
            connectionState = .needsCredentials(server: path.server)
        }
    }

    func connectWithCredentials(domain: String, username: String,
                                 password: String, saveToKeychain: Bool) async {
        guard let path = conversionService.parse(inputText) else { return }

        connectionState = .connecting(server: path.server)

        let fullUsername = conversionService.buildCredentialString(
            domain: domain, username: username)

        do {
            let result = try await xpcClient.mount(
                path: path, username: fullUsername, password: password)

            if saveToKeychain {
                try? KeychainService.shared.saveCredential(
                    ServerCredential(domain: domain, username: username, password: password),
                    for: path.server
                )
            }

            recordVisit(path: path)
            connectionState = .connected(mountPoint: result.mountPoint, subPath: result.subPath)
        } catch let error as XPCError where error.isAuthError {
            connectionState = .error(message: "Authentication failed. Check your credentials.")
        } catch {
            connectionState = .error(message: error.localizedDescription)
        }
    }

    func selectSuggestion(_ entry: PathEntry) {
        selectionDrivenChange = true
        inputText = entry.uncPath
    }

    func moveSelectionUp() {
        if suggestions.isEmpty { return }
        if selectedSuggestionIndex <= 0 {
            selectedSuggestionIndex = 0
        } else {
            selectedSuggestionIndex -= 1
        }
        // Auto-fill text field with selected suggestion
        selectionDrivenChange = true
        inputText = suggestions[selectedSuggestionIndex].uncPath
    }

    func moveSelectionDown() {
        if suggestions.isEmpty { return }
        if selectedSuggestionIndex < suggestions.count - 1 {
            selectedSuggestionIndex += 1
            // Auto-fill text field with selected suggestion
            selectionDrivenChange = true
            inputText = suggestions[selectedSuggestionIndex].uncPath
        }
    }

    func confirmSelection() {
        if selectedSuggestionIndex >= 0 && selectedSuggestionIndex < suggestions.count {
            selectSuggestion(suggestions[selectedSuggestionIndex])
        }
    }

    func reset() {
        selectionDrivenChange = true
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

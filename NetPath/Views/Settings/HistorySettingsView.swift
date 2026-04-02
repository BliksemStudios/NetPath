import SwiftUI
import SwiftData

struct HistorySettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showClearConfirmation = false
    @Query(sort: \PathEntry.lastVisited, order: .reverse) private var allEntries: [PathEntry]

    var body: some View {
        Form {
            Section("History Size") {
                Picker("Maximum Items", selection: Binding(
                    get: { viewModel.settings.maxHistoryItems },
                    set: {
                        viewModel.settings.maxHistoryItems = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("25").tag(25)
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("250").tag(250)
                }
            }

            Section("Actions") {
                Button("Clear All History", role: .destructive) {
                    showClearConfirmation = true
                }
            }

            Section("Recent Paths") {
                let unpinned = allEntries.filter { !$0.isPinned }
                if unpinned.isEmpty {
                    Text("No history").foregroundStyle(.secondary)
                } else {
                    ForEach(unpinned.prefix(20)) { entry in
                        HStack {
                            Text(entry.uncPath).font(Design.Fonts.pathMonoSmall).lineLimit(1)
                            Spacer()
                            Text(entry.lastVisited, style: .relative).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Clear History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { viewModel.clearHistory() }
        } message: {
            Text("This will remove all non-pinned path history. Pinned paths will be kept.")
        }
    }
}

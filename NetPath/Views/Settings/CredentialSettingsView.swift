import SwiftUI

struct CredentialSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var serverToDelete: String?

    var body: some View {
        Form {
            Section("Default Domain") {
                TextField("Domain (e.g. CORP)", text: Binding(
                    get: { viewModel.settings.defaultDomain ?? "" },
                    set: {
                        viewModel.settings.defaultDomain = $0.isEmpty ? nil : $0
                        viewModel.saveSettings()
                    }
                ))
            }

            Section("Stored Credentials") {
                if viewModel.storedServers.isEmpty {
                    Text("No stored credentials").foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.storedServers, id: \.server) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.server).font(.system(size: 13, weight: .medium))
                                Text("\(entry.credential.domain)\\\(entry.credential.username)")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { serverToDelete = entry.server } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Delete Credential?", isPresented: Binding(
            get: { serverToDelete != nil },
            set: { if !$0 { serverToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { serverToDelete = nil }
            Button("Delete", role: .destructive) {
                if let server = serverToDelete {
                    viewModel.deleteCredential(for: server)
                    serverToDelete = nil
                }
            }
        } message: {
            Text("Remove stored credentials for \(serverToDelete ?? "")?")
        }
    }
}

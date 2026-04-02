import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if let viewModel {
                TabView {
                    GeneralSettingsView(viewModel: viewModel)
                        .tabItem { Label("General", systemImage: "gear") }
                    CredentialSettingsView(viewModel: viewModel)
                        .tabItem { Label("Credentials", systemImage: "key") }
                    HistorySettingsView(viewModel: viewModel)
                        .tabItem { Label("History", systemImage: "clock") }
                }
                .frame(width: 500, height: 400)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(modelContext: modelContext)
            }
        }
    }
}

import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Global Shortcut")
                    Spacer()
                    Text("⌘⇧\\")
                        .font(Design.Fonts.pathMono)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
                }
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.launchAtLogin = $0 }
                ))
            }

            Section("File Browser") {
                Picker("Default View", selection: Binding(
                    get: { viewModel.settings.defaultViewMode },
                    set: {
                        viewModel.settings.defaultViewMode = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("List").tag("list")
                    Text("Grid").tag("grid")
                }

                Toggle("Show Hidden Files", isOn: Binding(
                    get: { viewModel.settings.showHiddenFiles },
                    set: {
                        viewModel.settings.showHiddenFiles = $0
                        viewModel.saveSettings()
                    }
                ))
            }

            Section("Connection") {
                Picker("Idle Disconnect", selection: Binding(
                    get: { viewModel.settings.idleTimeoutMinutes },
                    set: {
                        viewModel.settings.idleTimeoutMinutes = $0
                        viewModel.saveSettings()
                    }
                )) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("Never").tag(0)
                }
            }
        }
        .formStyle(.grouped)
    }
}

import SwiftUI
import SwiftData

struct LauncherView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LauncherViewModel?
    @State private var showCredentialSheet = false
    @FocusState private var isInputFocused: Bool

    var onBrowse: ((String, UNCPath) -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let viewModel {
                HStack(spacing: 12) {
                    Image(systemName: "network")
                        .foregroundStyle(Design.Colors.accent)
                        .font(.system(size: 18))

                    TextField("Type or paste a UNC path... (\\\\server\\share)",
                              text: Binding(
                                get: { viewModel.inputText },
                                set: { viewModel.inputText = $0 }
                              ))
                        .font(Design.Fonts.pathMonoLarge)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit { handleSubmit() }

                    if viewModel.connectionState.isConnecting {
                        LoadingIndicator()
                    } else {
                        Text("⏎")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Design.Colors.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(Design.Launcher.inputPadding)

                // Converted preview
                if let preview = viewModel.convertedPreview,
                   !viewModel.connectionState.isConnecting {
                    HStack {
                        Text("→ \(preview)")
                            .font(Design.Fonts.pathMonoSmall)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, Design.Launcher.inputPadding)
                    .padding(.leading, 32)
                    .padding(.bottom, 8)
                }

                // Error message
                if let error = viewModel.connectionState.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Design.Colors.errorRed)
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(Design.Colors.errorRed)
                        Spacer()
                        Button("Retry") { handleSubmit() }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Design.Colors.accent)
                    }
                    .padding(.horizontal, Design.Launcher.inputPadding)
                    .padding(.bottom, 8)
                }

                // Connecting status
                if viewModel.connectionState.isConnecting {
                    HStack {
                        if case .connecting(let server) = viewModel.connectionState {
                            Text("Connecting to \(server)...")
                                .font(Design.Fonts.pathMonoSmall)
                                .foregroundStyle(Design.Colors.accent)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, Design.Launcher.inputPadding)
                    .padding(.leading, 32)
                    .padding(.bottom, 8)
                }

                // Suggestions
                if !viewModel.suggestions.isEmpty {
                    Divider().padding(.horizontal, 8).opacity(0.3)

                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, entry in
                            PathSuggestionRow(
                                entry: entry,
                                isSelected: index == viewModel.selectedSuggestionIndex
                            )
                            .onTapGesture { viewModel.selectSuggestion(entry) }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                // Inline credential form (shown instead of a sheet to avoid panel dismiss issues)
                if showCredentialSheet,
                   case .needsCredentials(let server) = viewModel.connectionState {
                    Divider().padding(.horizontal, 8).opacity(0.3)

                    CredentialSheet(
                        server: server,
                        onSubmit: { domain, user, pass, save in
                            showCredentialSheet = false
                            setPanelPreventDismiss(false)
                            await viewModel.connectWithCredentials(
                                domain: domain, username: user,
                                password: pass, saveToKeychain: save)
                            if viewModel.connectionState.isConnected {
                                handleConnected()
                            }
                        },
                        onCancel: {
                            showCredentialSheet = false
                            setPanelPreventDismiss(false)
                            viewModel.connectionState = .idle
                        }
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Design.Launcher.cornerRadius))
        .frame(width: Design.Launcher.width)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .onAppear {
            if viewModel == nil {
                viewModel = LauncherViewModel(modelContext: modelContext)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
        .onChange(of: viewModel?.connectionState) { _, newState in
            if case .needsCredentials = newState {
                showCredentialSheet = true
                setPanelPreventDismiss(true)
            } else if case .connected = newState {
                handleConnected()
            }
        }
    }

    private func handleSubmit() {
        guard let viewModel else { return }
        if viewModel.selectedSuggestionIndex >= 0 {
            viewModel.confirmSelection()
        }
        Task { await viewModel.connect() }
    }

    private func handleConnected() {
        guard let viewModel,
              let mountPoint = viewModel.connectionState.mountPoint,
              let path = PathConversionService().parse(viewModel.inputText) else { return }
        onBrowse?(mountPoint, path)
        viewModel.reset()
        showCredentialSheet = false
        setPanelPreventDismiss(false)
        onDismiss?()
    }

    /// Tell the panel not to dismiss when it loses key status (e.g. during credential entry)
    private func setPanelPreventDismiss(_ prevent: Bool) {
        if let panel = NSApp.windows.first(where: { $0 is LauncherPanel }) as? LauncherPanel {
            panel.preventDismiss = prevent
        }
    }
}

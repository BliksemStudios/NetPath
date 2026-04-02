import SwiftUI
import SwiftData

struct BrowserView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Address bar — directly under the titlebar
            AddressBar(viewModel: viewModel)

            Divider().opacity(0.4)

            // Main content: sidebar + file listing
            HSplitView {
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)

                // File listing
                ZStack {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36))
                                .foregroundStyle(Design.Colors.errorRed)
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") { viewModel.refresh() }
                                .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.items.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "folder")
                                .font(.system(size: 36))
                                .foregroundStyle(.quaternary)
                            Text("This folder is empty")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .contextMenu {
                            DirectoryContextMenu(viewModel: viewModel)
                        }
                    } else {
                        switch viewModel.viewMode {
                        case .list: DirectoryListView(viewModel: viewModel)
                        case .grid: DirectoryGridView(viewModel: viewModel)
                        }
                    }
                }
            }

            Divider().opacity(0.4)

            // Status bar
            StatusBarView(
                itemCount: viewModel.items.count,
                server: viewModel.currentPath.server,
                username: viewModel.connectedAs,
                isConnected: true
            )
        }
        .frame(minWidth: Design.Browser.minWindowWidth, minHeight: Design.Browser.minWindowHeight)
    }
}

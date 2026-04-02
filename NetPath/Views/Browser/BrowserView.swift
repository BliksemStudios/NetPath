import SwiftUI
import SwiftData

struct BrowserView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            AddressBar(viewModel: viewModel)
            Divider()

            NavigationSplitView {
                SidebarView { uncPath in
                    if let path = UNCPath(from: uncPath) { viewModel.navigateTo(path: path) }
                }
            } detail: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle").font(.system(size: 32)).foregroundStyle(Design.Colors.errorRed)
                            Text(error).foregroundStyle(.secondary)
                            Button("Retry") { viewModel.refresh() }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.items.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder").font(.system(size: 32)).foregroundStyle(.tertiary)
                            Text("This folder is empty").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        switch viewModel.viewMode {
                        case .list: DirectoryListView(viewModel: viewModel)
                        case .grid: DirectoryGridView(viewModel: viewModel)
                        }
                    }
                }
            }

            Divider()
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

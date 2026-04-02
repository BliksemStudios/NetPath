import SwiftUI
import SwiftData

/// Tree-style folder browser sidebar showing the directory hierarchy
struct SidebarView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Server/share header
            HStack(spacing: 6) {
                Circle()
                    .fill(Design.Colors.connectedGreen)
                    .frame(width: 6, height: 6)
                Text(viewModel.currentPath.server)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().opacity(0.3)

            // Tree view
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.sidebarFolders) { folder in
                        SidebarFolderRow(
                            folder: folder,
                            isCurrentPath: folder.uncPath == viewModel.currentPath,
                            onNavigate: { viewModel.navigateTo(path: folder.uncPath) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(minWidth: Design.Browser.sidebarWidth)
    }
}

struct SidebarFolder: Identifiable {
    let id = UUID()
    let name: String
    let uncPath: UNCPath
    let depth: Int
    let isExpanded: Bool
}

struct SidebarFolderRow: View {
    let folder: SidebarFolder
    let isCurrentPath: Bool
    let onNavigate: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onNavigate) {
            HStack(spacing: 4) {
                // Indentation
                Spacer().frame(width: CGFloat(folder.depth) * 16)

                Image(systemName: folder.isExpanded ? "folder.fill" : "folder")
                    .font(.system(size: 12))
                    .foregroundStyle(isCurrentPath ? Design.Colors.accent : .secondary)
                    .frame(width: 16)

                Text(folder.name)
                    .font(.system(size: 12))
                    .foregroundStyle(isCurrentPath ? .primary : .secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isCurrentPath ? Design.Colors.selectedHighlight
                          : isHovered ? Design.Colors.hoverHighlight
                          : Color.clear)
                    .padding(.horizontal, 4)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

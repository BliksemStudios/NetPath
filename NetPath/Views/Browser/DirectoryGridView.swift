import SwiftUI

struct DirectoryGridView: View {
    @Bindable var viewModel: BrowserViewModel

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.sortedItems) { item in
                        VStack(spacing: 6) {
                            Image(systemName: item.icon)
                                .font(.system(size: 32))
                                .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                                .frame(height: 40)

                            Text(item.name)
                                .font(.system(size: 11))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 96, height: 80)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture(count: 2) {
                            if item.isDirectory { viewModel.navigateIntoFolder(item) }
                            else { viewModel.openFile(item) }
                        }
                        .contextMenu {
                            FileContextMenu(item: item, viewModel: viewModel)
                        }
                    }
                }
                .padding(16)

                // Empty space filler
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .contentShape(Rectangle())
                    .contextMenu {
                        DirectoryContextMenu(viewModel: viewModel)
                    }
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .contextMenu {
                    DirectoryContextMenu(viewModel: viewModel)
                }
        )
    }
}

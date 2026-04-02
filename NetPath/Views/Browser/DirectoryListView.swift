import SwiftUI

struct DirectoryListView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Spacer().frame(width: 28)
                sortableHeader("Name", field: .name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                sortableHeader("Date Modified", field: .dateModified)
                    .frame(width: 150, alignment: .leading)
                sortableHeader("Size", field: .size)
                    .frame(width: 80, alignment: .trailing)
                sortableHeader("Kind", field: .kind)
                    .frame(width: 100, alignment: .leading)
                    .padding(.leading, 16)
            }
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .frame(height: 28)

            Divider().opacity(0.5)

            // File list with full-area context menu
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.sortedItems) { item in
                        FileRowView(item: item)
                            .onTapGesture(count: 2) {
                                if item.isDirectory { viewModel.navigateIntoFolder(item) }
                                else { viewModel.openFile(item) }
                            }
                            .contextMenu {
                                FileContextMenu(item: item, viewModel: viewModel)
                            }
                    }

                    // Empty space filler — makes the rest of the scroll area right-clickable
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .contentShape(Rectangle())
                        .contextMenu {
                            DirectoryContextMenu(viewModel: viewModel)
                        }
                }
                .frame(maxWidth: .infinity)
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

    private func sortableHeader(_ title: String, field: SortField) -> some View {
        Button(action: { viewModel.toggleSort(field) }) {
            HStack(spacing: 4) {
                Text(title)
                if viewModel.sortBy == field {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

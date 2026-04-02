import SwiftUI

struct DirectoryListView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer().frame(width: 24)
                sortableHeader("Name", field: .name).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
                sortableHeader("Date Modified", field: .dateModified).frame(width: 150, alignment: .leading)
                sortableHeader("Size", field: .size).frame(width: 80, alignment: .trailing)
                sortableHeader("Kind", field: .kind).frame(width: 100, alignment: .leading).padding(.leading, 16)
            }
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 28)
            .background(.bar)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.sortedItems) { item in
                        FileRowView(item: item)
                            .onTapGesture(count: 2) {
                                if item.isDirectory { viewModel.navigateIntoFolder(item) }
                                else { viewModel.openFile(item) }
                            }
                            .contextMenu { contextMenu(for: item) }
                    }
                }
            }
        }
    }

    private func sortableHeader(_ title: String, field: SortField) -> some View {
        Button(action: { viewModel.toggleSort(field) }) {
            HStack(spacing: 4) {
                Text(title)
                if viewModel.sortBy == field {
                    Image(systemName: viewModel.sortAscending ? "chevron.up" : "chevron.down").font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        Button("Open") {
            if item.isDirectory { viewModel.navigateIntoFolder(item) }
            else { viewModel.openFile(item) }
        }
        Divider()
        Button("Copy UNC Path") { viewModel.copyUNCPath(item) }
        Button("Copy SMB URL") { viewModel.copySMBURL(item) }
        Divider()
        Button("Reveal in Finder") { viewModel.revealInFinder(item) }
    }
}

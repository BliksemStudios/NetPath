import SwiftUI

struct DirectoryGridView: View {
    @Bindable var viewModel: BrowserViewModel

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.sortedItems) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                            .frame(height: 44)
                        Text(item.name).font(.system(size: 12)).lineLimit(2).multilineTextAlignment(.center)
                    }
                    .frame(width: 100, height: 90)
                    .padding(8)
                    .onTapGesture(count: 2) {
                        if item.isDirectory { viewModel.navigateIntoFolder(item) }
                        else { viewModel.openFile(item) }
                    }
                    .contextMenu {
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
            }
            .padding(16)
        }
    }
}

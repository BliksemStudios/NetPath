import SwiftUI

struct AddressBar: View {
    @Bindable var viewModel: BrowserViewModel
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left").frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoBack)
                .foregroundStyle(viewModel.canGoBack ? .primary : .tertiary)

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right").frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoForward)
                .foregroundStyle(viewModel.canGoForward ? .primary : .tertiary)
            }

            if isEditing {
                TextField("Path", text: $viewModel.addressBarText)
                    .font(Design.Fonts.pathMono)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.navigateToAddressBar()
                        isEditing = false
                    }
                    .onExitCommand { isEditing = false }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        Text("\\\\")
                            .font(Design.Fonts.pathMono)
                            .foregroundStyle(.secondary)
                        ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                            if index > 0 {
                                Text("›").font(Design.Fonts.pathMono).foregroundStyle(.tertiary).padding(.horizontal, 2)
                            }
                            Button(crumb.label) { viewModel.navigateTo(path: crumb.path) }
                                .buttonStyle(.plain)
                                .font(Design.Fonts.pathMono)
                                .foregroundStyle(index == viewModel.breadcrumbs.count - 1 ? .primary : Design.Colors.accent)
                        }
                    }
                }
                .onTapGesture(count: 2) { isEditing = true }
                .contentShape(Rectangle())
            }

            Spacer()

            HStack(spacing: 2) {
                Button(action: { viewModel.viewMode = .list }) {
                    Image(systemName: "list.bullet").frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.viewMode == .list ? Design.Colors.accent : .secondary)

                Button(action: { viewModel.viewMode = .grid }) {
                    Image(systemName: "square.grid.2x2").frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.viewMode == .grid ? Design.Colors.accent : .secondary)
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

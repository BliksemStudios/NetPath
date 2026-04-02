import SwiftUI

struct AddressBar: View {
    @Bindable var viewModel: BrowserViewModel
    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            // Navigation buttons
            HStack(spacing: 2) {
                navButton(icon: "chevron.left", enabled: viewModel.canGoBack) {
                    viewModel.goBack()
                }
                navButton(icon: "chevron.right", enabled: viewModel.canGoForward) {
                    viewModel.goForward()
                }
                navButton(icon: "chevron.up", enabled: viewModel.currentPath.parentPath != nil) {
                    viewModel.goUp()
                }
            }

            // Path bar
            Group {
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
                        HStack(spacing: 0) {
                            Text("\\\\")
                                .font(Design.Fonts.pathMono)
                                .foregroundStyle(.tertiary)

                            ForEach(Array(viewModel.breadcrumbs.enumerated()), id: \.element.id) { index, crumb in
                                if index > 0 {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.quaternary)
                                        .padding(.horizontal, 4)
                                }

                                Button(crumb.label) {
                                    viewModel.navigateTo(path: crumb.path)
                                }
                                .buttonStyle(.plain)
                                .font(Design.Fonts.pathMono)
                                .foregroundStyle(
                                    index == viewModel.breadcrumbs.count - 1
                                        ? .primary
                                        : Design.Colors.accent
                                )
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(index == viewModel.breadcrumbs.count - 1
                                              ? Design.Colors.accent.opacity(0.1)
                                              : Color.clear)
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .onTapGesture(count: 2) { isEditing = true }
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.5))
            )

            // Refresh
            navButton(icon: "arrow.clockwise", enabled: true) {
                viewModel.refresh()
            }

            // View toggle
            HStack(spacing: 0) {
                viewToggleButton(icon: "list.bullet", mode: .list)
                viewToggleButton(icon: "square.grid.2x2", mode: .grid)
            }
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .foregroundStyle(enabled ? .secondary : .quaternary)
    }

    private func viewToggleButton(icon: String, mode: ViewMode) -> some View {
        Button(action: { viewModel.viewMode = mode }) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(viewModel.viewMode == mode ? Design.Colors.accent : .secondary)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(viewModel.viewMode == mode ? Design.Colors.accent.opacity(0.12) : Color.clear)
        )
    }
}

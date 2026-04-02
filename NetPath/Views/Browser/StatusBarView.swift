import SwiftUI

struct StatusBarView: View {
    let itemCount: Int
    let server: String
    let username: String
    let isConnected: Bool

    var body: some View {
        HStack {
            Text("\(itemCount) items")
                .font(Design.Fonts.statusBar)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Design.Colors.connectedGreen : Design.Colors.errorRed)
                    .frame(width: 6, height: 6)
                Text("\(username) — \(server)")
                    .font(Design.Fonts.statusBar)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Design.Browser.statusBarHeight)
        .background(.bar)
    }
}

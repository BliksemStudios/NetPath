import SwiftUI

struct StatusBarView: View {
    let itemCount: Int
    let server: String
    let username: String
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                .font(Design.Fonts.statusBar)
                .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Design.Colors.connectedGreen : Design.Colors.errorRed)
                    .frame(width: 6, height: 6)

                if !username.isEmpty {
                    Text("\(username) — \(server)")
                        .font(Design.Fonts.statusBar)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(server)
                        .font(Design.Fonts.statusBar)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: Design.Browser.statusBarHeight)
    }
}

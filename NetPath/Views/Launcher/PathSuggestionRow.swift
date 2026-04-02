import SwiftUI

struct PathSuggestionRow: View {
    let entry: PathEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.isPinned ? "star.fill" : "clock.arrow.circlepath")
                .font(.system(size: 13))
                .foregroundStyle(entry.isPinned ? Design.Colors.accent : .secondary)
                .frame(width: 16)

            Text(entry.uncPath)
                .font(Design.Fonts.pathMono)
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer()

            if entry.isPinned {
                Text("Pinned")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                Text(entry.lastVisited, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Design.Colors.selectedHighlight : Color.clear)
        )
    }
}

import SwiftUI

struct FileRowView: View {
    let item: FileItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                .frame(width: 28)

            Text(item.name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)

            Text(item.formattedDate)
                .foregroundStyle(.tertiary)
                .frame(width: 150, alignment: .leading)

            Text(item.formattedSize)
                .foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .trailing)
                .font(Design.Fonts.pathMonoSmall)

            Text(item.kindDescription)
                .foregroundStyle(.tertiary)
                .frame(width: 100, alignment: .leading)
                .padding(.leading, 16)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .frame(minHeight: Design.Browser.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Design.Colors.hoverHighlight : Color.clear)
                .padding(.horizontal, 4)
        )
        .onHover { isHovered = $0 }
    }
}

import SwiftUI

struct FileRowView: View {
    let item: FileItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: item.icon)
                .foregroundStyle(item.isDirectory ? Design.Colors.accent : .secondary)
                .frame(width: 24)
            Text(item.name).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 8)
            Text(item.formattedDate).foregroundStyle(.secondary).frame(width: 150, alignment: .leading)
            Text(item.formattedSize).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
            Text(item.kindDescription).foregroundStyle(.secondary).frame(width: 100, alignment: .leading).padding(.leading, 16)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .frame(height: Design.Browser.rowHeight)
        .background(isHovered ? Design.Colors.hoverHighlight : Color.clear)
        .onHover { isHovered = $0 }
    }
}

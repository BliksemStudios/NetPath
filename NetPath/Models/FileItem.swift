import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let path: URL
    let isDirectory: Bool
    let size: Int64?
    let dateModified: Date?
    let contentType: UTType?

    var icon: String {
        if isDirectory { return "folder.fill" }
        guard let contentType else { return "doc" }
        if contentType.conforms(to: .image) { return "photo" }
        if contentType.conforms(to: .movie) { return "film" }
        if contentType.conforms(to: .audio) { return "music.note" }
        if contentType.conforms(to: .pdf) { return "doc.richtext" }
        if contentType.conforms(to: .spreadsheet) { return "tablecells" }
        if contentType.conforms(to: .presentation) { return "slider.horizontal.below.rectangle" }
        if contentType.conforms(to: .sourceCode) { return "chevron.left.forwardslash.chevron.right" }
        if contentType.conforms(to: .archive) { return "doc.zipper" }
        if contentType.conforms(to: .text) { return "doc.text" }
        return "doc"
    }

    var kindDescription: String {
        if isDirectory { return "Folder" }
        guard let contentType else { return "Document" }
        return contentType.localizedDescription ?? contentType.preferredFilenameExtension?.uppercased() ?? "Document"
    }

    var formattedSize: String {
        guard let size, !isDirectory else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let dateModified else { return "—" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateModified, relativeTo: Date())
    }

    static func defaultSort(_ a: FileItem, _ b: FileItem) -> Bool {
        if a.isDirectory != b.isDirectory { return a.isDirectory }
        return a.name.localizedStandardCompare(b.name) == .orderedAscending
    }
}

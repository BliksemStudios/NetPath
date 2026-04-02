import Foundation
import UniformTypeIdentifiers

final class FileSystemService: Sendable {

    func listDirectory(at url: URL, showHidden: Bool = false) throws -> [FileItem] {
        let keys: [URLResourceKey] = [
            .nameKey, .isDirectoryKey, .fileSizeKey,
            .contentModificationDateKey, .typeIdentifierKey,
            .isHiddenKey,
        ]

        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: showHidden ? [] : [.skipsHiddenFiles]
        )

        return contents.compactMap { fileURL -> FileItem? in
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else {
                return nil
            }

            let isDir = values.isDirectory ?? false
            let size = isDir ? nil : Int64(values.fileSize ?? 0)

            return FileItem(
                id: fileURL.path,
                name: values.name ?? fileURL.lastPathComponent,
                path: fileURL,
                isDirectory: isDir,
                size: size,
                dateModified: values.contentModificationDate,
                contentType: fileURL.utType
            )
        }
        .sorted(by: FileItem.defaultSort)
    }
}

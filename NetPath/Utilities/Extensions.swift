import SwiftUI
import UniformTypeIdentifiers

extension URL {
    var utType: UTType? {
        guard let typeIdentifier = try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            return UTType(filenameExtension: pathExtension)
        }
        return UTType(typeIdentifier)
    }
}

extension String {
    var domainPrefix: String {
        let parts = split(separator: ".")
        guard let first = parts.first else { return self }
        return first.uppercased()
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

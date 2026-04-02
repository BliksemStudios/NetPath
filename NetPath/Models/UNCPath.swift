import Foundation

struct UNCPath: Equatable, Hashable, Sendable {
    let server: String
    let share: String?
    let components: [String]

    var smbURL: URL {
        var comps = URLComponents()
        comps.scheme = "smb"
        comps.host = server
        var fullPath = ""
        if let share { fullPath += "/\(share)" }
        for component in components { fullPath += "/\(component)" }
        if !fullPath.isEmpty {
            comps.path = fullPath
        }
        return comps.url!
    }

    var uncString: String {
        var result = "\\\\\(server)"
        if let share {
            result += "\\\(share)"
        }
        for component in components {
            result += "\\\(component)"
        }
        return result
    }

    var displayPath: String { uncString }

    var parentPath: UNCPath? {
        if !components.isEmpty {
            return UNCPath(server: server, share: share, components: Array(components.dropLast()))
        }
        if share != nil {
            return UNCPath(server: server, share: nil, components: [])
        }
        return nil
    }

    func appending(component: String) -> UNCPath {
        UNCPath(server: server, share: share, components: components + [component])
    }

    init(server: String, share: String?, components: [String]) {
        self.server = server
        self.share = share
        self.components = components
    }

    init?(from input: String) {
        var cleaned = input

        // Strip invisible Unicode characters
        let invisibleScalars: [Unicode.Scalar] = [
            "\u{200B}", "\u{200C}", "\u{200D}", "\u{FEFF}",
            "\u{00AD}", "\u{200E}", "\u{200F}", "\u{202A}",
            "\u{202B}", "\u{202C}", "\u{202D}", "\u{202E}",
            "\u{2060}", "\u{2061}", "\u{2062}", "\u{2063}",
        ]
        for scalar in invisibleScalars {
            cleaned = cleaned.replacingOccurrences(of: String(scalar), with: "")
        }

        // Strip surrounding whitespace and quotes
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        // Check if it's an SMB URL
        if cleaned.lowercased().hasPrefix("smb://") {
            guard let url = URL(string: cleaned) else { return nil }
            guard let host = url.host, !host.isEmpty else { return nil }
            self.server = host

            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.isEmpty {
                self.share = nil
                self.components = []
            } else {
                self.share = pathComponents[0]
                self.components = Array(pathComponents.dropFirst())
            }
            return
        }

        // Normalize: replace forward slashes with backslashes
        cleaned = cleaned.replacingOccurrences(of: "/", with: "\\")

        // Must start with at least \\ (UNC prefix)
        guard cleaned.hasPrefix("\\\\") else { return nil }

        // Remove leading backslashes
        cleaned = String(cleaned.drop(while: { $0 == "\\" }))

        // Normalize multiple consecutive backslashes to single
        while cleaned.contains("\\\\") {
            cleaned = cleaned.replacingOccurrences(of: "\\\\", with: "\\")
        }

        // Trim trailing backslash
        if cleaned.hasSuffix("\\") {
            cleaned = String(cleaned.dropLast())
        }

        guard !cleaned.isEmpty else { return nil }

        let segments = cleaned.split(separator: "\\", omittingEmptySubsequences: true)
            .map(String.init)

        guard !segments.isEmpty else { return nil }

        self.server = segments[0]

        if segments.count > 1 {
            self.share = segments[1]
            self.components = Array(segments.dropFirst(2))
        } else {
            self.share = nil
            self.components = []
        }
    }
}

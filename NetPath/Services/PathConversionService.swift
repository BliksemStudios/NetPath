import Foundation

struct PathConversionService: Sendable {

    func parse(_ input: String) -> UNCPath? {
        UNCPath(from: input)
    }

    func toSMBURL(_ path: UNCPath) -> String {
        path.smbURL.absoluteString
    }

    func toUNCDisplay(_ smbURL: String) -> String? {
        guard let path = UNCPath(from: smbURL) else { return nil }
        return path.uncString
    }

    func extractServer(_ input: String) -> String? {
        UNCPath(from: input)?.server
    }

    func buildCredentialString(domain: String?, username: String) -> String {
        if let domain, !domain.isEmpty {
            return "\(domain)\\\(username)"
        }
        return username
    }

    func parseCredentialString(_ input: String) -> (domain: String?, username: String) {
        if let backslashIndex = input.firstIndex(of: "\\") {
            let domain = String(input[input.startIndex..<backslashIndex])
            let username = String(input[input.index(after: backslashIndex)...])
            return (domain.isEmpty ? nil : domain, username)
        }
        return (nil, input)
    }
}

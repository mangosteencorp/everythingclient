import Foundation
import Plex_Shared_Backend

extension DemoSession {
    /// Pretty-printed JSON with token, password and secret fields and known credentials redacted.
    func formatted(_ result: PlexHTTPResult) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: result.data, options: [.fragmentsAllowed]) else {
            return String(localized: "Response: \(result.statusCode), \(result.data.count) bytes of non-JSON content.")
        }
        func redact(_ value: Any) -> Any {
            if let dictionary = value as? [String: Any] {
                return dictionary.reduce(into: [String: Any]()) { output, pair in
                    let sensitive = ["token", "password", "secret", "authorization"].contains { pair.key.lowercased().contains($0) }
                    output[pair.key] = sensitive ? "[redacted]" : redact(pair.value)
                }
            }
            if let array = value as? [Any] { return array.map(redact) }
            if let string = value as? String { return redacted(string) }
            return value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: redact(json), options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return String(text.prefix(200_000))
    }

    nonisolated static func message(for error: any Error) -> String {
        switch error {
        case PlexAPIError.offline:
            String(localized: "This isn't available offline. Open it once while connected, or download it.")
        case PlexAPIError.noReachableServer:
            String(localized: "No working connection was found for this server. Check that it is online and accessible, then retry.")
        case PlexAPIError.pinExpired: String(localized: "Your sign-in code expired. Start sign-in again.")
        case let PlexAPIError.httpStatus(code):
            String(localized: "Plex returned HTTP \(code). Check access permissions and the selected connection.")
        case PlexAPIError.invalidConfiguration:
            String(localized: "No usable server address is available. Check the server access token or use the advanced connection settings.")
        case PlexAPIError.invalidPath:
            String(localized: "Use a server-relative path without credentials, traversal, or an external host.")
        case PlexAPIError.missingMachineIdentifier:
            String(localized: "The server did not report its identifier, so this list can't be changed.")
        case PlexAPIError.noDownloadableMedia, PlexAPIError.unavailablePart:
            String(localized: "No complete original file is available for this media selection. Try another version.")
        case is URLError: String(localized: "The server couldn't be reached. Check your connection or turn on offline mode.")
        case is DecodingError: String(localized: "Plex returned an unexpected response format for this operation.")
        default: String(localized: "The operation failed. Check the connection and try again.")
        }
    }
}

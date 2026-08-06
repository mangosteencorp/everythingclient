import Foundation

#if DEBUG
/// DEBUG-only TMDB API key. The literal key lives in `Preview/DebugPreview.swift`,
/// which is excluded from the Swift package target (not compiled/indexed).
public let debugTMDBAPIKey: String = DebugPreviewKeyLoader.load()

enum DebugPreviewKeyLoader {
    static func load() -> String {
        if let env = ProcessInfo.processInfo.environment["TMDB_API_KEY"], !env.isEmpty {
            return env
        }
        for url in candidateURLs() {
            if let key = parseKey(from: url) {
                return key
            }
        }
        assertionFailure("debugTMDBAPIKey unavailable: set TMDB_API_KEY or keep Preview/DebugPreview.swift on disk")
        return ""
    }

    private static func candidateURLs() -> [URL] {
        let thisFile = URL(fileURLWithPath: #filePath)
        let previewDir = thisFile.deletingLastPathComponent()
        var urls = [previewDir.appendingPathComponent("DebugPreview.swift")]

        // Walk up from this source file looking for the repo-relative path.
        var directory = previewDir
        for _ in 0 ..< 6 {
            directory.deleteLastPathComponent()
            urls.append(
                directory
                    .appendingPathComponent("Sources/TMDB_Shared_Backend/Preview/DebugPreview.swift")
            )
        }
        return urls
    }

    private static func parseKey(from url: URL) -> String? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        // public let debugTMDBAPIKey = "..."
        guard let equalsRange = contents.range(of: "debugTMDBAPIKey"),
              let quoteStart = contents[equalsRange.upperBound...].firstIndex(of: "\""),
              let quoteEnd = contents[contents.index(after: quoteStart)...].firstIndex(of: "\"")
        else { return nil }
        let key = contents[contents.index(after: quoteStart) ..< quoteEnd]
        return key.isEmpty ? nil : String(key)
    }
}
#endif

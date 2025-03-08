import everythingclient
import SwiftUI

@main
struct RebuildApp: App {
#if DEBUG
    let isAppStoreOrTestFlight = false
#else
    let isAppStoreOrTestFlight = true
#endif

    var body: some Scene {
        WindowGroup {
            RootContentView(
                TMDBApiKey: try! Configuration.value(for: "TMDB_API_KEY"),
                isAppStoreOrTestFlight: isAppStoreOrTestFlight,
                options3rdPartySDKs: .init(firebase: true) // mark this as false if you don't have GoogleService-Info.plist or not indending to use Firebase
            )
        }
    }
}

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

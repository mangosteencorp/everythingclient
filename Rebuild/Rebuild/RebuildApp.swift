//
//  RebuildApp.swift
//  Rebuild
//
//  Created by Quang on 2024-04-18.
//

import SwiftUI
import everythingclient
@main
struct RebuildApp: App {
    var body: some Scene {
        WindowGroup {
            RootContentView(TMDBApiKey: try! Configuration.value(for: "TMDB_API_KEY"))
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

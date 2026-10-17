import Foundation
import Observation
#if canImport(SwiftfinLib)
import SwiftfinLib
#endif

/// Display information only; authentication remains owned by Swiftfin.
public struct SwiftfinConnectionInfo: Equatable, Sendable {
    public let serverName: String
    public let username: String

    public init(serverName: String, username: String) {
        self.serverName = serverName
        self.username = username
    }
}

/// Isolates the optional Swiftfin session API from feature modules and previews.
public protocol SwiftfinSessionServicing: Sendable {
    var isAvailable: Bool { get }
    func currentConnection() async throws -> SwiftfinConnectionInfo?
}

public struct SwiftfinSessionService: SwiftfinSessionServicing {
    public init() {}

    public var isAvailable: Bool {
        #if canImport(SwiftfinLib) && SWIFTFIN_LAUNCHER_BRIDGE
        true
        #else
        false
        #endif
    }

    public func currentConnection() async throws -> SwiftfinConnectionInfo? {
        #if canImport(SwiftfinLib) && SWIFTFIN_LAUNCHER_BRIDGE
        guard let connection = try await SwiftfinLibrary.currentConnection() else { return nil }
        return SwiftfinConnectionInfo(serverName: connection.serverName, username: connection.username)
        #else
        return nil
        #endif
    }
}

public enum SwiftfinConnectionStatus: Equatable, Sendable {
    case loading
    case unavailable
    case notConnected
    case connected(SwiftfinConnectionInfo)
    case failed
}

@MainActor
@Observable
public final class SwiftfinConnectionModel {
    public private(set) var status: SwiftfinConnectionStatus = .loading
    private let service: any SwiftfinSessionServicing

    public init(service: any SwiftfinSessionServicing = SwiftfinSessionService()) {
        self.service = service
    }

    public func refresh() async {
        guard service.isAvailable else {
            status = .unavailable
            return
        }
        status = .loading
        do {
            let connection = try await service.currentConnection()
            guard !Task.isCancelled else { return }
            status = connection.map(SwiftfinConnectionStatus.connected) ?? .notConnected
        } catch {
            guard !Task.isCancelled else { return }
            status = .failed
        }
    }
}

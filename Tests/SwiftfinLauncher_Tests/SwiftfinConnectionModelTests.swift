import Foundation
import SwiftfinLauncher
import Testing

@MainActor
struct SwiftfinConnectionModelTests {
    @Test func displaysTheConnectedServerAndUser() async {
        let info = SwiftfinConnectionInfo(serverName: "Home Cinema", username: "Alex")
        let service = SessionStub(result: .success(info))
        let model = SwiftfinConnectionModel(service: service)
        await model.refresh()
        #expect(model.status == .connected(info))
        #expect(await service.requests == 1)
    }

    @Test func noSessionIsDifferentFromAnUnavailableAPI() async {
        let model = SwiftfinConnectionModel(service: SessionStub(result: .success(nil)))
        await model.refresh()
        #expect(model.status == .notConnected)
    }

    @Test func unavailableAPIDoesNotReadSessionStorage() async {
        let service = SessionStub(isAvailable: false, result: .success(nil))
        let model = SwiftfinConnectionModel(service: service)
        await model.refresh()
        #expect(model.status == .unavailable)
        #expect(await service.requests == 0)
    }

    @Test func failureDoesNotPretendTheUserSignedOut() async {
        let model = SwiftfinConnectionModel(service: SessionStub(result: .failure(.unavailable)))
        await model.refresh()
        #expect(model.status == .failed)
    }

    @Test func refreshReadsTheNewSessionAfterSwiftfinCloses() async {
        let first = SwiftfinConnectionInfo(serverName: "Home", username: "Alex")
        let second = SwiftfinConnectionInfo(serverName: "Studio", username: "Sam")
        let service = SessionStub(result: .success(first))
        let model = SwiftfinConnectionModel(service: service)
        await model.refresh()
        await service.update(.success(second))
        await model.refresh()
        #expect(model.status == .connected(second))
        #expect(await service.requests == 2)
    }
}

private enum SessionFailure: Error { case unavailable }

private actor SessionStub: SwiftfinSessionServicing {
    let isAvailable: Bool
    private var result: Result<SwiftfinConnectionInfo?, SessionFailure>
    private(set) var requests = 0

    init(isAvailable: Bool = true, result: Result<SwiftfinConnectionInfo?, SessionFailure>) {
        self.isAvailable = isAvailable
        self.result = result
    }

    func currentConnection() throws -> SwiftfinConnectionInfo? {
        requests += 1
        return try result.get()
    }

    func update(_ result: Result<SwiftfinConnectionInfo?, SessionFailure>) {
        self.result = result
    }
}

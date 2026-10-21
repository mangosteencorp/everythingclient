@testable import PlexIntegration
import PlexLauncher
import Testing

struct PlexSharedLauncherTests {
    @Test func concurrentResumesShareOneRequest() async throws {
        let base = try LaunchingFake(resume: .success(connection()), holdsResume: true)
        let launcher = PlexSharedLauncher(base)
        let first = Task { try await launcher.resume()?.name }
        while await base.resumeCount == 0 { await Task.yield() }
        let second = Task { try await launcher.resume()?.name }
        // Give the second call time to join the held request before it is released.
        try await Task.sleep(for: .milliseconds(100))
        await base.releaseResume()
        #expect(try await first.value == "Home Cinema")
        #expect(try await second.value == "Home Cinema")
        #expect(await base.resumeCount == 1)
    }

    @Test func aFinishedResumeIsNotReused() async throws {
        let base = try LaunchingFake(resume: .success(connection()))
        let launcher = PlexSharedLauncher(base)
        _ = try await launcher.resume()
        _ = try await launcher.resume()
        #expect(await base.resumeCount == 2)
    }
}

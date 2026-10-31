@testable import CoreFeatures
import SwiftUI
import Testing
import UIKit

private enum PinTestDesign: String, DesignVariant {
    case alpha
    case beta
    case gamma

    static var slotTitle: String { "Pin Test Slot" }
    static var fallback: PinTestDesign { .alpha }
    var displayName: String { rawValue }
}

/// Records what `@DesignStyle` resolved to each time SwiftUI evaluates it.
private final class Probe {
    var seen: PinTestDesign?
}

private struct ProbeView: View {
    let probe: Probe
    @DesignStyle private var design: PinTestDesign

    var body: some View {
        probe.seen = design
        return Text(design.rawValue)
    }
}

@MainActor
struct DesignStyleTests {
    private let suiteName = "design.style.tests.\(UUID().uuidString)"

    private func makeCoordinator(selecting value: PinTestDesign) throws -> DesignCoordinator {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let coordinator = DesignCoordinator(defaults: defaults, storageKey: "selections")
        coordinator.select(value)
        return coordinator
    }

    /// Lays the view out once, which is enough for SwiftUI to evaluate every body in it.
    private func render(_ view: some View) {
        _ = UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 320, height: 480))
    }

    @Test func pinnedSlotOverridesTheCoordinator() throws {
        let coordinator = try makeCoordinator(selecting: .beta)
        var overrides = DesignOverrides()
        overrides[PinTestDesign.self] = .gamma

        #expect(overrides.resolve(PinTestDesign.self, from: coordinator) == .gamma)
        #expect(DesignOverrides().resolve(PinTestDesign.self, from: coordinator) == .beta)
        #expect(coordinator.style(PinTestDesign.self) == .beta, "pinning must not write to the coordinator")
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test func viewReadsInjectedCoordinatorUnlessPinned() throws {
        let coordinator = try makeCoordinator(selecting: .beta)
        let injected = Probe()
        let pinned = Probe()

        render(ProbeView(probe: injected).environment(\.designCoordinator, coordinator))
        render(
            ProbeView(probe: pinned)
                .designStyle(PinTestDesign.gamma)
                .environment(\.designCoordinator, coordinator)
        )

        #expect(injected.seen == .beta)
        #expect(pinned.seen == .gamma)
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}

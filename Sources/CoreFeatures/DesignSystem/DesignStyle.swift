import SwiftUI

/// Reads one design slot from the environment and redraws the view whenever it changes.
///
/// ```swift
/// struct FeedTabContainer: View {
///     @DesignStyle private var design: FeedTabDesign
///     var body: some View { switch design { ... } }
/// }
/// ```
///
/// The value comes from the nearest `.designStyle(_:)` pin for this slot, otherwise from the
/// injected `designCoordinator`, otherwise from `DesignCoordinator.shared` — so a host can
/// decide the look from outside, while previews, unit tests and views rendered outside the app
/// shell still work without any injection step:
///
/// ```swift
/// FeedPage(...).designStyle(FeedContentDesign.paletteCards)       // pin one slot
/// AppRoot().environment(\.designCoordinator, DesignCoordinator(defaults: suite)) // own store
/// ```
///
/// `$design` writes go to the coordinator; a pinned subtree keeps showing its pin.
@MainActor
@propertyWrapper
public struct DesignStyle<V: DesignVariant>: DynamicProperty {
    @Environment(\.designCoordinator) private var injectedCoordinator
    @Environment(\.designOverrides) private var overrides

    public init() {}

    public var wrappedValue: V {
        overrides.resolve(V.self, from: coordinator)
    }

    public var projectedValue: Binding<V> {
        let coordinator = coordinator
        let overrides = overrides
        return Binding(
            get: { overrides.resolve(V.self, from: coordinator) },
            set: { coordinator.select($0) }
        )
    }

    private var coordinator: DesignCoordinator { injectedCoordinator ?? .shared }
}

public extension EnvironmentValues {
    /// The coordinator `@DesignStyle` and the shuffle button use; `nil` means
    /// `DesignCoordinator.shared`. Optional because the default must be a stable,
    /// nonisolated constant and `shared` is main-actor isolated.
    @Entry var designCoordinator: DesignCoordinator?
}

extension EnvironmentValues {
    @Entry var designOverrides = DesignOverrides()
}

/// Slots pinned with `.designStyle(_:)` for one subtree, keyed by `DesignVariant.slotKey`.
struct DesignOverrides {
    private var rawValues: [String: String] = [:]

    subscript<V: DesignVariant>(_: V.Type) -> V? {
        get { rawValues[V.slotKey].flatMap(V.init(rawValue:)) }
        set { rawValues[V.slotKey] = newValue?.rawValue }
    }

    /// The pin when there is one this device can show, otherwise the coordinator's choice.
    /// A pinned slot never reads the coordinator, so a shuffle leaves it alone.
    @MainActor
    func resolve<V: DesignVariant>(_: V.Type, from coordinator: DesignCoordinator) -> V {
        guard let pinned = self[V.self], pinned.isAvailableOnThisDevice else {
            return coordinator.style(V.self)
        }
        return pinned
    }
}

public extension View {
    /// Pins one design slot for this subtree, overriding the coordinator without touching what
    /// it stores. One modifier per slot: `.designStyle(FeedEmptyStateDesign.plain)`.
    func designStyle<V: DesignVariant>(_ value: V) -> some View {
        transformEnvironment(\.designOverrides) { $0[V.self] = value }
    }
}

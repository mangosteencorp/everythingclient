import SwiftUI

/// Reads one design slot and redraws the view whenever it changes.
///
/// ```swift
/// struct FeedTabContainer: View {
///     @DesignStyle private var design: FeedTabDesign
///     var body: some View { switch design { ... } }
/// }
/// ```
///
/// Backed by `DesignCoordinator.shared` rather than `@EnvironmentObject`, so previews, unit
/// tests and views rendered outside the app shell all work without an injection step — the
/// same singleton arrangement `ThemeManager` already uses in this module.
@propertyWrapper
public struct DesignStyle<V: DesignVariant>: DynamicProperty {
    @ObservedObject private var coordinator: DesignCoordinator

    public init(_ coordinator: DesignCoordinator = .shared) {
        _coordinator = ObservedObject(wrappedValue: coordinator)
    }

    public var wrappedValue: V {
        coordinator.style(V.self)
    }

    public var projectedValue: Binding<V> {
        coordinator.binding(V.self)
    }
}

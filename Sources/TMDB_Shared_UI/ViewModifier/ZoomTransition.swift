import SwiftUI

// MARK: - Namespace plumbing

/// The zoom navigation transition needs one `Namespace` shared by the tapped view and the pushed
/// page. Navigation here is value based — feature modules build routes through closures and never
/// see the page they push — so the namespace travels through the environment instead of being
/// passed down by hand.
private struct ZoomTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    var zoomTransitionNamespace: Namespace.ID? {
        get { self[ZoomTransitionNamespaceKey.self] }
        set { self[ZoomTransitionNamespaceKey.self] = newValue }
    }
}

/// Owns the namespace and publishes it to everything below.
private struct ZoomTransitionNamespaceRoot: ViewModifier {
    @Namespace private var namespace

    func body(content: Content) -> some View {
        content.environment(\.zoomTransitionNamespace, namespace)
    }
}

// MARK: - View modifiers

/// Marks the view a zoom transition should grow out of.
private struct ZoomTransitionSource<ID: Hashable>: ViewModifier {
    @Environment(\.zoomTransitionNamespace) private var namespace
    let id: ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// Marks the pushed page a zoom transition should grow into.
private struct ZoomTransitionDestination<ID: Hashable>: ViewModifier {
    @Environment(\.zoomTransitionNamespace) private var namespace
    let id: ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), let namespace {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

public extension View {
    /// Publishes a zoom transition namespace to every view below, including pages pushed by
    /// `navigationDestination`.
    ///
    /// Apply this **above** the `NavigationStack`. Pushed destinations inherit the stack's own
    /// environment, not the environment of the stack's root content — putting this inside the
    /// stack leaves both ends of the transition reading `nil`, and each modifier below silently
    /// falls back to a plain push.
    func zoomTransitionNamespaceRoot() -> some View {
        modifier(ZoomTransitionNamespaceRoot())
    }

    /// Tags this view as the origin of a zoom navigation transition.
    ///
    /// Pass the same value handed to `NavigationLink(value:)`: routes are `Hashable`, so the
    /// route itself pairs the source with its destination without either side knowing the other.
    /// A no-op before iOS 18, and a no-op when no namespace has been published — callers stay
    /// free of availability branches.
    func zoomTransitionSource(id: some Hashable) -> some View {
        modifier(ZoomTransitionSource(id: id))
    }

    /// Tags this view as the destination of a zoom transition originating from `id`.
    ///
    /// Falls back to the standard push when no matching source is on screen.
    func zoomTransitionDestination(id: some Hashable) -> some View {
        modifier(ZoomTransitionDestination(id: id))
    }
}

import Foundation

/// A family of interchangeable looks for one part of the UI — a "design slot".
///
/// Every module declares its own conforming enum (app shell, feed tabs, feed content, …);
/// `CoreFeatures` never learns about the concrete cases. Adding a new look is one new case
/// plus one new view — nothing in this file changes.
///
/// ```swift
/// public enum FeedTabDesign: String, DesignVariant {
///     case systemTabs
///     case pageController
///
///     public static var slotTitle: String { "Feed Tabs" }
///     public static var fallback: FeedTabDesign { .pageController }
///     public var displayName: String { ... }
/// }
/// ```
public protocol DesignVariant: CaseIterable, Hashable, Identifiable, RawRepresentable
    where RawValue == String, AllCases == [Self] {
    /// Section header used by the design picker menu, e.g. "Feed Tabs".
    static var slotTitle: String { get }
    /// Used when nothing is stored yet, or when the stored case is not available on this device.
    static var fallback: Self { get }
    var displayName: String { get }
    /// Lets a variant opt out on a given idiom/OS version — the picker hides it and the
    /// shuffle never lands on it.
    var isAvailableOnThisDevice: Bool { get }
}

public extension DesignVariant {
    var id: String { rawValue }

    var isAvailableOnThisDevice: Bool { true }

    static var availableCases: [Self] {
        let available = allCases.filter(\.isAvailableOnThisDevice)
        // A slot with nothing available would make `style(_:)` return an unusable case.
        return available.isEmpty ? [fallback] : available
    }

    /// Stable key for persistence. Renaming the type resets that slot to its fallback,
    /// which is why `rawValue`s (not ordinals) are what get stored.
    static var slotKey: String { String(describing: Self.self) }
}

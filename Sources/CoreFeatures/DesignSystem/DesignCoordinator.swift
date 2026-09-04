import SwiftUI

/// Single source of truth for which look each design slot is currently wearing.
///
/// Every level of the UI reads the same object, so one mutation redraws the app shell, the
/// inner feed tabs and the feed content inside a single SwiftUI transaction — which is what
/// makes `shuffleAll()` change everything at once instead of level by level.
@MainActor
public final class DesignCoordinator: ObservableObject {
    /// A registered slot, flattened at registration time so the shuffle and the picker can
    /// work without knowing the concrete `DesignVariant` type.
    public struct Slot: Identifiable, Hashable {
        public struct Option: Identifiable, Hashable {
            public let rawValue: String
            public let displayName: String
            public var id: String { rawValue }
        }

        public let key: String
        public let title: String
        public let options: [Option]
        public let fallbackRawValue: String
        public var id: String { key }
    }

    public static let shared = DesignCoordinator()

    @Published private var selections: [String: String]

    /// Deliberately *not* `@Published`: registration happens lazily from `style(_:)`, which is
    /// called during view body evaluation. Publishing here would mutate observed state mid-update.
    public private(set) var slots: [Slot] = []

    private let defaults: UserDefaults
    private let storageKey: String

    public init(defaults: UserDefaults = .standard, storageKey: String = "design_coordinator_selections") {
        self.defaults = defaults
        self.storageKey = storageKey
        selections = defaults.dictionary(forKey: storageKey) as? [String: String] ?? [:]
    }

    // MARK: - Reading

    /// The current look for `type`. Never fails: falls back when nothing is stored, when the
    /// stored case was removed from the enum, or when it is unavailable on this device.
    public func style<V: DesignVariant>(_ type: V.Type) -> V {
        registerIfNeeded(V.self)

        guard let rawValue = selections[V.slotKey],
              let value = V(rawValue: rawValue),
              value.isAvailableOnThisDevice else {
            return V.fallback
        }
        return value
    }

    public func binding<V: DesignVariant>(_ type: V.Type) -> Binding<V> {
        Binding(
            get: { [weak self] in self?.style(V.self) ?? V.fallback },
            set: { [weak self] newValue in self?.select(newValue) }
        )
    }

    // MARK: - Writing

    public func select<V: DesignVariant>(_ value: V) {
        registerIfNeeded(V.self)
        apply([V.slotKey: value.rawValue])
    }

    /// Type-erased setter used by the picker menu, which only has strings to work with.
    public func select(slotKey: String, rawValue: String) {
        guard slots.contains(where: { $0.key == slotKey }) else { return }
        apply([slotKey: rawValue])
    }

    /// Rolls a new look for every registered slot in one go. Slots with more than one available
    /// option never land on their current value, so a tap always visibly changes something.
    public func shuffleAll() {
        var newSelections = selections
        for slot in slots {
            let current = newSelections[slot.key] ?? slot.fallbackRawValue
            let candidates = slot.options.map(\.rawValue).filter { $0 != current }
            guard let pick = candidates.randomElement() else { continue }
            newSelections[slot.key] = pick
        }
        apply(newSelections, replacingAll: true)
    }

    public func resetToDefaults() {
        apply([:], replacingAll: true)
    }

    // MARK: - Registration

    public func registerIfNeeded<V: DesignVariant>(_ type: V.Type) {
        let key = V.slotKey
        guard !slots.contains(where: { $0.key == key }) else { return }

        slots.append(Slot(
            key: key,
            title: V.slotTitle,
            options: V.availableCases.map { Slot.Option(rawValue: $0.rawValue, displayName: $0.displayName) },
            fallbackRawValue: V.fallback.rawValue
        ))
    }

    /// Current option of a slot, for the picker's checkmark.
    public func selectedRawValue(for slot: Slot) -> String {
        selections[slot.key] ?? slot.fallbackRawValue
    }

    // MARK: - Private

    private func apply(_ changes: [String: String], replacingAll: Bool = false) {
        let updated: [String: String]
        if replacingAll {
            updated = changes
        } else {
            updated = selections.merging(changes) { _, new in new }
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            selections = updated
        }
        defaults.set(updated, forKey: storageKey)
    }
}

import SwiftUI

/// Toolbar button that re-rolls every registered design slot at once.
///
/// Tap shuffles. Long press opens a picker listing each registered slot and its available
/// looks, which is how you get back to a specific combination for a screenshot or a bug report.
public struct DesignShuffleToolbarItem: ToolbarContent {
    private let placement: ToolbarItemPlacement
    private let accessibilityIdentifier: String
    private let coordinator: DesignCoordinator

    public init(
        placement: ToolbarItemPlacement = .platformTrailing,
        accessibilityIdentifier: String = "design.shuffle.button",
        coordinator: DesignCoordinator = .shared
    ) {
        self.placement = placement
        self.accessibilityIdentifier = accessibilityIdentifier
        self.coordinator = coordinator
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            DesignShuffleButton(
                accessibilityIdentifier: accessibilityIdentifier,
                coordinator: coordinator
            )
        }
    }
}

public struct DesignShuffleButton: View {
    @ObservedObject private var coordinator: DesignCoordinator
    private let accessibilityIdentifier: String

    public init(
        accessibilityIdentifier: String = "design.shuffle.button",
        coordinator: DesignCoordinator = .shared
    ) {
        self.accessibilityIdentifier = accessibilityIdentifier
        _coordinator = ObservedObject(wrappedValue: coordinator)
    }

    public var body: some View {
        Button {
            coordinator.shuffleAll()
        } label: {
            Image(systemName: "shuffle")
        }
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel("Shuffle design")
        .contextMenu {
            ForEach(coordinator.slots) { slot in
                Menu(slot.title) {
                    ForEach(slot.options) { option in
                        Button {
                            coordinator.select(slotKey: slot.key, rawValue: option.rawValue)
                        } label: {
                            if coordinator.selectedRawValue(for: slot) == option.rawValue {
                                Label(option.displayName, systemImage: "checkmark")
                            } else {
                                Text(option.displayName)
                            }
                        }
                    }
                }
            }

            Divider()

            Button {
                coordinator.resetToDefaults()
            } label: {
                Label("Reset to defaults", systemImage: "arrow.counterclockwise")
            }
        }
    }
}

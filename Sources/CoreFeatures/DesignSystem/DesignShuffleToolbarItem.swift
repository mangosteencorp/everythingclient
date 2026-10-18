import SwiftUI

/// Toolbar button that re-rolls every registered design slot at once.
///
/// Tap shuffles. Long press opens a picker listing each registered slot and its available
/// looks, which is how you get back to a specific combination for a screenshot or a bug report.
/// Acts on the environment's `designCoordinator`, the same one the `@DesignStyle` views below
/// it read.
public struct DesignShuffleToolbarItem: ToolbarContent {
    private let placement: ToolbarItemPlacement
    private let accessibilityIdentifier: String

    public init(
        placement: ToolbarItemPlacement = .navigationBarTrailing,
        accessibilityIdentifier: String = "design.shuffle.button"
    ) {
        self.placement = placement
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            DesignShuffleButton(accessibilityIdentifier: accessibilityIdentifier)
        }
    }
}

public struct DesignShuffleButton: View {
    @Environment(\.designCoordinator) private var injectedCoordinator
    private let accessibilityIdentifier: String

    public init(accessibilityIdentifier: String = "design.shuffle.button") {
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    private var coordinator: DesignCoordinator { injectedCoordinator ?? .shared }

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

#if DEBUG
#Preview {
    NavigationStack {
        Text("Tap to shuffle, long press to pick")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { DesignShuffleButton() }
            }
    }
}
#endif

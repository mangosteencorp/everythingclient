#if DEBUG
import SwiftUI

/// Every core feature preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing.
public enum CoreFeaturesPreviewCatalog: String, CaseIterable {
    case themeSwitcherDemo
    case themeSwitchButton
    case designShuffleButton
    case sectionedTabView

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .themeSwitcherDemo:
            ThemeSwitcherDemoView()
        case .themeSwitchButton:
            NavigationStack {
                Text("Tap the toolbar button to cycle themes")
                    .toolbar { ThemeSwitchButton() }
            }
            .environmentObject(ThemeManager.shared)
        case .designShuffleButton:
            NavigationStack {
                Text("Tap to shuffle, long press to pick")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) { DesignShuffleButton() }
                    }
            }
        case .sectionedTabView:
            SectionedTabViewPreview()
        }
    }
}
#endif

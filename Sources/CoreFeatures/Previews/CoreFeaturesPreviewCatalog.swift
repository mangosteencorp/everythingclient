#if DEBUG
import SwiftUI

/// Every core feature preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing.
public enum CoreFeaturesPreviewCatalog: String, CaseIterable {
    case themeSwitcherDemo

    @MainActor
    public var view: some View {
        ThemeSwitcherDemoView()
    }
}
#endif

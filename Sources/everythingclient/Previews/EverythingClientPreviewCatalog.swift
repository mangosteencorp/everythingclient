#if DEBUG
import SwiftUI
import TMDB_Shared_Backend

/// The app root's preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. It is the whole app, loading live from TMDB, with
/// every tab turned on.
public enum EverythingClientPreviewCatalog: String, CaseIterable {
    case allTabs

    @MainActor
    public var view: some View {
        TabManager.shared.availableTabs = Set(AppTab.allCases)
        return RootContentView(TMDBApiKey: debugTMDBAPIKey, isAppStoreOrTestFlight: false)
    }
}
#endif

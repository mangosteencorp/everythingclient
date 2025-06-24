import SwiftUI
import TMDB_Shared_Backend
// swiftlint:disable all
#if DEBUG
import TMDB_Shared_Backend
#Preview {
    // Initialize TabManager.shared.availableTabs for preview
    TabManager.shared.availableTabs = Set(AppTab.allCases)

    return RootContentView(
        TMDBApiKey: debugTMDBAPIKey,
        isAppStoreOrTestFlight: false
    )
}
#endif
// swiftlint:enable all

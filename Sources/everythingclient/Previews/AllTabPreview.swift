import SwiftUI

// swiftlint:disable all
#if DEBUG
import TMDB_Shared_Backend
#Preview {
    RootContentView(
        TMDBApiKey: debugTMDBAPIKey,
        isAppStoreOrTestFlight: false
    )
}
#endif
// swiftlint:enable all

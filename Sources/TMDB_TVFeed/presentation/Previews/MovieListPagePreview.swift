import SwiftUI
import Swinject
import TMDB_Shared_Backend
#if DEBUG
@available(iOS 16, *)
#Preview {
    MovieListPage(
        container: Container(),
        apiKey: debugTMDBAPIKey,
        type: .nowPlaying,
        detailRouteBuilder: { _ in 1 })
}

#endif

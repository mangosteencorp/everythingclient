#if DEBUG
import SwiftUI
import TMDB_Shared_Backend

/// Every person preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. All of it is Brad Pitt from the sample fixtures.
public enum TMDBPersonPreviewCatalog: String, CaseIterable {
    case detailPage

    @MainActor
    public var view: some View {
        NavigationStack {
            PersonDetailPage(personId: PersonDetail.example.id, apiService: Self.apiService, movieRouteBuilder: { $0 })
        }
    }

    private static var apiService: PreviewTMDBAPIRequester {
        PreviewTMDBAPIRequester([
            .personDetail(person: PersonDetail.example.id): PersonDetail.example,
            .personMovieCredits(person: PersonDetail.example.id): PersonMovieCredits.example,
        ])
    }
}
#endif

#if DEBUG
import SwiftUI
import TMDB_Shared_Backend

/// Every person preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. All of it is Brad Pitt from the sample fixtures.
public enum TMDBPersonPreviewCatalog: String, CaseIterable {
    case detailPage
    case contentCarousel
    case contentList
    case header
    case profileImage
    case factGrid
    case biography
    case scoreTimeline
    case filmographyCarousel
    case filmographySection
    case movieCreditRows
    case errorState

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .detailPage:
            NavigationStack {
                PersonDetailPage(personId: PersonDetail.example.id, apiService: Self.apiService, movieRouteBuilder: { $0 })
            }
        case .contentCarousel, .contentList:
            NavigationStack {
                PersonDetailContent(
                    person: .example,
                    credits: Self.credits,
                    useCarouselFilmography: self == .contentCarousel,
                    movieRouteBuilder: { $0 }
                )
            }
        case .filmographyCarousel:
            NavigationStack {
                PersonFilmographyCarouselSection(credits: Self.credits, movieRouteBuilder: { $0 })
                    .padding()
            }
        case .filmographySection:
            NavigationStack {
                ScrollView {
                    PersonFilmographySection(credits: Self.credits, movieRouteBuilder: { $0 })
                        .padding()
                }
            }
        case .errorState:
            PersonErrorStateView(message: "The Internet connection appears to be offline.", retry: {})
        default:
            padded.padding()
        }
    }

    @MainActor @ViewBuilder
    private var padded: some View {
        switch self {
        case .header:
            PersonDetailHeaderView(person: .example)
        case .profileImage:
            PersonProfileImageView(profilePath: nil)
        case .factGrid:
            PersonFactGrid(person: .example)
        case .biography:
            PersonBiographySection(
                biography: "William Bradley Pitt is an American actor and film producer. He is the recipient of various accolades, including two Academy Awards."
            )
        case .scoreTimeline:
            PersonScoreTimelineSection(credits: Self.credits)
        default:
            VStack {
                PersonMovieCreditRow(credit: PersonMovieCredits.example.cast[0])
                PersonMovieCreditRow(credit: PersonMovieCredits.example.crew[0])
            }
        }
    }

    private static var credits: [PersonMovieCredit] { PersonMovieCredits.example.featuredCredits }

    private static var apiService: PreviewTMDBAPIRequester {
        PreviewTMDBAPIRequester([
            .personDetail(person: PersonDetail.example.id): PersonDetail.example,
            .personMovieCredits(person: PersonDetail.example.id): PersonMovieCredits.example,
        ])
    }
}
#endif

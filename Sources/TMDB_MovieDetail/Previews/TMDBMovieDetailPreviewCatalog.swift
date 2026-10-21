#if DEBUG
import PlexIntegration
import SwiftfinLauncher
import SwiftUI
import TMDB_Shared_Backend

/// Every movie detail preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. Everything but `demo` is seeded with the
/// sample movie and never reaches TMDB; `demo` is the live page.
public enum TMDBMovieDetailPreviewCatalog: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case demo
    case detailPage
    case coverRow
    case coverRowWithOverview
    case creditSection
    case crosslinePeople
    case crosslinePeopleRedacted
    case peopleSeeAllList
    case keywords
    case locations
    case roundedBadges
    case watchProviders
    case watchProvidersLoading
    case watchProvidersError
    case ostSection
    case jellyfinSection
    case plexSection
    case serverSection
    case serverSectionPlexOnly
    case sectionRetry

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBMovieDetailDemoView()
        case .detailPage:
            NavigationStack { Self.loadedPage }
        case .coverRow:
            Section {
                MovieCoverRow(movie: exampleMovieDetail)
            }
        case .coverRowWithOverview:
            Section {
                MovieCoverRow(movie: exampleMovieDetail)
                MovieOverview(movie: exampleMovieDetail)
            }
        case .creditSection:
            MovieCreditSection(movieId: exampleMovieCredits.id, creditsViewModel: Self.creditsViewModel, personRouteBuilder: { $0 })
        case .watchProviders, .watchProvidersLoading, .watchProvidersError:
            MovieWatchProvidersSection(movieId: exampleMovieDetail.id, watchProvidersViewModel: watchProvidersViewModel)
        case .plexSection:
            List {
                Section {
                    MoviePlexSection(plexViewModel: Self.plexViewModel(), movieTitle: "Dune", movieYear: 2021)
                }
            }
        case .serverSection, .serverSectionPlexOnly:
            // Plain, like the detail page, so the section header looks the same.
            List {
                MovieServerSection(
                    movieTitle: "Dune",
                    movieId: 438_631,
                    movieYear: 2021,
                    jellyfinViewModel: self == .serverSection ? Self.jellyfinViewModel() : Self.signedOutJellyfinViewModel,
                    plexViewModel: Self.plexViewModel()
                )
            }
            .listStyle(.plain)
        default:
            staticView
        }
    }

    @MainActor @ViewBuilder
    private var staticView: some View {
        switch self {
        case .crosslinePeople:
            MovieCrosslinePeopleRow(title: "Cast", peoples: examplePeoples, personRouteBuilder: { $0 })
        case .crosslinePeopleRedacted:
            RedactedMovieCrosslinePeopleRow()
        case .peopleSeeAllList:
            NavigationStack {
                List(examplePeoples) { people in PeopleListItem(people: people, personRouteBuilder: { $0 }) }
            }
        case .keywords:
            MovieKeywords(keywords: Self.sampleKeywords, discoverMovieByKeywordRouteBuilder: { _ in 1 })
        case .locations:
            MovieLocations(locations: ["Los Angeles", "New York", "London", "Paris", "Tokyo", "Peru", "Amazon Rainforest"])
        case .roundedBadges:
            VStack(spacing: 10) {
                RoundedBadge(text: "Hello, World!", color: .red)
                RoundedBadge(text: "Gradient Badge", color: .blue, useGradient: true)
                RoundedBadge(text: "Another Badge", color: .green, useGradient: true)
            }
        case .ostSection:
            List {
                MovieOSTSection(ostViewModel: Self.ostViewModel)
            }
        case .jellyfinSection:
            let viewModel = Self.jellyfinViewModel()
            List {
                Section {
                    MovieJellyfinSection(movieTitle: "Dune", movieId: 438_631, jellyfinViewModel: viewModel)
                }
            }
            .task {
                await viewModel.load(title: "Dune", tmdbID: 438_631)
            }
        default:
            List {
                SectionRetryView(message: "The Internet connection appears to be offline.") {}
            }
        }
    }

    @MainActor
    private var watchProvidersViewModel: MovieWatchProvidersViewModel {
        let viewModel = MovieWatchProvidersViewModel(apiService: PreviewTMDBAPIRequester())
        switch self {
        case .watchProvidersLoading: viewModel.state = .loading
        case .watchProvidersError: viewModel.state = .error("The Internet connection appears to be offline.")
        default: viewModel.state = .success(.example)
        }
        return viewModel
    }
}

private extension TMDBMovieDetailPreviewCatalog {
    /// The page with every section already loaded, so it never asks TMDB for anything.
    @MainActor
    static var loadedPage: some View {
        let apiService = PreviewTMDBAPIRequester()
        let movieDetailViewModel = MovieDetailViewModel(apiService: apiService)
        movieDetailViewModel.state = .success(exampleMovieDetail)
        let watchProvidersViewModel = MovieWatchProvidersViewModel(apiService: apiService)
        watchProvidersViewModel.state = .success(.example)

        return MovieDetailPage(
            movie: exampleMovieDetail,
            // Only used to build view models, and every one is passed in.
            apiService: TMDBAPIService(apiKey: ""),
            movieDetailViewModel: movieDetailViewModel,
            creditsViewModel: creditsViewModel,
            watchProvidersViewModel: watchProvidersViewModel,
            ostViewModel: MovieOSTViewModel(),
            jellyfinViewModel: jellyfinViewModel(title: exampleMovieDetail.userTitle),
            plexViewModel: plexViewModel(title: exampleMovieDetail.userTitle),
            discoverMovieByKeywordRouteBuilder: { _ in 1 },
            photoSlidesRouteBuilder: { _, index in index }
        )
    }

    @MainActor
    static var creditsViewModel: MovieCastingViewModel {
        let viewModel = MovieCastingViewModel(apiService: PreviewTMDBAPIRequester())
        viewModel.state = .success(exampleMovieCredits)
        return viewModel
    }

    @MainActor
    static var ostViewModel: MovieOSTViewModel {
        let viewModel = MovieOSTViewModel()
        viewModel.state = .success([
            MovieOSTAlbumDisplayModel(
                id: "1",
                title: "Superman (Original Motion Picture Soundtrack)",
                artistName: "Various Artists",
                trackCount: 24,
                artwork: nil,
                url: URL(string: "https://music.apple.com")
            ),
        ])
        return viewModel
    }

    @MainActor
    static func jellyfinViewModel(title: String = "Dune (2021)") -> MovieJellyfinViewModel {
        let match = JellyfinMovieMatch(
            id: "abc",
            title: title,
            runtimeSeconds: 9315,
            playedFraction: 0.35,
            resumeSeconds: 3260,
            isPlayed: false
        )
        let viewModel = MovieJellyfinViewModel(service: PreviewJellyfinLibraryService(match: match))
        viewModel.state = .found(match)
        return viewModel
    }

    @MainActor
    static var signedOutJellyfinViewModel: MovieJellyfinViewModel {
        let viewModel = MovieJellyfinViewModel(service: PreviewJellyfinLibraryService(match: nil))
        viewModel.state = .unavailable
        return viewModel
    }

    /// A match built here has no server behind it, so its player shows why it cannot play.
    @MainActor
    static func plexViewModel(title: String = "Dune") -> MoviePlexViewModel {
        let match = PlexMovieMatch(
            id: "42",
            title: title,
            runtimeSeconds: 9315,
            playedFraction: 0.6,
            resumeSeconds: 5589,
            isPlayed: false
        )
        let viewModel = MoviePlexViewModel(service: PreviewPlexLibraryService(match: match))
        viewModel.state = .found(match)
        return viewModel
    }

    static var sampleKeywords: [Keyword] {
        [
            Keyword(id: 613, name: "new year's eve"),
            Keyword(id: 592, name: "capitalism"),
            Keyword(id: 2449, name: "black market"),
            Keyword(id: 1284, name: "identity"),
            Keyword(id: 10123, name: "dark comedy"),
            Keyword(id: 8201, name: "satire"),
            Keyword(id: 4995, name: "aging"),
            Keyword(id: 6562, name: "celebrity"),
            Keyword(id: 11322, name: "female protagonist"),
            Keyword(id: 12670, name: "los angeles, california"),
            Keyword(id: 163_405, name: "aerobics"),
            Keyword(id: 170_383, name: "disfigurement"),
            Keyword(id: 187_056, name: "woman director"),
            Keyword(id: 214_664, name: "beauty standards"),
            Keyword(id: 224_636, name: "horror comedy"),
            Keyword(id: 228_429, name: "insecure woman"),
            Keyword(id: 245_415, name: "toxic masculinity"),
            Keyword(id: 251_961, name: "drug"),
            Keyword(id: 283_085, name: "body horror"),
            Keyword(id: 295_902, name: "actress"),
            Keyword(id: 325_778, name: "bold"),
            Keyword(id: 325_801, name: "distressing"),
        ]
    }
}

private struct PreviewJellyfinLibraryService: JellyfinLibraryServicing {
    let match: JellyfinMovieMatch?
    var isAvailable: Bool { true }

    func findMovie(title: String, tmdbID: Int) async throws -> JellyfinMovieMatch? {
        match
    }
}

private struct PreviewPlexLibraryService: PlexLibraryServicing {
    let match: PlexMovieMatch
    var isSignedIn: Bool { true }

    func findMovie(title: String, year: Int?) async throws -> PlexMovieMatch? {
        match
    }
}
#endif

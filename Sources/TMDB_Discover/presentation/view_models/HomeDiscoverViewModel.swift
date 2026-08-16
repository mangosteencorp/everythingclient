import CoreFeatures
import SwiftUI

public class HomeDiscoverViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var tvGenres: [Genre] = []
    @Published var popularPeople: [PopularPerson] = []
    @Published var trendingItems: [TrendingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchGenresUseCase: FetchGenresUseCase
    private let fetchTVGenresUseCase: FetchTVGenresUseCase
    private let fetchPopularPeopleUseCase: FetchPopularPeopleUseCase
    private let fetchTrendingItemsUseCase: FetchTrendingItemsUseCase
    private let analyticsTracker: AnalyticsTracker?
    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }

    init(
        fetchGenresUseCase: FetchGenresUseCase,
        fetchTVGenresUseCase: FetchTVGenresUseCase,
        fetchPopularPeopleUseCase: FetchPopularPeopleUseCase,
        fetchTrendingItemsUseCase: FetchTrendingItemsUseCase,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.fetchGenresUseCase = fetchGenresUseCase
        self.fetchTVGenresUseCase = fetchTVGenresUseCase
        self.fetchPopularPeopleUseCase = fetchPopularPeopleUseCase
        self.fetchTrendingItemsUseCase = fetchTrendingItemsUseCase
        self.analyticsTracker = analyticsTracker
    }

    /// Bridge for the UIKit caller. Single-flight: a second call while a load is in flight is a
    /// no-op, and the handle lets the controller stop the work when it goes away.
    func fetchAllData() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self] in
            await self?.fetchAll()
            await MainActor.run { self?.loadTask = nil }
        }
    }

    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func fetchAll() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        async let genresResult = fetchGenresUseCase.execute()
        async let tvGenresResult = fetchTVGenresUseCase.execute()
        async let peopleResult = fetchPopularPeopleUseCase.execute()
        async let trendingResult = fetchTrendingItemsUseCase.execute()

        let (genres, tvGenres, people, trending) = await (genresResult, tvGenresResult, peopleResult, trendingResult)

        await MainActor.run {
            self.isLoading = false

            // Dropped results when the controller went away; the next appearance loads again.
            guard !Task.isCancelled else { return }

            switch genres {
            case .success(let genreList):
                self.genres = genreList
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }

            switch tvGenres {
            case .success(let tvGenreList):
                self.tvGenres = tvGenreList
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }

            switch people {
            case .success(let peopleList):
                self.popularPeople = peopleList
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }

            switch trending {
            case .success(let trendingList):
                self.trendingItems = trendingList
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }

            analyticsTracker?.trackPageView(parameters: PageViewParameters(
                screenName: "HomeDiscover",
                screenClass: "HomeDiscoverViewController"
            ))
        }
    }
}

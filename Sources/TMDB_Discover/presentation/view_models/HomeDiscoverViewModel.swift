import CoreFeatures
import SwiftUI

public class HomeDiscoverViewModel: ObservableObject {
    @Published var genres: [Genre] = []
    @Published var popularPeople: [PopularPerson] = []
    @Published var trendingItems: [TrendingItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchGenresUseCase: FetchGenresUseCase
    private let fetchPopularPeopleUseCase: FetchPopularPeopleUseCase
    private let fetchTrendingItemsUseCase: FetchTrendingItemsUseCase
    private let analyticsTracker: AnalyticsTracker?

    init(
        fetchGenresUseCase: FetchGenresUseCase,
        fetchPopularPeopleUseCase: FetchPopularPeopleUseCase,
        fetchTrendingItemsUseCase: FetchTrendingItemsUseCase,
        analyticsTracker: AnalyticsTracker? = nil
    ) {
        self.fetchGenresUseCase = fetchGenresUseCase
        self.fetchPopularPeopleUseCase = fetchPopularPeopleUseCase
        self.fetchTrendingItemsUseCase = fetchTrendingItemsUseCase
        self.analyticsTracker = analyticsTracker
    }

    func fetchAllData() {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            async let genresResult = fetchGenresUseCase.execute()
            async let peopleResult = fetchPopularPeopleUseCase.execute()
            async let trendingResult = fetchTrendingItemsUseCase.execute()

            let (genres, people, trending) = await (genresResult, peopleResult, trendingResult)

            await MainActor.run {
                self.isLoading = false

                switch genres {
                case .success(let genreList):
                    self.genres = genreList
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
}

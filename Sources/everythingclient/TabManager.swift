import Combine
import Foundation
import TMDB
public class TabManager: ObservableObject {
    @Published public var availableTabs: Set<AppTab>

    public static let shared = TabManager()
    let specialKeywordMap: [Int: AppTab] = [
        11551: .pokedex, // pocket monsters
        222288: .pokedex, //
        210024: .pokedex, // anime
    ]

    private init() {
        availableTabs = []
    }

    public func enableSpecialTab(specialKeywordId: Int) {
        if let tab = specialKeywordMap[specialKeywordId], !availableTabs.contains(tab) {
            DispatchQueue.main.async {
                self.availableTabs.insert(tab)
            }
        }
    }
}

public enum AppTab: Int, CaseIterable, Identifiable {
    case tmdb = 0
    case pokedex = 1

    public var id: Int { rawValue }

    public var label: (String, String) {
        switch self {
        case .tmdb:
            return ("TMDB", "movieclapper")
        case .pokedex:
            return ("Pokédex", "sparkles")
        }
    }
}

extension TabManager: TMDBNavigationInterceptor {
    public func willNavigate(to route: TMDBRoute) {
        if case .movieList(let additionalMovieListParams) = route, let kwId = additionalMovieListParams.keywordId {
            enableSpecialTab(specialKeywordId: kwId)
        }
    }
}

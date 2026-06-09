import Combine
import Foundation
import TMDB

public class TabManager: ObservableObject {
    @Published public var availableTabs: Set<AppTab>

    public static let shared = TabManager()

    private init() {
        availableTabs = []
    }
}

public enum AppTab: Int, CaseIterable, Identifiable {
    case tmdb = 0

    public var id: Int { rawValue }

    public var label: (String, String) {
        switch self {
        case .tmdb:
            return ("TMDB", "movieclapper")
        }
    }
}

extension TabManager: TMDBNavigationInterceptor {
    public func willNavigate(to route: TMDBRoute) {
        _ = route
    }
}

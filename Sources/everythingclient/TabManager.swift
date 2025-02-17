import Combine
import Foundation
public class TabManager: ObservableObject {
    @Published public var availableTabs: Set<AppTab>

    public static let shared = TabManager()
    let specialKeywordMap: [Int: AppTab] = [11551: .pokedex]

    private init() {
        availableTabs = []
    }

    public func specialKeywordIdList() -> [Int] {
        return specialKeywordMap.keys.sorted()
    }

    public func enableSpecialTab(specialKeywordId: Int) {
        if let tab = specialKeywordMap[specialKeywordId] {
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

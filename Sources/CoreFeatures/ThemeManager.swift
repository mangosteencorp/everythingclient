import SwiftUI
public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    @Published var currentTheme: ThemeProtocol = LightTheme()

    private init() {}

    func setTheme(_ theme: ThemeProtocol) {
        currentTheme = theme
    }

    func availableThemes() -> [ThemeProtocol] {
        [LightTheme(), DarkTheme(), SepiaTheme()]
    }
}

import SwiftUI
public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    @Published public var currentTheme: ThemeProtocol = LightTheme()

    private init() {}

    public func setTheme(_ theme: ThemeProtocol) {
        currentTheme = theme
    }

    public func availableThemes() -> [ThemeProtocol] {
        [LightTheme(), DarkTheme(), SepiaTheme()]
    }
}

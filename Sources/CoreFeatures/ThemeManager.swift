import SwiftUI

@MainActor
public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var currentTheme: ThemeProtocol

    // Store user's theme preference
    @AppStorage("user_selected_theme_index") private var userSelectedThemeIndex: Int = -1
    @AppStorage("has_user_selected_theme") private var hasUserSelectedTheme: Bool = false

    private init() {
        // Initialize with a default theme first
        currentTheme = PlatformAppearance.isDarkMode ? DarkTheme() : LightTheme()

        // Then check if user has already selected a theme and update if needed
        if hasUserSelectedTheme && userSelectedThemeIndex >= 0 && userSelectedThemeIndex < availableThemes().count {
            // Use the saved theme
            currentTheme = availableThemes()[userSelectedThemeIndex]
        }

        // Setup notification to detect system appearance changes
        setupAppearanceChangeObserver()
    }

    public func setTheme(_ theme: ThemeProtocol) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }

    public func availableThemes() -> [ThemeProtocol] {
        [LightTheme(), DarkTheme(), SepiaTheme()]
    }

    public func switchToNextTheme() {
        let availableThemes = availableThemes()
        guard let currentIndex = availableThemes.firstIndex(where: { $0.backgroundColor == currentTheme.backgroundColor }) else { return }
        let nextIndex = (currentIndex + 1) % availableThemes.count

        withAnimation(.easeInOut(duration: 0.3)) {
            setTheme(availableThemes[nextIndex])
        }

        // Save the user's theme preference after switching
        saveThemePreference()
    }

    private func saveThemePreference() {
        if let currentThemeIndex = availableThemes().firstIndex(where: { $0.backgroundColor == currentTheme.backgroundColor }) {
            userSelectedThemeIndex = currentThemeIndex
            hasUserSelectedTheme = true
        }
    }

    private func setupAppearanceChangeObserver() {
        // `PlatformAppearance` owns which notifications actually signal an appearance change on
        // each platform. The previous `NSNotification.Name("UITraitCollectionDidChangeNotification")`
        // observer here was dead code: no such notification is ever posted, so it never fired.
        PlatformAppearance.addAppearanceChangeObserver(
            self,
            selector: #selector(handleAppearanceChange)
        )
    }

    @objc private func handleAppearanceChange() {
        // Only update theme based on system if user hasn't explicitly chosen a theme
        if !hasUserSelectedTheme {
            currentTheme = PlatformAppearance.isDarkMode ? DarkTheme() : LightTheme()
        }
    }

    deinit {
        PlatformAppearance.removeAppearanceChangeObserver(self)
    }
}

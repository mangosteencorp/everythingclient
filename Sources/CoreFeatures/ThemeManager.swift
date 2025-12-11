import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var currentTheme: ThemeProtocol

    // Store user's theme preference
    @AppStorage("user_selected_theme_index") private var userSelectedThemeIndex: Int = -1
    @AppStorage("has_user_selected_theme") private var hasUserSelectedTheme: Bool = false

    private init() {
        // Initialize with a default theme first
        #if canImport(UIKit)
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        #elseif canImport(AppKit)
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        #else
        let isDarkMode = false
        #endif
        currentTheme = isDarkMode ? DarkTheme() : LightTheme()

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
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTraitCollectionChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // Also observe for appearance changes while app is running
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTraitCollectionChange),
            name: NSNotification.Name("UITraitCollectionDidChangeNotification"),
            object: nil
        )
        #elseif canImport(AppKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTraitCollectionChange),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTraitCollectionChange),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        #endif
    }

    @objc private func handleTraitCollectionChange() {
        // Only update theme based on system if user hasn't explicitly chosen a theme
        if !hasUserSelectedTheme {
            #if canImport(UIKit)
            let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            #elseif canImport(AppKit)
            let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            #else
            let isDarkMode = false
            #endif
            currentTheme = isDarkMode ? DarkTheme() : LightTheme()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        #if canImport(AppKit)
        DistributedNotificationCenter.default().removeObserver(self)
        #endif
    }
}

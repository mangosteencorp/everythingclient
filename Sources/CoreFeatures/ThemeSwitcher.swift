import SwiftUI

public extension ThemeManager {
    func switchToNextTheme() {
        let availableThemes = availableThemes()
        guard let currentIndex = availableThemes.firstIndex(where: { $0.backgroundColor == currentTheme.backgroundColor }) else { return }
        let nextIndex = (currentIndex + 1) % availableThemes.count
        setTheme(availableThemes[nextIndex])
    }
}

public struct ThemeSwitchButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    public init() {}
    
    public var body: some View {
        Button(action: {
            themeManager.switchToNextTheme()
        }) {
            Image(systemName: "arrow.trianglehead.swap")
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
} 
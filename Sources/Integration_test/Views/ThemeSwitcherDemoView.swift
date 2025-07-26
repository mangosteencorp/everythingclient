import CoreFeatures
import SwiftUI

struct ThemeSwitcherDemoView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: ThemeProtocol = ThemeManager.shared.currentTheme

    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Switcher Demo")
                .font(.title)
                .padding()

            Text("Current Theme: \(themeName(for: themeManager.currentTheme))")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 10) {
                ForEach(ThemeManager.shared.availableThemes(), id: \.backgroundColor) { theme in
                    Button(action: {
                        themeManager.setTheme(theme)
                        selectedTheme = theme
                    }) {
                        HStack {
                            Text(themeName(for: theme))
                                .foregroundColor(.primary)
                            Spacer()
                            if theme.backgroundColor == selectedTheme.backgroundColor {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()

            Spacer()
        }
        .background(selectedTheme.backgroundColor)
        .foregroundColor(selectedTheme.labelColor)
    }

    private func themeName(for theme: ThemeProtocol) -> String {
        if theme.backgroundColor == Color.white {
            return "Light"
        } else if theme.backgroundColor == Color.black {
            return "Dark"
        } else {
            return "Sepia"
        }
    }
}

#if DEBUG
#Preview {
    ThemeSwitcherDemoView()
}
#endif
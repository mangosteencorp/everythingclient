import SwiftUI

public struct ThemeSwitchButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    public init() {}

    public var body: some View {
        Button(action: {
            themeManager.switchToNextTheme()
        }, label: {
            Image(systemName: "arrow.trianglehead.swap")
                .foregroundColor(.primary)
        })
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Text("Tap the toolbar button to cycle themes")
            .toolbar { ThemeSwitchButton() }
    }
    .environmentObject(ThemeManager.shared)
}
#endif

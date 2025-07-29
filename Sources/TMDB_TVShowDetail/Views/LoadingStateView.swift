import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct LoadingStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(themeManager.currentTheme.labelColor)
            
            Text(L10n.Tvshow.Detail.loading)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

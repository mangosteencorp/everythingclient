import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct TVShowOverviewSection: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Tvshow.Detail.overview)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text(overview)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor)
        }
    }
}

#if DEBUG
@available(iOS 15, *)
#Preview {
    TVShowOverviewSection(overview: "Seven noble families fight for control of the mythical land of Westeros.")
        .padding()
        .environmentObject(ThemeManager.shared)
}
#endif

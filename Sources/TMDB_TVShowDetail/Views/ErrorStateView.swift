import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct ErrorStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.6))

            Text(L10n.Tvshow.Detail.somethingWentWrong)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)

            Text(message)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(L10n.Tvshow.Detail.tryAgain) {
                Task { await retryAction() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

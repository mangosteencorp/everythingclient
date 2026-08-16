import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 15.0, *)
struct TVShowWatchProvidersSection: View {
    let tvShowId: Int
    let apiService: TMDBAPIService

    @EnvironmentObject private var themeManager: ThemeManager

    enum ViewState {
        case loading
        case success(WatchProviderResponse)
        case error(String)
    }

    @State private var state: ViewState = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Tvshow.Detail.whereToWatch)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.labelColor)
                .padding(.horizontal)

            contentView
        }
        .task(id: tvShowId) {
            await loadProviders()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .loading:
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(themeManager.currentTheme.labelColor)
                Text(L10n.Tvshow.Detail.loadingWatchProviders)
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
            }
            .padding()

        case .success(let response):
            if let userRegion = Locale.current.region?.identifier,
               let regionData = response.results[userRegion] {
                WatchProvidersView(regionData: regionData)
            } else if let firstRegion = response.results.first {
                WatchProvidersView(regionData: firstRegion.value)
            } else {
                Text(L10n.Tvshow.Detail.noWatchProviders)
                    .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                    .padding()
            }

        case .error(let message):
            Text(L10n.Tvshow.Detail.watchProvidersError(message))
                .foregroundColor(themeManager.currentTheme.labelColor)
                .padding()
        }
    }

    private func loadProviders() async {
        state = .loading
        do {
            let result: WatchProviderResponse = try await apiService.request(.tvShowWatchProviders(show: tvShowId))
            state = .success(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

@available(iOS 15.0, *)
private struct WatchProvidersView: View {
    let regionData: WatchProviderRegion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Streaming services (flatrate)
            if let flatrate = regionData.flatrate, !flatrate.isEmpty {
                ProviderCategoryView(title: L10n.Tvshow.Detail.streaming, providers: flatrate, regionLink: regionData.link)
            }

            // Free services
            if let free = regionData.free, !free.isEmpty {
                ProviderCategoryView(title: L10n.Tvshow.Detail.free, providers: free, regionLink: regionData.link)
            }

            // Rent services
            if let rent = regionData.rent, !rent.isEmpty {
                ProviderCategoryView(title: L10n.Tvshow.Detail.rent, providers: rent, regionLink: regionData.link)
            }

            // Buy services
            if let buy = regionData.buy, !buy.isEmpty {
                ProviderCategoryView(title: L10n.Tvshow.Detail.buy, providers: buy, regionLink: regionData.link)
            }
        }
    }
}

@available(iOS 15.0, *)
private struct ProviderCategoryView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let providers: [WatchProvider]
    let regionLink: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.labelColor)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(providers) { provider in
                        ProviderLogoView(provider: provider, regionLink: regionLink)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

@available(iOS 15.0, *)
private struct ProviderLogoView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let provider: WatchProvider
    let regionLink: String

    var body: some View {
        Button(action: {
            if let url = URL(string: regionLink) {
                UIApplication.shared.open(url)
            }
        }) {
            AsyncImage(url: URL(string: provider.logoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(provider.providerName.prefix(1))
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.labelColor.opacity(0.7))
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

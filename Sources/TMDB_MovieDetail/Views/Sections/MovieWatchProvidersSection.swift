import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
public struct MovieWatchProvidersSection: View {
    let movieId: Int
    @ObservedObject var watchProvidersViewModel: MovieWatchProvidersViewModel

    public init(movieId: Int, watchProvidersViewModel: MovieWatchProvidersViewModel) {
        self.movieId = movieId
        self.watchProvidersViewModel = watchProvidersViewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where to Watch")
                .font(.headline)
                .padding(.horizontal)

            switch watchProvidersViewModel.state {
            case .loading:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading watch providers...")
                        .foregroundColor(.secondary)
                }
                .padding()

            case .success(let watchProvidersResponse):
                if let userRegion = Locale.current.regionCode,
                   let regionData = watchProvidersResponse.results[userRegion] {
                    WatchProvidersView(regionData: regionData)
                } else {
                    // Fallback to first available region
                    if let firstRegion = watchProvidersResponse.results.first {
                        WatchProvidersView(regionData: firstRegion.value)
                    } else {
                        Text("No watch providers available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }

            case .error(let error):
                Text("Error loading watch providers: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

@available(iOS 16.0, *)
private struct WatchProvidersView: View {
    let regionData: WatchProviderRegion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Streaming services (flatrate)
            if let flatrate = regionData.flatrate, !flatrate.isEmpty {
                ProviderCategoryView(title: "Streaming", providers: flatrate, regionLink: regionData.link)
            }

            // Free services
            if let free = regionData.free, !free.isEmpty {
                ProviderCategoryView(title: "Free", providers: free, regionLink: regionData.link)
            }

            // Rent services
            if let rent = regionData.rent, !rent.isEmpty {
                ProviderCategoryView(title: "Rent", providers: rent, regionLink: regionData.link)
            }

            // Buy services
            if let buy = regionData.buy, !buy.isEmpty {
                ProviderCategoryView(title: "Buy", providers: buy, regionLink: regionData.link)
            }
        }
    }
}

@available(iOS 16.0, *)
private struct ProviderCategoryView: View {
    let title: String
    let providers: [WatchProvider]
    let regionLink: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
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

@available(iOS 16.0, *)
private struct ProviderLogoView: View {
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
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
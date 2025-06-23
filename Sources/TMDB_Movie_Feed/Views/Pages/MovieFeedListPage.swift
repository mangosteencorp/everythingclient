import Combine
import CoreFeatures
import Foundation
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, macOS 10.15, *)
public struct MovieFeedListPage<Route: Hashable>: View {
    @StateObject var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route

    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: MovieFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        self.detailRouteBuilder = detailRouteBuilder
    }

#if DEBUG
    init(
        viewModel: MovieFeedViewModel,
        detailRouteBuilder: @escaping (Movie) -> Route
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.detailRouteBuilder = detailRouteBuilder
    }
#endif

    public var body: some View {
        VStack(spacing: 0) {
            Group {
                switch viewModel.state {
                case .initial:
                    EmptyView()
                case .loading where viewModel.searchQuery.isEmpty:
                    ProgressView(L10n.playingLoading)
                case .error(let message):
                    Text(message)
                case .loaded(let movies), .searchResults(let movies):
                    List(movies) { movie in
                        NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                    }
                    .searchable(text: $viewModel.searchQuery)
                    .overlay {
                        if case .loading = viewModel.state {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .background(Color.black.opacity(0.1))
                        }
                    }
                case .loading:
                    List([] as [Movie]) { movie in
                        NavigationMovieRow(viewModel, movie: movie, routeBuilder: detailRouteBuilder)
                    }
                    .searchable(text: $viewModel.searchQuery)
                    .overlay {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .background(Color.black.opacity(0.1))
                    }
                }
            }
        }
        .accessibilityIdentifier("movielist1.group")
        .navigationTitle(viewModel.currentFeedType.localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(MovieFeedType.allCases) { feedType in
                        Button(action: {
                            viewModel.switchFeedType(feedType)
                        }) {
                            HStack {
                                Text(feedType.localizedTitle)
                                if viewModel.currentFeedType == feedType {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.primary)
                }
            }
        }
        .onFirstAppear {
            viewModel.fetchNowPlayingMovies()
        }
    }
}

// Custom search bar component
@available(iOS 16.0, *)
struct SearchBar: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search movies...", text: $text)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { focused in
                    isFocused = focused
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isTextFieldFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 16, macOS 10.15, *)
#Preview {
    MovieFeedListPage(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                      detailRouteBuilder: { _ in 1 })
}

@available(iOS 16, macOS 10.15, *)
#Preview("now playing page within nested tab view") {
    TabView {
        TabView {
            NavigationStack {
                MovieFeedListPage(
                    apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
                    detailRouteBuilder: { _ in 1 }
                )
                .tag(0)
                .tabItem {
                    Label("First View", systemImage: "house")
                }
            }
            Text("Second View").tag(1)
                .tabItem {
                    Label("Second View", systemImage: "gear")
                }
        }
        //.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .tag(0)
        .tabItem {
            Label("Outer First View", systemImage: "star")
        }
        Text("Outer Second View").tag(1)
            .tabItem {
                Label("Outer Second View", systemImage: "moon")
            }
    }
}
// swiftlint:enable all
#endif

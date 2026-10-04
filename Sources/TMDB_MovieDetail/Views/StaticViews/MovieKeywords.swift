import SwiftUI

@available(iOS 16.0, *)
struct MovieKeywords<Route: Hashable>: View {
    let keywords: [Keyword]
    let discoverMovieByKeywordRouteBuilder: (Int) -> Route
    init(
        keywords: [Keyword],
        discoverMovieByKeywordRouteBuilder: @escaping (Int) -> Route
    ) {
        self.keywords = keywords
        self.discoverMovieByKeywordRouteBuilder = discoverMovieByKeywordRouteBuilder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.keywordsTitle)
                .titleStyle()
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(keywords) { keyword in
                        NavigationLink(value: discoverMovieByKeywordRouteBuilder(keyword.id), label: {
                            RoundedBadge(text: keyword.name, color: .steamGold, useGradient: true)
                        })
                    }
                }.padding(.leading)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
}

#if DEBUG
#Preview {
    TMDBMovieDetailPreviewCatalog.keywords.view
}
#endif

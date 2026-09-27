import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// One search hit: artwork, title, a metadata line and a short synopsis.
@available(iOS 16, *)
struct SearchResultRow: View {
    let item: SearchResultItem
    /// Only the mixed "All" scope needs to say what each row is.
    var showsKind = false

    @ScaledMetric(relativeTo: .body) private var artworkWidth: CGFloat = 60

    var body: some View {
        HStack(spacing: 14) {
            SearchArtwork(item: item, width: artworkWidth)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                metadata

                if let overview {
                    Text(overview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var metadata: some View {
        HStack(spacing: 6) {
            if showsKind {
                SearchKindBadge(kind: item.kind)
            }
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let voteAverage = item.voteAverage, voteAverage > 0 {
                SearchRatingLabel(voteAverage: voteAverage)
            }
        }
    }

    /// The year for titles, the department for people, the country for companies.
    private var detail: String? {
        switch item.kind {
        case .movie, .tvShow: return item.year
        case .person, .collection, .company, .keyword: return item.subtitle.flatMap { $0.isEmpty ? nil : $0 }
        }
    }

    private var overview: String? {
        guard let overview = item.overview, !overview.isEmpty else { return nil }
        return item.kind == .person ? L10n.searchKnownFor(overview) : overview
    }

    /// Title first, so VoiceOver — and UI tests matching on a prefix — hear what the row is.
    private var accessibilityText: String {
        let rating = item.voteAverage.flatMap { $0 > 0 ? L10n.searchRatingAccessibility(SearchRatingLabel.text(for: $0)) : nil }
        return [item.title, item.kind.title, detail, rating, overview].compactMap { $0 }.joined(separator: ", ")
    }
}

/// Poster, profile photo or logo, over a tinted placeholder that also stands in for kinds
/// TMDB has no artwork for.
@available(iOS 16, *)
struct SearchArtwork: View {
    let item: SearchResultItem
    let width: CGFloat

    var body: some View {
        ZStack {
            item.kind.tint.opacity(0.15)

            if let imagePath = item.imagePath {
                RemoteTMDBImage(
                    posterPath: imagePath,
                    imageSize: imageSize,
                    contentMode: item.kind == .company ? .fit : .fill,
                    // Kingfisher owns its own load lifecycle, so a recycled row never sticks on
                    // a spinner.
                    loader: .kingfisher
                )
                // Logos are drawn for light backgrounds, so they get a white tile in dark mode too.
                .padding(item.kind == .company ? 8 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(item.kind == .company ? Color.white : Color.clear)
            } else {
                // Keywords and most companies have no artwork at all.
                Image(systemName: item.kind.systemImage)
                    .font(.title3)
                    .foregroundStyle(item.kind.tint)
            }
        }
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay(shape.stroke(.quaternary, lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    /// Posters keep their 2:3 frame; portraits, logos and keyword tags are square, so a
    /// one-line keyword row is not padded out to poster height.
    private var height: CGFloat {
        switch item.kind {
        case .movie, .tvShow, .collection: return width * 1.5
        case .person, .company, .keyword: return width
        }
    }

    private var shape: AnyShape {
        item.kind == .person ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var imageSize: TMDBImageSize {
        switch item.kind {
        case .person: return .profileMedium
        case .company: return .logoMedium
        case .movie, .tvShow, .collection, .keyword: return .posterSmall
        }
    }
}

/// "MOVIE", "TV SHOW", … in the kind's colour, for the mixed "All" results.
@available(iOS 16, *)
struct SearchKindBadge: View {
    let kind: SearchResultKind

    var body: some View {
        Text(kind.title.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(kind.tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(kind.tint.opacity(0.15), in: Capsule())
            .fixedSize()
    }
}

/// TMDB's vote average, out of ten.
@available(iOS 16, *)
struct SearchRatingLabel: View {
    let voteAverage: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .imageScale(.small)
                .foregroundStyle(.yellow)
            Text(Self.text(for: voteAverage))
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
        .fixedSize()
    }

    /// "7.8": one decimal, the precision TMDB shows on its own site.
    static func text(for voteAverage: Double) -> String {
        voteAverage.formatted(.number.precision(.fractionLength(1)))
    }
}

extension SearchResultKind {
    /// One colour per kind, shared by the badge and the artwork placeholder.
    var tint: Color {
        switch self {
        case .movie: return .blue
        case .tvShow: return .purple
        case .person: return .green
        case .collection: return .orange
        case .company: return .gray
        case .keyword: return .pink
        }
    }
}

#if DEBUG
@available(iOS 16, *)
#Preview("Row — every kind") {
    List {
        ForEach(SearchScope.allCases.dropFirst()) { scope in
            ForEach(StubSearchService.items(for: scope, query: "super", page: 1).prefix(1)) { item in
                SearchResultRow(item: item, showsKind: true)
            }
        }
    }
    .listStyle(.plain)
}

@available(iOS 16, *)
#Preview("Row — accessibility size") {
    List(StubSearchService.items(for: .multi, query: "super", page: 1).prefix(3)) { item in
        SearchResultRow(item: item, showsKind: true)
    }
    .listStyle(.plain)
    .dynamicTypeSize(.accessibility2)
}

@available(iOS 16, *)
#Preview("Artwork — every kind") {
    HStack(alignment: .top) {
        ForEach(SearchScope.allCases.dropFirst()) { scope in
            if let item = StubSearchService.items(for: scope, query: "super", page: 1, count: 1).first {
                SearchArtwork(item: SearchResultItem(tmdbID: item.tmdbID, kind: item.kind, title: item.title), width: 44)
            }
        }
    }
    .padding()
}

@available(iOS 16, *)
#Preview("Kind badges") {
    VStack(alignment: .leading) {
        ForEach([SearchResultKind.movie, .tvShow, .person, .collection, .company, .keyword], id: \.self) { kind in
            SearchKindBadge(kind: kind)
        }
    }
}

@available(iOS 16, *)
#Preview("Rating") {
    VStack {
        SearchRatingLabel(voteAverage: 8.123)
        SearchRatingLabel(voteAverage: 5)
    }
}
#endif

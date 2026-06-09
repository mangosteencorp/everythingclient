import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
public struct PersonDetailPage<Route: Hashable>: View {
    private struct LoadedPayload {
        let detail: PersonDetail
        let credits: PersonMovieCredits
    }

    private enum ViewState {
        case loading
        case loaded(LoadedPayload)
        case error(String)
    }

    private final class Store: ObservableObject {
        @Published var state: ViewState = .loading

        private let apiService: TMDBAPIService
        private let personId: Int

        init(apiService: TMDBAPIService, personId: Int) {
            self.apiService = apiService
            self.personId = personId
        }

        func fetch() async {
            await MainActor.run {
                state = .loading
            }
            do {
                let detail: PersonDetail = try await apiService.request(.personDetail(person: personId))
                let credits: PersonMovieCredits = try await apiService.request(.personMovieCredits(person: personId))
                await MainActor.run {
                    state = .loaded(LoadedPayload(detail: detail, credits: credits))
                }
            } catch {
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    private let personId: Int
    private let movieRouteBuilder: (Int) -> Route
    @StateObject private var store: Store

    public init(
        personId: Int,
        apiService: TMDBAPIService,
        movieRouteBuilder: @escaping (Int) -> Route
    ) {
        self.personId = personId
        self.movieRouteBuilder = movieRouteBuilder
        _store = StateObject(wrappedValue: Store(apiService: apiService, personId: personId))
    }

    public var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task(id: personId) {
                await store.fetch()
            }
            .refreshable {
                await store.fetch()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ProgressView("Loading person...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let payload):
            PersonDetailContent(
                person: payload.detail,
                credits: payload.credits.featuredCredits,
                movieRouteBuilder: movieRouteBuilder
            )
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await store.fetch() }
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

@available(iOS 16.0, *)
private struct PersonDetailContent<Route: Hashable>: View {
    let person: PersonDetail
    let credits: [PersonMovieCredit]
    let movieRouteBuilder: (Int) -> Route

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                factGrid
                biography
                filmography
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(person.name)
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 18) {
            profileImage

            VStack(alignment: .leading, spacing: 10) {
                Text(person.name)
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                if let knownFor = person.knownForDepartment {
                    Label(knownFor, systemImage: "sparkles.tv")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Label(String(format: "%.1f popularity", person.popularity), systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var profileImage: some View {
        AsyncImage(url: person.profilePath.flatMap { TMDBImageSize.profileLarge.buildImageUrl(path: $0) }) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty:
                ProgressView()
            case .failure:
                Image(systemName: "person.crop.square")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 118, height: 168)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var factGrid: some View {
        let facts = [
            PersonFact(title: "Life", value: person.lifespan),
            PersonFact(title: "Birthplace", value: person.placeOfBirth),
            PersonFact(title: "Also Known As", value: person.alsoKnownAs.prefix(2).joined(separator: ", ")),
        ].filter { fact in
            guard let value = fact.value else { return false }
            return !value.isEmpty
        }

        if !facts.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(facts) { fact in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(fact.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(fact.value ?? "")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private var biography: some View {
        if !person.biography.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Biography")
                    .font(.headline)
                Text(person.biography)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var filmography: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filmography")
                .font(.headline)

            if credits.isEmpty {
                Text("No movie credits available.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(credits.prefix(40)) { credit in
                        NavigationLink(value: movieRouteBuilder(credit.id)) {
                            PersonMovieCreditRow(credit: credit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct PersonFact: Identifiable {
    let title: String
    let value: String?

    var id: String { title }
}

@available(iOS 16.0, *)
private struct PersonMovieCreditRow: View {
    let credit: PersonMovieCredit

    var body: some View {
        HStack(spacing: 12) {
            RemoteTMDBImage(
                posterPath: credit.posterPath,
                posterSize: PosterSize(width: 54, height: 82),
                imageSize: .posterSmall
            )
            .frame(width: 54, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(credit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let roleText = credit.roleText {
                    Text(roleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let year = credit.releaseYearText {
                        Label(year, systemImage: "calendar")
                    }
                    Label(String(format: "%.1f", credit.voteAverage), systemImage: "star.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        PersonDetailPage(
            personId: 287,
            apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
            movieRouteBuilder: { $0 }
        )
    }
}
#endif

import Foundation
import TMDB_Shared_Backend

/// One call for all seven TMDB search endpoints, returning rows the UI can render without
/// knowing which endpoint produced them.
public protocol TMDBSearchServicing {
    func search(
        scope: SearchScope,
        query: String,
        filters: SearchFilters,
        page: Int?
    ) async -> Result<SearchResultPage, Error>
}

public extension TMDBSearchServicing {
    /// Unfiltered search, for call sites that have no filter UI.
    func search(scope: SearchScope, query: String, page: Int?) async -> Result<SearchResultPage, Error> {
        await search(scope: scope, query: query, filters: SearchFilters(), page: page)
    }
}

public struct TMDBSearchService: TMDBSearchServicing {
    private let requester: TMDBAPIRequesting

    public init(requester: TMDBAPIRequesting) {
        self.requester = requester
    }

    public func search(
        scope: SearchScope,
        query: String,
        filters: SearchFilters,
        page: Int?
    ) async -> Result<SearchResultPage, Error> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .success(SearchResultPage(items: [], page: 1, totalPages: 1))
        }

        // A filter left over from another scope must not leak into a request that scope cannot
        // honour — the picker hides those chips, but the values survive a scope switch.
        let filters = filters.narrowed(to: scope)

        do {
            switch scope {
            case .multi: return .success(try await multi(trimmed, filters, page))
            case .movies: return .success(try await movies(trimmed, filters, page))
            case .tvShows: return .success(try await tvShows(trimmed, filters, page))
            case .people: return .success(try await people(trimmed, filters, page))
            case .collections: return .success(try await collections(trimmed, filters, page))
            case .companies: return .success(try await companies(trimmed, page))
            case .keywords: return .success(try await keywords(trimmed, page))
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - One endpoint each

    private func multi(_ query: String, _ filters: SearchFilters, _ page: Int?) async throws -> SearchResultPage {
        let response: TrendingAllResultModel = try await requester.request(.searchMulti(
            query: query,
            includeAdult: filters.includeAdult,
            language: filters.language,
            page: page
        ))
        return SearchResultPage(
            items: response.results.compactMap(SearchResultItem.init(multiItem:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    private func movies(_ query: String, _ filters: SearchFilters, _ page: Int?) async throws -> SearchResultPage {
        let response: MovieListResultModel = try await requester.request(.searchMovie(
            query: query,
            includeAdult: filters.includeAdult,
            language: filters.language,
            primaryReleaseYear: filters.primaryReleaseYear,
            page: page,
            region: filters.region,
            year: filters.year
        ))
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(movie:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    private func tvShows(_ query: String, _ filters: SearchFilters, _ page: Int?) async throws -> SearchResultPage {
        let response: TVShowListResultModel = try await requester.request(.searchTVShows(
            query: query,
            includeAdult: filters.includeAdult,
            language: filters.language,
            // `search/tv` has no `primary_release_year`; the one year chip it offers is the
            // first-air-date year.
            firstAirDateYear: filters.year,
            page: page,
            region: filters.region,
            year: filters.year
        ))
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(tvShow:)),
            page: response.page,
            totalPages: response.total_pages
        )
    }

    private func people(_ query: String, _ filters: SearchFilters, _ page: Int?) async throws -> SearchResultPage {
        let response: PersonListResultModel = try await requester.request(.searchPerson(
            query: query,
            includeAdult: filters.includeAdult,
            language: filters.language,
            page: page
        ))
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(person:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    private func collections(
        _ query: String,
        _ filters: SearchFilters,
        _ page: Int?
    ) async throws -> SearchResultPage {
        let response: CollectionSearchResultModel = try await requester.request(
            .searchCollection(
                query: query,
                includeAdult: filters.includeAdult,
                language: filters.language,
                page: page,
                region: filters.region
            )
        )
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(collection:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    private func companies(_ query: String, _ page: Int?) async throws -> SearchResultPage {
        let response: CompanySearchResultModel = try await requester.request(.searchCompany(query: query, page: page))
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(company:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }

    private func keywords(_ query: String, _ page: Int?) async throws -> SearchResultPage {
        let response: KeywordSearchResultModel = try await requester.request(.searchKeyword(query: query, page: page))
        return SearchResultPage(
            items: response.results.map(SearchResultItem.init(keyword:)),
            page: response.page,
            totalPages: response.totalPages
        )
    }
}

// MARK: - Row mapping

extension SearchResultItem {
    init(movie: TMDBMovieModel) {
        self.init(
            tmdbID: movie.id,
            kind: .movie,
            title: movie.title,
            subtitle: movie.release_date,
            imagePath: movie.poster_path,
            voteAverage: Double(movie.vote_average)
        )
    }

    init(tvShow: TVShow) {
        self.init(
            tmdbID: tvShow.id,
            kind: .tvShow,
            title: tvShow.name,
            subtitle: tvShow.first_air_date,
            imagePath: tvShow.poster_path,
            voteAverage: tvShow.vote_average
        )
    }

    init(person: PersonModel) {
        self.init(
            tmdbID: person.id,
            kind: .person,
            title: person.name,
            subtitle: person.knownForDepartment,
            imagePath: person.profilePath
        )
    }

    init(collection: MovieCollectionSummary) {
        self.init(
            tmdbID: collection.id,
            kind: .collection,
            title: collection.name,
            subtitle: collection.overview,
            imagePath: collection.posterPath
        )
    }

    init(company: CompanySummary) {
        self.init(
            tmdbID: company.id,
            kind: .company,
            title: company.name,
            subtitle: company.originCountry,
            imagePath: company.logoPath
        )
    }

    init(keyword: Keyword) {
        self.init(tmdbID: keyword.id, kind: .keyword, title: keyword.name)
    }

    /// `search/multi` mixes media types in one array; anything unrecognised is dropped rather
    /// than rendered as a blank row.
    init?(multiItem: TrendingAllItem) {
        switch multiItem.mediaType {
        case "movie":
            self.init(
                tmdbID: multiItem.id,
                kind: .movie,
                title: multiItem.title ?? multiItem.originalTitle ?? "",
                subtitle: multiItem.releaseDate,
                imagePath: multiItem.posterPath,
                voteAverage: multiItem.voteAverage
            )
        case "tv":
            self.init(
                tmdbID: multiItem.id,
                kind: .tvShow,
                title: multiItem.name ?? multiItem.originalName ?? "",
                subtitle: multiItem.firstAirDate,
                imagePath: multiItem.posterPath,
                voteAverage: multiItem.voteAverage
            )
        case "person":
            self.init(
                tmdbID: multiItem.id,
                kind: .person,
                title: multiItem.name ?? multiItem.originalName ?? "",
                subtitle: multiItem.knownForDepartment,
                imagePath: multiItem.profilePath
            )
        default:
            return nil
        }
    }
}

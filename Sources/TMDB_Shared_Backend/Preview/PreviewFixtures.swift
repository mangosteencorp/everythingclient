import Foundation

// Sample responses for previews in the feature modules, which cannot build these models
// themselves: their memberwise initialisers are internal to this module. Artwork paths are left
// out so a preview never waits on the image CDN.

// swiftlint:disable all
#if DEBUG
public extension WatchProviderResponse {
    static var example: WatchProviderResponse { WatchProviderResponse(
        id: 1399,
        results: [
            "US": WatchProviderRegion(
                link: "https://www.themoviedb.org/tv/1399/watch?locale=US",
                buy: [
                    WatchProvider(id: 2, logoPath: nil, providerName: "Apple TV", displayPriority: 4),
                    WatchProvider(id: 3, logoPath: nil, providerName: "Google Play Movies", displayPriority: 16),
                ],
                rent: nil,
                flatrate: [
                    WatchProvider(id: 1899, logoPath: nil, providerName: "Max", displayPriority: 1),
                    WatchProvider(id: 9, logoPath: nil, providerName: "Amazon Prime Video", displayPriority: 2),
                ],
                free: nil,
                ads: nil
            ),
        ]
    ) }
}

public extension PersonDetail {
    static var example: PersonDetail { PersonDetail(
        adult: false,
        alsoKnownAs: ["William Bradley Pitt", "B. Pitt"],
        biography: "William Bradley Pitt is an American actor and film producer. He is the recipient of various accolades, including two Academy Awards, a British Academy Film Award, and two Golden Globe Awards.",
        birthday: "1963-12-18",
        deathday: nil,
        gender: 2,
        homepage: nil,
        id: 287,
        imdbId: "nm0000093",
        knownForDepartment: "Acting",
        name: "Brad Pitt",
        placeOfBirth: "Shawnee, Oklahoma, USA",
        popularity: 42.5,
        profilePath: nil
    ) }
}

public extension PersonMovieCredit {
    static func example(id: Int, title: String, character: String?, releaseDate: String, voteAverage: Double) -> PersonMovieCredit {
        PersonMovieCredit(
            adult: false,
            backdropPath: nil,
            character: character,
            creditId: "credit-\(id)",
            department: character == nil ? "Production" : "Acting",
            id: id,
            job: character == nil ? "Producer" : nil,
            order: character == nil ? nil : 0,
            originalTitle: title,
            overview: "",
            popularity: Double(id % 100),
            posterPath: nil,
            releaseDate: releaseDate,
            title: title,
            voteAverage: voteAverage,
            voteCount: 1000
        )
    }
}

public extension PersonMovieCredits {
    static var example: PersonMovieCredits { PersonMovieCredits(
        id: 287,
        cast: [
            .example(id: 550, title: "Fight Club", character: "Tyler Durden", releaseDate: "1999-10-15", voteAverage: 8.4),
            .example(id: 807, title: "Se7en", character: "Detective David Mills", releaseDate: "1995-09-22", voteAverage: 8.4),
            .example(id: 16869, title: "Inglourious Basterds", character: "Lt. Aldo Raine", releaseDate: "2009-08-02", voteAverage: 8.2),
            .example(id: 466_272, title: "Once Upon a Time… in Hollywood", character: "Cliff Booth", releaseDate: "2019-07-26", voteAverage: 7.4),
            .example(id: 911_430, title: "F1", character: "Sonny Hayes", releaseDate: "2025-06-25", voteAverage: 7.8),
        ],
        crew: [
            .example(id: 76203, title: "12 Years a Slave", character: nil, releaseDate: "2013-10-18", voteAverage: 7.9),
        ]
    ) }
}

public extension TVShow {
    static var examples: [TVShow] { [
        TVShow(
            adult: false,
            backdrop_path: nil,
            genre_ids: [18, 10765],
            id: 1399,
            origin_country: ["US"],
            original_language: "en",
            original_name: "Game of Thrones",
            overview: "Seven noble families fight for control of the mythical land of Westeros.",
            popularity: 450.3,
            poster_path: nil,
            first_air_date: "2011-04-17",
            name: "Game of Thrones",
            vote_average: 8.5,
            vote_count: 24515
        ),
        TVShow(
            adult: false,
            backdrop_path: nil,
            genre_ids: [18, 80],
            id: 1396,
            origin_country: ["US"],
            original_language: "en",
            original_name: "Breaking Bad",
            overview: "A chemistry teacher diagnosed with terminal lung cancer turns to cooking methamphetamine.",
            popularity: 380.1,
            poster_path: nil,
            first_air_date: "2008-01-20",
            name: "Breaking Bad",
            vote_average: 8.9,
            vote_count: 15000
        ),
        TVShow(
            adult: false,
            backdrop_path: nil,
            genre_ids: [10765, 18],
            id: 66732,
            origin_country: ["US"],
            original_language: "en",
            original_name: "Stranger Things",
            overview: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments.",
            popularity: 290.7,
            poster_path: nil,
            first_air_date: "2016-07-15",
            name: "Stranger Things",
            vote_average: 8.6,
            vote_count: 18000
        ),
    ] }
}

public extension TVShowListResultModel {
    static var example: TVShowListResultModel { TVShowListResultModel(
        page: 1,
        results: TVShow.examples,
        total_pages: 1,
        total_results: TVShow.examples.count
    ) }
}
#endif
// swiftlint:enable all

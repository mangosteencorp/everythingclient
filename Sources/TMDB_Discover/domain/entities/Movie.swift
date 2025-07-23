// Entities
import Foundation
import Shared_UI_Support
import TMDB_Shared_UI

struct Movie: Equatable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let voteAverage: Float
    let popularity: Float
    let releaseDate: Date?

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

// swiftlint:disable all
#if DEBUG
    static let exampleMovies = [
        Movie(
            id: 889_737,
            title: "Joker: Folie à Deux",
            overview: "While struggling with his dual identity, Arthur Fleck not only stumbles upon true love, but also finds the music that's always been inside him.",
            posterPath: "/aciP8Km0waTLXEYf5ybFK5CSUxl.jpg",
            voteAverage: 7.5,
            popularity: 177.167,
            releaseDate: dateFormatter.date(from: "2024-10-04")
        ),
        Movie(
            id: 1_100_782,
            title: "Smile 2",
            overview: "About to embark on a new world tour, global pop sensation Skye Riley begins experiencing increasingly terrifying and inexplicable events. Overwhelmed by the escalating horrors and the pressures of fame, Skye is forced to face her dark past to regain control of her life before it spirals out of control.",
            posterPath: "/aE85MnPIsSoSs3978Noo16BRsKN.jpg",
            voteAverage: 0,
            popularity: 35.385,
            releaseDate: dateFormatter.date(from: "2024-10-18")
        ),
        Movie(
            id: 1_244_492,
            title: "Look Back",
            overview: "Popular, outgoing Fujino is celebrated by her classmates for her funny comics in the class newspaper. One day, her teacher asks her to share the space with Kyomoto, a truant recluse whose beautiful artwork sparks a competitive fervor in Fujino. What starts as jealousy transforms when Fujino realizes their shared passion for drawing.",
            posterPath: "/oL4ab05VAvVkTwk5BL0JJDKQkfD.jpg",
            voteAverage: 8.6,
            popularity: 38.391,
            releaseDate: dateFormatter.date(from: "2024-10-06")
        ),
        Movie(
            id: 1_182_047,
            title: "The Apprentice",
            overview: "A young Donald Trump, eager to make his name as a hungry scion of a wealthy family in 1970s New York, comes under the spell of Roy Cohn, the cutthroat attorney who would help create the Donald Trump we know today. Cohn sees in Trump the perfect protégé—someone with raw ambition, a hunger for success, and a willingness to do whatever it takes to win.",
            posterPath: "/5icMlNq4rx6XJ9luWAR1Nr3M9rZ.jpg",
            voteAverage: 0,
            popularity: 33.11,
            releaseDate: dateFormatter.date(from: "2024-10-11")
        ),
        Movie(
            id: 835_113,
            title: "Woman of the Hour",
            overview: "The stranger-than-fiction story of an aspiring actor in 1970s Los Angeles and a serial killer in the midst of a years-long murder spree, whose lives intersect when they're cast on an episode of The Dating Game.",
            posterPath: "/td4fbQkQ0bb9GY4NwjTXj6pV60i.jpg",
            voteAverage: 0,
            popularity: 30.62,
            releaseDate: dateFormatter.date(from: "2024-10-11")
        ),
    ]
#endif
}

// swiftlint:enable all
extension Movie {
    func toMovieRowEntity() -> MovieRowEntity {
        return MovieRowEntity(
            id: id,
            posterPath: posterPath,
            title: title,
            voteAverage: Double(voteAverage),
            releaseDate: releaseDate,
            overview: overview
        )
    }
}

// Extension to make Movie conform to ItemDisplayable for use with MovieItemCell
extension Movie: ItemDisplayable {
    func getId() -> String? {
        return String(id)
    }

    func getTitle() -> String {
        return title
    }

    func getDescription() -> String {
        return overview
    }

    func getReleaseDate() -> String? {
        guard let releaseDate = releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: releaseDate)
    }

    func getRating() -> Float? {
        return voteAverage
    }

    func getImageURL() -> String? {
        guard let posterPath = posterPath else { return nil }
        return "https://image.tmdb.org/t/p/w500\(posterPath)"
    }

    func isFavorited() -> Bool {
        return false // Default implementation, can be enhanced later
    }

    func setFavorited(_ favorited: Bool) {
        // No-op for now, can be enhanced later
    }
}

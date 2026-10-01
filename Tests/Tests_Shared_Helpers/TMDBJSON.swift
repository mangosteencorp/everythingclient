import Foundation

/// Minimal but complete TMDB payloads: every non-optional field of the matching model is present,
/// and the values are the ones the tests assert on.
public enum TMDBJSON {
    public static func movieDetail(id: Int = 1, title: String = "Dune") -> String {
        """
        {
          "id": \(id), "title": "\(title)", "original_title": "\(title)",
          "overview": "Paul Atreides", "popularity": 12.5, "video": false,
          "poster_path": "/poster.jpg", "backdrop_path": null,
          "vote_average": 8.1, "vote_count": 900, "release_date": "2021-10-22",
          "genres": [{"id": 878, "name": "Science Fiction"}], "runtime": 155, "status": "Released"
        }
        """
    }

    public static func movieCredits(id: Int = 1, castName: String = "Timothee", crewName: String = "Denis") -> String {
        """
        {
          "id": \(id),
          "cast": [{
            "adult": false, "gender": 2, "id": 11, "known_for_department": "Acting",
            "name": "\(castName)", "original_name": "\(castName)", "popularity": 40.0,
            "profile_path": "/cast.jpg", "cast_id": 1, "character": "Paul",
            "credit_id": "c1", "order": 0
          }],
          "crew": [{
            "adult": false, "gender": 2, "id": 22, "known_for_department": "Directing",
            "name": "\(crewName)", "original_name": "\(crewName)", "popularity": 20.0,
            "profile_path": null, "credit_id": "c2", "department": "Directing", "job": "Director"
          }]
        }
        """
    }

    public static func watchProviders(id: Int = 1, region: String = "US") -> String {
        """
        {
          "id": \(id),
          "results": {
            "\(region)": {
              "link": "https://www.themoviedb.org/movie/\(id)/watch",
              "flatrate": [{
                "provider_id": 8, "logo_path": "/netflix.jpg",
                "provider_name": "Netflix", "display_priority": 1
              }]
            }
          }
        }
        """
    }

    public static func personDetail(id: Int = 287, name: String = "Brad Pitt") -> String {
        """
        {
          "adult": false, "also_known_as": ["William Bradley Pitt"], "biography": "An actor.",
          "birthday": "1963-12-18", "deathday": null, "gender": 2, "homepage": null,
          "id": \(id), "imdb_id": "nm0000093", "known_for_department": "Acting",
          "name": "\(name)", "place_of_birth": "Shawnee, Oklahoma",
          "popularity": 30.0, "profile_path": "/profile.jpg"
        }
        """
    }

    public static func personMovieCredits(id: Int = 287, castTitle: String = "Se7en") -> String {
        """
        {
          "id": \(id),
          "cast": [{
            "adult": false, "backdrop_path": null, "character": "Detective Mills",
            "credit_id": "pc1", "department": null, "id": 807, "job": null, "order": 0,
            "original_title": "\(castTitle)", "overview": "Two detectives.", "popularity": 55.0,
            "poster_path": "/se7en.jpg", "release_date": "1995-09-22", "title": "\(castTitle)",
            "vote_average": 8.4, "vote_count": 1000
          }],
          "crew": []
        }
        """
    }

    public static func tvShowDetail(id: Int = 1399, name: String = "Game of Thrones") -> String {
        """
        {
          "id": \(id), "name": "\(name)", "original_name": "\(name)",
          "overview": "Nine noble families.", "first_air_date": "2011-04-17",
          "last_air_date": "2019-05-19", "number_of_episodes": 73, "number_of_seasons": 8,
          "vote_average": 8.4, "vote_count": 20000,
          "status": "Ended", "tagline": "Winter is coming.", "type": "Scripted",
          "poster_path": "/got.jpg", "backdrop_path": null,
          "created_by": [], "genres": [], "networks": [], "seasons": []
        }
        """
    }

    public static func tvShowList(ids: [Int], name: String = "Better Call Saul") -> String {
        let shows = ids.map { id in
            """
            {
              "adult": false, "backdrop_path": "/backdrop\(id).jpg", "genre_ids": [18],
              "id": \(id), "origin_country": ["US"], "original_language": "en",
              "original_name": "\(name) \(id)", "overview": "A show.", "popularity": 10.0,
              "poster_path": "/poster\(id).jpg", "first_air_date": "2015-02-08",
              "name": "\(name) \(id)", "vote_average": 8.7, "vote_count": 100
            }
            """
        }
        .joined(separator: ",")
        return """
        {"page": 1, "results": [\(shows)], "total_pages": 1, "total_results": \(ids.count)}
        """
    }

    public static func accountInfo(id: Int = 42, username: String = "mrclient") -> String {
        """
        {
          "avatar": {"gravatar": {"hash": "abc"}, "tmdb": {"avatar_path": "/avatar.jpg"}},
          "id": \(id), "iso_639_1": "en", "iso_3166_1": "US",
          "name": "Mr Client", "include_adult": false, "username": "\(username)"
        }
        """
    }

    public static func movieList(ids: [Int], title: String = "Arrival") -> String {
        let movies = ids.map { id in
            """
            {
              "adult": false, "backdrop_path": null, "genre_ids": [878], "id": \(id),
              "original_language": "en", "original_title": "\(title) \(id)",
              "overview": "A movie.", "popularity": 9.9, "poster_path": "/p\(id).jpg",
              "release_date": "2016-11-11", "title": "\(title) \(id)",
              "video": false, "vote_average": 7.9, "vote_count": 500
            }
            """
        }
        .joined(separator: ",")
        return """
        {"page": 1, "results": [\(movies)], "total_pages": 1, "total_results": \(ids.count)}
        """
    }
}

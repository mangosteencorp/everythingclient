import SwiftUI
import TMDB_Shared_UI
struct MovieCoverRow: View {
    let movie: Movie
    var body: some View {
        ZStack {
            // MovieTopBackdropImage
            
            RemoteTMDBImage(posterPath: movie.backdrop_path, posterSize: PosterSize(width: 250, height: 250), image: .medium)
            VStack(alignment: .leading) {
                HStack(spacing: 16) {
                    RemoteTMDBImage(posterPath: movie.poster_path, posterSize: .medium, image: .medium)
                        .padding(.leading, 16)
                    VStack(alignment: .leading, spacing: 16) {
                        MovieInfoRow(movie: movie)
                        HStack {
                            PopularityBadge(score: Int(movie.vote_average * 10), textColor: .white)
                            Text("\(movie.vote_count) ratings")
                                .lineLimit(1)
                                .foregroundColor(.white)
                        }
                    }
                }
                genresBadges().padding(.top, 16)
            }
        }
        .listRowInsets(EdgeInsets())
        
    }
    private func genresBadges() -> some View {
        let fakeGenres = Array(repeating: Genre(id: 0, name: "     "), count: 3)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(movie.genres ?? fakeGenres) { genre in
                    // TODO: MoviesGenreList
                    NavigationLink(destination: EmptyView()) {
                        RoundedBadge(text: genre.name, color: .secondary)
                    }.disabled(movie.genres == nil)
                }
            }
            .padding(.leading, 16)
            .redacted(reason: movie.genres == nil ? .placeholder : [])
        }
    }
}

struct MovieInfoRow : View {
    let movie: Movie
    
    var asyncTextTransition: AnyTransition {
        .opacity
    }
    
    var asyncTextAnimation: Animation {
        .easeInOut
    }
    
    private var infos: some View {
        HStack {
            if let date = movie.release_date {
                Text(date.prefix(4)).font(.subheadline)
            }
            if let runtime = movie.runtime {
                Text("• \(runtime) minutes")
                    .font(.subheadline)
                    .animation(asyncTextAnimation)
                    .transition(asyncTextTransition)
            }
            if let status = movie.status {
                Text("• \(status)")
                    .font(.subheadline)
                    .animation(asyncTextAnimation)
                    .transition(asyncTextTransition)
            }
        }
        .foregroundColor(.white)
    }
    
    private var productionCountry: some View {
        Group {
            if movie.production_countries?.isEmpty == false {
                Text("\(movie.production_countries!.first!.name)")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            infos
            productionCountry
        }
    }
}
#Preview {
    MovieInfoRow(movie: sampleApeMovie)
}
#Preview {
    MovieCoverRow(movie: sampleApeMovie)
}

let sampleApeMovie = Movie(
    id: 653346,
    original_title: "Kingdom of the Planet of the Apes",
    title: "Kingdom of the Planet of the Apes",
    overview: "Several generations in the future following Caesar's reign, apes are now the dominant species and live harmoniously while humans have been reduced to living in the shadows. As a new tyrannical ape leader builds his empire, one young ape undertakes a harrowing journey that will cause him to question all that he has known about the past and to make choices that will define a future for apes and humans alike.",
    poster_path: "/gKkl37BQuKTanygYQG1pyYgLVgf.jpg",
    backdrop_path: "/fqv8v6AycXKsivp1T5yKtLbGXce.jpg",
    popularity: 4050.674,
    vote_average: 6.861,
    vote_count: 955,
    release_date: "2024-05-10",
    genres: nil,
    runtime: nil,
    status: nil,
    video: false,
    keywords: nil,
    images: nil,
    production_countries: nil,
    character: nil,
    department: nil
)

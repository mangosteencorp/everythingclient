import SwiftUI
import TMDB_Shared_UI
struct MovieCoverRow: View {
    let movie: Movie
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                RemoteTMDBImage(
                    posterPath: movie.backdrop_path,
                    posterSize: PosterSize(width: geometry.size.width, height: 250),
                    image: .medium
                )
                .blur(radius: 3)
                .overlay(Color.black.opacity(0.6))
                
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
    }
    private func genresBadges() -> some View {
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(movie.genres ?? []) { genre in
                    // TODO: MoviesGenreList
                    NavigationLink(destination: EmptyView()) {
                        RoundedBadge(text: genre.name, color: .accentColor)
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
    Section{
        MovieCoverRow(movie: exampleMovieDetail).debugBorder(color: .purple)
    }
}
#Preview {
    Section {
        MovieCoverRow(movie: exampleMovieDetail)
        // TODO: Button rows: Wishlist, Seenlist, list
        MovieOverview(movie: exampleMovieDetail)
    }
}

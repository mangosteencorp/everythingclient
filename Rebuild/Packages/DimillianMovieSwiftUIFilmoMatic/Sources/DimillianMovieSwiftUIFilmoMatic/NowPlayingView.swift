import SwiftUI

struct SingleMovieViewModel: Identifiable {
    var id = UUID()
    var title: String
    var rating: Int
    var releaseDate: String
    var description: String
    var poster: URL?
}

public struct NowPlayingView: View {
    @ObservedObject var nowPlayingViewModel = MovieViewModel()
    public init() {}
    public var body: some View {
        NavigationView {
            List(nowPlayingViewModel.movies) { movie in
                HStack(alignment: .top) {
                    AsyncImage(url: movie.poster)
                        .frame(width: 100, height: 150)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(movie.title)
                            .font(.headline)
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(movie.rating*10)%")
                        }
                        Text(movie.releaseDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(movie.description)
                            .font(.body)
                            .lineLimit(3)
                    }
                }
            }
            .navigationTitle("Now Playing")
            .toolbar {
                // Add toolbar items if needed
            }
        }.onAppear{
            Task {
                await nowPlayingViewModel.loadNowPlaying()
            }
        }
        .searchable(text: .constant(""), prompt: "Search any movies or person")
        
    }
}

// Define a custom tab bar component based on your design here.
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
    }
}
#endif

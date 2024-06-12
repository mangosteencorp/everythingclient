import SwiftUI
struct Movie: Identifiable {
    let id: Int
    let posterPath: String?
    let userTitle: String
    let voteAverage: Double
    let releaseDate: Date?
    let overview: String
}

@available(iOS 15.0, *)
struct MovieRow: View {
    @State private var isLoading = true
    @State private var movie: Movie?

    let movieId: Int

    var body: some View {
        HStack {
            if isLoading {
                loadingView
            } else if let movie = movie {
                movieDetailView(movie)
            } else {
                Text("Failed to load movie")
            }
        }
        .onAppear {
            fetchMovieDetails()
        }
        .padding(.vertical, 8)
    }

    private var loadingView: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 150)
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .cornerRadius(4)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .cornerRadius(4)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 60)
                    .cornerRadius(4)
            }
            .padding(.leading, 8)
        }
        .redacted(reason: .placeholder)
    }

    private func movieDetailView(_ movie: Movie) -> some View {
        HStack {
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath ?? "")")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 150)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.userTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                HStack {
                    PopularityBadge(score: Int(movie.voteAverage * 10))
                    Text(formatter.string(from: movie.releaseDate ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(movie.overview)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
            .padding(.leading, 8)
        }
    }

    private func fetchMovieDetails() {
        // Simulate network request by delaying for a couple of seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Update this block with actual network request logic to fetch movie details.
            let exampleMovie = Movie(
                id: movieId,
                posterPath: "/path_to_poster.jpg",
                userTitle: "Example Movie Title",
                voteAverage: 6.8,
                releaseDate: Date(),
                overview: "Example movie overview."
            )
            self.movie = exampleMovie
            self.isLoading = false
        }
    }
}

fileprivate let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()


@available(iOS 15.0,*)
#Preview {
    MovieRow(movieId: 0)
}

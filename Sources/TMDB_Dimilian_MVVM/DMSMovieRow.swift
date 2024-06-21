import SwiftUI

fileprivate let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

@available(iOS 15, macOS 12, *)
struct MoviePosterImage: View {
    var posterPath: String?
    var posterSize: PosterSize

    var body: some View {
        if let posterPath = posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: posterSize.width, height: posterSize.height)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: posterSize.width, height: posterSize.height)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: posterSize.width, height: posterSize.height)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                        .frame(width: posterSize.width, height: posterSize.height)
                }
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: posterSize.width, height: posterSize.height)
                .foregroundColor(.gray)
        }
    }

}

struct PosterSize {
    var width: CGFloat
    var height: CGFloat
    
    static let medium = PosterSize(width: 100, height: 150)
}

@available(iOS 15, macOS 12, *)
struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline) // Set the font to headline
            .foregroundColor(.primary) // Set the text color to primary
            .padding(.vertical, 4) // Add vertical padding
    }
}
@available(iOS 15, macOS 12, *)
extension View {
    func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }
}

@available(iOS 13, macOS 10.15, *)
extension Color {
    static let steamGold = Color(red: 199 / 255, green: 165 / 255, blue: 67 / 255)
}


@available(iOS 15, macOS 12, *)
struct MovieRow: View {
    let movie: Movie
    var displayListImage = true

    var body: some View {
        HStack {
            ZStack(alignment: .topLeading) {
                MoviePosterImage(posterPath: movie.poster_path, posterSize: .medium)
            }
            .fixedSize()
            .animation(.spring())
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.userTitle)
                    .titleStyle()
                    .foregroundColor(Color.steamGold)
                    .lineLimit(2)
                HStack {
                    PopularityBadge(score: Int(movie.vote_average * 10))
                    Text(formatter.string(from: movie.releaseDate ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(movie.overview)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }.padding(.leading, 8)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .contextMenu { Text(self.movie.id.description) }
        .redacted(if: movie.id == 0)
    }
}

@available(iOS 15, macOS 12, *)
#Preview {
    Group{
        MovieRow(movie: sampleEmptyMovie)
        MovieRow(movie: sampleApeMovie)
    }
    
}

@available(iOS 13, macOS 11, *)
extension View {
    @ViewBuilder
    func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}

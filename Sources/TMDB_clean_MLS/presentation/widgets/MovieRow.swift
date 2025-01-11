import SwiftUI
import TMDB_Shared_UI
fileprivate let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

@available(iOS 14, macOS 11, *)
struct MovieRow: View {
    let movie: Movie
    var displayListImage = true

    var body: some View {
        HStack {
            ZStack(alignment: .topLeading) {
                RemoteTMDBImage(posterPath: movie.posterPath ?? "",
                               posterSize: .medium,
                               image: .medium)
                    .redacted(if: movie.posterPath == nil)
            }
            .fixedSize()
            .animation(.spring())
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .titleStyle()
                    .foregroundColor(Color.steamGold)
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
            }.padding(.leading, 8)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .contextMenu { Text(self.movie.id.description) }
        .redacted(if: movie.id == 0)
    }
}


@available(iOS 13, macOS 11, *)
extension View {
    @ViewBuilder
    func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}

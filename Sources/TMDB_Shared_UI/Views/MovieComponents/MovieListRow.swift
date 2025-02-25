import SwiftUI
import Shared_UI_Support
private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

public struct MovieRowEntity {
    public let id: Int
    public let posterPath: String?
    public let title: String
    public let voteAverage: Double
    public let releaseDate: Date?
    public let overview: String
    public init(
        id: Int,
        posterPath: String?,
        title: String,
        voteAverage: Double,
        releaseDate: Date?,
        overview: String
    ) {
        self.id = id
        self.posterPath = posterPath
        self.title = title
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.overview = overview
    }
}

@available(iOS 14, macOS 11, *)
public struct MovieRow: View {
    @State private var appear = false

    let movie: MovieRowEntity
    var displayListImage = true
    public init(movie: MovieRowEntity, displayListImage: Bool = true) {
        self.movie = movie
        self.displayListImage = displayListImage
    }

    public var body: some View {
        HStack {
            ZStack(alignment: .topLeading) {
                RemoteTMDBImage(
                    posterPath: movie.posterPath ?? "",
                    posterSize: .medium,
                    image: .medium
                )
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
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : 50)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appear = true
            }
        }
    }
}

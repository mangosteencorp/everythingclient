import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct PersonMovieCreditRow: View {
    let credit: PersonMovieCredit

    var body: some View {
        HStack(spacing: 12) {
            RemoteTMDBImage(
                posterPath: credit.posterPath,
                imageSize: .posterSmall
            )
            .frame(width: 54, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(credit.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let roleText = credit.roleText {
                    Text(roleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let year = credit.releaseYearText {
                        Label(year, systemImage: "calendar")
                    }
                    Label {
                        Text(credit.voteAverage, format: .number.precision(.fractionLength(1)))
                    } icon: {
                        Image(systemName: "star.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

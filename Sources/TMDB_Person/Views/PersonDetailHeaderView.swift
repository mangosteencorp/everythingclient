import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

@available(iOS 16.0, *)
struct PersonDetailHeaderView: View {
    let person: PersonDetail

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            PersonProfileImageView(profilePath: person.profilePath)

            VStack(alignment: .leading, spacing: 10) {
                Text(person.name)
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)

                if let knownFor = person.knownForDepartment {
                    Label(knownFor, systemImage: "sparkles.tv")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Label {
                    Text(LocalizedStringResource.personPopularityFormat(Float(person.popularity)))
                } icon: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.platformSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

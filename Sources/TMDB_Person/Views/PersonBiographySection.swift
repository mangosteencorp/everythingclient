import SwiftUI

@available(iOS 16.0, *)
struct PersonBiographySection: View {
    let biography: String

    var body: some View {
        if !biography.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStringResource.personBiography)
                    .font(.headline)
                Text(biography)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    PersonBiographySection(biography: "William Bradley Pitt is an American actor and film producer. He is the recipient of various accolades, including two Academy Awards.")
        .padding()
}
#endif

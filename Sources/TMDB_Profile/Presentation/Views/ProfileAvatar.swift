import Kingfisher
import SwiftUI
import TMDB_Shared_Backend

/// The account's avatar, or an animal symbol (stable per account, so it doesn't change on refresh) when
/// there is none. Decorative: the navigation title already names the account.
struct ProfileAvatar: View {
    let id: Int
    let avatarPath: String?

    private static let animalSymbols = [
        "hare.fill", "tortoise.fill", "dog.fill", "cat.fill", "bird.fill",
        "fish.fill", "ant.fill", "ladybug.fill", "lizard.fill", "pawprint.fill",
    ]

    var body: some View {
        Group {
            if let url = avatarPath.flatMap(TMDBImageSize.profileMedium.buildImageUrl(path:)) {
                KFImage(url).resizable().scaledToFill()
            } else {
                Image(systemName: Self.animalSymbols[abs(id) % Self.animalSymbols.count])
                    .resizable()
                    .scaledToFit()
                    .padding(7)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 32, height: 32)
        .background(Color(.systemGray6))
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Animal") {
    ProfileAvatar(id: sampleProfileEntity.accountInfo.id, avatarPath: nil)
}

#Preview("Avatar") {
    ProfileAvatar(id: 1, avatarPath: sampleProfileEntity.favoriteMovies?.first?.posterPath)
}
#endif

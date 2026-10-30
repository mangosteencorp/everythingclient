import SwiftUI

/// The user's own media servers, Jellyfin then Plex, as one list section. Each block stays out while its server has
/// nothing for the movie; with neither, so does the section.
struct MovieServerSection: View {
    let movieTitle: String
    let movieId: Int
    let movieYear: Int?
    @ObservedObject var jellyfinViewModel: MovieJellyfinViewModel
    @ObservedObject var plexViewModel: MoviePlexViewModel

    var body: some View {
        if jellyfinViewModel.isVisible || plexViewModel.isVisible {
            Section {
                if jellyfinViewModel.isVisible {
                    MovieJellyfinSection(movieTitle: movieTitle, movieId: movieId, jellyfinViewModel: jellyfinViewModel)
                }
                if plexViewModel.isVisible {
                    MoviePlexSection(plexViewModel: plexViewModel, movieTitle: movieTitle, movieYear: movieYear)
                }
            } header: {
                Text(L10n.serverSectionTitle)
                    .accessibilityIdentifier("movieDetail.server.section")
            }
        }
    }
}

#if DEBUG
#Preview("Jellyfin and Plex") {
    TMDBMovieDetailPreviewCatalog.serverSection.view
}

#Preview("Plex only") {
    TMDBMovieDetailPreviewCatalog.serverSectionPlexOnly.view
}
#endif

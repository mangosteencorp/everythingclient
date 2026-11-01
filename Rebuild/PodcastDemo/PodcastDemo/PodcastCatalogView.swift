#if DEBUG
import Podcast_Shared_UI
import SwiftUI

/// Every `Podcast_Shared_UI` preview, a tap away, the way the other demos list their catalogs.
struct PodcastCatalogView: View {
    var body: some View {
        List(PodcastUIPreviewCatalog.allCases) { preview in
            NavigationLink {
                preview.view
                    .navigationTitle(Text(verbatim: preview.rawValue))
            } label: {
                Text(verbatim: preview.rawValue)
            }
            .accessibilityIdentifier("podcastDemo.catalog.\(preview.rawValue)")
        }
        .navigationTitle(Text(.componentsTitle))
    }
}

#Preview {
    NavigationStack {
        PodcastCatalogView()
    }
}
#endif

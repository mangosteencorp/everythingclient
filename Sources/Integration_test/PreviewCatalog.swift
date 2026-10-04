#if DEBUG
import CoreFeatures
import everythingclient
import PhotoListViewer
import Pokedex
import Pokedex_Detail
import Pokedex_Pokelist
import Shared_UI_Support
import SwiftUI
import TMDB
import TMDB_Discover
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Person
import TMDB_Profile
import TMDB_Search
import TMDB_Shared_Backend
import TMDB_Shared_UI
import TMDB_TVShowDetail

/// One preview from a module's preview catalog, launchable through `INTEGRATION_TEST_NAME` as
/// `"<module>/<preview>"` — the same view Xcode's canvas shows for it.
public struct PreviewCatalogEntry: Identifiable {
    public let module: String
    public let name: String
    let content: @MainActor () -> AnyView

    public var id: String { "\(module)/\(name)" }
    public var accessibilityIdentifier: String { "integration.preview.\(id)" }
    /// What the screenshot run files it under.
    public var snapshotName: String { "\(module)_\(name)" }
}

@available(iOS 16, *)
public extension IntegrationTestLauncher {
    /// Every module's preview catalog, in launcher order.
    static var previewCatalog: [PreviewCatalogEntry] {
        [
            entries("TMDB", TMDBPreviewCatalog.self) { $0.view },
            entries("TMDBFeed", TMDBFeedPreviewCatalog.self) { $0.view },
            entries("TMDBSearch", TMDBSearchPreviewCatalog.self) { $0.view },
            entries("TMDBDiscover", TMDBDiscoverPreviewCatalog.self) { $0.view },
            entries("TMDBProfile", TMDBProfilePreviewCatalog.self) { $0.view },
            entries("TMDBMovieDetail", TMDBMovieDetailPreviewCatalog.self) { $0.view },
            entries("TMDBTVShowDetail", TMDBTVShowDetailPreviewCatalog.self) { $0.view },
            entries("TMDBPerson", TMDBPersonPreviewCatalog.self) { $0.view },
            entries("PhotoListViewer", PhotoListViewerPreviewCatalog.self) { $0.view },
            entries("TMDBSharedUI", TMDBSharedUIPreviewCatalog.self) { $0.view },
            entries("TMDBSharedBackend", TMDBSharedBackendPreviewCatalog.self) { $0.view },
            entries("SharedUISupport", SharedUISupportPreviewCatalog.self) { $0.view },
            entries("CoreFeatures", CoreFeaturesPreviewCatalog.self) { $0.view },
            entries("Pokedex", PokedexPreviewCatalog.self) { $0.view },
            entries("PokedexPokelist", PokedexPokelistPreviewCatalog.self) { $0.view },
            entries("PokedexDetail", PokedexDetailPreviewCatalog.self) { $0.view },
            entries("EverythingClient", EverythingClientPreviewCatalog.self) { $0.view },
        ].flatMap { $0 }
    }

    /// The modules with a preview catalog, in launcher order.
    static var previewCatalogModules: [String] {
        previewCatalog.reduce(into: []) { modules, entry in
            if modules.last != entry.module { modules.append(entry.module) }
        }
    }

    static func previewCatalog(module: String) -> [PreviewCatalogEntry] {
        previewCatalog.filter { $0.module == module }
    }

    private static func entries<Catalog: CaseIterable & RawRepresentable>(
        _ module: String,
        _: Catalog.Type,
        view: @escaping @MainActor (Catalog) -> some View
    ) -> [PreviewCatalogEntry] where Catalog.RawValue == String {
        Catalog.allCases.map { item in
            PreviewCatalogEntry(module: module, name: item.rawValue) { AnyView(view(item)) }
        }
    }
}

/// Renders a catalog entry, on the main actor its views are built on.
struct PreviewCatalogEntryView: View {
    let entry: PreviewCatalogEntry

    var body: some View {
        entry.content()
    }
}
#endif

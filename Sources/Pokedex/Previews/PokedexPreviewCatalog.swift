#if DEBUG
import SwiftUI

/// The Pokédex tab's preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. It loads from the live PokeAPI.
public enum PokedexPreviewCatalog: String, CaseIterable {
    case tab

    @MainActor @ViewBuilder
    public var view: some View {
        PokedexTabView()
    }
}
#endif

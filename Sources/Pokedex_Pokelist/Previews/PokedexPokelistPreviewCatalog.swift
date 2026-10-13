#if DEBUG
import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI

/// Every Pokémon list preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. `demo` and `list` load from the live PokeAPI
/// — `PokemonService` has no stand-in yet; `cell` is offline.
public enum PokedexPokelistPreviewCatalog: String, CaseIterable {
    case demo
    case list
    case cell

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            PokedexListDemoView()
        case .list:
            UIViewControllerPreview { ExamplePokelistRouter.createModule(pokemonService: pokemonService) }
        case .cell:
            UIViewPreview {
                let cell = PokemonCell(frame: CGRect(x: 0, y: 0, width: 160, height: 180))
                // No sprite URL: the cell shows its offline fallback instead of downloading one.
                cell.configure(with: PokemonEntity(id: 25, name: "pikachu", imageURL: ""))
                return cell
            }
            .frame(width: 160, height: 180)
        }
    }
}
#endif

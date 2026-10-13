#if DEBUG
import Pokedex_Shared_Backend
import Shared_UI_Support
import SwiftUI
import UIKit

/// Every Pokémon detail preview as a view of its own, so Xcode's canvas, the integration launcher
/// and the screenshot run all render the same thing. `detail` loads Pikachu from the live
/// PokeAPI — `PokemonService` has no stand-in yet; the rest use sample data.
public enum PokedexDetailPreviewCatalog: String, CaseIterable {
    case demo
    case detail
    case designOne
    case designTwo
    case loading
    case robotError

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            PokedexDetailDemoView()
        case .detail:
            UIViewControllerPreview {
                let viewModel = PokemonDetailViewModel(pokemonService: .shared)
                viewModel.loadPokemon(id: 25)
                return Self.pushed(PokemonDetailViewController(viewModel: viewModel))
            }
        case .designOne:
            UIViewControllerPreview { DetailDesign1ViewController(pokemon: Self.caterpie) }
        case .designTwo:
            UIViewControllerPreview { Self.pushed(DetailDesign2ViewController(pokemon: Self.caterpieShort)) }
        case .loading:
            UIViewControllerPreview { LoadingViewController() }
        case .robotError:
            UIViewControllerPreview { RobotErrorViewController() }
        }
    }

    /// Shows `viewController` pushed onto a stack, back button and all.
    @MainActor
    private static func pushed(_ viewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationController.pushViewController(viewController, animated: false)
        }
        return navigationController
    }

    private static var caterpie: PokemonDetail {
        PokemonDetail(
            id: 1,
            name: "Caterpie",
            imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/10.gif",
            weight: 290,
            speciesId: 1,
            moves: [
                PokemonDetail.Move(id: 1, moveId: 33, name: "Tackle"),
                PokemonDetail.Move(id: 2, moveId: 81, name: "String Shot"),
                PokemonDetail.Move(id: 3, moveId: 173, name: "Snore"),
                PokemonDetail.Move(id: 4, moveId: 450, name: "Bug Bite"),
                PokemonDetail.Move(id: 5, moveId: 527, name: "Electroweb"),
            ],
            abilities: [
                PokemonDetail.Ability(abilityId: 19, name: "Shield Dust"),
                PokemonDetail.Ability(abilityId: 50, name: "Run Away"),
            ],
            stats: [
                PokemonDetail.Stat(statId: 1, baseStat: 45, effort: 1, name: "HP"),
                PokemonDetail.Stat(statId: 2, baseStat: 30, effort: 0, name: "Attack"),
                PokemonDetail.Stat(statId: 3, baseStat: 35, effort: 0, name: "Defense"),
                PokemonDetail.Stat(statId: 4, baseStat: 20, effort: 0, name: "Sp. Atk"),
                PokemonDetail.Stat(statId: 5, baseStat: 20, effort: 0, name: "Sp. Def"),
                PokemonDetail.Stat(statId: 6, baseStat: 45, effort: 0, name: "Speed"),
            ]
        )
    }

    private static var caterpieShort: PokemonDetail {
        PokemonDetail(
            id: 10,
            name: "Caterpie",
            imageURL: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/shiny/10.gif",
            weight: 29,
            speciesId: 10,
            moves: [
                .init(id: 1, moveId: 1, name: "Tackle"),
                .init(id: 2, moveId: 2, name: "String Shot"),
                .init(id: 3, moveId: 3, name: "Bug Bite"),
                .init(id: 4, moveId: 4, name: "Electroweb"),
            ],
            abilities: [
                .init(abilityId: 1, name: "Shield Dust"),
                .init(abilityId: 2, name: "Run Away"),
            ],
            stats: [
                .init(statId: 1, baseStat: 45, effort: 1, name: "hp"),
                .init(statId: 2, baseStat: 30, effort: 0, name: "attack"),
                .init(statId: 3, baseStat: 35, effort: 0, name: "defense"),
                .init(statId: 6, baseStat: 45, effort: 0, name: "speed"),
            ]
        )
    }
}
#endif

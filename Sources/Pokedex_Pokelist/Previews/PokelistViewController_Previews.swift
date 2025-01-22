import SwiftUI
import Pokedex_Shared_Backend
#if DEBUG
let pokemonService = PokemonService.shared
//let previewViewController = PokelistRouter.createModule(pokemonService: pokemonService)
#Preview {
    UIViewControllerPreview{
        UIViewController()
    }
}
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
#endif

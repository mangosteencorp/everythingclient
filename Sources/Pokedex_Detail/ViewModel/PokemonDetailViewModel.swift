import Foundation
import Pokedex_Shared_Backend
import RxCocoa
import RxSwift

public class PokemonDetailViewModel {
    private let pokemonService: PokemonService
    private let disposeBag = DisposeBag()

    // Inputs
    private let pokemonIdRelay = BehaviorRelay<Int>(value: 0)

    // Outputs
    let pokemonDetail = BehaviorRelay<PokemonDetail?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()

    // Add property to track current pokemon id
    private(set) var currentPokemonId: Int?

    public init(pokemonService: PokemonService) {
        self.pokemonService = pokemonService

        setupBindings()
    }

    private func setupBindings() {
        pokemonIdRelay
            .filter { $0 > 0 }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] id -> Observable<PokemonDetail?> in
                guard let self = self else { return .just(nil) }
                return Observable.create { observer in
                    Task {
                        do {
                            let result = try await self.pokemonService.fetchPokemonDetail(id: id)
                            observer.onNext(result)
                            observer.onCompleted()
                        } catch {
                            observer.onError(error)
                        }
                    }
                    return Disposables.create()
                }
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .bind(to: pokemonDetail)
            .disposed(by: disposeBag)
    }

    public func loadPokemon(id: Int) {
        currentPokemonId = id
        pokemonIdRelay.accept(id)
    }
}

// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
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
                    let task = Task {
                        do {
                            let result = try await self.pokemonService.fetchPokemonDetail(id: id)
                            guard !Task.isCancelled else { return }
                            observer.onNext(result)
                            observer.onCompleted()
                        } catch {
                            guard !Task.isCancelled else { return }
                            observer.onError(error)
                        }
                    }
                    // In Rx, cancellation is disposal. Without this the `flatMapLatest` above
                    // disposes the previous sequence while its request keeps running, so switching
                    // pokémon quickly leaves stale fetches in flight.
                    return Disposables.create { task.cancel() }
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
#endif

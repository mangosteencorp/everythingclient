// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import Combine
import Foundation
import RxCocoa
import RxSwift
import TMDB_Shared_Backend

class ProfileViewModel {
    private let stateRelay = BehaviorRelay<ProfileViewState>(value: .loading)
    var state: Observable<ProfileViewState> { return stateRelay.asObservable() }

    private let disposeBag = DisposeBag()
    // Holds the profile request on its own: assigning a new subscription disposes the previous one,
    // so a refresh cannot race the load it replaces, and `cancelLoad()` can stop it outright. The
    // shared `disposeBag` would only drain when this view model is deallocated.
    private let profileRequest = SerialDisposable()
    private let getProfileUseCase: GetProfileUseCaseProtocol
    private let authViewModel: any AuthenticationViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    init(getProfileUseCase: GetProfileUseCaseProtocol, authViewModel: any AuthenticationViewModelProtocol) {
        self.getProfileUseCase = getProfileUseCase
        self.authViewModel = authViewModel

        // Observe authentication state changes using Combine publisher
        authViewModel.isAuthenticatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isAuthenticated: Bool) in
                if isAuthenticated {
                    self?.fetchProfile()
                } else {
                    self?.stateRelay.accept(.unauthorized)
                }
            }
            .store(in: &cancellables)
    }

    func fetchProfile() {
        stateRelay.accept(.loading)
        loadProfile()
    }

    func refreshProfile() {
        loadProfile()
    }

    /// Stops an in-flight profile request, for when the screen is dismissed.
    func cancelLoad() {
        profileRequest.disposable = Disposables.create()
    }

    private func loadProfile() {
        profileRequest.disposable = getProfileUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] profile in
                    self?.stateRelay.accept(.loaded(profile))
                },
                onFailure: { [weak self] error in
                    self?.stateRelay.accept(.error(error))
                }
            )
    }

    func signOut() {
        Task {
            await authViewModel.signOut()
            stateRelay.accept(.unauthorized)
        }
    }

    func signIn() async {
        await authViewModel.signIn()
    }
}

enum ProfileViewState {
    case unauthorized
    case loading
    case loaded(ProfileEntity)
    case error(Error)
}
#endif

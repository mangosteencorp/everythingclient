import Combine
import Foundation
import RxCocoa
import RxSwift
import TMDB_Shared_Backend

class ProfileViewModel {
    private let stateRelay = BehaviorRelay<ProfileViewState>(value: .loading)
    var state: Observable<ProfileViewState> { return stateRelay.asObservable() }

    private let disposeBag = DisposeBag()
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

        getProfileUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] profile in
                    self?.stateRelay.accept(.loaded(profile))
                },
                onFailure: { [weak self] error in
                    self?.stateRelay.accept(.error(error))
                }
            )
            .disposed(by: disposeBag)
    }

    func refreshProfile() {
        getProfileUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] profile in
                    self?.stateRelay.accept(.loaded(profile))
                },
                onFailure: { [weak self] error in
                    self?.stateRelay.accept(.error(error))
                }
            )
            .disposed(by: disposeBag)
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

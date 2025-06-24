import Combine
import Foundation
import TMDB_Shared_Backend

class ProfileViewModel: ObservableObject {
    @Published var state: ProfileViewState = .loading
    private var cancellables = Set<AnyCancellable>()
    private let getProfileUseCase: GetProfileUseCaseProtocol
    private let authViewModel: any AuthenticationViewModelProtocol

    init(getProfileUseCase: GetProfileUseCaseProtocol, authViewModel: any AuthenticationViewModelProtocol) {
        self.getProfileUseCase = getProfileUseCase
        self.authViewModel = authViewModel

        // Observe authentication state changes using the publisher
        authViewModel.isAuthenticatedPublisher
            .sink { [weak self] (isAuthenticated: Bool) in
                if isAuthenticated {
                    self?.fetchProfile()
                } else {
                    self?.state = .unauthorized
                }
            }
            .store(in: &cancellables)
    }

    func fetchProfile() {
        state = .loading

        getProfileUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.state = .error(error)
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.state = .loaded(profile)
                }
            )
            .store(in: &cancellables)
    }

    func signOut() {
        Task {
            await authViewModel.signOut()
            state = .unauthorized
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

import Foundation

protocol SignInViewModelProtocol: AnyObject {
    var isLoading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
    func signIn(username: String, password: String)
}

class SignInViewModel: SignInViewModelProtocol {
    private let authService: AuthServiceProtocol
    
    let isLoading = Observable<Bool>(false)
    let error = Observable<Error?>(nil)
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func signIn(username: String, password: String) {
        isLoading.value = true
        error.value = nil
        
        authService.signIn(username: username, password: password) { [weak self] result in
            self?.isLoading.value = false
            switch result {
            case .success:
                // Handle successful sign-in (e.g., navigate to main screen)
                break
            case .failure(let error):
                self?.error.value = error
            }
        }
    }
}

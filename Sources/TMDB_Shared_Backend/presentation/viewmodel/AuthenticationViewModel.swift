import Combine
import Foundation

public protocol AuthenticationViewModelProtocol: ObservableObject {
    var isAuthenticatedPublisher: Published<Bool>.Publisher { get }
    var isLoadingPublisher: Published<Bool>.Publisher { get }
    var errorPublisher: Published<Error?>.Publisher { get }
    
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }
    var error: Error? { get set }
    
    func signIn() async
    func signOut() async
}

@MainActor
public class AuthenticationViewModel: AuthenticationViewModelProtocol {
    private let authService: AuthenticationServiceProtocol
    private let webAuthService: WebAuthenticationService
    @Published public var isAuthenticated = false
    @Published public var isLoading = false
    @Published public var error: Error?

    public init(
        authService: AuthenticationServiceProtocol,
        webAuthService: WebAuthenticationService = WebAuthenticationService()
    ) {
        self.authService = authService
        self.webAuthService = webAuthService
        isAuthenticated = authService.isAuthenticated
    }
    
    public var isAuthenticatedPublisher: Published<Bool>.Publisher { $isAuthenticated }
    public var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    public var errorPublisher: Published<Error?>.Publisher { $error }
    
    public func signIn() async {
        isLoading = true
        error = nil
        
        do {
            // Step 1: Get request token
            let requestToken = try await authService.getRequestToken()
            // Step 2: Get auth URL and launch web authentication
            let authURL = try authService.getAuthenticationURL(with: requestToken)
            // Step 3: Wait for web authentication to complete
            let authenticatedToken = try await webAuthService.authenticate(url: authURL)
            // Step 4: Create session with the authenticated token
            let _ = try await authService.createSession(requestToken: authenticatedToken)
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    public func signOut() async {
        isLoading = true
        error = nil
        do {
            try await authService.signOut()
            isAuthenticated = false
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

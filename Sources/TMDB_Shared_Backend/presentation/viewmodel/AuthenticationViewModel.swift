import Foundation
import Combine
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
public class AuthenticationViewModel: AuthenticationViewModelProtocol {
    private let authService: AuthenticationServiceProtocol
    private let webAuthService: WebAuthenticationService
    @Published public var isAuthenticated = false
    @Published public var isLoading = false
    @Published public var error: Error?
    
    public init(authService: AuthenticationServiceProtocol, webAuthService: WebAuthenticationService = WebAuthenticationService()) {
        self.authService = authService
        self.webAuthService = webAuthService
        self.isAuthenticated = authService.isAuthenticated
    }
    
    public var isAuthenticatedPublisher: Published<Bool>.Publisher { $isAuthenticated }
    public var isLoadingPublisher: Published<Bool>.Publisher { $isLoading }
    public var errorPublisher: Published<Error?>.Publisher { $error }
    
    public func signIn() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Step 1: Get request token
            let requestToken = try await authService.getRequestToken()
            
            // Step 2: Get auth URL and launch web authentication
            let authURL = try authService.getAuthenticationURL(with: requestToken)
            
            // Step 3: Wait for web authentication to complete
            let authenticatedToken = try await webAuthService.authenticate(url: authURL)
            
            // Step 4: Create session with the authenticated token
            let _ = try await authService.createSession(requestToken: authenticatedToken)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    public func signOut() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await authService.signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false
            }
        }
    }
}

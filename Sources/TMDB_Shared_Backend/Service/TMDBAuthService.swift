import AuthenticationServices
import Foundation
import SwiftUI

// MARK: - Models

// MARK: - Authentication Service Protocol

public protocol AuthenticationServiceProtocol {
    func getRequestToken() async throws -> String
    func createSession(requestToken: String) async throws -> String
    func signOut() async throws
    func getAuthenticationURL(with token: String) throws -> URL
    var isAuthenticated: Bool { get }
}

// MARK: - Authentication Service Implementation

public class AuthenticationService: AuthenticationServiceProtocol {
    private let apiService: TMDBAPIService
    private let authRepository: AuthRepository
    private let webAuthBaseURL: String

    public init(
        apiService: TMDBAPIService,
        authRepository: AuthRepository,
        webAuthBaseURL: String = "https://www.themoviedb.org/authenticate"
    ) {
        self.apiService = apiService
        self.authRepository = authRepository
        self.webAuthBaseURL = webAuthBaseURL
    }

    public var isAuthenticated: Bool {
        authRepository.getSessionId() != nil
    }

    public func getRequestToken() async throws -> String {
        let response: RequestTokenResponse = try await apiService.request(.authStep1)
        return response.requestToken
    }

    public func getAuthenticationURL(with token: String) throws -> URL {
        var components = URLComponents(string: webAuthBaseURL + "/\(token)")
        components?.queryItems = [
            URLQueryItem(name: "redirect_to", value: "tmdb-app://auth-callback"),
        ]

        guard let url = components?.url else {
            throw AuthenticationError.invalidAuthURL
        }
        return url
    }

    public func createSession(requestToken: String) async throws -> String {
        let response: SessionResponse = try await apiService.request(.authNewSession(requestToken: requestToken))
        try authRepository.saveSessionId(response.sessionId)
        return response.sessionId
    }

    public func signOut() async throws {
        try authRepository.clearSessionId()
    }
}

// MARK: - Authentication Errors

public enum AuthenticationError: Error {
    case invalidAuthURL
    case authenticationCancelled
    case authorizationDenied
    case invalidCallbackURL
    case missingRequestToken
    case webAuthenticationFailed(Error)
    case apiError(TMDBAPIError)

    public var localizedDescription: String {
        switch self {
        case .invalidAuthURL:
            return "Could not create authentication URL"
        case .authenticationCancelled:
            return "Authentication was cancelled"
        case .authorizationDenied:
            return "Authorization was denied"
        case .invalidCallbackURL:
            return "Invalid callback URL received"
        case .missingRequestToken:
            return "No request token found in response"
        case let .webAuthenticationFailed(error):
            return "Web authentication failed: \(error.localizedDescription)"
        case let .apiError(apiError):
            return "API Error: \(apiError)"
        }
    }
}

// MARK: - Web Authentication Service

public class WebAuthenticationService: NSObject {
    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<String, Error>) -> Void)?

    public func authenticate(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "tmdb-app"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: AuthenticationError.webAuthenticationFailed(error))
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthenticationError.invalidCallbackURL)
                    return
                }

                let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems

                // Check if user denied authorization
                if (queryItems?.first(where: { $0.name == "denied" })?.value) != nil {
                    continuation.resume(throwing: AuthenticationError.authorizationDenied)
                    return
                }

                // Get request token from callback
                if let token = queryItems?.first(where: { $0.name == "request_token" })?.value {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: AuthenticationError.missingRequestToken)
                }
            }

            authSession?.presentationContextProvider = self
            // authSession?.prefersEphemeralWebBrowserSession = true

            if !authSession!.start() {
                continuation.resume(throwing: AuthenticationError.authenticationCancelled)
            }
        }
    }
}

extension WebAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

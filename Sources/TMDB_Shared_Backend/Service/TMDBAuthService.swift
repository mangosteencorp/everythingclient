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

/// Main actor isolated because `ASWebAuthenticationSession` must be started and
/// presented from the main thread.
@MainActor
public class WebAuthenticationService: NSObject {
    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<String, Error>) -> Void)?

    public func authenticate(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 17.4, macOS 14.4, watchOS 10.4, tvOS 17.4, visionOS 1.1, *) {
                authSession = ASWebAuthenticationSession(url: url, callback: .customScheme("tmdb-app")) { callbackURL, error in
                    continuation.resume(with: Self.requestToken(from: callbackURL, error: error))
                }
            } else {
                authSession = ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: "tmdb-app"
                ) { callbackURL, error in
                    continuation.resume(with: Self.requestToken(from: callbackURL, error: error))
                }
            }
            authSession?.presentationContextProvider = self
            // authSession?.prefersEphemeralWebBrowserSession = true
            authSession?.start()
        }
    }

    /// Maps the `ASWebAuthenticationSession` completion arguments to the request token,
    /// or to the `AuthenticationError` describing why it could not be obtained.
    private static func requestToken(from callbackURL: URL?, error: Error?) -> Result<String, Error> {
        if let error = error {
            return .failure(AuthenticationError.webAuthenticationFailed(error))
        }

        guard let callbackURL = callbackURL else {
            return .failure(AuthenticationError.invalidCallbackURL)
        }

        let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems

        // Check if user denied authorization
        if (queryItems?.first(where: { $0.name == "denied" })?.value) != nil {
            return .failure(AuthenticationError.authorizationDenied)
        }

        // Get request token from callback
        guard let token = queryItems?.first(where: { $0.name == "request_token" })?.value else {
            return .failure(AuthenticationError.missingRequestToken)
        }
        return .success(token)
    }
}

extension WebAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

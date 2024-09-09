import SwiftUI
import AuthenticationServices
import Foundation
import Combine
import Network
import KeychainAccess

final class NetworkManager: NSObject, ObservableObject {
    @Published var noInternet: Bool = false
    @Published var noWifinoCelularData = false
    
    private let monitor = NWPathMonitor()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForResource = 5
        return URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }()
    
    override init() {
        super.init()
        detectWIFIandData()
    }
    
    func makeHTTPRequest<T: Decodable>(url: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 || (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw MovieServiceError.invalidServerResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func signInAsync(requestToken: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.webAuth(requestToken: requestToken) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func webAuth(requestToken: String, completion: @escaping (Result<String, Error>) -> Void) {
        let scheme = "exampleauth"
        let sessionAuth = ASWebAuthenticationSession(url: URL(string: EndPoint.authStep2 + requestToken + "?redirect_to=exampleauth://auth")!, callbackURLScheme: scheme) { callbackURL, error in
            guard error == nil, let callbackURL = callbackURL else {
                completion(.failure(OthersErrors.userCanceledAuth))
                return
            }
            
            let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems
            guard ((queryItems?.filter({ $0.name == "denied" }).first?.value) != nil) == false else {
                completion(.failure(OthersErrors.userDeniedAuth))
                return
            }
            
            let token = queryItems?.filter({ $0.name == "request_token" }).first?.value
            guard let token = token else {
                completion(.failure(OthersErrors.cantGetToken))
                return
            }
            completion(.success(token))
        }
        sessionAuth.presentationContextProvider = self
        sessionAuth.start()
    }
    
    private func detectWIFIandData() {
        monitor.start(queue: .main)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("TENEMOS WIFI/DATA")
                self.noWifinoCelularData = false
                self.noInternet = false
            } else {
                print("NO HAY WIFI/DATA")
                self.noWifinoCelularData = true
                self.noInternet = true
            }
        }
    }
}

extension NetworkManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

extension NetworkManager: URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        print("SIN INTERNET")
        noInternet = true
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard task.error == nil, let metric = metrics.transactionMetrics.first?.resourceFetchType else {
            print("HUBO UN TASK ERROR QUE NO ES NIL")
            noInternet = true
            return
        }
        
        switch metric {
        case .networkLoad, .serverPush:
            print("RECURSO OBTENIDO DE NEWORKLOAD, SERVERPUSH")
            noInternet = false
        default:
            break
        }
    }
}

struct KeychainManager {
    private let keychain = Keychain(service: "TMDBSwiftUI")
    
    func saveSessionID(_ sessionID: String) throws {
        try keychain.set(sessionID, key: "userSessionID")
    }
    
    func getSessionID() throws -> String {
        try keychain.get("userSessionID") ?? ""
    }
    
    func deleteSessionID() throws {
        try keychain.remove("userSessionID")
    }
}

enum EndPoint {
    static let apiKey = "0141e6d543b187f0b7e6bb3a1902209a"
    static let authStep2 = "https://www.themoviedb.org/authenticate/"
    private static let baseURL = "https://api.themoviedb.org/3/"
    
    static func createURLRequest(url: Route, method: HTTPMethod, query: [String: String]? = nil, parameters: [String: Any]? = nil) throws -> URLRequest {
        let urlString = EndPoint.baseURL + url.rawValue
        let URL = URL(string: urlString)!
        
        var urlRequest = URLRequest(url: URL)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = method.rawValue
        
        if let query = query {
            var urlComponent = URLComponents(string: urlString)
            urlComponent?.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
            urlRequest.url = urlComponent?.url
        }
        
        if let parameters = parameters {
            let bodyData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            urlRequest.httpBody = bodyData
        }
        return urlRequest
    }
}

enum HTTPMethod: String {
    case GET, POST, DELETE
}

enum Route: Equatable {
    case authStep1, authStep3, accountInfo
    
    var rawValue: String {
        switch self {
        case .authStep1: return "authentication/token/new"
        case .authStep3: return "authentication/session/new"
        case .accountInfo: return "account"
        }
    }
}

struct UserModel: Codable {
    let avatar: Avatar
    let id: Int
    let iso639_1, iso3166_1, name: String
    let includeAdult: Bool
    let username: String

    enum CodingKeys: String, CodingKey {
        case avatar, id
        case iso639_1 = "iso_639_1"
        case iso3166_1 = "iso_3166_1"
        case name
        case includeAdult = "include_adult"
        case username
    }
}

struct Avatar: Codable {
    let gravatar: Gravatar
}

struct Gravatar: Codable {
    let hash: String
}

struct AuthModel: Codable {
    let requestToken: String
}

struct AuthSessionModel: Codable {
    let sessionID: String
}

enum OthersErrors: Error {
    case userCanceledAuth, userDeniedAuth, cantGetToken
}

enum KeychainError: Error {
    case savingError, gettingError, deletingError
}

enum MovieServiceError: Error {
    case invalidServerResponse, failedDecode, badInternet
}

public struct LoginView: View {
    @StateObject private var userVM = UserViewModel(service: NetworkManager(), keychainM: KeychainManager())
    public init(){}
    public var body: some View {
        VStack {
            Text("Log in to your TMDB account")
                .padding()
            Button("Log in") {
                Task {
                    try await userVM.LogIn()
                }
            }
            .disabled(userVM.isLoading)
            
            if userVM.isLoading {
                ProgressView()
            }
        }
        .alert(isPresented: $userVM.showAlert) {
            Alert(title: Text("Error"), message: Text(userVM.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

class UserViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var isLoading: Bool = false
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    
    private let service: NetworkManager
    let keychainM: KeychainManager
    
    init(service: NetworkManager, keychainM: KeychainManager) {
        self.service = service
        self.keychainM = keychainM
    }
    
    @MainActor func LogIn() async throws {
        isLoading = true
        
        do {
            // Request a new token for login (STEP 1)
            let urlRequestSTEP1 = try EndPoint.createURLRequest(url: .authStep1, method: .GET, query: ["api_key": EndPoint.apiKey])
            let tokenRequest: AuthModel = try await service.makeHTTPRequest(url: urlRequestSTEP1)
            
            // Show web view for user login and app authorization (STEP 2)
            let token = try await service.signInAsync(requestToken: tokenRequest.requestToken)
            
            // Get sessionID (STEP 3) and save it securely
            let urlRequest = try EndPoint.createURLRequest(url: .authStep3, method: .POST, query: ["api_key": EndPoint.apiKey], parameters: ["request_token": token])
            let sessionID: AuthSessionModel = try await service.makeHTTPRequest(url: urlRequest)
            
            try keychainM.saveSessionID(sessionID.sessionID)
            
            await getUserInfo()
            isLoading = false
        } catch let error as OthersErrors where error == .userCanceledAuth {
            print("Login cancelled")
            isLoading = false
        } catch {
            await loadError(error)
        }
    }
    
    @MainActor func getUserInfo() async {
        isLoading = true
        
        do {
            let urlRequest = try EndPoint.createURLRequest(url: .accountInfo, method: .GET, query: ["api_key": EndPoint.apiKey, "session_id": keychainM.getSessionID()])
            let user: UserModel = try await service.makeHTTPRequest(url: urlRequest)
            
            isLoading = false
            self.user = user
        } catch {
            await loadError(error)
        }
    }
    
    @MainActor private func loadError(_ error: Error) async {
        isLoading = false
        alertMessage = error.localizedDescription
        showAlert = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

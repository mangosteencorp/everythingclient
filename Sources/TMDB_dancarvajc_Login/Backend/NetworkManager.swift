import Combine
import Foundation
import Network
import AuthenticationServices
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
    
    func makeHTTPRequest<T:Decodable>(url: URLRequest) async throws-> T {
        
        var data: Data
        var response: URLResponse
        
        // Se consume la API. Se hace un DO-Catch para personalizar el error a uno de MovieServiceError
        do {
            (data, response) = try await session.data(for: url)
            
        } catch {
            throw MovieServiceError.badInternet
        }
        
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 || (response as? HTTPURLResponse)?.statusCode == 201 else {
            
            throw MovieServiceError.invalidServerResponse
        }
        
        
        do {
            let dataDecoded = try JSONDecoder().decode(T.self, from: data)
            
            return dataDecoded
        } catch  {
            throw MovieServiceError.failedDecode
        }
        
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

import Foundation

enum EndPoint {
    static var apiKey = ""
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

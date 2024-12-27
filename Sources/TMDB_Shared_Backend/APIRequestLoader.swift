import Foundation
protocol APIRequest {
    associatedtype RequestDataType
    associatedtype ResponseDataType
    func makeRequest(from data: RequestDataType) throws -> URLRequest
    func parseResponse(data: Data) throws -> ResponseDataType
}
class APIRequestLoader<T: APIRequest> {
    let apiRequest: T
    let urlSession: URLSession
    
    init(apiRequest: T, urlSession: URLSession = .shared) {
        self.apiRequest = apiRequest
        self.urlSession = urlSession
    }
    
    func loadAPIRequest(requestData: T.RequestDataType) async throws -> T.ResponseDataType {
        let urlRequest = try apiRequest.makeRequest(from: requestData)
        let (data, _) = try await urlSession.data(for: urlRequest)
        return try apiRequest.parseResponse(data: data)
    }
}

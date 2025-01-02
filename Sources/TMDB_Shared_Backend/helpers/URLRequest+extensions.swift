import Foundation
extension URLRequest {
    var curlString: String {
        guard let url = self.url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"
        
        if self.httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        
        var command = [baseCommand]
        
        if let method = self.httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = self.allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H \"\(key): \(value)\"")
            }
        }
        
        if let bodyData = self.httpBody, let bodyString = String(data: bodyData, encoding: .utf8), !bodyString.isEmpty {
            var escapedBody = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "`", with: "'")
            command.append("-d \"\(escapedBody)\"")
        }
        
        return command.joined(separator: " ")
    }
}


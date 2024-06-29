import Foundation

protocol AuthServiceProtocol {
    func signIn(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
}

class AuthService: AuthServiceProtocol {
    func signIn(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Implement your sign-in logic here (e.g., API call)
        // For this example, we'll just simulate a network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if username == "test" && password == "password" {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])))
            }
        }
    }
}

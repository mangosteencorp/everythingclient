public protocol AuthRepository {
    func getSessionId() -> String?
    func saveSessionId(_ sessionId: String) throws
    func clearSessionId() throws
}

public class DefaultAuthRepository: AuthRepository {
    private let keychainDataSource: KeychainDataSource
    private let sessionIdKey = "tmdb_session_id"
    
    public init(keychainDataSource: KeychainDataSource = KeychainDataSource()) {
        self.keychainDataSource = keychainDataSource
    }
    
    public func getSessionId() -> String? {
        try? keychainDataSource.get(forKey: sessionIdKey)
    }
    
    public func saveSessionId(_ sessionId: String) throws {
        try keychainDataSource.save(sessionId, forKey: sessionIdKey)
    }
    
    public func clearSessionId() throws {
        try keychainDataSource.delete(forKey: sessionIdKey)
    }
} 
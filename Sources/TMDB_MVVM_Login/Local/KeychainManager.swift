import KeychainAccess


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

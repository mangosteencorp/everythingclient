public protocol AuthRepository {
    func getSessionId() -> String?
    func saveSessionId(_ sessionId: String) throws
    func clearSessionId() throws
}


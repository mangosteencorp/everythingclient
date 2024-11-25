
import Foundation


enum OthersErrors: Error {
    case userCanceledAuth, userDeniedAuth, cantGetToken
}

enum KeychainError: Error {
    case savingError, gettingError, deletingError
}

enum MovieServiceError: Error {
    case invalidServerResponse, failedDecode, badInternet
}

import Foundation

public struct ThirdPartyInitializationOptions {
    public let firebase: Bool
    public init(firebase: Bool = false) {
        self.firebase = firebase
    }
}

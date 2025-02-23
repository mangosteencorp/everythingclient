import Foundation

// Common parameter protocols that can be implemented by specific tracking events
public protocol AnalyticsParameters {
    var additionalParameters: [String: Any]? { get }
}

public protocol ItemParameters {
    var itemId: String? { get }
    var itemName: String? { get }
    var itemCategory: String? { get }
    var itemBrand: String? { get }
    var price: Double? { get }
    var quantity: Int? { get }
    var currency: String? { get }
}

public protocol ScreenParameters {
    var screenName: String { get }
    var screenClass: String? { get }
    var contentType: String? { get }
}

public protocol UserParameters {
    var userId: String? { get }
    var method: String? { get }
    var score: Double? { get }
    var success: Bool? { get }
    var level: Int? { get }
}

// Concrete parameter structs
public struct PageViewParameters: AnalyticsParameters, ScreenParameters {
    public let screenName: String
    public let screenClass: String?
    public let contentType: String?
    public let additionalParameters: [String: Any]?

    public init(
        screenName: String,
        screenClass: String? = nil,
        contentType: String? = nil,
        additionalParameters: [String: Any]? = nil
    ) {
        self.screenName = screenName
        self.screenClass = screenClass
        self.contentType = contentType
        self.additionalParameters = additionalParameters
    }
}

public struct EventParameters: AnalyticsParameters, ItemParameters, UserParameters {
    public let itemId: String?
    public let itemName: String?
    public let itemCategory: String?
    public let itemBrand: String?
    public let price: Double?
    public let quantity: Int?
    public let currency: String?
    public let userId: String?
    public let method: String?
    public let score: Double?
    public let success: Bool?
    public let level: Int?
    public let additionalParameters: [String: Any]?

    public init(
        itemId: String? = nil,
        itemName: String? = nil,
        itemCategory: String? = nil,
        itemBrand: String? = nil,
        price: Double? = nil,
        quantity: Int? = nil,
        currency: String? = nil,
        userId: String? = nil,
        method: String? = nil,
        score: Double? = nil,
        success: Bool? = nil,
        level: Int? = nil,
        additionalParameters: [String: Any]? = nil
    ) {
        self.itemId = itemId
        self.itemName = itemName
        self.itemCategory = itemCategory
        self.itemBrand = itemBrand
        self.price = price
        self.quantity = quantity
        self.currency = currency
        self.userId = userId
        self.method = method
        self.score = score
        self.success = success
        self.level = level
        self.additionalParameters = additionalParameters
    }
}

public protocol AnalyticsTracker {
    /// Tracks a page view with structured parameters
    func trackPageView(parameters: PageViewParameters)

    /// Tracks a custom event with structured parameters
    func trackEvent(name: String, parameters: EventParameters?)
}

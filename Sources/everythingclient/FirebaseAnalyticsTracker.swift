import Foundation
import FirebaseAnalytics
import CoreFeatures

public class FirebaseAnalyticsTracker: AnalyticsTracker {
    public init() {}
    
    public func trackPageView(parameters: PageViewParameters) {
        var params: [String: Any] = [
            AnalyticsParameterScreenName: parameters.screenName
        ]
        
        if let screenClass = parameters.screenClass {
            params[AnalyticsParameterScreenClass] = screenClass
        }
        
        if let contentType = parameters.contentType {
            params[AnalyticsParameterContentType] = contentType
        }
        
        if let additional = parameters.additionalParameters {
            params.merge(additional) { current, _ in current }
        }
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
    }
    
    public func trackEvent(name: String, parameters: EventParameters?) {
        guard let parameters = parameters else {
            Analytics.logEvent(name, parameters: nil)
            return
        }
        
        var params: [String: Any] = [:]
        
        // Item parameters
        if let itemId = parameters.itemId {
            params[AnalyticsParameterItemID] = itemId
        }
        if let itemName = parameters.itemName {
            params[AnalyticsParameterItemName] = itemName
        }
        if let itemCategory = parameters.itemCategory {
            params[AnalyticsParameterItemCategory] = itemCategory
        }
        if let itemBrand = parameters.itemBrand {
            params[AnalyticsParameterItemBrand] = itemBrand
        }
        if let price = parameters.price {
            params[AnalyticsParameterPrice] = price
        }
        if let quantity = parameters.quantity {
            params[AnalyticsParameterQuantity] = quantity
        }
        if let currency = parameters.currency {
            params[AnalyticsParameterCurrency] = currency
        }
        
        // User parameters
        if let method = parameters.method {
            params[AnalyticsParameterMethod] = method
        }
        if let score = parameters.score {
            params[AnalyticsParameterScore] = score
        }
        if let success = parameters.success {
            params[AnalyticsParameterSuccess] = success
        }
        if let level = parameters.level {
            params[AnalyticsParameterLevel] = level
        }
        
        if let additional = parameters.additionalParameters {
            params.merge(additional) { current, _ in current }
        }
        
        Analytics.logEvent(name, parameters: params)
    }
} 
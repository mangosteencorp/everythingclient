import Foundation

public protocol MovieFeedAnalyticsTrackerProtocol {
    func trackAnalyticEvent(_ event: MovieFeedTrackingEvent)
}

import FirebaseAnalytics
import Foundation

struct FirebaseAnalyticsTrackerImpl {
    func track(kw: String) {
        Analytics.logEvent(kw, parameters: nil)
    }
}

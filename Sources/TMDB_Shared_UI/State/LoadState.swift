import Foundation

/// Load lifecycle shared by the feature view models.
///
/// `initial` is what makes a load idempotent: a view model only starts work from `initial`, so any
/// number of `.task` modifiers can ask for the same load without stacking requests. An explicit
/// user action goes through `reload`, which only refuses while a request is already in flight.
public enum LoadState<Value> {
    case initial
    case loading
    case success(Value)
    case error(String)

    public var isInitial: Bool {
        if case .initial = self { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var value: Value? {
        if case let .success(value) = self { return value }
        return nil
    }

    public var errorMessage: String? {
        if case let .error(message) = self { return message }
        return nil
    }
}

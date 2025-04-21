import SwiftUI
@available(iOS 16.0, *)
public class NavigationState: ObservableObject {
    @Published public var path = NavigationPath()
    @Published public var sheet: (any Route)?

    public func navigate(to route: TMDBRoute) {
        path.append(route)
        objectWillChange.send() // Explicitly notify about the change
    }

    public func push(_ route: any Route) {
        path.append(route)
    }

    public func present(_ route: any Route) {
        sheet = route
    }

    public func pop() {
        path.removeLast()
    }

    public func popToRoot() {
        while !path.isEmpty {
            path.removeLast()
        }
    }

    public func dismiss() {
        sheet = nil
    }
}

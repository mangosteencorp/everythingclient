import SwiftUI
import Combine

@available(iOS 16.0, *)
@MainActor
public class Coordinator: ObservableObject {
    @Published public var navigationPath: NavigationPath
    @Published public var sheet: (any Route)?
    

    public init(navigationPath: NavigationPath = NavigationPath(), sheet: (any Route)? = nil) {
        self.navigationPath = navigationPath
        self.sheet = sheet
    }
    public func push(_ route: any Route) {
        navigationPath.append(route)
    }
    
    public func present(_ route: any Route) {
        sheet = route
    }
    
    public func pop() {
        navigationPath.removeLast()
    }
    
    public func popToRoot() {
        navigationPath.popToRoot()
    }
    
    public func dismiss() {
        sheet = nil
    }
}
@available(iOS 16.0, *)
extension NavigationPath {
    mutating func popToRoot() {
        while !isEmpty {
            removeLast()
        }
    }
}

public protocol Route: Hashable { }

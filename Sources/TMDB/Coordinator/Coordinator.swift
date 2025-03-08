import Combine
import SwiftUI

public enum TabRoute: Hashable {
    case nowPlaying
    case upcoming
    case profile

    public var title: String {
        switch self {
        case .nowPlaying: return "Now Playing"
        case .upcoming: return "Upcoming"
        case .profile: return "Profile"
        }
    }

    public var iconName: String {
        switch self {
        case .nowPlaying: return "play.circle"
        case .upcoming: return "magnifyingglass"
        case .profile: return "list.bullet"
        }
    }
}

// MARK: - NavigationState.swift

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

// MARK: - Coordinator.swift

@available(iOS 16.0, *)
@MainActor
public class Coordinator: ObservableObject {
    @Published public var selectedTab: TabRoute
    @Published private(set) var navigationStates: [TabRoute: NavigationState]
    public let tabList: [TabRoute]
    public init(tabList: [TabRoute]) {
        self.tabList = tabList
        selectedTab = tabList[0]

        // Initialize navigation state for each tab
        var states: [TabRoute: NavigationState] = [:]
        for tab in tabList {
            states[tab] = NavigationState()
        }
        navigationStates = states
    }

    public func path(for tab: TabRoute) -> Binding<NavigationPath> {
        Binding(
            get: { [weak self] in
                self?.navigationStates[tab]?.path ?? NavigationPath()
            },
            set: { [weak self] newValue in
                self?.navigationStates[tab]?.path = newValue
            }
        )
    }

    public func switchTab(to tab: TabRoute) {
        selectedTab = tab
    }

    public func switchTab(to index: Int) {
        guard index >= 0 && index < tabList.count else { return }
        selectedTab = tabList[index]
    }

    public var currentIndex: Int {
        tabList.firstIndex(of: selectedTab) ?? 0
    }

    public func navigate(to route: TMDBRoute, in tab: TabRoute) {
        if let state = navigationStates[tab] {
            state.navigate(to: route)
            objectWillChange.send() // Explicitly notify about the change
        }
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

public protocol Route: Hashable {}

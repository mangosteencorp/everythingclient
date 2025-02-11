import SwiftUI
import Combine

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
    @Published public  var path = NavigationPath()
    @Published public  var sheet: (any Route)?
    
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
    private var navigationStates: [TabRoute: NavigationState]
    public let tabList: [TabRoute]
    public init(tabList: [TabRoute]) {
        self.tabList = tabList
        self.selectedTab = tabList[0]
        
        // Initialize navigation state for each tab
        var states: [TabRoute: NavigationState] = [:]
        for tab in tabList {
            states[tab] = NavigationState()
        }
        self.navigationStates = states
    }
    
    public func path(for tab: TabRoute) -> Binding<NavigationPath> {
        Binding(
            get: { self.navigationStates[tab]!.path },
            set: { self.navigationStates[tab]!.path = $0 }
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

import Combine
import SwiftUI

// MARK: - Coordinator.swift
@available(iOS 16.0, *)
@MainActor
public class Coordinator: ObservableObject {
    @Published public var selectedTab: TabRoute
    @Published private(set) var navigationStates: [TabRoute: NavigationState]
    @Published private(set) var tabBarHiddenStates: [TabRoute: Bool] // Tracks tab bar visibility
    public let tabList: [TabRoute]

    public init(tabList: [TabRoute]) {
        self.tabList = tabList
        selectedTab = tabList[0]

        // Initialize navigation and visibility states
        var states: [TabRoute: NavigationState] = [:]
        var hiddenStates: [TabRoute: Bool] = [:]
        for tab in tabList {
            states[tab] = NavigationState()
            hiddenStates[tab] = false // Tab bar visible by default
        }
        navigationStates = states
        tabBarHiddenStates = hiddenStates
    }

    public func path(for tab: TabRoute) -> Binding<NavigationPath> {
        Binding(
            get: { [weak self] in
                self?.navigationStates[tab]?.path ?? NavigationPath()
            },
            set: { [weak self] newValue in
                self?.navigationStates[tab]?.path = newValue
                // Update visibility based on navigation depth
                if let count = self?.navigationStates[tab]?.path.count {
                    self?.tabBarHiddenStates[tab] = count > 0
                }
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
            tabBarHiddenStates[tab] = true // Hide tab bar on navigation
            objectWillChange.send()
        }
    }

    public func pop(in tab: TabRoute) {
        if let state = navigationStates[tab] {
            state.pop()
            // Show tab bar if back at root
            tabBarHiddenStates[tab] = state.path.isEmpty
            objectWillChange.send()
        }
    }

    public func popToRoot(in tab: TabRoute) {
        if let state = navigationStates[tab] {
            state.popToRoot()
            tabBarHiddenStates[tab] = false // Show tab bar at root
            objectWillChange.send()
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

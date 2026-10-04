import SwiftUI
import UIKit

/// Full-bleed pages with a dot indicator instead of a bar: swipe sideways or tap the dots to turn.
///
/// Only the selected tab is built, as in `FloatingTabShell`. A paging `TabView` kept its pages
/// inside the safe area, so on the iPhone Duo their navigation bars never reached the rail beside
/// the camera, where every other shell's bar puts its buttons.
@available(iOS 16, *)
struct PagedTabShell<Page: View>: View {
    @ObservedObject var coordinator: Coordinator
    @ViewBuilder let page: (TabRoute) -> Page

    /// Which way the last turn went, so pages slide in from the side the swipe came from.
    @State private var isTurningForward = true

    /// A pushed detail page owns horizontal swipes (back) and the bottom edge.
    private var isDetailPushed: Bool {
        coordinator.tabBarHiddenStates[coordinator.selectedTab] ?? false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            page(coordinator.selectedTab)
                .id(coordinator.selectedTab)
                .transition(.asymmetric(
                    insertion: .move(edge: isTurningForward ? .trailing : .leading),
                    removal: .move(edge: isTurningForward ? .leading : .trailing)
                ))

            if !isDetailPushed {
                PageDots(
                    currentPage: Binding(get: { coordinator.currentIndex }, set: turn(to:)),
                    numberOfPages: coordinator.tabList.count
                )
            }
        }
        .gesture(PageSwipeGesture(isEnabled: !isDetailPushed) { turn(to: coordinator.currentIndex + $0) })
    }

    private func turn(to index: Int) {
        guard coordinator.tabList.indices.contains(index), index != coordinator.currentIndex else { return }
        isTurningForward = index > coordinator.currentIndex
        // A leaving page slides with the transition it was last drawn with, so the new direction
        // has to reach it one update before the page changes.
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) { coordinator.switchTab(to: index) }
        }
    }
}

/// Horizontal swipe that turns the page by one (+1 forward, -1 back). It waits for anything in
/// the page that scrolls sideways, such as the feed's category chips, to fail first.
private struct PageSwipeGesture: UIGestureRecognizerRepresentable {
    let isEnabled: Bool
    let onTurn: (Int) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let distance = recognizer.translation(in: recognizer.view).x
        guard recognizer.state == .ended, abs(distance) > 40 else { return }
        onTurn(distance < 0 ? 1 : -1)
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Delegate {
        Delegate()
    }

    final class Delegate: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRequireFailureOf other: UIGestureRecognizer
        ) -> Bool {
            scrollsSideways(other)
        }

        // Vertical lists keep scrolling while a sideways swipe over them turns the page.
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            other.view is UIScrollView && !scrollsSideways(other)
        }

        private func scrollsSideways(_ other: UIGestureRecognizer) -> Bool {
            guard let scrollView = other.view as? UIScrollView, other === scrollView.panGestureRecognizer else {
                return false
            }
            return scrollView.contentSize.width > scrollView.bounds.width
        }
    }
}

#if DEBUG
#Preview {
    TMDBPreviewCatalog.pagedTabShell.view
}
#endif

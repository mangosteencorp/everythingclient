import SwiftUI
import UIKit

/// The system page dots, standing alone. Tapping or scrubbing them changes the page, and
/// VoiceOver reads and adjusts them with UIKit's own localized "page x of y".
struct PageDots: UIViewRepresentable {
    static let accessibilityIdentifier = "paged.shell.dots"

    @Binding var currentPage: Int
    let numberOfPages: Int

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        // Pages are full-bleed and often white: the platter keeps the dots readable on any of them,
        // and the default white current dot would vanish on the light platter.
        control.backgroundStyle = .prominent
        control.currentPageIndicatorTintColor = .label
        control.accessibilityIdentifier = Self.accessibilityIdentifier
        control.addTarget(context.coordinator, action: #selector(Target.pageChanged(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UIPageControl, context: Context) {
        context.coordinator.currentPage = $currentPage
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
    }

    func makeCoordinator() -> Target {
        Target(currentPage: $currentPage)
    }

    final class Target: NSObject {
        var currentPage: Binding<Int>

        init(currentPage: Binding<Int>) {
            self.currentPage = currentPage
        }

        @objc func pageChanged(_ control: UIPageControl) {
            currentPage.wrappedValue = control.currentPage
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var page = 1

    PageDots(currentPage: $page, numberOfPages: 5)
        .padding()
}
#endif

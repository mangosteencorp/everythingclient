import SwiftUI

public extension View {
    /// Offsets layout to avoid iPadOS 26 window corner insets (traffic-light controls).
    ///
    /// SwiftUI alternative to UIKit's `layoutGuide(for: .margins(cornerAdaptation: .horizontal))`.
    @ViewBuilder
    func adaptiveContainerCornerOffset(
        _ edges: Edge.Set = .horizontal,
        sizeToFit: Bool = true
    ) -> some View {
        // `macOS 26.0` must be spelled out: a bare `*` clause matches macOS, so without it the
        // macOS build takes this branch and fails on the macOS 26-only API.
        if #available(iOS 26.0, macOS 26.0, *) {
            containerCornerOffset(edges, sizeToFit: sizeToFit)
        } else {
            self
        }
    }
}

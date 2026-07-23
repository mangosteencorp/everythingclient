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
        if #available(iOS 26.0, *) {
            containerCornerOffset(edges, sizeToFit: sizeToFit)
        } else {
            self
        }
    }
}

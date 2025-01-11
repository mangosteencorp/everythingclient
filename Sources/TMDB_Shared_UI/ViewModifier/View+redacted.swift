import SwiftUI
@available(iOS 13, macOS 11, *)
extension View {
    @ViewBuilder
    public func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}

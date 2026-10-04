import SwiftUI

#if DEBUG
/// Holds a preview's `@State`, so a preview that needs a live binding can still be a plain view —
/// `@Previewable` only works inside `#Preview`, and preview catalogs render outside it too.
public struct StatefulPreview<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    public init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    public var body: some View {
        content($value)
    }
}
#endif

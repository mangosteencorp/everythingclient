import SwiftUI

@available(iOS 15, macOS 12, *)
struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline) // Set the font to headline
            .foregroundColor(.primary) // Set the text color to primary
            .padding(.vertical, 4) // Add vertical padding
    }
}
@available(iOS 15, macOS 12, *)
extension View {
    func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }
}

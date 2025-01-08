import SwiftUI


struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline) // Set the font to headline
            .foregroundColor(.primary) // Set the text color to primary
            .padding(.vertical, 4) // Add vertical padding
    }
}

extension Text {
    public func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }
}

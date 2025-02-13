import SwiftUI

public extension Color {
    static func random() -> Color {
        return Color(
            red: Double.random(in: 0 ... 1),
            green: Double.random(in: 0 ... 1),
            blue: Double.random(in: 0 ... 1)
        )
    }
}

public extension View {
    @ViewBuilder
    func debugBorder(color: Color? = nil) -> some View {
#if DEBUG
        border(color ?? Color.random(), width: 1)
#else
        self
#endif
    }
}

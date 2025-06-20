import SwiftUI

public struct RoundedBadge: View {
    public let text: String
    public let color: Color
    public let useGradient: Bool

    public init(text: String, color: Color, useGradient: Bool = false) {
        self.text = text
        self.color = color
        self.useGradient = useGradient
    }

    public var body: some View {
        HStack {
            Text(text.capitalized)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading, 10)
                .padding([.top, .bottom], 5)
            Image(systemName: "chevron.right")
                .resizable()
                .frame(width: 5, height: 10)
                .foregroundColor(.primary)
                .padding(.trailing, 10)
        }
        .background(
            Group {
                if useGradient {
                    LinearGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(12)
                } else {
                    Rectangle()
                        .foregroundColor(color)
                        .cornerRadius(12)
                }
            }
        )
        .padding(.bottom, 4)
    }
}

#Preview {
    VStack(spacing: 10) {
        RoundedBadge(text: "Hello, World!", color: .red)
        RoundedBadge(text: "Gradient Badge", color: .blue, useGradient: true)
        RoundedBadge(text: "Another Badge", color: .green, useGradient: true)
    }
}

import SwiftUI

struct NoResultView: View {
    let configuration: NoResultViewConfiguration

    // State variables for animations
    @State private var iconScale: CGFloat = 0
    @State private var mainTextOffset: CGFloat = 50
    @State private var mainTextOpacity: Double = 0
    @State private var subTextOffset: CGFloat = 50
    @State private var subTextOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50
    @State private var buttonOpacity: Double = 0
    @State private var secondaryButtonOffset: CGFloat = 50
    @State private var secondaryButtonOpacity: Double = 0

    init(configuration: NoResultViewConfiguration = NoResultViewConfiguration()) {
        self.configuration = configuration
    }

    var body: some View {
        ZStack {
            // Radial gradient background
            RadialGradient(
                gradient: Gradient(colors: [.blue, .white]),
                center: .center,
                startRadius: 10,
                endRadius: 200
            )
            .edgesIgnoringSafeArea(.all)

            // Card-like container
            VStack(spacing: 20) {
                // Animated emoji icon
                Text("🤷‍♂️")
                    .font(.system(size: 100))
                    .scaleEffect(iconScale)
                    .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)

                // Main text with slide-up and fade-in
                Text(configuration.headline)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .offset(y: mainTextOffset)
                    .opacity(mainTextOpacity)
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)

                // Subtext with slide-up and fade-in
                Text(configuration.subheadline)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .offset(y: subTextOffset)
                    .opacity(subTextOpacity)
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)

                // Primary button with gradient and slide-up animation
                Button(action: configuration.primaryButtonAction) {
                    Text(configuration.primaryButtonText)
                        .font(.headline)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 5)
                }
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)

                // Secondary button with outline and slide-up animation
                Button(action: configuration.secondaryButtonAction) {
                    Text(configuration.secondaryButtonText)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                .offset(y: secondaryButtonOffset)
                .opacity(secondaryButtonOpacity)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 10)
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                iconScale = 1
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                mainTextOffset = 0
                mainTextOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.6)) {
                subTextOffset = 0
                subTextOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.9)) {
                buttonOffset = 0
                buttonOpacity = 1
            }
            withAnimation(.easeInOut(duration: 0.5).delay(1.2)) {
                secondaryButtonOffset = 0
                secondaryButtonOpacity = 1
            }
        }
    }
}

#if DEBUG
#Preview {
    NoResultView()
}
#endif

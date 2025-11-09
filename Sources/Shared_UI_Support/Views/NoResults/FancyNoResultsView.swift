import SwiftUI
@available(iOS 17, *)
public struct FancyNoResultsView: View {
    let configuration: NoResultViewConfiguration

    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var floatingOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var searchPulse = false

    public init(configuration: NoResultViewConfiguration = NoResultViewConfiguration()) {
        self.configuration = configuration
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.cyan.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Floating particles background
                ForEach(0..<15, id: \.self) { _ in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 4...12))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(sparkleOpacity)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: sparkleOpacity
                        )
                }

                VStack(spacing: 32) {
                    // Main icon container with glassmorphism
                    ZStack {
                        // Glassmorphism background
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 140)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                            .scaleEffect(pulseAnimation ? 1.05 : 1.0)

                        // Animated search icon
                        ZStack {
                            // Search circle
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .frame(width: 40, height: 40)
                                .scaleEffect(searchPulse ? 1.2 : 1.0)
                                .opacity(searchPulse ? 0.6 : 1.0)

                            // Search handle
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 4, height: 20)
                                .offset(x: 20, y: 20)
                                .rotationEffect(.degrees(45))

                            // Animated question mark
                            Text("?")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .offset(y: floatingOffset)
                                .rotationEffect(.degrees(rotationAngle))
                        }
                        .offset(y: floatingOffset * 0.5)
                    }
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))

                    // Text content with animated appearance
                    VStack(spacing: 16) {
                        // Main title
                        Text(configuration.headline)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.primary, .secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)

                        // Subtitle
                        Text(configuration.subheadline)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    .padding(.horizontal, 32)

                    // Action buttons
                    VStack(spacing: 16) {
                        // Primary action button
                        Button(action: configuration.primaryButtonAction) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(configuration.primaryButtonText)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                        // Secondary action button
                        Button(action: configuration.secondaryButtonAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(configuration.secondaryButtonText)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    }
                }
                .offset(y: floatingOffset * 0.3)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Main entrance animation
        withAnimation(.easeOut(duration: 0.8)) {
            isAnimating = true
        }

        // Floating animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            floatingOffset = -8
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }

        // Rotation animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Sparkle animation
        withAnimation(.easeInOut(duration: 1).delay(0.5)) {
            sparkleOpacity = 1
        }

        // Search pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1)) {
            searchPulse = true
        }
    }
}

@available(iOS 17, *)
struct FancyNoResultsView_Previews: PreviewProvider {
    static var previews: some View {
        FancyNoResultsView()
            .preferredColorScheme(ColorScheme.dark)
    }
}

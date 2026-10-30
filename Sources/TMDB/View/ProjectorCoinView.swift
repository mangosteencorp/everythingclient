import SwiftUI

/// A coin-sized movie projector. Dragging spins it in 3D, sideways around its upright axis and up
/// or down around its flat one, and on release it springs back face up. A stationary long press,
/// or VoiceOver's named action, calls `onLongPress`; a drag never does.
struct ProjectorCoinView: View {
    static let accessibilityIdentifier = "settings.projectorCoin"

    let onLongPress: () -> Void
    /// Degrees around the y-axis (width) and x-axis (height): one degree per point dragged.
    @State private var angles = CGSize.zero

    var body: some View {
        Image(systemName: "videoprojector.fill")
            .resizable()
            .scaledToFit()
            .padding(16)
            .foregroundStyle(.black.opacity(0.65))
            .frame(width: 64, height: 64)
            .background(Circle().fill(AngularGradient(colors: [.gray, .white, .gray, .white, .gray], center: .center)))
            .overlay(Circle().strokeBorder(
                .linearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom),
                lineWidth: 4
            ))
            .shadow(radius: 3, y: 2)
            .rotation3DEffect(.degrees(-angles.height), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(angles.width), axis: (x: 0, y: 1, z: 0))
            .gesture(spin.simultaneously(with: LongPressGesture(minimumDuration: 0.5).onEnded { _ in onLongPress() }))
            .accessibilityLabel(L10n.settingsProjectorCoin)
            .accessibilityAction(named: L10n.settingsOpenSamples, onLongPress)
            .accessibilityIdentifier(Self.accessibilityIdentifier)
    }

    /// Moving past the long press's 10 pt tolerance cancels it, so a drag only spins.
    private var spin: some Gesture {
        DragGesture()
            .onChanged { angles = $0.translation }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                    angles = CGSize(width: Self.faceUp(angles.width), height: Self.faceUp(angles.height))
                }
            }
    }

    /// The nearest whole turn, so the coin always lands face up. The next drag restarts from zero,
    /// which looks the same.
    private static func faceUp(_ degrees: CGFloat) -> CGFloat {
        (degrees / 360).rounded() * 360
    }
}

#if DEBUG
#Preview {
    TMDBPreviewCatalog.projectorCoin.view
}
#endif

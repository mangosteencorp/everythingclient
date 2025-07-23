import SwiftUI
struct OnFirstAppearModifier: ViewModifier {
    let onFirstAppear: () -> Void
    let onSubsequentAppear: ((Int) -> Void)?
    @State private var firstTime: Bool = true
    @State private var appearCount: Int = 0

    init(onFirstAppear: @escaping () -> Void, onSubsequentAppear: ((Int) -> Void)? = nil) {
        self.onFirstAppear = onFirstAppear
        self.onSubsequentAppear = onSubsequentAppear
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                if firstTime {
                    firstTime = false
                    self.onFirstAppear()
                } else {
                    appearCount += 1
                    self.onSubsequentAppear?(appearCount)
                }
            }
    }
}

public extension View {
    func onFirstAppear(perform: @escaping () -> Void) -> some View {
        return modifier(OnFirstAppearModifier(onFirstAppear: perform))
    }

    func onFirstAppear(perform: @escaping () -> Void, onSubsequentAppear: @escaping (Int) -> Void) -> some View {
        return modifier(OnFirstAppearModifier(onFirstAppear: perform, onSubsequentAppear: onSubsequentAppear))
    }
}

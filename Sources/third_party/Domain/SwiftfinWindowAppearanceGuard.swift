import UIKit

/// Undoes Swiftfin's window tinting whenever Swiftfin isn't on screen.
///
/// Swiftfin paints its accent colour (`.jellyfinPurple` when signed out) onto the key window's
/// `tintColor` and forces dark mode through `overrideUserInterfaceStyle`. Resetting once on dismiss
/// isn't enough: anything in Swiftfin that outlives its view — its observers used to, through
/// strongly captured tasks — can repaint the host window purple later. A hidden sentinel view in the
/// window hears every such repaint and reverts it while no Swiftfin screen is presented.
@MainActor
enum SwiftfinWindowAppearanceGuard {
    private static var presentedCount = 0

    static func swiftfinWillAppear() {
        presentedCount += 1
        installSentinel()
    }

    /// `onDisappear` only runs once the dismissal animation is over, so the app it uncovers would
    /// slide into view in Swiftfin's tint and dark mode. Resetting before dismissing avoids that;
    /// the leaving presentation takes Swiftfin's look over so Swiftfin doesn't flash light on its
    /// way out.
    static func swiftfinWillDismiss() {
        for window in windows {
            var presentation = window.rootViewController?.presentedViewController
            while let presented = presentation?.presentedViewController {
                presentation = presented
            }
            presentation?.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
            presentation?.view.tintColor = window.tintColor
            reset(window)
        }
    }

    static func swiftfinDidDisappear() {
        presentedCount = max(presentedCount - 1, 0)
        installSentinel()
        resetIfIdle()
    }

    fileprivate static func resetIfIdle() {
        guard presentedCount == 0 else { return }
        windows.forEach(reset)
    }

    private static func reset(_ window: UIWindow) {
        // Both setters are no-ops when already reset, which also ends the change notifications
        // they trigger on the sentinel.
        if window.overrideUserInterfaceStyle != .unspecified {
            window.overrideUserInterfaceStyle = .unspecified
        }
        // nil falls back to the app's AccentColor asset (unset here, so the system default).
        window.tintColor = nil
    }

    private static func installSentinel() {
        for window in windows where !window.subviews.contains(where: { $0 is AppearanceSentinelView }) {
            window.addSubview(AppearanceSentinelView())
        }
    }

    private static var windows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { $0.windowLevel == .normal && !$0.isHidden }
    }
}

private final class AppearanceSentinelView: UIView {
    private var isResetting = false

    init() {
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: AppearanceSentinelView, _) in
                view.reset()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        reset()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0),
           traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            reset()
        }
    }

    private func reset() {
        guard !isResetting else { return }
        isResetting = true
        defer { isResetting = false }
        SwiftfinWindowAppearanceGuard.resetIfIdle()
    }
}

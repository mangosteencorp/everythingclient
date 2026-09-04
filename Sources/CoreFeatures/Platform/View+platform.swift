import SwiftUI

// MARK: - Navigation bar title

/// Platform-neutral stand-in for `NavigationBarItem.TitleDisplayMode`, which only exists on iOS.
public enum PlatformTitleDisplayMode {
    case automatic
    case inline
    case large
}

// MARK: - Keyboard

/// Platform-neutral stand-in for `UIKeyboardType`, which only exists on iOS.
public enum PlatformKeyboardType {
    case `default`
    case numberPad
    case emailAddress
    case url
}

public extension View {
    /// `navigationBarTitleDisplayMode` on iOS; a no-op on macOS, which has no navigation bar.
    @ViewBuilder
    func platformNavigationBarTitleDisplayMode(_ mode: PlatformTitleDisplayMode) -> some View {
        #if os(iOS)
        switch mode {
        case .automatic: navigationBarTitleDisplayMode(.automatic)
        case .inline: navigationBarTitleDisplayMode(.inline)
        case .large: navigationBarTitleDisplayMode(.large)
        }
        #else
        self
        #endif
    }

    /// `keyboardType` on iOS; a no-op on macOS, which has no software keyboard.
    @ViewBuilder
    func platformKeyboardType(_ type: PlatformKeyboardType) -> some View {
        #if os(iOS)
        switch type {
        case .default: keyboardType(.default)
        case .numberPad: keyboardType(.numberPad)
        case .emailAddress: keyboardType(.emailAddress)
        case .url: keyboardType(.URL)
        }
        #else
        self
        #endif
    }

    /// `textInputAutocapitalization(.never)` on iOS; a no-op on macOS, where hardware keyboard
    /// input is never auto-capitalised in the first place.
    @ViewBuilder
    func platformDisableAutocapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// `fullScreenCover` on iOS; a `sheet` on macOS, where windows are already resizable and
    /// `fullScreenCover` does not exist.
    @ViewBuilder
    func platformFullScreenCover(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, content: content)
        #else
        sheet(isPresented: isPresented, content: content)
        #endif
    }

    /// The wheel picker on iOS; a pop-up menu on macOS, which has no wheel style.
    @ViewBuilder
    func platformWheelPickerStyle() -> some View {
        #if os(iOS)
        pickerStyle(.wheel)
        #else
        pickerStyle(.menu)
        #endif
    }

    /// `PageTabViewStyle` on iOS; the default `TabView` style on macOS, which has no paged style.
    @ViewBuilder
    func platformPagedTabViewStyle(showsIndex: Bool = true) -> some View {
        #if os(iOS)
        tabViewStyle(.page(indexDisplayMode: showsIndex ? .automatic : .never))
        #else
        self
        #endif
    }
}

// MARK: - Toolbar placement

public extension ToolbarItemPlacement {
    /// Leading edge of the navigation bar on iOS; the navigation section of the window toolbar
    /// on macOS.
    static var platformLeading: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #else
        return .navigation
        #endif
    }

    /// Trailing edge of the navigation bar on iOS; the primary-action section of the window
    /// toolbar on macOS.
    static var platformTrailing: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .primaryAction
        #endif
    }
}

public extension ToolbarPlacement {
    /// The navigation bar on iOS; the window toolbar on macOS.
    static var platformNavigationBar: ToolbarPlacement {
        #if os(iOS)
        return .navigationBar
        #else
        return .windowToolbar
        #endif
    }
}

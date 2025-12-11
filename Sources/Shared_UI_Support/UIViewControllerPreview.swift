import SwiftUI

#if DEBUG

#if canImport(UIKit)
public struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    public let viewController: ViewController

    public init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    public func makeUIViewController(context: Context) -> ViewController {
        viewController
    }

    public func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
#endif

#if canImport(AppKit)
import AppKit

public struct NSViewControllerPreview<ViewController: NSViewController>: NSViewControllerRepresentable {
    public let viewController: ViewController

    public init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    public func makeNSViewController(context: Context) -> ViewController {
        viewController
    }

    public func updateNSViewController(_ nsViewController: ViewController, context: Context) {}
}
#endif

#endif

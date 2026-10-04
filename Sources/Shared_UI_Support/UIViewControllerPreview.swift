import SwiftUI

#if DEBUG
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

/// `UIViewControllerPreview` for a bare `UIView`, so UIKit cells can be previewed as SwiftUI views.
public struct UIViewPreview<UIViewType: UIView>: UIViewRepresentable {
    public let view: UIViewType

    public init(_ builder: @escaping () -> UIViewType) {
        view = builder()
    }

    public func makeUIView(context: Context) -> UIViewType {
        view
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {}
}
#endif

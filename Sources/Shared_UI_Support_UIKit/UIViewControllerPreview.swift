// This whole target is UIKit-only and is reachable from iOS builds alone (see
// `Package.swift`). The guard keeps it compiling to an empty module if a toolchain or
// IDE builds every target regardless of reachability, rather than failing on `import UIKit`.
#if canImport(UIKit)
import SwiftUI
import UIKit

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
#endif
#endif

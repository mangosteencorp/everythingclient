import SwiftUI
extension UIHostingController {
    func forceRender() {
        _render(seconds: 0)
    }
}


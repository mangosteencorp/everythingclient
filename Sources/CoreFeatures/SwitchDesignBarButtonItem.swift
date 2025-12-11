#if canImport(UIKit)
import UIKit

public class SwitchDesignBarButtonItem: UIBarButtonItem {
    public init(target: AnyObject?, action: Selector) {
        super.init()
        image = UIImage(systemName: "arrow.left.arrow.right")
        style = .plain
        self.target = target
        self.action = action
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension UIViewController {
    func addSwitchDesignButton(action: Selector) {
        let switchButton = SwitchDesignBarButtonItem(target: self, action: action)
        navigationItem.rightBarButtonItem = switchButton
    }
}
#endif
#if canImport(SwiftUI)
import SwiftUI

public struct SwitchDesignToolbarItem: ToolbarContent {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some ToolbarContent {
        #if os(macOS)
        ToolbarItem(placement: .automatic) {
            Button(action: action) {
                Image(systemName: "arrow.left.arrow.right")
            }
        }
        #else
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: action) {
                Image(systemName: "arrow.left.arrow.right")
            }
        }
        #endif
    }
}

public extension View {
    func addSwitchDesignToolbar(action: @escaping () -> Void) -> some View {
        toolbar {
            SwitchDesignToolbarItem(action: action)
        }
    }
}

#endif


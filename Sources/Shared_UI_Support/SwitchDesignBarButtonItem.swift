import UIKit

public class SwitchDesignBarButtonItem: UIBarButtonItem {
    public init(target: AnyObject?, action: Selector) {
        super.init()
        self.image = UIImage(systemName: "arrow.left.arrow.right")
        self.style = .plain
        self.target = target
        self.action = action
    }
    
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

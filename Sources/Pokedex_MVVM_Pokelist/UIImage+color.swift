import UIKit

extension UIImage {
    var averageColor: UIColor? {
        // Create a 1x1 pixel context
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the image in the 1x1 context
        context.scaleBy(x: 1.0 / self.size.width, y: 1.0 / self.size.height)
        self.draw(at: .zero)
        
        // Get pixel data
        let data = context.data
        UIGraphicsEndImageContext()
        
        guard let ptr = data?.bindMemory(to: UInt8.self, capacity: 4) else { return nil }
        let r = CGFloat(ptr[0]) / 255.0
        let g = CGFloat(ptr[1]) / 255.0
        let b = CGFloat(ptr[2]) / 255.0
        let a = CGFloat(ptr[3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

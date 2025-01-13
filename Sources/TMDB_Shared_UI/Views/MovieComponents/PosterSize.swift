import Foundation
public struct PosterSize {
    public var width: CGFloat
    public var height: CGFloat
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    public static let medium = PosterSize(width: 100, height: 150)
}

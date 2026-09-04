import Foundation

public struct PosterSize {
    public var width: CGFloat
    public var height: CGFloat
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    public static let medium = PosterSize(width: 100, height: 150)
    /// Poster-ratio tile used by the grid feed layout.
    public static let grid = PosterSize(width: 110, height: 165)
    /// Thumbnail used by the compact feed rows.
    public static let thumbnail = PosterSize(width: 40, height: 60)
}

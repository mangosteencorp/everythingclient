import Foundation

public struct PhotoSlidesRouteModel: Hashable {
    public let imagePaths: [String]
    public let initialIndex: Int

    public init(imagePaths: [String], initialIndex: Int) {
        self.imagePaths = imagePaths
        self.initialIndex = initialIndex
    }
}

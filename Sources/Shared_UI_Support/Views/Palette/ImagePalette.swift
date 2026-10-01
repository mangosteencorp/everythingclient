import Kingfisher
import SwiftUI
import UIKit

/// The two colours an image suggests: its average colour, and whichever of black or white
/// stays legible on top of it.
///
/// Extracted from `MovieItemCell`, which had this trick buried in a UIKit collection view cell,
/// so SwiftUI screens can use the same effect.
public struct ImagePalette: Equatable {
    public let background: Color
    public let foreground: Color

    public init(background: Color, foreground: Color) {
        self.background = background
        self.foreground = foreground
    }

    public init(uiColor: UIColor) {
        self.init(background: Color(uiColor), foreground: Color(uiColor.contrastingColor()))
    }

    /// Used until the image arrives, and for items with no image at all.
    public static let placeholder = ImagePalette(
        background: Color(.secondarySystemBackground),
        foreground: .primary
    )
}

/// Loads an image and derives its palette, once per URL per session.
@MainActor
public final class ImagePaletteLoader: ObservableObject {
    @Published public private(set) var palette: ImagePalette = .placeholder

    private static var cache: [URL: ImagePalette] = [:]
    /// Building a `CIContext` is the expensive half of `averageColor()`; one is enough.
    private static let ciContext = CIContext(options: [.workingColorSpace: kCFNull as Any])

    public init() {}

    public func load(_ url: URL?) async {
        guard let url else {
            palette = .placeholder
            return
        }
        if let cached = Self.cache[url] {
            palette = cached
            return
        }
        guard let image = try? await KingfisherManager.shared.retrieveImage(with: url).image else { return }
        // 40×40 keeps the area average honest while making the render trivial.
        let scaled = image.kf.resize(to: CGSize(width: 40, height: 40))
        guard let average = scaled.averageColor(context: Self.ciContext) else { return }
        let resolved = ImagePalette(uiColor: average)
        Self.cache[url] = resolved
        palette = resolved
    }
}

public extension UIImage {
    /// Mean colour of the whole image. Pass a shared `CIContext` when calling this per cell.
    func averageColor(context: CIContext? = nil) -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
        ), let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let renderContext = context ?? CIContext(options: [.workingColorSpace: kCFNull as Any])
        renderContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }
}

public extension UIColor {
    /// Black on light colours, white on dark ones, by perceived brightness.
    func contrastingColor() -> UIColor {
        guard let components = cgColor.components else { return .white }
        let brightness: CGFloat
        if components.count >= 3 {
            brightness = ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
        } else {
            brightness = ((components[0] * 299) + (components[0] * 587) + (components[0] * 114)) / 1000
        }
        return brightness > 0.5 ? .black : .white
    }
}

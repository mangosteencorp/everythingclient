#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import CoreImage

extension NSImage {
    /// Average colour of the sprite, used to tint the cell behind it.
    ///
    /// The AppKit counterpart of `Pokedex_Pokelist/helpers/UIImage+color.swift`. That file uses the
    /// `UIGraphics*` context API, which has no AppKit equivalent; this goes through CoreImage's
    /// `CIAreaAverage` instead, which is available on both platforms.
    func averageColor() -> NSColor? {
        guard let tiff = tiffRepresentation,
              let inputImage = CIImage(data: tiff) else { return nil }

        let extent = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extent]
        ), let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        // A fully transparent sprite margin averages out to transparent black, which would render
        // as an invisible tint; treat that as "no usable colour".
        guard bitmap[3] > 0 else { return nil }

        return NSColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1.0
        )
    }

    /// Whether white or black text reads better on top of this colour.
    static func contrastingLabelColor(on color: NSColor) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return .white }
        let brightness = (rgb.redComponent * 299 + rgb.greenComponent * 587 + rgb.blueComponent * 114) / 1000
        return brightness > 0.6 ? .black : .white
    }
}
#endif

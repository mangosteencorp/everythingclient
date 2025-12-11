import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit

extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red) / 255
        let newGreen = CGFloat(green) / 255
        let newBlue = CGFloat(blue) / 255
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

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

#elseif canImport(AppKit)
import AppKit

extension NSImage {
    func averageColor() -> NSColor? {
        guard let tiff = self.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        let width = 1, height = 1
        let ctx = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 4, bitsPerPixel: 32)
        ctx?.size = NSSize(width: 1, height: 1)
        NSGraphicsContext.saveGraphicsState()
        if let cg = NSGraphicsContext(bitmapImageRep: ctx!) {
            NSGraphicsContext.current = cg
            NSColor.clear.set()
            NSRect(x: 0, y: 0, width: 1, height: 1).fill()
            self.draw(in: NSRect(x: 0, y: 0, width: 1, height: 1), from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            if let data = ctx?.bitmapData {
                let r = CGFloat(data[0]) / 255.0
                let g = CGFloat(data[1]) / 255.0
                let b = CGFloat(data[2]) / 255.0
                let a = CGFloat(data[3]) / 255.0
                return NSColor(red: r, green: g, blue: b, alpha: a)
            }
        }
        return nil
    }
}

extension NSColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red) / 255
        let newGreen = CGFloat(green) / 255
        let newBlue = CGFloat(blue) / 255
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

    func contrastingColor() -> NSColor {
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

#endif

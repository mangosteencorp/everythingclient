import Foundation
import CoreGraphics
import CoreImage

#if canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
private typealias PlatformColor = NSColor
#endif

#if canImport(UIKit) || canImport(AppKit)
private struct UIImageColorsCounter {
    let color: Double
    let count: Int
}

private extension Double {
    // swiftlint:disable identifier_name
    var r: Double { fmod(floor(self / 1_000_000), 1_000_000) }
    var g: Double { fmod(floor(self / 1000), 1000) }
    var b: Double { fmod(self, 1000) }
    // swiftlint:enable identifier_name

    var platformColor: PlatformColor {
        PlatformColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1
        )
    }

    var isBlackOrWhite: Bool { (r > 232 && g > 232 && b > 232) || (r < 23 && g < 23 && b < 23) }
    var isDarkColor: Bool { (r * 0.2126) + (g * 0.7152) + (b * 0.0722) < 127.5 }

    func with(minSaturation: Double) -> Double {
        let _r = r / 255
        let _g = g / 255
        let _b = b / 255
        var H, S, V: Double
        let M = fmax(_r, fmax(_g, _b))
        var C = M - fmin(_r, fmin(_g, _b))

        V = M
        S = V == 0 ? 0 : C / V

        if minSaturation <= S {
            return self
        }

        if C == 0 {
            H = 0
        } else if _r == M {
            H = fmod((_g - _b) / C, 6)
        } else if _g == M {
            H = 2 + ((_b - _r) / C)
        } else {
            H = 4 + ((_r - _g) / C)
        }

        if H < 0 {
            H += 6
        }

        C = V * minSaturation
        let X = C * (1 - fabs(fmod(H, 2) - 1))
        var R, G, B: Double

        switch H {
        case 0 ... 1:
            R = C
            G = X
            B = 0
        case 1 ... 2:
            R = X
            G = C
            B = 0
        case 2 ... 3:
            R = 0
            G = C
            B = X
        case 3 ... 4:
            R = 0
            G = X
            B = C
        case 4 ... 5:
            R = X
            G = 0
            B = C
        case 5 ..< 6:
            R = C
            G = 0
            B = X
        default:
            R = 0
            G = 0
            B = 0
        }

        let m = V - C

        return (floor((R + m) * 255) * 1_000_000) + (floor((G + m) * 255) * 1000) + floor((B + m) * 255)
    }
}

fileprivate func averageColor(from cgImage: CGImage) -> PlatformColor? {
    let inputImage = CIImage(cgImage: cgImage)
    let extentVector = CIVector(
        x: inputImage.extent.origin.x,
        y: inputImage.extent.origin.y,
        z: inputImage.extent.size.width,
        w: inputImage.extent.size.height
    )

    guard let filter = CIFilter(
        name: "CIAreaAverage",
        parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: extentVector,
        ]
    ),
        let outputImage = filter.outputImage
    else { return nil }

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

    return PlatformColor(
        red: CGFloat(bitmap[0]) / 255,
        green: CGFloat(bitmap[1]) / 255,
        blue: CGFloat(bitmap[2]) / 255,
        alpha: CGFloat(bitmap[3]) / 255
    )
}

fileprivate func dominantColor(from cgImage: CGImage, originalSize: CGSize) -> PlatformColor? {
    var scaleDownSize: CGSize = originalSize
    let quality: CGFloat = 50.0

    if originalSize.width < originalSize.height {
        let ratio = originalSize.height / max(originalSize.width, 1)
        scaleDownSize = CGSize(width: quality / ratio, height: quality)
    } else {
        let ratio = originalSize.width / max(originalSize.height, 1)
        scaleDownSize = CGSize(width: quality, height: quality / ratio)
    }

    guard let resizedImage = resizeCGImage(cgImage, to: scaleDownSize) else { return nil }

    let width = resizedImage.width
    let height = resizedImage.height

    let threshold = Int(CGFloat(height) * 0.01)
    var proposed: [Double] = [-1, -1, -1, -1]

    guard let bytes = resizedImage.dataProvider?.data,
          let data = CFDataGetBytePtr(bytes)
    else {
        return nil
    }

    let imageColors = NSCountedSet(capacity: width * height)

    for x in 0 ..< width {
        for y in 0 ..< height {
            let pixel: Int = ((width * y) + x) * 4

            if data[pixel + 3] >= 127 {
                imageColors
                    .add(
                        (Double(data[pixel + 2]) * 1_000_000) + (Double(data[pixel + 1]) * 1000) +
                            Double(data[pixel])
                    )
            }
        }
    }

    let sortedColorComparator: Comparator = { main, other -> ComparisonResult in
        let m = main as! UIImageColorsCounter, o = other as! UIImageColorsCounter

        if m.count < o.count {
            return .orderedDescending
        } else if m.count == o.count {
            return .orderedSame
        } else {
            return .orderedAscending
        }
    }

    var enumerator = imageColors.objectEnumerator()
    var sortedColors = NSMutableArray(capacity: imageColors.count)

    while let k = enumerator.nextObject() as? Double {
        let c = imageColors.count(for: k)

        if threshold < c {
            sortedColors.add(UIImageColorsCounter(color: k, count: c))
        }
    }

    sortedColors.sort(comparator: sortedColorComparator)

    var proposedEdgeColor: UIImageColorsCounter

    if sortedColors.count > 0 {
        proposedEdgeColor = sortedColors.object(at: 0) as! UIImageColorsCounter
    } else {
        proposedEdgeColor = UIImageColorsCounter(color: 0, count: 1)
    }

    if proposedEdgeColor.color.isBlackOrWhite, sortedColors.count > 0 {
        for i in 1 ..< sortedColors.count {
            let nextProposedEdgeColor = sortedColors.object(at: i) as! UIImageColorsCounter

            if Double(nextProposedEdgeColor.count) / Double(proposedEdgeColor.count) > 0.3 {
                if !nextProposedEdgeColor.color.isBlackOrWhite {
                    proposedEdgeColor = nextProposedEdgeColor
                    break
                }
            } else {
                break
            }
        }
    }
    proposed[0] = proposedEdgeColor.color

    enumerator = imageColors.objectEnumerator()
    sortedColors.removeAllObjects()
    sortedColors = NSMutableArray(capacity: imageColors.count)
    let findDarkTextColor = !proposed[0].isDarkColor

    while var K = enumerator.nextObject() as? Double {
        K = K.with(minSaturation: 0.15)

        if K.isDarkColor == findDarkTextColor {
            let C = imageColors.count(for: K)
            sortedColors.add(UIImageColorsCounter(color: K, count: C))
        }
    }
    sortedColors.sort(comparator: sortedColorComparator)

    let isDarkBackground = proposed[0].isDarkColor

    for i in 1 ... 3 {
        if proposed[i] == -1 {
            proposed[i] = isDarkBackground ? 255_255_255 : 0
        }
    }

    return proposed[0].platformColor
}

private func resizeCGImage(_ cgImage: CGImage, to newSize: CGSize) -> CGImage? {
    let width = max(Int(newSize.width.rounded()), 1)
    let height = max(Int(newSize.height.rounded()), 1)

    let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = cgImage.bitmapInfo.rawValue

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )
    else { return nil }

    context.interpolationQuality = .medium
    context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
    return context.makeImage()
}

#if canImport(UIKit)
extension UIImage {
    private func makeCGImage() -> CGImage? {
        if let cgImage {
            return cgImage
        }

        if let ciImage {
            let context = CIContext(options: [.useSoftwareRenderer: false])
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }

    func averageColor() -> UIColor? {
        guard let cgImage = makeCGImage() else { return nil }
        return averageColor(from: cgImage)
    }

    public var dominantColor: UIColor? {
        guard let cgImage = makeCGImage() else { return nil }
        return dominantColor(from: cgImage, originalSize: size)
    }
}
#elseif canImport(AppKit)
extension NSImage {
    private func cgImageRepresentation() -> CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    func averageColor() -> NSColor? {
        guard let cgImage = cgImageRepresentation() else { return nil }
        return Pokedex_Pokelist.averageColor(from: cgImage)
    }

    public var dominantColor: NSColor? {
        guard let cgImage = cgImageRepresentation() else { return nil }
        return Pokedex_Pokelist.dominantColor(from: cgImage, originalSize: size)
    }
}
#endif
#endif

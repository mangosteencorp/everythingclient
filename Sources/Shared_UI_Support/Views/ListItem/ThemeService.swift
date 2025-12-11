import Foundation

public class ThemeService: NSObject {
    public static let padding = 20
    public static let cellsHeight = 222
    public static let fontFamily = "HelveticaNeue"
}

#if canImport(UIKit)
import UIKit

public extension ThemeService {
    static let h1Font = UIFont(name: "\(fontFamily)-Bold", size: 22)
    static let h2FontBold = UIFont(name: "\(fontFamily)-Bold", size: 16)
    static let h2Font = UIFont(name: "\(fontFamily)-Light", size: 16)
    static let h3Font = UIFont(name: fontFamily, size: 12)
    static let defaultFont = UIFont(name: fontFamily, size: 14)

    static let lightGrey = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    static let midGrey = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
    static let darkGrey = UIColor(red: 130/255, green: 130/255, blue: 130/255, alpha: 1)
    static let white = UIColor.white
    static let yellow = UIColor(red: 250/255, green: 200/255, blue: 50/255, alpha: 1)
    static let black = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)

    static let primaryColor = black
    static let secondaryColor = darkGrey
}
#elseif canImport(AppKit)
import AppKit

public extension ThemeService {
    static let h1Font = NSFont(name: "\(fontFamily) Bold", size: 22)
    static let h2FontBold = NSFont(name: "\(fontFamily) Bold", size: 16)
    static let h2Font = NSFont(name: "\(fontFamily) Light", size: 16)
    static let h3Font = NSFont(name: fontFamily, size: 12)
    static let defaultFont = NSFont(name: fontFamily, size: 14)

    static let lightGrey = NSColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    static let midGrey = NSColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
    static let darkGrey = NSColor(red: 130/255, green: 130/255, blue: 130/255, alpha: 1)
    static let white = NSColor.white
    static let yellow = NSColor(red: 250/255, green: 200/255, blue: 50/255, alpha: 1)
    static let black = NSColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)

    static let primaryColor = black
    static let secondaryColor = darkGrey
}
#endif

#if canImport(UIKit)
import UIKit
public typealias PlatformViewController = UIViewController
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias PlatformViewController = NSViewController
public typealias PlatformColor = NSColor
#endif

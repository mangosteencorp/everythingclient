import SwiftUI
public protocol ThemeProtocol {
    var backgroundColor: Color { get }
    var labelColor: Color { get }
    var buttonColor: Color { get }
}

public struct LightTheme: ThemeProtocol {
    public var backgroundColor: Color = .white
    public var labelColor: Color = .black
    public var buttonColor: Color = .blue
}

public struct DarkTheme: ThemeProtocol {
    public var backgroundColor: Color = .black
    public var labelColor: Color = .white
    public var buttonColor: Color = .gray
}

public struct SepiaTheme: ThemeProtocol {
    public var backgroundColor: Color = Color(red: 0.96, green: 0.96, blue: 0.86)
    public var labelColor: Color = .black
    public var buttonColor: Color = .orange
}

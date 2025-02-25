import SwiftUI
protocol ThemeProtocol {
    var backgroundColor: Color { get }
    var labelColor: Color { get }
    var buttonColor: Color { get }
}

struct LightTheme: ThemeProtocol {
    var backgroundColor: Color = .white
    var labelColor: Color = .black
    var buttonColor: Color = .blue
}

struct DarkTheme: ThemeProtocol {
    var backgroundColor: Color = .black
    var labelColor: Color = .white
    var buttonColor: Color = .gray
}

struct SepiaTheme: ThemeProtocol {
    var backgroundColor: Color = Color(red: 0.96, green: 0.96, blue: 0.86)
    var labelColor: Color = .black
    var buttonColor: Color = .orange
}

import SwiftUI
import XCTest
// Helper extension to search for Text views within a SwiftUI hierarchy
extension View {
    public func searchForText(containing string: String) -> Text? {
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let text = child.value as? Text, text.compareTextTo(string) {
                return text
            }
            
            if let view = child.value as? (any View), let found = view.searchForText(containing: string) {
                return found
            }
        }
        
        return nil
    }
}
public func findViewOfType<T>(_ type: T.Type, in view: Any) -> T? {
    if let view = view as? T {
        return view
    }
    
    let mirror = Mirror(reflecting: view)
    for child in mirror.children {
        if let childView = child.value as? Any {
            if let result = findViewOfType(type, in: childView) {
                return result
            }
        }
    }
    
    return nil
}
extension Text {
    public func compareTextTo(_ string: String) -> Bool {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let value = child.value as? String, value.contains(string) {
                return true
            }
        }
        return false
    }
}

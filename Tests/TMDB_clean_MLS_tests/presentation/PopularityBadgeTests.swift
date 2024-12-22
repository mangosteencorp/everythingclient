import XCTest
import SwiftUI
@testable import TMDB_clean_MLS

class PopularityBadgeTests: XCTestCase {
    func testScoreColor() {
        let testCases = [
            (score: 30, expectedColor: Color.red),
            (score: 50, expectedColor: Color.orange),
            (score: 70, expectedColor: Color.yellow),
            (score: 80, expectedColor: Color.green)
        ]
        
        for testCase in testCases {
            let badge = PopularityBadge(score: testCase.score)
            XCTAssertEqual(badge.scoreColor, testCase.expectedColor, "Score \(testCase.score) should result in \(testCase.expectedColor)")
        }
    }
    
    func testInitialization() {
        let score = 75
        let badge = PopularityBadge(score: score)
        
        XCTAssertEqual(badge.score, score, "Initialized score should match")
        XCTAssertEqual(badge.textColor, .primary, "Default text color should be .primary")
    }
    
    func testCustomTextColor() {
        let score = 60
        let customColor = Color.blue
        let badge = PopularityBadge(score: score, textColor: customColor)
        
        XCTAssertEqual(badge.textColor, customColor, "Custom text color should be applied")
    }
    @available(iOS 15,*)
    func testViewContent() {
        let score = 85
        let badge = PopularityBadge(score: score)
        
        
        // Search for Text
        let text = findViewOfType(Text.self, in: badge.body)
        XCTAssertNotNil(text, "View should contain a Text")
        
        if let textView = text {
            
            XCTAssertEqual(textView.string, "85%", "Text should display the correct score percentage")
        }
    }
    
}


// Helper extension to search for Text views within a SwiftUI hierarchy
extension View {
    func searchForText(containing string: String) -> Text? {
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
func findViewOfType<T>(_ type: T.Type, in view: Any) -> T? {
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
    func compareTextTo(_ string: String) -> Bool {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let value = child.value as? String, value.contains(string) {
                return true
            }
        }
        return false
    }
}

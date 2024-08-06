import XCTest
import SwiftUI
@testable import TMDB_Dimilian_clean

class ImageViewTests: XCTestCase {
    func testImageLoaderInitialization() {
        let loader = ImageLoader()
        XCTAssertNil(loader.image, "Image should be nil on initialization")
    }
    
    func testImageLoading() {
        let expectation = XCTestExpectation(description: "Image should load")
        let loader = ImageLoader()
        
        // Use a local test image URL
        let testImageURL = URL(string: "https://picsum.photos/200/300")!
        
        loader.load(fromURL: testImageURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNotNil(loader.image, "Image should be loaded")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCustomImageViewInitialization() {
        let testImageURL = URL(string: "https://example.com/test.jpg")!
        let customImageView = CustomImageView(imageURL: testImageURL)
        
        XCTAssertNotNil(customImageView, "Should be able to initialize CustomImageView")
        XCTAssertEqual(customImageView.imageURL, testImageURL, "Image URL should match")
    }
}

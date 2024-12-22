import XCTest
import SwiftUI
import Combine
@testable import TMDB_clean_MLS

class CustomImageViewTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testCustomImageViewLoading() {
        let expectation = XCTestExpectation(description: "Image should load")
        let url = URL(string: "https://example.com/image.jpg")!
        
        let imageLoader = ImageLoader()
        let customImageView = CustomImageView(imageURL: url)
        
        imageLoader.$image
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        imageLoader.load(fromURL: url)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCustomImageViewFailure() {
        let expectation = XCTestExpectation(description: "Image loading should fail")
        let invalidURL = URL(string: "https://invalid-url")!
        
        let imageLoader = ImageLoader()
        let customImageView = CustomImageView(imageURL: invalidURL)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertNil(imageLoader.image, "Image should not be loaded for invalid URL")
            expectation.fulfill()
        }
        
        imageLoader.load(fromURL: invalidURL)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCustomImageViewInitialization() {
        let url = URL(string: "https://picsum.photos/200")!
        let customImageView = CustomImageView(imageURL: url)
        
        XCTAssertEqual(customImageView.imageURL, url, "ImageURL should be set correctly")
    }
}

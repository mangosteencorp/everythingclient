import XCTest

/// Swiftfin paints its accent colour onto the host window and forces it dark. Closing Swiftfin has
/// to uncover the app as it was, not in Swiftfin's purple and dark mode until the cover's
/// `onDisappear` catches up after the dismissal animation.
///
/// Signed out, Swiftfin's accent is always `.jellyfinPurple`, so no Jellyfin server is needed. Run
/// it with the simulator in light mode, which is how the app tells itself apart from Swiftfin.
final class SwiftfinAppearanceTests: XCTestCase {
    @MainActor
    func testClosingSwiftfinUncoversTheAppInItsOwnAppearance() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "-AppleLanguages", "(en)"]
        app.launch()
        addTeardownBlock { app.terminate() }

        // The app root seeds the bottom tab bar, whose system buttons carry no identifier.
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 15), "No Settings tab")
        settingsTab.tap()
        // The section's identifier replaces the button's own, so it is found by its label.
        let launchButton = app.buttons["Launch Jellyfin by Swiftfin"]
        XCTAssertTrue(launchButton.waitForExistence(timeout: 10), "No Swiftfin launch button")
        XCTAssertEqual(Appearance(XCUIScreen.main.screenshot()), .host, "The app is not in its own appearance to begin with")

        // Twice: the second presentation starts from a window Swiftfin has already painted once.
        for round in 1...2 {
            launchButton.tap()
            let closeButton = app.buttons["swiftfin.close.button"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 10), "Swiftfin did not open (round \(round))")
            closeButton.tap()

            // Sampled straight away and for a moment after: the leftover lasts well under a second.
            for frame in 1...5 {
                let screenshot = XCUIScreen.main.screenshot()
                guard Appearance(screenshot) == .host else {
                    add(XCTAttachment(screenshot: screenshot))
                    return XCTFail("Round \(round), frame \(frame): the app is in Swiftfin's appearance after closing it")
                }
            }
        }
    }
}

/// Whether a screenshot of the Settings page shows the app's light appearance with its blue tint,
/// or Swiftfin's dark appearance and purple tint.
private enum Appearance {
    case host
    case swiftfin

    init(_ screenshot: XCUIScreenshot) {
        guard let image = screenshot.image.cgImage else {
            self = .swiftfin
            return
        }
        // A quarter of the resolution is plenty to count colours, and keeps sampling quick.
        let width = image.width / 4, height = image.height / 4
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var purple = 0, dark = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Int(pixels[index]), green = Int(pixels[index + 1]), blue = Int(pixels[index + 2])
            // `.jellyfinPurple`: red and blue well above green. The system blue has next to no red.
            if red > 120, blue > 140, red - green > 60 { purple += 1 }
            if red + green + blue < 90 { dark += 1 }
        }
        let total = width * height
        // Light Settings is almost all grouped background; dark mode turns most of it black.
        self = purple * 1000 > total || dark * 2 > total ? .swiftfin : .host
    }
}

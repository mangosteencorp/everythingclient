import XCTest

/// The palette-card feed used to fetch each poster twice through Kingfisher — once in `KFImage`,
/// once for the palette. The two requests could race into two download tasks, and the one
/// Kingfisher lost track of never completed, so cards came up as a flat palette colour with no
/// poster. Needs network: the `demo` feed is live TMDB data. The race only happens on a download,
/// so run it on a fresh install; posters already in Kingfisher's disk cache never race.
final class TMDBFeedDemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testPaletteCardsShowEveryPoster() throws {
        let app = XCUIApplication()
        // `DesignCoordinator` reads its selections from UserDefaults; the argument domain overrides them.
        app.launchArguments += ["-design_coordinator_selections", "{ FeedContentDesign = paletteCards; }"]
        app.launch()
        app.buttons["demo"].tap()

        let cards = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'movielist1.movierow'"))
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 20), "The feed never loaded")

        let window = app.windows.firstMatch.frame
        var checked = Set<String>()
        // Down and back up, so cells that scrolled out and back in are checked too.
        for scrollsDown in [true, true, true, false, false, false] {
            for card in cards.allElementsBoundByIndex where window.contains(card.frame) {
                XCTAssertTrue(waitForPoster(in: card), "\(card.identifier) shows no poster")
                checked.insert(card.identifier)
            }
            if scrollsDown { app.swipeUp() } else { app.swipeDown() }
        }
        XCTAssertGreaterThanOrEqual(checked.count, 3, "Too few cards were fully on screen to judge")
    }

    /// Polls, because the poster arrives from the network and fades in.
    @MainActor
    private func waitForPoster(in card: XCUIElement, timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if showsPoster(card.screenshot().image) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < deadline
        return false
    }

    /// A missing poster leaves one flat colour where the artwork belongs; a poster never is.
    private func showsPoster(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        // The middle of the artwork: clear of the rounded corners and the caption underneath.
        let artwork = CGRect(
            x: cgImage.width / 10, y: cgImage.height / 10,
            width: cgImage.width * 8 / 10, height: cgImage.height / 2
        )
        guard let cropped = cgImage.cropping(to: artwork) else { return false }

        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        pixels.withUnsafeMutableBytes { buffer in
            CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )?.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return stride(from: 0, to: pixels.count, by: 4).contains { pixel in
            (0..<3).contains { abs(Int(pixels[pixel + $0]) - Int(pixels[$0])) > 24 }
        }
    }
}

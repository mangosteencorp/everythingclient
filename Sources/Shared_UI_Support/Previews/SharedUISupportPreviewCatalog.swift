#if DEBUG
import SwiftUI

/// Every shared UI preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. All of it is sample data.
public enum SharedUISupportPreviewCatalog: String, CaseIterable {
    case filterableList

    @MainActor
    public var view: some View {
        UIViewControllerPreview { Self.sampleList }
    }

    @MainActor
    private static var sampleList: FilterableFavouritableItemList {
        let list = FilterableFavouritableItemList()
        list.searchPlaceholder = "Filter movies"
        list.display(items: [
            PreviewItem(id: 1, title: "Dune: Part Two", rating: 8.2, favorited: true),
            PreviewItem(id: 2, title: "Inside Out 2", rating: 7.6),
            PreviewItem(id: 3, title: "Unrated Movie", rating: 0),
        ])
        return list
    }
}

private final class PreviewItem: ItemDisplayable {
    private let id: Int
    private let title: String
    private let rating: Float
    private var favorited: Bool

    init(id: Int, title: String, rating: Float, favorited: Bool = false) {
        self.id = id
        self.title = title
        self.rating = rating
        self.favorited = favorited
    }

    func getId() -> String? { String(id) }
    func getTitle() -> String { title }
    func getDescription() -> String { "A sample description long enough to wrap onto a second line of the cell." }
    func getReleaseDate() -> String? { "2024-05-10" }
    func getRating() -> Float? { rating }
    func getImageURL() -> String? { nil }
    func isFavorited() -> Bool { favorited }
    func setFavorited(_ favorited: Bool) { self.favorited = favorited }
}
#endif

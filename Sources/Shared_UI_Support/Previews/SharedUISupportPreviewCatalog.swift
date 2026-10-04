#if DEBUG
import SwiftUI
import UIKit

/// Every shared UI preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. All of it is sample data.
public enum SharedUISupportPreviewCatalog: String, CaseIterable {
    case noResult
    case commonNoResultPlain
    case commonNoResultFancy
    case fancyNoResults
    case coverFlow
    case adaptiveColumnGrid
    case paletteCard
    case movieItemCell
    case filterableList

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .noResult:
            NoResultView()
        case .commonNoResultPlain:
            CommonNoResultView(useFancyDesign: .constant(false))
        case .commonNoResultFancy:
            CommonNoResultView(
                configuration: NoResultViewConfiguration(headline: "No Movies", subheadline: "Nothing is playing right now."),
                useFancyDesign: .constant(true)
            )
        case .fancyNoResults:
            FancyNoResultsView()
                .preferredColorScheme(.dark)
        case .coverFlow:
            CoverFlowExample()
        case .adaptiveColumnGrid:
            AdaptiveColumnGrid(items: (0..<9).map(PreviewSwatch.init)) { swatch in
                RoundedRectangle(cornerRadius: 12)
                    .fill(swatch.color)
                    .frame(height: 120)
                    .overlay(Text("\(swatch.id)").foregroundStyle(.white))
            }
        case .paletteCard:
            PaletteCard(imageURL: nil) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dune: Part Two")
                        .font(.subheadline.weight(.semibold))
                    Text("8.2")
                        .font(.caption)
                }
            }
            .frame(width: 180)
            .padding()
        case .movieItemCell:
            UIViewPreview { MovieItemCell() }
        case .filterableList:
            UIViewControllerPreview { Self.sampleList }
        }
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

private struct CoverFlowExample: View {
    @State private var currentPage: Int? = 0
    let colors: [Color] = [.red, .blue, .green, .orange, .yellow, .pink, .purple, .gray, .black]

    var body: some View {
        VStack {
            CoverFlow(config: CoverFlowConfig(cardWidth: 160, activeElevation: 50), currentPage: $currentPage) {
                ForEach(colors, id: \.self) { color in
                    Rectangle().fill(color)
                }
            }
            .frame(height: 220)
            .onChange(of: currentPage) { _, newValue in
                Swift.debugPrint("currentPage -> \(String(describing: newValue))")
            }
            Button("go to 4") {
                withAnimation(.smooth) {
                    currentPage = 4
                }
            }
        }
    }
}

private struct PreviewSwatch: Identifiable {
    let id: Int
    var color: Color { [.red, .orange, .yellow, .green, .blue, .purple][id % 6] }
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

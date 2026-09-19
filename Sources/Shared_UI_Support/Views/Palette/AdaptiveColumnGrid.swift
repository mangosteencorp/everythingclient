import SwiftUI
import UIKit

/// A scrolling grid that picks 1, 2 or 3 columns from the width it is actually given.
///
/// Three columns are reserved for a wide iPad (landscape, or a large split-view pane); phones
/// and narrow panes stay single-column. Width, not size class, because both iPad orientations
/// report the same size class.
public struct AdaptiveColumnGrid<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let spacing: CGFloat
    private let content: (Item) -> Content

    public init(
        items: [Item],
        spacing: CGFloat = 14,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns(for: proxy.size.width), spacing: spacing) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, spacing)
                .padding(.vertical, spacing / 2)
            }
        }
    }

    private func columns(for width: CGFloat) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: Self.columnCount(for: width)
        )
    }

    static func columnCount(for width: CGFloat) -> Int {
        if width >= 900, UIDevice.current.userInterfaceIdiom == .pad { return 3 }
        if width >= 600 { return 2 }
        return 1
    }
}

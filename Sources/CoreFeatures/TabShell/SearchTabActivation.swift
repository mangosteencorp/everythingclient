import SwiftUI

public extension View {
    /// Makes selecting a `role: .search` tab start a search. Apply it to the `TabView`.
    ///
    /// Under the default activation, iOS 27 on iPhone neither detaches the search tab from the
    /// bar nor shows the `.searchable` field of the page inside it, so the tab opens on a page
    /// nobody can type into. With `.searchTabSelection` the tab sits apart from the others and
    /// turns into the search field when selected. Before iOS 26 the field lives in the page's
    /// navigation bar, so there is nothing to change.
    @ViewBuilder
    func searchTabActivatesSearch() -> some View {
        if #available(iOS 26, *) {
            tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
    }
}

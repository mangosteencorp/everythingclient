/// How many rows on each side of a tapped movie its detail page can swipe to.
let movieDetailWindowRadius = 10

extension Array {
    /// The element at `index` and up to `radius` neighbours on each side, clamped to the array.
    /// A slice, so building one for every feed row never copies the feed.
    func window(around index: Int, radius: Int = movieDetailWindowRadius) -> ArraySlice<Element> {
        self[Swift.max(startIndex, index - radius) ..< Swift.min(endIndex, index + radius + 1)]
    }
}

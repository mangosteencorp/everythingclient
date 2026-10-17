extension Array where Element: Identifiable {
    /// Appends `page`, skipping ids already present. TMDB rankings drift between requests, so
    /// page N+1 often repeats items from page N, and duplicate ids break `ForEach` identity.
    func appendingUnique(_ page: [Element]) -> [Element] {
        var seen = Set(map(\.id))
        return self + page.filter { seen.insert($0.id).inserted }
    }
}

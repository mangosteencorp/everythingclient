import CoreFeatures

/// Whether an empty list uses the animated empty state or the plain one.
///
/// Lives here rather than beside the feed's own design slots because `FeedStateView` — which
/// every feed *and* the search page render through — is the only thing that reads it.
public enum FeedEmptyStateDesign: String, DesignVariant {
    case fancy
    case plain

    public static var slotTitle: String { "Empty State" }

    public static var fallback: FeedEmptyStateDesign { .fancy }

    public var displayName: String {
        switch self {
        case .fancy: return "Fancy"
        case .plain: return "Plain"
        }
    }
}

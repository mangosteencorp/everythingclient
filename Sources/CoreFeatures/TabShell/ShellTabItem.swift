import Foundation

/// Anything a `SectionedTabView` can render as a tab, a sidebar row or a list row.
///
/// Deliberately free of any app vocabulary: a feed category, a Pokédex generation and a
/// podcast library row all satisfy it the same way.
public protocol ShellTabItem: Hashable, Identifiable {
    var title: String { get }
    var systemImage: String { get }
    /// Stable key for `TabViewCustomization`. Must not change between launches, or the user's
    /// reordering is lost.
    var customizationID: String { get }
}

public extension ShellTabItem {
    var id: String { customizationID }
}

/// A named group of rows: one sidebar section on regular width, one tab on compact width.
public struct ShellSection<Row: ShellTabItem>: Identifiable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let rows: [Row]

    public init(id: String, title: String, systemImage: String, rows: [Row]) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.rows = rows
    }
}

/// What the shell currently shows. Rows exist only on regular width, so compact width falls
/// back to `sectionList`, which names the section rather than a row inside it.
public enum ShellSelection<Root: ShellTabItem, Row: ShellTabItem>: Hashable {
    case root(Root)
    case row(Row)
    case sectionList(String)
}

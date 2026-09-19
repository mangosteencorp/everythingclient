import SwiftUI

/// Two-level `TabView`: flat root tabs plus sections of rows.
///
/// Regular width (iPad, wide windows) renders the sections as sidebar groups. Compact width
/// (iPhone) cannot show a sidebar, so each section collapses into a single tab holding a
/// pushable list of the same rows — the Podcasts/Music arrangement.
///
/// Domain-free on purpose: it knows about `ShellTabItem`, `ShellSection` and two content
/// closures, and nothing about feeds, coordinators or DI containers. Give it a different
/// `Root`/`Row` pair and it renders a different app.
///
/// Roots supply their own `NavigationStack`; rows do not, because the shell has to own the
/// stack to be able to push them from the compact list as well.
@available(iOS 18, *)
public struct SectionedTabView<
    Root: ShellTabItem,
    Row: ShellTabItem,
    RootContent: View,
    RowContent: View,
    Header: View
>: View {
    private let roots: [Root]
    private let sections: [ShellSection<Row>]
    private let searchRoot: Root?
    private let rowPath: ((Row) -> Binding<NavigationPath>)?
    private let rootContent: (Root) -> RootContent
    private let rowContent: (Row) -> RowContent
    private let header: () -> Header

    @Binding private var selection: ShellSelection<Root, Row>
    @AppStorage private var customization: TabViewCustomization
    @Environment(\.horizontalSizeClass) private var sizeClass

    public init(
        roots: [Root],
        sections: [ShellSection<Row>],
        searchRoot: Root? = nil,
        selection: Binding<ShellSelection<Root, Row>>,
        customizationStorageKey: String,
        rowPath: ((Row) -> Binding<NavigationPath>)? = nil,
        @ViewBuilder rootContent: @escaping (Root) -> RootContent,
        @ViewBuilder rowContent: @escaping (Row) -> RowContent,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.roots = roots
        self.sections = sections
        self.searchRoot = searchRoot
        self.rowPath = rowPath
        self.rootContent = rootContent
        self.rowContent = rowContent
        self.header = header
        _selection = selection
        _customization = AppStorage(
            wrappedValue: TabViewCustomization(),
            "shell.customization.\(customizationStorageKey)"
        )
    }

    private var isCompact: Bool { sizeClass == .compact }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(roots) { root in
                // Every `Tab` passes a title and a symbol: the `Tab(value:content:)` overload
                // has no label, and renders sidebar rows as blank capsules.
                Tab(root.title, systemImage: root.systemImage, value: Selection.root(root)) {
                    rootContent(root)
                }
                .customizationID(root.customizationID)
            }

            if isCompact {
                ForEach(sections) { section in
                    Tab(section.title, systemImage: section.systemImage, value: Selection.sectionList(section.id)) {
                        SectionRowList(section: section, content: rowContent)
                    }
                    .customizationID("section.\(section.id)")
                }
            } else {
                ForEach(sections) { section in
                    TabSection(section.title) {
                        ForEach(section.rows) { row in
                            Tab(row.title, systemImage: row.systemImage, value: Selection.row(row)) {
                                rowStack(for: row)
                            }
                            .customizationID(row.customizationID)
                        }
                    }
                    .customizationID("section.\(section.id)")
                    // Sidebar-only. iOS still surfaces the section as a grouped tab while one of
                    // its rows is selected, so the rows stay reachable in tab-bar mode.
                    .defaultVisibility(.hidden, for: .tabBar)
                }
            }

            if let searchRoot {
                Tab(
                    searchRoot.title,
                    systemImage: searchRoot.systemImage,
                    value: Selection.root(searchRoot),
                    role: .search
                ) {
                    rootContent(searchRoot)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($customization)
        .tabViewSidebarHeader(content: header)
        .onChange(of: isCompact, initial: true) { _, nowCompact in
            clampSelection(isCompact: nowCompact)
        }
    }

    private typealias Selection = ShellSelection<Root, Row>

    @ViewBuilder
    private func rowStack(for row: Row) -> some View {
        if let rowPath {
            NavigationStack(path: rowPath(row)) { rowContent(row) }
        } else {
            NavigationStack { rowContent(row) }
        }
    }

    /// Row selections exist only on regular width and section selections only on compact, so a
    /// size-class change would otherwise leave the shell pointing at a tab that is not there.
    private func clampSelection(isCompact: Bool) {
        switch (isCompact, selection) {
        case let (true, .row(row)):
            guard let section = sections.first(where: { $0.rows.contains(row) }) else { return }
            selection = .sectionList(section.id)
        case let (false, .sectionList(id)):
            guard let row = sections.first(where: { $0.id == id })?.rows.first else { return }
            selection = .row(row)
        default:
            break
        }
    }
}

/// The compact-width stand-in for a sidebar section.
@available(iOS 18, *)
private struct SectionRowList<Row: ShellTabItem, Content: View>: View {
    let section: ShellSection<Row>
    let content: (Row) -> Content

    var body: some View {
        NavigationStack {
            List(section.rows) { row in
                NavigationLink(value: row) {
                    Label(row.title, systemImage: row.systemImage)
                }
            }
            .navigationTitle(section.title)
            .navigationDestination(for: Row.self) { content($0) }
        }
    }
}

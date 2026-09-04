import SwiftUI

/// Scrollable segment header pinned above the content — the shape Mail, X and Podcasts all
/// use when the tabs cannot live on the bottom edge.
@available(iOS 16, *)
struct TopSegmentsFeedTabLayout<Content: View>: View {
    let tabs: [FeedTab]
    @Binding var selection: FeedTab
    @Binding var visibleTab: FeedTab
    @ViewBuilder let content: (FeedTab) -> Content

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content(selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityIdentifier("feed_tabs_top_segments")
        .onAppear { visibleTab = selection }
        .onChange(of: selection) { visibleTab = $0 }
    }

    private var header: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs) { tab in
                        segment(for: tab)
                            .id(tab)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: selection) { tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(tab, anchor: .center)
                }
            }
        }
    }

    private func segment(for tab: FeedTab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            Label(tab.title, systemImage: tab.systemImage)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("feed_tab_segment_\(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

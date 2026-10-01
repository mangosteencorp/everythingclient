import SwiftUI

/// The seven search scopes as a scrolling row of capsules.
///
/// Replaces `.searchScopes`, which on iOS 26+ iPhone stays hidden until the field has focus and
/// a query, and then squeezes seven scopes into one segmented control ("TV S…", "Colle…").
@available(iOS 16, *)
struct SearchScopeBar: View {
    @Binding var selection: SearchScope

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchScope.allCases) { scope in
                        SearchScopeButton(scope: scope, isSelected: scope == selection) {
                            selection = scope
                        }
                        .id(scope)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            // A scope picked from code — a recent search, a preview — still scrolls into view.
            .onChange(of: selection) { _, scope in
                withAnimation { proxy.scrollTo(scope, anchor: .center) }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("search_scope_bar")
    }
}

@available(iOS 16, *)
struct SearchScopeButton: View {
    let scope: SearchScope
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(scope.title, systemImage: scope.systemImage)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 4)
        }
        .scopeButtonStyle(isSelected: isSelected)
        .buttonBorderShape(.capsule)
        .accessibilityIdentifier("search_scope_\(scope.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension View {
    /// Liquid Glass on iOS 26+, tinted bordered capsules before it.
    @ViewBuilder
    func scopeButtonStyle(isSelected: Bool) -> some View {
        if #available(iOS 26, *) {
            if isSelected {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if isSelected {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered).tint(.secondary)
        }
    }
}

#if DEBUG
@available(iOS 16, *)
#Preview("Scope bar") {
    @Previewable @State var selection = SearchScope.movies
    VStack(spacing: 24) {
        SearchScopeBar(selection: $selection)
        SearchScopeBar(selection: .constant(.keywords))
    }
}

@available(iOS 16, *)
#Preview("Scope button") {
    HStack {
        SearchScopeButton(scope: .multi, isSelected: true) {}
        SearchScopeButton(scope: .people, isSelected: false) {}
    }
}
#endif

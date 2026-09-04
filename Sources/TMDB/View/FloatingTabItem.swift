import SwiftUI

struct FloatingTabItem<Selection: Hashable> {
    let tag: Selection
    let icon: Image
    let title: String
}

// Define the floating tab bar view
struct FloatingTabBar<Selection: Hashable>: View {
    @Binding var selection: Selection
    @Binding var isHidden: Bool
    let items: [FloatingTabItem<Selection>]

    @Namespace private var glassNamespace

    var body: some View {
        ZStack {
            if #available(iOS 26, macOS 26, *) {
                liquidGlassTabBar
            } else {
                legacyTabBar
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHidden)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selection)
    }

    // MARK: - iOS 26+ Liquid Glass Tab Bar

    @available(iOS 26, macOS 26, *)
    private var liquidGlassTabBar: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(items, id: \.tag) { item in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = item.tag
                        }
                    }) {
                        HStack(spacing: 4) {
                            item.icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            if item.tag == selection {
                                Text(item.title).font(.caption)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .foregroundStyle(item.tag == selection ? .primary : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .glassEffect(
                            item.tag == selection
                                ? .regular.interactive()
                                : .regular
                        )
                        .glassEffectID("\(item.tag)", in: glassNamespace)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .glassEffect(in: .capsule)
        }
        .padding(.horizontal)
        .offset(y: isHidden ? 100 : 0)
        .opacity(isHidden ? 0 : 1)
    }

    // MARK: - Legacy Tab Bar (iOS < 26)

    private var legacyTabBar: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = item.tag
                    }
                }) {
                    HStack(spacing: 4) {
                        item.icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        if item.tag == selection {
                            Text(item.title).font(.caption)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    .foregroundColor(item.tag == selection ? .blue : .gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
        .offset(y: isHidden ? 100 : 0)
        .opacity(isHidden ? 0 : 1)
    }
}

import SwiftUI

@available(iOS 16.0, *)
public struct StackedPosterCarouselView<Item: Identifiable, Poster: View>: View {
    public let title: String
    public let items: [Item]
    @Binding public var selectedIndex: Int
    @ViewBuilder public let poster: (Item) -> Poster
    public var onItemSelected: ((Item) -> Void)?

    @GestureState private var dragOffset: CGFloat = 0

    private let posterWidth: CGFloat = 180
    private let posterHeight: CGFloat = 270
    private let layerOffset: CGFloat = 48
    private let maxVisibleLayers = 4

    public init(
        title: String,
        items: [Item],
        selectedIndex: Binding<Int>,
        onItemSelected: ((Item) -> Void)? = nil,
        @ViewBuilder poster: @escaping (Item) -> Poster
    ) {
        self.title = title
        self.items = items
        _selectedIndex = selectedIndex
        self.onItemSelected = onItemSelected
        self.poster = poster
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("stackedPosterCarousel.title")

            if items.isEmpty {
                Text("No items to display")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ZStack(alignment: .leading) {
                    ForEach(visibleLayerIndices, id: \.self) { layerIndex in
                        let itemIndex = normalizedIndex(selectedIndex + layerIndex)
                        let item = items[itemIndex]
                        let isFront = layerIndex == 0

                        poster(item)
                            .frame(width: posterWidth, height: posterHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .scaleEffect(scale(for: layerIndex))
                            .offset(x: xOffset(for: layerIndex))
                            .opacity(opacity(for: layerIndex))
                            .brightness(brightness(for: layerIndex))
                            .shadow(
                                color: .black.opacity(isFront ? 0.35 : 0.15),
                                radius: isFront ? 16 : 8,
                                x: 0,
                                y: isFront ? 10 : 4
                            )
                            .zIndex(Double(maxVisibleLayers - layerIndex))
                            .accessibilityIdentifier("stackedPosterCarousel.item.\(itemIndex)")
                            .onTapGesture {
                                if layerIndex == 0 {
                                    onItemSelected?(item)
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                        selectedIndex = itemIndex
                                    }
                                }
                            }
                    }
                }
                .frame(height: posterHeight + 12)
                .padding(.trailing, CGFloat(maxVisibleLayers - 1) * layerOffset)
                .contentShape(Rectangle())
                .gesture(dragGesture)

                if let activeItem = items[safe: selectedIndex] {
                    Text(activeItemTitle(for: activeItem))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .accessibilityIdentifier("stackedPosterCarousel.activeTitle")
                }
            }
        }
        .accessibilityIdentifier("stackedPosterCarousel.container")
    }

    private var visibleLayerIndices: [Int] {
        guard !items.isEmpty else { return [] }
        let layerCount = min(maxVisibleLayers, items.count)
        return Array(0..<layerCount)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 40
                guard items.count > 1 else { return }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    if value.translation.width < -threshold {
                        selectedIndex = normalizedIndex(selectedIndex + 1)
                    } else if value.translation.width > threshold {
                        selectedIndex = normalizedIndex(selectedIndex - 1)
                    }
                }
            }
    }

    private func normalizedIndex(_ index: Int) -> Int {
        guard !items.isEmpty else { return 0 }
        let count = items.count
        return ((index % count) + count) % count
    }

    private func scale(for layer: Int) -> CGFloat {
        switch layer {
        case 0: return 1.0
        case 1: return 0.82
        case 2: return 0.70
        default: return 0.60
        }
    }

    private func xOffset(for layer: Int) -> CGFloat {
        CGFloat(layer) * layerOffset
    }

    private func opacity(for layer: Int) -> Double {
        switch layer {
        case 0: return 1.0
        case 1: return 0.55
        case 2: return 0.45
        default: return 0.35
        }
    }

    private func brightness(for layer: Int) -> Double {
        layer == 0 ? 0 : -0.25
    }

    private func activeItemTitle(for item: Item) -> String {
        if let titled = item as? StackedPosterCarouselTitled {
            return titled.carouselTitle
        }
        return "Selected item"
    }
}

public protocol StackedPosterCarouselTitled {
    var carouselTitle: String { get }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#if DEBUG
@available(iOS 16.0, *)
private struct PreviewCarouselItem: Identifiable, StackedPosterCarouselTitled {
    let id: Int
    let carouselTitle: String
    let color: Color
}

@available(iOS 16.0, *)
#Preview("Stacked Poster Carousel") {
    struct PreviewContainer: View {
        @State private var selectedIndex = 0
        private let items: [PreviewCarouselItem] = [
            PreviewCarouselItem(id: 1, carouselTitle: "Superman", color: .blue),
            PreviewCarouselItem(id: 2, carouselTitle: "Jurassic World Rebirth", color: .green),
            PreviewCarouselItem(id: 3, carouselTitle: "F1", color: .red),
            PreviewCarouselItem(id: 4, carouselTitle: "Mission: Impossible", color: .orange),
            PreviewCarouselItem(id: 5, carouselTitle: "The Phoenician Scheme", color: .purple),
        ]

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                StackedPosterCarouselView(
                    title: "Now Playing",
                    items: items,
                    selectedIndex: $selectedIndex
                ) { item in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.color.gradient)
                        .overlay(alignment: .bottomLeading) {
                            Text(item.carouselTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
}
#endif

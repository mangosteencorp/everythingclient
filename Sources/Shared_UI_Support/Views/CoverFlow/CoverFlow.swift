import SwiftUI

public struct CoverFlowConfig {
    public var cardWidth: CGFloat
    public var rotation: CGFloat = 58
    public var offsetFactor: CGFloat = 1.4
    public var activeElevation: CGFloat = 0
    public var reflectionGap: CGFloat = 0.5
    public var reflectionFade: CGFloat = 4
    public var reflectionDim: CGFloat = 0.8

    public init(
        cardWidth: CGFloat,
        rotation: CGFloat = 58,
        offsetFactor: CGFloat = 1.4,
        activeElevation: CGFloat = 0,
        reflectionGap: CGFloat = 0.5,
        reflectionFade: CGFloat = 4,
        reflectionDim: CGFloat = 0.8
    ) {
        self.cardWidth = cardWidth
        self.rotation = rotation
        self.offsetFactor = offsetFactor
        self.activeElevation = activeElevation
        self.reflectionGap = reflectionGap
        self.reflectionFade = reflectionFade
        self.reflectionDim = reflectionDim
    }
}

@available(iOS 18.0, *)
public struct CoverFlow<CardContent: View>: View {
    public var config: CoverFlowConfig
    @Binding public var currentPage: Int?
    @ViewBuilder public var content: CardContent

    public init(
        config: CoverFlowConfig,
        currentPage: Binding<Int?>,
        @ViewBuilder content: () -> CardContent
    ) {
        self.config = config
        _currentPage = currentPage
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size
            let currentIndex = currentPage ?? 0
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    Group(subviews: content) { collection in
                        ForEach(collection.startIndex..<collection.endIndex, id: \.self) { index in
                            let subView = collection[index]
                            let zIndex = currentIndex > index ? Double(index) : Double(-index)
                            subView
                                .frame(width: config.cardWidth, height: containerSize.height)
                                .visualEffect { [config] effect, proxy in
                                    let layout = Self.retrieveLayoutAdjustmentValue(proxy, config: config)
                                    let shader = ShaderLibrary.bundle(.module).coverflowReflection(
                                        .float(Float(proxy.size.height)),
                                        .float(config.reflectionGap),
                                        .float(config.reflectionFade),
                                        .float(config.reflectionDim)
                                    )
                                    return effect
                                        .layerEffect(shader, maxSampleOffset: proxy.size)
                                        .rotation3DEffect(
                                            .degrees(layout.rotation),
                                            axis: (x: 0, y: 1, z: 0),
                                            anchor: layout.anchor,
                                            anchorZ: layout.anchorZ,
                                            perspective: 1
                                        )
                                        .offset(x: layout.offset)
                                }
                                .zIndex(currentIndex == index ? 1000 : zIndex)
                        }
                    }
                }.scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, (containerSize.width - config.cardWidth) / 2)
            .scrollPosition(id: $currentPage, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }

    private struct LayoutAdjustment {
        let rotation: CGFloat
        let anchor: UnitPoint
        let anchorZ: CGFloat
        let offset: CGFloat
    }

    nonisolated private static func retrieveLayoutAdjustmentValue(
        _ proxy: GeometryProxy,
        config: CoverFlowConfig
    ) -> LayoutAdjustment {
        let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
        let progress = minX / config.cardWidth
        let cappedProgress = max(-1, min(1, progress))
        let rotation = -cappedProgress * config.rotation
        let offset = -progress * (config.cardWidth / config.offsetFactor)
        let anchor: UnitPoint = cappedProgress < 0 ? .leading : .trailing
        let anchorZ = abs(cappedProgress) * config.activeElevation
        return LayoutAdjustment(rotation: rotation, anchor: anchor, anchorZ: anchorZ, offset: offset)
    }
}

#if DEBUG
@available(iOS 18.0, *)
private struct CoverFlowExample: View {
    @State private var currentPage: Int? = 0
    let colors: [Color] = [.red, .blue, .green, .orange, .yellow, .pink, .purple, .gray, .black]

    var body: some View {
        VStack {
            CoverFlow(config: CoverFlowConfig(cardWidth: 160, activeElevation: 50), currentPage: $currentPage) {
                ForEach(colors, id: \.self) { color in
                    Rectangle().fill(color)
                }
            }
            .frame(height: 220)
            .onChange(of: currentPage) { _, newValue in
                debugPrint("currentPage -> \(String(describing: newValue))")
            }
            Button("go to 4") {
                withAnimation(.smooth) {
                    currentPage = 4
                }
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview {
    CoverFlowExample()
}
#endif

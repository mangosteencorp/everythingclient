import SwiftUI

public struct CommonNoResultView: View {
    let configuration: NoResultViewConfiguration
    @Binding var useFancyDesign: Bool

    public init(configuration: NoResultViewConfiguration = NoResultViewConfiguration(), useFancyDesign: Binding<Bool>) {
        self.configuration = configuration
        _useFancyDesign = useFancyDesign
    }

    public var body: some View {
        Group {
            if #available(iOS 17, *) {
                Group {
                    if useFancyDesign {
                        FancyNoResultsView(configuration: configuration)
                    } else {
                        NoResultView(configuration: configuration)
                    }
                }
            } else {
                NoResultView(configuration: configuration)
            }
        }
    }
}

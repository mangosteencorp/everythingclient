import SwiftUI

struct CommonNoResultView: View {
    let configuration: NoResultViewConfiguration
    @Binding var useFancyDesign: Bool

    init(configuration: NoResultViewConfiguration = NoResultViewConfiguration(), useFancyDesign: Binding<Bool>) {
        self.configuration = configuration
        _useFancyDesign = useFancyDesign
    }

    var body: some View {
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

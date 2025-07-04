import SwiftUI
struct CommonNoResultView: View {
    let configuration: NoResultViewConfiguration

    init(configuration: NoResultViewConfiguration = NoResultViewConfiguration()) {
        self.configuration = configuration
    }

    var body: some View {
        if #available(iOS 17, *) {
            FancyNoResultsView(configuration: configuration)
        } else {
            NoResultView(configuration: configuration)
        }
    }
}

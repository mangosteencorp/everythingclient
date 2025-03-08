import SwiftUI
import Swinject
#if DEBUG
@available(iOS 16, *)
#Preview {
    MovieListPage(
        container: Container(),
        apiKey: <#T##String#>,
        type: .nowPlaying,
        detailRouteBuilder: { _ in 1 })
}

#endif

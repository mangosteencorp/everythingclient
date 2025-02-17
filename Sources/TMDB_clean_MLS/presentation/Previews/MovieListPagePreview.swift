import SwiftUI
import Swinject
#if DEBUG
#Preview {
    MovieListPage(
        container: Container(),
        apiKey: <#T##String#>,
        type: .nowPlaying,
        detailRouteBuilder: {_ in 1})
}

#endif

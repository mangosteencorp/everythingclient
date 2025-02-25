import SwiftUI
import CoreFeatures
struct TVShowDetailView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    TVShowDetailView()
        .environmentObject(ThemeManager.shared)
}

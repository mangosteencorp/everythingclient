import CoreFeatures
import SwiftUI

@available(iOS 15, *)
struct DetailRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.body)
            .foregroundColor(themeManager.currentTheme.labelColor)
    }
}

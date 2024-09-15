import SwiftUI
struct CustomProgressViewStyle: ProgressViewStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
            )
            .shadow(radius: 3)
           // .frame(width: 50, height: 50)
    }
    
    
}

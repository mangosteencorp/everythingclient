import SwiftUI

struct NoInternetView: View {
    var retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 70))
                .foregroundColor(.red)
            
            Text("No Internet Connection")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please check your internet connection and try again")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button(action: retryAction) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
        }
    }
} 
#Preview {
    NoInternetView(retryAction: {})
}

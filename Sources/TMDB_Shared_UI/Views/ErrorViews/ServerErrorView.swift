import SwiftUI

public struct ServerErrorView: View {
    var retryAction: () -> Void
    public init(retryAction: @escaping () -> Void) {
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            Text("Oops! Something Went Wrong")
                .font(.title2)
                .fontWeight(.bold)

            Text("We're having trouble connecting to our servers.\nPlease try again later.")
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
    ServerErrorView(retryAction: {})
}

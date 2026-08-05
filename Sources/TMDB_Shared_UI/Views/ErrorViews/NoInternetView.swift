import SwiftUI

public struct NoInternetView: View {
    var retryAction: () -> Void
    var cancelAction: (() -> Void)?

    public init(retryAction: @escaping () -> Void, cancelAction: (() -> Void)? = nil) {
        self.retryAction = retryAction
        self.cancelAction = cancelAction
    }

    public var body: some View {
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
            .accessibilityIdentifier("error.retry.button")

            if let cancelAction {
                Button("Cancel Search", action: cancelAction)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                    .accessibilityIdentifier("error.cancelSearch.button")
            }
        }
        .accessibilityIdentifier("error.noInternet")
    }
}

#Preview {
    NoInternetView(retryAction: {}, cancelAction: {})
}

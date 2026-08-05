import SwiftUI

public struct ServerErrorView: View {
    var message: String?
    var retryAction: () -> Void
    var cancelAction: (() -> Void)?

    public init(
        message: String? = nil,
        retryAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryAction = retryAction
        self.cancelAction = cancelAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            Text("Oops! Something Went Wrong")
                .font(.title2)
                .fontWeight(.bold)

            Text(message ?? "We're having trouble connecting to our servers.\nPlease try again later.")
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
        .accessibilityIdentifier("error.server")
    }
}

#Preview {
    ServerErrorView(retryAction: {}, cancelAction: {})
}

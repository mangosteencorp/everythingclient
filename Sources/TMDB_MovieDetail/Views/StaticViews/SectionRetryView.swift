import SwiftUI

/// Compact inline failure + retry, sized for a `List` section.
/// `ServerErrorView` is the full page equivalent and is too heavy inside a section.
struct SectionRetryView: View {
    let message: String
    let retryAction: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            Button(L10n.retryButtonTitle) {
                Task { await retryAction() }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("movieDetail.retry")
    }
}

#if DEBUG
#Preview {
    List {
        SectionRetryView(message: "The Internet connection appears to be offline.") {}
    }
}
#endif

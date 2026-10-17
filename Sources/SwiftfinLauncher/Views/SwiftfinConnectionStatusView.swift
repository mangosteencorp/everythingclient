import SwiftUI

/// The signed-in server and user, refreshed by the host after Swiftfin closes.
public struct SwiftfinConnectionStatusView: View {
    private let status: SwiftfinConnectionStatus

    public init(status: SwiftfinConnectionStatus) {
        self.status = status
    }

    public var body: some View {
        Group {
            switch status {
            case .loading:
                ProgressView()
                    .accessibilityLabel(L10n.swiftfinConnectionLoading)
            case .unavailable:
                Text(L10n.swiftfinConnectionUnavailable)
            case .notConnected:
                Text(L10n.swiftfinConnectionNotConnected)
            case let .connected(connection):
                VStack(alignment: .leading, spacing: 4) {
                    Label(connection.serverName, systemImage: "server.rack")
                        .accessibilityIdentifier("settings.swiftfin.server")
                    Label(connection.username, systemImage: "person.crop.circle")
                        .accessibilityIdentifier("settings.swiftfin.user")
                }
            case .failed:
                Text(L10n.swiftfinConnectionFailed)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("settings.swiftfin.connection")
    }
}

#if DEBUG
#Preview("Connected") {
    Form {
        SwiftfinConnectionStatusView(status: .connected(.init(serverName: "Home Cinema", username: "Alex")))
    }
}

#Preview("No connected server") {
    Form { SwiftfinConnectionStatusView(status: .notConnected) }
}

#Preview("Connection API unavailable") {
    Form { SwiftfinConnectionStatusView(status: .unavailable) }
}
#endif

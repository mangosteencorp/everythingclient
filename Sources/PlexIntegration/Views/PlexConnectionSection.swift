import SwiftUI

/// A Form section to sign in to Plex, show the connected server and sign out.
public struct PlexConnectionSection: View {
    private let model: PlexConnectionModel
    @Environment(\.openURL) private var openURL

    public init(model: PlexConnectionModel) {
        self.model = model
    }

    public var body: some View {
        Section {
            switch model.status {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(L10n.plexConnectionLoading)
                    .accessibilityIdentifier("settings.plex.loading")
            case .signedOut:
                Button(L10n.plexSignIn, action: signIn)
                    .accessibilityIdentifier("settings.plex.signIn.button")
            case let .signingIn(code, authorizationURL):
                ProgressView(L10n.plexSignInWaiting)
                LabeledContent(L10n.plexSignInCode, value: code)
                    .accessibilityIdentifier("settings.plex.code")
                Button(L10n.plexSignInOpen) { openURL(authorizationURL) }
                    .accessibilityIdentifier("settings.plex.open.button")
                Button(L10n.plexSignInCancel, role: .cancel) { Task { await model.cancelSignIn() } }
                    .accessibilityIdentifier("settings.plex.cancel.button")
            case let .connected(info):
                VStack(alignment: .leading, spacing: 4) {
                    Label(info.serverName, systemImage: "server.rack")
                        .accessibilityIdentifier("settings.plex.server")
                    if let accountName = info.accountName {
                        Label(accountName, systemImage: "person.crop.circle")
                            .accessibilityIdentifier("settings.plex.user")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                signOutButton
            case let .failed(message, canSignOut):
                Text(message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.plex.error")
                // With an account saved, retrying reconnects; otherwise it starts a new sign-in.
                Button(L10n.plexTryAgain) {
                    if canSignOut { Task { await model.refresh() } } else { signIn() }
                }
                .accessibilityIdentifier("settings.plex.retry.button")
                if canSignOut { signOutButton }
            }
        } header: {
            Text(L10n.plexSectionTitle)
        }
        .accessibilityIdentifier("settings.section.plex")
    }

    private var signOutButton: some View {
        Button(L10n.plexSignOut, role: .destructive) { Task { await model.signOut() } }
            .accessibilityIdentifier("settings.plex.signOut.button")
    }

    private func signIn() {
        Task { await model.signIn { openURL($0) } }
    }
}

#if DEBUG
/// Drives a real model with `PlexPreviewLauncher` into one state.
private struct PlexConnectionSectionPreview: View {
    @State private var model: PlexConnectionModel
    private let startsSignIn: Bool

    init(_ session: PlexPreviewLauncher.Session, startsSignIn: Bool = false) {
        _model = State(initialValue: PlexConnectionModel(launcher: PlexPreviewLauncher(session)))
        self.startsSignIn = startsSignIn
    }

    var body: some View {
        Form { PlexConnectionSection(model: model) }
            .task {
                if startsSignIn {
                    await model.signIn { _ in }
                } else {
                    await model.refresh()
                }
            }
    }
}

#Preview("Signed out") { PlexConnectionSectionPreview(.signedOut) }
#Preview("Signing in") { PlexConnectionSectionPreview(.signedOut, startsSignIn: true) }
#Preview("Connected") { PlexConnectionSectionPreview(.connected) }
#Preview("Loading") { PlexConnectionSectionPreview(.loading) }
#Preview("Server unreachable") { PlexConnectionSectionPreview(.unreachable) }
#Preview("Sign-in code expired") { PlexConnectionSectionPreview(.expiredSignIn, startsSignIn: true) }
#endif

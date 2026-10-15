import Plex_Shared_Backend
import SwiftUI

/// Sign-in, server choice, home profiles, offline mode and server tools.
struct AccountView: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            Form {
                Section {
                    if session.api != nil {
                        LabeledContent("Connected to", value: session.serverName)
                        if session.isSample { Label("Sample mode — synthetic data", systemImage: "testtube.2") }
                    } else if session.isConnecting {
                        ProgressView("Finding a working connection…")
                    } else {
                        Text("Sign in to connect automatically and load your library. Your sign-in is kept in the Keychain.")
                    }
                }
                SignInSection()
                if session.api != nil {
                    Section {
                        Toggle("Offline mode", isOn: Binding(get: { session.isOffline }, set: { value in Task { await session.setOffline(value) } }))
                            .accessibilityIdentifier("plex.offlineMode")
                        NavigationLink("Server tools") { ServerToolsView() }
                    } footer: {
                        Text("Offline mode shows what you've already opened from the cache and queues watch changes until you're back online.")
                    }
                }
                ManualConnectionSection()
                NetworkLoggingSection()
                Section("Explore without an account") {
                    Button("Explore sample library") { session.loadSamples() }.accessibilityIdentifier("plex.samples")
                }
            }
            .formStyle(.grouped)
            .statusBanner()
            .navigationTitle("Account")
        }
    }
}

/// PIN sign-in, server picker and home profile switching.
struct SignInSection: View {
    @Environment(DemoSession.self) private var session
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section("Plex account") {
            if session.waitingForLogin {
                ProgressView("Waiting for browser authorization…")
                LabeledContent("Sign-in code", value: session.pinCode)
                if let url = session.authorizationURL { Button("Open Plex sign-in") { openURL(url) } }
                Button("Cancel sign-in", role: .cancel) { session.cancelLogin() }
            } else if session.hasAccount {
                if !session.accountName.isEmpty { LabeledContent("Signed in as", value: session.accountName) }
                if !session.servers.isEmpty {
                    Picker("Server", selection: Binding(get: { session.selectedServerID }, set: session.selectServer)) {
                        ForEach(session.servers) { Text($0.name).tag($0.id) }
                    }
                }
                Button("Refresh servers") { Task { await session.refreshServers() } }.disabled(session.isConnecting)
                HomeProfilesView()
                Button("Sign out", role: .destructive) { session.signOut() }
            } else {
                Button("Sign in with Plex") { session.signIn() }.accessibilityIdentifier("plex.signIn")
            }
        }
    }
}

/// Lists Plex Home profiles and switches to one, with its PIN when protected.
struct HomeProfilesView: View {
    @Environment(DemoSession.self) private var session
    @State private var selectedUUID = ""
    @State private var pin = ""

    var body: some View {
        if session.homeUsers.isEmpty {
            Button("Load home profiles") { Task { await session.loadProfiles() } }.disabled(session.busy)
        } else {
            Picker("Home profile", selection: $selectedUUID) {
                Text("Choose a profile").tag("")
                ForEach(session.homeUsers) { Text($0.title).tag($0.uuid ?? "") }
            }
            if session.homeUsers.first(where: { $0.uuid == selectedUUID })?.isProtected == true {
                SecureField("Profile PIN", text: $pin)
            }
            Button("Switch profile") {
                let enteredPIN = pin
                pin = ""
                Task { await session.switchProfile(uuid: selectedUUID, pin: enteredPIN) }
            }
            .disabled(selectedUUID.isEmpty || session.busy)
        }
    }
}

/// Direct server URL and token, for servers not linked to a Plex account.
struct ManualConnectionSection: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        @Bindable var session = session
        Section {
            DisclosureGroup("Advanced connection settings") {
                TextField("Server URL, including any proxy prefix", text: $session.serverURL)
                    .textContentType(.URL).autocorrectionDisabled()
                SecureField("Server access token", text: $session.manualToken)
                Toggle("Allow an unencrypted HTTP connection", isOn: $session.allowHTTP)
                if session.allowHTTP {
                    Text("HTTP sends the server token without encryption. Use only a trusted local network.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Connect manually") { Task { await session.connectManual() } }
                    .disabled(session.busy || session.serverURL.isEmpty || session.manualToken.isEmpty)
            }
            .accessibilityIdentifier("plex.advancedConnection")
        }
    }
}

/// Turns `curl` logging of every network call on or off and opens the log.
struct NetworkLoggingSection: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        @Bindable var session = session
        Section {
            Toggle("Log network calls as cURL", isOn: $session.logsNetworkCalls)
                .accessibilityIdentifier("plex.curlLogging")
            Toggle("Hide tokens and PINs", isOn: $session.redactsNetworkLog)
            NavigationLink("Network log") { NetworkLogView() }
        } header: {
            Text("Developer")
        } footer: {
            Text("Commands also appear in Xcode's console. With tokens shown, anyone who sees the log can use your account.")
        }
    }
}

/// Recent `curl` commands, newest first, selectable and shareable.
struct NetworkLogView: View {
    @Environment(DemoSession.self) private var session

    var body: some View {
        let log = session.networkLog
        List(log.entries) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.date, format: .dateTime.hour().minute().second()).font(.caption).foregroundStyle(.secondary)
                Text(verbatim: entry.command).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }
            .contextMenu { ShareLink("Share command", item: entry.command) }
        }
        .overlay {
            if log.entries.isEmpty {
                ContentUnavailableView("No requests logged", systemImage: "terminal",
                                       description: Text("Turn on cURL logging, then use the app."))
            }
        }
        .navigationTitle("Network log")
        .toolbar { Button("Clear", systemImage: "trash") { log.clear() }.disabled(log.entries.isEmpty) }
    }
}

#Preview { AccountView().environment(DemoSession.preview()) }
#Preview("Network log") {
    let session = DemoSession.preview()
    session.networkLog.append("curl 'https://sample.invalid/library/sections' \\\n  -H 'X-Plex-Token: [redacted]'")
    return NavigationStack { NetworkLogView() }.environment(session)
}

#Preview("Signed out") { Form { SignInSection() }.environment(DemoSession(credentials: DemoMemoryCredentialStore())) }
#Preview("Manual connection") { Form { ManualConnectionSection() }.environment(DemoSession(credentials: DemoMemoryCredentialStore())) }

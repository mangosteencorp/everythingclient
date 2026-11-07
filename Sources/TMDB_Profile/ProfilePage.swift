import RxSwift
import SwiftUI
import Swinject

/// The profile tab's page: the UIKit list fills the page under a navigation bar that carries the
/// signed-in account, so the bars track the list as it scrolls.
public struct ProfilePage: View {
    @State private var model: ProfilePageModel
    private let onNavigateToMovie: (Int) -> Void
    private let onNavigateToTVShow: (Int) -> Void

    public init(
        container: Container,
        onNavigateToMovie: @escaping (Int) -> Void,
        onNavigateToTVShow: @escaping (Int) -> Void
    ) {
        self.init(
            makeViewModel: {
                TMDB_Profile.configure(container)
                guard let viewModel = container.resolve(ProfileViewModel.self) else {
                    fatalError("Failed to resolve ProfileViewModel")
                }
                return viewModel
            },
            onNavigateToMovie: onNavigateToMovie,
            onNavigateToTVShow: onNavigateToTVShow
        )
    }

    init(
        makeViewModel: @escaping () -> ProfileViewModel,
        onNavigateToMovie: @escaping (Int) -> Void = { _ in },
        onNavigateToTVShow: @escaping (Int) -> Void = { _ in }
    ) {
        _model = State(initialValue: ProfilePageModel(makeViewModel: makeViewModel))
        self.onNavigateToMovie = onNavigateToMovie
        self.onNavigateToTVShow = onNavigateToTVShow
    }

    public var body: some View {
        ProfilePageVCView(
            viewModel: model.viewModel,
            onNavigateToMovie: onNavigateToMovie,
            onNavigateToTVShow: onNavigateToTVShow
        )
        // Under the bars, so they see the list scroll; the list insets its own content.
        .ignoresSafeArea()
        .navigationTitle(title)
        .toolbar {
            if let account = model.account {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatar(id: account.id, avatarPath: account.avatarPath)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { model.viewModel.signOut() } label: { Text(.profileSignOut) }
                }
            }
        }
    }

    /// The account's name, else its @username; the page's own name until someone is signed in.
    private var title: Text {
        guard let account = model.account else { return Text(.profileTitle) }
        return account.name.isEmpty ? Text(.profileUsernameFormat(account.username)) : Text(account.name)
    }
}

/// The view model the UIKit page and the navigation bar share, and the account the bar shows.
@MainActor @Observable
final class ProfilePageModel {
    private(set) var account: AccountInfoEntity?

    /// Made on first use: SwiftUI builds a throwaway model on every `ProfilePage` init, and only the one
    /// it keeps may make a view model, which starts loading the profile.
    @ObservationIgnored private(set) lazy var viewModel: ProfileViewModel = {
        let viewModel = makeViewModel()
        viewModel.state
            .map { state -> AccountInfoEntity? in
                guard case let .loaded(profile) = state else { return nil }
                return profile.accountInfo
            }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in self?.account = $0 })
            .disposed(by: disposeBag)
        return viewModel
    }()

    @ObservationIgnored private let makeViewModel: () -> ProfileViewModel
    @ObservationIgnored private let disposeBag = DisposeBag()

    init(makeViewModel: @escaping () -> ProfileViewModel) {
        self.makeViewModel = makeViewModel
    }
}

#if DEBUG
#Preview("Signed in") {
    TMDBProfilePreviewCatalog.signedInPage.view
}

#Preview("Long name") {
    NavigationStack {
        ProfilePage(makeViewModel: {
            TMDBProfilePreviewCatalog.viewModel(profile: ProfileEntity(
                accountInfo: AccountInfoEntity(
                    id: 7,
                    name: "Maximilian Alexander Featherstonehaugh-Montgomery",
                    username: "maximilian_alexander_featherstonehaugh",
                    avatarPath: nil
                ),
                favoriteMovies: sampleProfileEntity.favoriteMovies,
                favoriteTVShows: sampleProfileEntity.favoriteTVShows,
                watchlistTVShows: sampleProfileEntity.watchlistTVShows
            ))
        })
    }
}
#endif

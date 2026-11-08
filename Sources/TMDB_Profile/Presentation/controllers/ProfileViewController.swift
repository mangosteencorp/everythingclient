import Kingfisher
import RxCocoa
import RxSwift
import TMDB_Shared_Backend
import UIKit

public class ProfileViewController: UIViewController, ProfileContentViewControllerDelegate {
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    private var coordinator: ProfilePageVCView.Coordinator?
    /// The signed-in account the navigation bar shows; nil while signed out, loading or failed.
    private var account: AccountInfoEntity?

    private static let animalSymbols = [
        "hare.fill", "tortoise.fill", "dog.fill", "cat.fill", "bird.fill",
        "fish.fill", "ant.fill", "ladybug.fill", "lizard.fill", "pawprint.fill",
    ]

    private lazy var signOutItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: String(localized: .profileSignOut), style: .plain, target: self, action: #selector(signOutTapped))
        item.tintColor = .systemRed
        return item
    }()

    /// An image item, not a custom view: the glass bar draws custom views as a flat grey silhouette.
    private let avatarItem = UIBarButtonItem()

    // Child View Controllers
    private let unauthorizedView = UnauthorizedView()
    private let errorView = ErrorView()
    private var contentViewController: ProfileContentViewController?
    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
    }

    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        updateNavigationBar()
    }

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Add loading indicator
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        // Add unauthorized and error views
        for item in [unauthorizedView, errorView] {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
            NSLayoutConstraint.activate([
                item.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                item.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                item.topAnchor.constraint(equalTo: view.topAnchor),
                item.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        // Configure unauthorized view
        unauthorizedView.setSignInAction { [weak self] in
            Task {
                await self?.viewModel.signIn()
            }
        }
    }

    private func bindViewModel() {
        viewModel.state
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateUI(for: state)
            })
            .disposed(by: disposeBag)
    }

    private func updateUI(for state: ProfileViewState) {
        // First, remove any existing content view controller
        contentViewController?.removeFromParent()
        contentViewController?.view.removeFromSuperview()
        contentViewController = nil

        // Hide all views initially
        unauthorizedView.isHidden = true
        errorView.isHidden = true
        loadingView.stopAnimating()

        if case let .loaded(profile) = state { account = profile.accountInfo } else { account = nil }
        updateNavigationBar()

        // Update UI based on state
        switch state {
        case .unauthorized:
            unauthorizedView.isHidden = false

        case .loading:
            loadingView.startAnimating()

        case let .loaded(profile):
            if let existingContentVC = contentViewController {
                existingContentVC.updateProfile(profile)
            } else {
                let contentVC = ProfileContentViewController(profile: profile)
                contentVC.delegate = self
                contentVC.coordinator = coordinator
                addChild(contentVC)
                contentVC.view.frame = view.bounds
                contentVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(contentVC.view)
                contentVC.didMove(toParent: self)
                contentViewController = contentVC
            }

        case let .error(error):
            errorView.isHidden = false
            errorView.configure(with: error) { [weak self] in
                self?.viewModel.fetchProfile()
            }
        }
    }

    /// Title is the account's name, else its @username, else the page's own name; Sign Out and the avatar only while signed in.
    private func updateNavigationBar() {
        guard let navigationItem = navigationBarHost?.navigationItem else { return }
        navigationItem.largeTitleDisplayMode = .always
        guard let account else {
            navigationItem.title = String(localized: .profileTitle)
            navigationItem.rightBarButtonItems = nil
            return
        }
        navigationItem.title = account.name.isEmpty ? String(localized: .profileUsernameFormat(account.username)) : account.name
        configureAvatar(with: account)
        navigationItem.rightBarButtonItems = [signOutItem, avatarItem]
    }

    /// Account avatar, or an animal symbol (stable per account, so it doesn't change on refresh) when there is none.
    private func configureAvatar(with account: AccountInfoEntity) {
        guard let avatarURL = account.avatarPath.flatMap({ TMDBImageSize.profileMedium.buildImageUrl(path: $0) }) else {
            avatarItem.image = UIImage(systemName: Self.animalSymbols[abs(account.id) % Self.animalSymbols.count])
            return
        }
        let size = CGSize(width: 32, height: 32)
        let processor = ResizingImageProcessor(referenceSize: size, mode: .aspectFill)
            |> CroppingImageProcessor(size: size)
            |> RoundCornerImageProcessor(radius: .widthFraction(0.5))
        let options: KingfisherOptionsInfo = [.processor(processor), .scaleFactor(traitCollection.displayScale)]
        KingfisherManager.shared.retrieveImage(with: avatarURL, options: options) { [weak self] result in
            // Original colours: a bar item image is otherwise tinted like a symbol.
            self?.avatarItem.image = try? result.get().image.withRenderingMode(.alwaysOriginal)
        }
    }

    @objc private func signOutTapped() {
        viewModel.signOut()
    }

    func profileContentViewControllerDidRefresh(_ viewController: ProfileContentViewController) {
        viewModel.refreshProfile()
    }

    // Add setter for coordinator
    func setCoordinator(_ coordinator: ProfilePageVCView.Coordinator) {
        self.coordinator = coordinator
    }
}

extension UIViewController {
    /// The controller the navigation bar takes its items and scroll view from. In a SwiftUI `NavigationStack`
    /// that is SwiftUI's hosting controller, which can't see into this page's representable.
    var navigationBarHost: UIViewController? {
        sequence(first: self, next: \.parent).first { $0.parent is UINavigationController }
    }
}

#if DEBUG
import SwiftUI

#Preview("Signed in") {
    TMDBProfilePreviewCatalog.signedIn.view
}

#Preview("Signed out") {
    TMDBProfilePreviewCatalog.signedOut.view
}
#endif

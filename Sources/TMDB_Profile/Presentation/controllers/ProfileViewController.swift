#if canImport(UIKit)
import RxCocoa
import RxSwift
import UIKit

public class ProfileViewController: UIViewController, ProfileContentViewControllerDelegate {
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    private var coordinator: ProfilePageVCView.Coordinator?

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

    private func setupViews() {
        view.backgroundColor = .systemBackground
        title = "Profile"

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

    func profileContentViewControllerDidTapSignOut(_ viewController: ProfileContentViewController) {
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

#elseif canImport(AppKit)
import AppKit
import RxCocoa
import RxSwift

public class ProfileViewController: NSViewController, ProfileContentViewControllerDelegate {
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    private var coordinator: ProfilePageVCView.Coordinator?

    private let unauthorizedView = UnauthorizedView()
    private let errorView = ErrorView()
    private var contentViewController: ProfileContentViewController?
    private let contentContainer = NSView()
    private let loadingIndicator: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .large
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
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

    public override func loadView() {
        view = NSView()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        view.addSubview(loadingIndicator)

        [unauthorizedView, errorView, contentContainer].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        contentContainer.isHidden = true

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            unauthorizedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            unauthorizedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            unauthorizedView.topAnchor.constraint(equalTo: view.topAnchor),
            unauthorizedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

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
        contentViewController?.removeFromParent()
        contentViewController?.view.removeFromSuperview()
        contentViewController = nil

        unauthorizedView.isHidden = true
        errorView.isHidden = true
        contentContainer.isHidden = true
        loadingIndicator.stopAnimation(self)

        switch state {
        case .unauthorized:
            unauthorizedView.isHidden = false

        case .loading:
            loadingIndicator.startAnimation(self)

        case let .loaded(profile):
            showContent(for: profile)

        case let .error(error):
            errorView.isHidden = false
            errorView.configure(with: error) { [weak self] in
                self?.viewModel.fetchProfile()
            }
        }
    }

    private func showContent(for profile: ProfileEntity) {
        let contentVC = ProfileContentViewController(profile: profile)
        contentVC.delegate = self
        contentVC.coordinator = coordinator

        addChild(contentVC)
        let contentView = contentVC.view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])

        contentViewController = contentVC
        contentContainer.isHidden = false
    }

    func profileContentViewControllerDidTapSignOut(_ viewController: ProfileContentViewController) {
        viewModel.signOut()
    }

    func profileContentViewControllerDidRefresh(_ viewController: ProfileContentViewController) {
        viewModel.refreshProfile()
    }

    func setCoordinator(_ coordinator: ProfilePageVCView.Coordinator) {
        self.coordinator = coordinator
    }
}
#endif

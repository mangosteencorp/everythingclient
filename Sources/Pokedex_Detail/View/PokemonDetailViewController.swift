import CoreFeatures
import Pokedex_Shared_Backend
import RxCocoa
import RxSwift
#if canImport(UIKit)
import Shared_UI_Support
import SnapKit
import UIKit
#elseif canImport(AppKit)
import AppKit
import SwiftUI
#endif

public typealias PokemonDetailModel = PokemonDetail

#if canImport(UIKit)
typealias PlatformDetailViewController = UIViewController
#elseif canImport(AppKit)
typealias PlatformDetailViewController = NSViewController
#endif

protocol PokemonContentViewController: PlatformDetailViewController {
    init(pokemon: PokemonDetailModel)
}

#if canImport(UIKit)

@MainActor
public class PokemonDetailViewController: UIViewController {
    private let viewModel: PokemonDetailViewModel
    private let disposeBag = DisposeBag()

    private var loadingViewController: LoadingViewController?
    private var errorViewController: RobotErrorViewController?

    // Replace individual content view controllers with array and current index
    private var contentViewControllers: [PokemonContentViewController.Type] = [
        DetailDesign1ViewController.self,
        DetailDesign2ViewController.self,
    ]
    private var currentContentIndex = 0
    private var currentContentViewController: PokemonContentViewController?

    private let containerView: UIView = {
        let view = UIView()
        return view
    }()

    public init(viewModel: PokemonDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupBindings() {
        // Bind loading state
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.showLoadingView()
                } else {
                    self?.hideLoadingView()
                }
            })
            .disposed(by: disposeBag)

        // Bind pokemon detail
        viewModel.pokemonDetail
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] pokemon in
                self?.showContentView(with: pokemon)
                self?.setupNavigationButton()
            })
            .disposed(by: disposeBag)

        // Bind error
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.showErrorView()
            })
            .disposed(by: disposeBag)
    }

    private func setupNavigationButton() {
        addSwitchDesignButton(action: #selector(switchDesignTapped))
    }

    @objc private func switchDesignTapped() {
        guard let pokemon = viewModel.pokemonDetail.value else { return }
        currentContentIndex = (currentContentIndex + 1) % contentViewControllers.count
        showContentView(with: pokemon)
    }

    private func showLoadingView() {
        removeCurrentChildViewController()

        let loadingVC = LoadingViewController()
        addChild(loadingVC)
        containerView.addSubview(loadingVC.view)
        loadingVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingVC.didMove(toParent: self)

        loadingViewController = loadingVC
    }

    private func hideLoadingView() {
        loadingViewController?.willMove(toParent: nil)
        loadingViewController?.view.removeFromSuperview()
        loadingViewController?.removeFromParent()
        loadingViewController = nil
    }

    private func showContentView(with pokemon: PokemonDetailModel) {
        removeCurrentChildViewController()

        let contentVC = contentViewControllers[currentContentIndex].init(pokemon: pokemon)
        addChild(contentVC)
        containerView.addSubview(contentVC.view)
        contentVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentVC.didMove(toParent: self)

        currentContentViewController = contentVC
    }

    private func showErrorView() {
        removeCurrentChildViewController()

        let errorVC = RobotErrorViewController()
        errorVC.delegate = self
        addChild(errorVC)
        containerView.addSubview(errorVC.view)
        errorVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        errorVC.didMove(toParent: self)

        errorViewController = errorVC
    }

    private func removeCurrentChildViewController() {
        loadingViewController?.willMove(toParent: nil)
        loadingViewController?.view.removeFromSuperview()
        loadingViewController?.removeFromParent()
        loadingViewController = nil

        currentContentViewController?.willMove(toParent: nil)
        currentContentViewController?.view.removeFromSuperview()
        currentContentViewController?.removeFromParent()
        currentContentViewController = nil

        errorViewController?.willMove(toParent: nil)
        errorViewController?.view.removeFromSuperview()
        errorViewController?.removeFromParent()
        errorViewController = nil
    }
}

extension PokemonDetailViewController: RobotErrorViewControllerDelegate {
    func didTapTryAgain() {
        if let currentPokemonId = viewModel.currentPokemonId {
            viewModel.loadPokemon(id: currentPokemonId)
        }
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("iOS Detail Screen") {
    UIViewControllerPreview {
        let viewModel = PokemonDetailViewModel(pokemonService: .shared)
        let detailVC = PokemonDetailViewController(viewModel: viewModel)
        viewModel.loadPokemon(id: 25)
        let navVC = UINavigationController(rootViewController: UIViewController())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navVC.pushViewController(detailVC, animated: false)
        }
        return navVC
    }
}
#endif
#elseif canImport(AppKit)

@MainActor
public final class PokemonDetailViewController: NSViewController {
    private let viewModel: PokemonDetailViewModel
    private let disposeBag = DisposeBag()

    private var loadingViewController: LoadingViewController?
    private var errorHostingController: NSHostingController<PokemonDetailErrorView>?
    private var currentContentViewController: PokemonContentViewController?

    private var contentViewControllers: [PokemonContentViewController.Type] = [
        DetailDesign1ViewController.self,
        DetailDesign2ViewController.self,
    ]
    private var currentContentIndex = 0

    private let containerView = NSView()
    private lazy var switchButton: NSButton = {
        let button = NSButton(title: "Switch Design", target: self, action: #selector(switchDesignTapped))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    public init(viewModel: PokemonDetailViewModel) {
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
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        view.addSubview(switchButton)

        NSLayoutConstraint.activate([
            switchButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            switchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupBindings() {
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    self.showLoadingView()
                } else {
                    self.hideLoadingView()
                }
            })
            .disposed(by: disposeBag)

        viewModel.pokemonDetail
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] pokemon in
                self?.switchButton.isHidden = false
                self?.showContentView(with: pokemon)
            })
            .disposed(by: disposeBag)

        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showErrorView(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }

    @objc private func switchDesignTapped() {
        guard viewModel.pokemonDetail.value != nil else { return }
        currentContentIndex = (currentContentIndex + 1) % contentViewControllers.count
        if let pokemon = viewModel.pokemonDetail.value {
            showContentView(with: pokemon)
        }
    }

    private func showLoadingView() {
        removeDisplayedControllers()

        let loader = LoadingViewController()
        addChild(loader)
        containerView.addSubview(loader.view)
        loader.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loader.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            loader.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            loader.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            loader.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        loader.didMove(toParent: self)
        loadingViewController = loader
        switchButton.isHidden = true
    }

    private func hideLoadingView() {
        guard let loader = loadingViewController else { return }
        loader.willMove(toParent: nil)
        loader.view.removeFromSuperview()
        loader.removeFromParent()
        loadingViewController = nil
    }

    private func showContentView(with pokemon: PokemonDetailModel) {
        removeDisplayedControllers()

        let contentVC = contentViewControllers[currentContentIndex].init(pokemon: pokemon)
        addChild(contentVC)
        containerView.addSubview(contentVC.view)
        contentVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        contentVC.didMove(toParent: self)
        currentContentViewController = contentVC
    }

    private func showErrorView(message: String) {
        removeDisplayedControllers()

        let hosting = NSHostingController(rootView: PokemonDetailErrorView(message: message, onRetry: { [weak self] in
            self?.handleTryAgain()
        }))
        addChild(hosting)
        containerView.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
        errorHostingController = hosting
        switchButton.isHidden = true
    }

    private func removeDisplayedControllers() {
        if let loader = loadingViewController {
            loader.willMove(toParent: nil)
            loader.view.removeFromSuperview()
            loader.removeFromParent()
            loadingViewController = nil
        }

        if let contentVC = currentContentViewController {
            contentVC.willMove(toParent: nil)
            contentVC.view.removeFromSuperview()
            contentVC.removeFromParent()
            currentContentViewController = nil
        }

        if let errorVC = errorHostingController {
            errorVC.willMove(toParent: nil)
            errorVC.view.removeFromSuperview()
            errorVC.removeFromParent()
            errorHostingController = nil
        }
    }

    private func handleTryAgain() {
        if let currentPokemonId = viewModel.currentPokemonId {
            viewModel.loadPokemon(id: currentPokemonId)
        }
    }
}

private struct PokemonDetailErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 320)

            Button(action: onRetry) {
                Text("Try Again")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(nsColor: NSColor.windowBackgroundColor))
    }
}

#endif

#if canImport(UIKit) || canImport(AppKit)
extension DetailDesign1ViewController: PokemonContentViewController {}
extension DetailDesign2ViewController: PokemonContentViewController {}
#endif

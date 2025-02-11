import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Pokedex_Shared_Backend
import Shared_UI_Support
public typealias PokemonDetailModel = PokemonDetail

// Add protocol
protocol PokemonContentViewController: UIViewController {
    init(pokemon: PokemonDetailModel)
}

public class PokemonDetailViewController: UIViewController {
    private let viewModel: PokemonDetailViewModel
    private let disposeBag = DisposeBag()
    
    private var loadingViewController: LoadingViewController?
    private var errorViewController: RobotErrorViewController?
    
    // Replace individual content view controllers with array and current index
    private var contentViewControllers: [PokemonContentViewController.Type] = [
        DetailDesign1ViewController.self,
        DetailDesign2ViewController.self
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
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
        
        self.loadingViewController = loadingVC
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
        
        self.currentContentViewController = contentVC
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
        
        self.errorViewController = errorVC
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

// Update view controllers to conform to protocol
extension DetailDesign1ViewController: PokemonContentViewController {}
extension DetailDesign2ViewController: PokemonContentViewController {}

#if DEBUG
import SwiftUI
#Preview {
    UIViewControllerPreview {
        let viewModel = PokemonDetailViewModel(pokemonService: .shared)
        let detailVC = PokemonDetailViewController(viewModel: viewModel)
        viewModel.loadPokemon(id: 25)
        let navVC = UINavigationController(rootViewController: UIViewController())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            navVC.pushViewController(detailVC, animated: false)
        })
        return navVC
    }
}
#endif

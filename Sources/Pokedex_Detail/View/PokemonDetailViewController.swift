import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Pokedex_Shared_Backend

public typealias PokemonDetailModel = PokemonDetail

public class PokemonDetailViewController: UIViewController {
    private let viewModel: PokemonDetailViewModel
    private let disposeBag = DisposeBag()
    
    private var loadingViewController: LoadingViewController?
    private var contentViewController: PokemonContentDetailViewController?
    private var errorViewController: RobotErrorViewController?
    
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
            })
            .disposed(by: disposeBag)
        
        // Bind error
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showErrorView()
            })
            .disposed(by: disposeBag)
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
        
        let contentVC = PokemonContentDetailViewController(pokemon: pokemon)
        addChild(contentVC)
        containerView.addSubview(contentVC.view)
        contentVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentVC.didMove(toParent: self)
        
        self.contentViewController = contentVC
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
        
        contentViewController?.willMove(toParent: nil)
        contentViewController?.view.removeFromSuperview()
        contentViewController?.removeFromParent()
        contentViewController = nil
        
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
#if DEBUG
import SwiftUI
#Preview {
    UIViewControllerPreview {
        let viewModel = PokemonDetailViewModel(pokemonService: .shared)
        let detailVC = PokemonDetailViewController(viewModel: viewModel)
        viewModel.loadPokemon(id: 25)
        let navVC = UINavigationController()
        navVC.pushViewController(detailVC, animated: false)
        return navVC
    }
}
#endif

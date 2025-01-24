import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import Pokedex_Shared_Backend

public typealias PokemonDetailModel = PokemonDetail

public class PokemonDetailViewController: UIViewController {
    private let viewModel: PokemonDetailViewModel
    private let disposeBag = DisposeBag()
    
    private var loadingViewController: LoadingViewController?
    private var contentViewController: PokemonContentDetailViewController?
    private var errorViewController: RobotErrorViewController?
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
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
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statsStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
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
        loadingVC.view.frame = view.bounds
        view.addSubview(loadingVC.view)
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
        contentVC.view.frame = view.bounds
        view.addSubview(contentVC.view)
        contentVC.didMove(toParent: self)
        
        self.contentViewController = contentVC
    }
    
    private func showErrorView() {
        removeCurrentChildViewController()
        
        let errorVC = RobotErrorViewController()
        errorVC.delegate = self
        addChild(errorVC)
        errorVC.view.frame = view.bounds
        view.addSubview(errorVC.view)
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
        // Retry loading the pokemon
        if let currentPokemonId = viewModel.currentPokemonId {
            viewModel.loadPokemon(id: currentPokemonId)
        }
    }
}

private class StatView: UIView {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(nameLabel)
        addSubview(valueLabel)
        addSubview(progressView)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            valueLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            
            progressView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with stat: PokemonDetail.Stat) {
        nameLabel.text = stat.name.capitalized
        valueLabel.text = "\(stat.baseStat)"
        progressView.progress = Float(stat.baseStat) / 255.0
    }
}

import UIKit
import Combine
public class ProfileViewController: UIViewController, ProfileContentViewControllerDelegate {
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
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
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add unauthorized and error views
        [unauthorizedView, errorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
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
            
            
        case .loaded(let profile):
            let contentVC = ProfileContentViewController(profile: profile)
            contentVC.delegate = self
            contentVC.coordinator = coordinator
            addChild(contentVC)
            contentVC.view.frame = view.bounds
            view.addSubview(contentVC.view)
            contentVC.didMove(toParent: self)
            self.contentViewController = contentVC
            
        case .error(let error):
            errorView.isHidden = false
            errorView.configure(with: error) { [weak self] in
                self?.viewModel.fetchProfile()
            }
            
        }
    }
    
    func profileContentViewControllerDidTapSignOut(_ viewController: ProfileContentViewController) {
        viewModel.signOut()
    }
    
    // Add setter for coordinator
    func setCoordinator(_ coordinator: ProfilePageVCView.Coordinator) {
        self.coordinator = coordinator
    }
}

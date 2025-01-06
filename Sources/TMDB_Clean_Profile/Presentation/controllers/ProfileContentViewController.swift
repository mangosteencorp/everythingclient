import UIKit
class ProfileContentViewController: UIViewController {
    private let profile: ProfileEntity
    private var multiSectionViewController: MultiSectionViewController<ProfileCollectionItem>?
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    init(profile: ProfileEntity) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureWithProfile()
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Setup header stack view
        let headerStack = UIStackView(arrangedSubviews: [avatarImageView, nameLabel, usernameLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(headerStack)
        
        // Avatar size constraints
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Setup sections
        setupSections()
    }
    
    private func configureWithProfile() {
        nameLabel.text = profile.accountInfo.name
        usernameLabel.text = "@\(profile.accountInfo.username)"
        
        if let avatarPath = profile.accountInfo.avatarPath {
            // Here you would load the avatar image using your image loading system
            // For example: imageLoader.loadImage(path: avatarPath, into: avatarImageView)
        }
    }
    
    private func setupSections() {
        var sections: [Section<ProfileCollectionItem>] = []
        
        // Add watchlist section (featured)
        if let watchlist = profile.watchlistTVShows {
            let watchlistItems = watchlist.map { show in
                ProfileCollectionItem(
                    id: show.id,
                    image: show.posterPath ?? "",
                    name: show.name,
                    tagline: "TV Show",
                    subheading: "First aired: \(show.firstAirDate)"
                )
            }
            
            sections.append(Section(
                id: 1,
                type: .featured,
                title: "Watchlist",
                subtitle: "Shows you want to watch",
                items: watchlistItems
            ))
        }
        
        // Add favorite TV shows section (mediumTable)
        if let favoriteTVShows = profile.favoriteTVShows {
            let tvShowItems = favoriteTVShows.map { show in
                ProfileCollectionItem(
                    id: show.id,
                    image: show.posterPath ?? "",
                    name: show.name,
                    tagline: String(format: "%.1f★", show.voteAverage),
                    subheading: show.overview
                )
            }
            
            sections.append(Section(
                id: 2,
                type: .mediumTable,
                title: "Favorite TV Shows",
                subtitle: "Your top picks",
                items: tvShowItems
            ))
        }
        
        // Add favorite movies section (mediumTable)
        if let favoriteMovies = profile.favoriteMovies {
            let movieItems = favoriteMovies.map { movie in
                ProfileCollectionItem(
                    id: movie.id,
                    image: movie.posterPath ?? "",
                    name: movie.title,
                    tagline: String(format: "%.1f★", movie.voteAverage),
                    subheading: movie.overview
                )
            }
            
            sections.append(Section(
                id: 3,
                type: .mediumTable,
                title: "Favorite Movies",
                subtitle: "Your movie collection",
                items: movieItems
            ))
        }
        
        let multiSectionVC = MultiSectionViewController(sections: sections)
        addChild(multiSectionVC)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        multiSectionVC.view.frame = containerView.bounds
        containerView.addSubview(multiSectionVC.view)
        multiSectionVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        multiSectionVC.didMove(toParent: self)
        
        self.multiSectionViewController = multiSectionVC
    }
}

// MARK: - Profile Collection Item
struct ProfileCollectionItem: CollectionItem {
    let id: Int
    let image: String
    let name: String
    let tagline: String
    let subheading: String
}

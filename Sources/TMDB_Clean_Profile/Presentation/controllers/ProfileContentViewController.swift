import UIKit
import TMDB_Shared_Backend
import Kingfisher
class ProfileContentViewController: UIViewController {
    private let profile: ProfileEntity
    private var multiSectionViewController: MultiSectionViewController<ProfileCollectionItem>?
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBackground.cgColor
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
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
        
        // Setup header stack view with improved spacing
        let headerStack = UIStackView(arrangedSubviews: [avatarImageView, nameLabel, usernameLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add a background view for the header
        let headerBackground = UIView()
        headerBackground.backgroundColor = .secondarySystemBackground
        headerBackground.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(headerBackground)
        view.addSubview(headerStack)
        
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            headerBackground.topAnchor.constraint(equalTo: view.topAnchor),
            headerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBackground.bottomAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
            
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
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
            avatarImageView.kf.setImage(with: TMDBImageSize.original.buildImageUrl(path: avatarPath))
        }
    }
    
    private func setupSections() {
        var sections: [Section<ProfileCollectionItem>] = []
        let placeholderImageUrl = URL(string: "https://placehold.co/400")!
        // Add watchlist section (featured)
        if let watchlist = profile.watchlistTVShows {
            let watchlistItems = watchlist.map { show in
                let imageUrl = show.posterPath != nil ? TMDBImageSize.medium.buildImageUrl(path: show.posterPath!) : placeholderImageUrl
                return ProfileCollectionItem(
                    id: show.id,
                    imageURL: imageUrl,
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
                    imageURL: show.posterPath != nil ? TMDBImageSize.small.buildImageUrl(path: show.posterPath!) : placeholderImageUrl,
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
                    imageURL: movie.posterPath != nil ? TMDBImageSize.small.buildImageUrl(path: movie.posterPath!) : placeholderImageUrl,
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
    let imageURL: URL
    let name: String
    let tagline: String
    let subheading: String
}

#if DEBUG
import SwiftUI
let sampleProfileEntity = ProfileEntity(
    accountInfo: AccountInfoEntity(
        id: 21446814,
        name: "",
        username: "radiosilence",
        avatarPath: nil
    ),
    favoriteMovies: [
        MovieEntity(
            id: 1184918,
            title: "The Wild Robot",
            overview: "After a shipwreck, an intelligent robot called Roz is stranded on an uninhabited island. To survive the harsh environment, Roz bonds with the island's animals and cares for an orphaned baby goose.",
            posterPath: "/9w0Vh9eizfBXrcomiaFWTIPdboo.jpg",
            voteAverage: 8.38,
            releaseDate: "2024-09-12"
        ),
        MovieEntity(
            id: 238,
            title: "The Godfather",
            overview: "Spanning the years 1945 to 1955, a chronicle of the fictional Italian-American Corleone crime family. When organized crime family patriarch, Vito Corleone barely survives an attempt on his life, his youngest son, Michael steps in to take care of the would-be killers, launching a campaign of bloody revenge.",
            posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
            voteAverage: 8.69,
            releaseDate: "1972-03-14"
        ),
        MovieEntity(
            id: 912649,
            title: "Venom: The Last Dance",
            overview: "Eddie and Venom are on the run. Hunted by both of their worlds and with the net closing in, the duo are forced into a devastating decision that will bring the curtains down on Venom and Eddie's last dance.",
            posterPath: "/aosm8NMQ3UyoBVpSxyimorCQykC.jpg",
            voteAverage: 6.799,
            releaseDate: "2024-10-22"
        )
    ],
    favoriteTVShows: [
        TVShowEntity(
            id: 251691,
            name: "Autumn of the Heart",
            overview: "A devastating car accident unearths a long-buried secret that turns wealthy businessman Rashid and hardworking Nahla's life around; fifteen years ago, their daughters were switched at birth.",
            posterPath: "/8uDmIxjBx90y5OCwJDBADtQzxb7.jpg",
            firstAirDate: "2024-10-27",
            voteAverage: 4.222
        ),
        TVShowEntity(
            id: 2734,
            name: "Law & Order: Special Victims Unit",
            overview: "In the criminal justice system, sexually-based offenses are considered especially heinous. In New York City, the dedicated detectives who investigate these vicious felonies are members of an elite squad known as the Special Victims Unit. These are their stories.",
            posterPath: "/abWOCrIo7bbAORxcQyOFNJdnnmR.jpg",
            firstAirDate: "1999-09-20",
            voteAverage: 7.935
        )
    ],
    watchlistTVShows: [
        TVShowEntity(
            id: 251691,
            name: "Autumn of the Heart",
            overview: "A devastating car accident unearths a long-buried secret that turns wealthy businessman Rashid and hardworking Nahla's life around; fifteen years ago, their daughters were switched at birth.",
            posterPath: "/8uDmIxjBx90y5OCwJDBADtQzxb7.jpg",
            firstAirDate: "2024-10-27",
            voteAverage: 4.222
        ),
        TVShowEntity(
            id: 2734,
            name: "Law & Order: Special Victims Unit",
            overview: "In the criminal justice system, sexually-based offenses are considered especially heinous. In New York City, the dedicated detectives who investigate these vicious felonies are members of an elite squad known as the Special Victims Unit. These are their stories.",
            posterPath: "/abWOCrIo7bbAORxcQyOFNJdnnmR.jpg",
            firstAirDate: "1999-09-20",
            voteAverage: 7.935
        )
    ]
)
struct ProfileContentViewController_Previews: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            
            return ProfileContentViewController(profile: sampleProfileEntity)
        }
    }
}

// Helper struct to wrap UIViewController for SwiftUI preview
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController
    
    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

#endif

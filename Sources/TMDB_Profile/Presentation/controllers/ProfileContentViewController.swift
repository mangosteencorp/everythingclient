import Kingfisher
import Shared_UI_Support
import TMDB_Shared_Backend
import TMDB_Shared_UI
import UIKit

protocol ProfileContentViewControllerDelegate: AnyObject {
    func profileContentViewControllerDidTapSignOut(_ viewController: ProfileContentViewController)
    func profileContentViewControllerDidRefresh(_ viewController: ProfileContentViewController)
}

enum ProfileContentSection: Int {
    case watchlistTV = 1
    case favoriteTV = 2
    case favoriteMovie = 3
}

class ProfileContentViewController: UIViewController, MultiSectionViewControllerDelegate {
    weak var delegate: ProfileContentViewControllerDelegate?
    weak var coordinator: ProfilePageVCView.Coordinator?
    private let profile: ProfileEntity
    private var multiSectionViewController: MultiSectionViewController<ProfileCollectionItem>?
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private static let avatarMaxSize: CGFloat = 80
    private static let avatarMinSize: CGFloat = 36
    /// Scroll distance over which the avatar goes from full size to collapsed.
    private static let avatarCollapseDistance: CGFloat = 80
    private static let animalSymbols = [
        "hare.fill", "tortoise.fill", "dog.fill", "cat.fill", "bird.fill",
        "fish.fill", "ant.fill", "ladybug.fill", "lizard.fill", "pawprint.fill",
    ]

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = ProfileContentViewController.avatarMaxSize / 2
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.systemBackground.cgColor
        return imageView
    }()

    /// Shown inside the avatar circle when the account has no avatar.
    private let animalImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var avatarSize = avatarImageView.widthAnchor.constraint(equalToConstant: Self.avatarMaxSize)

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        // Long names truncate instead of squeezing or stretching the button.
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private var currentProfile: ProfileEntity

    init(profile: ProfileEntity) {
        self.profile = profile
        currentProfile = profile
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
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

        // Header row: avatar | name over @username | Sign Out. Its height follows the avatar (never below the text).
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        nameStack.axis = .vertical
        nameStack.spacing = 2
        let headerStack = UIStackView(arrangedSubviews: [avatarImageView, nameStack, signOutButton])
        headerStack.spacing = 12
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Add a background view for the header
        let headerBackground = UIView()
        headerBackground.backgroundColor = .secondarySystemBackground
        headerBackground.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerBackground)
        view.addSubview(headerStack)

        avatarImageView.addSubview(animalImageView)

        NSLayoutConstraint.activate([
            avatarSize,
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),

            animalImageView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            animalImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            animalImageView.widthAnchor.constraint(equalTo: avatarImageView.widthAnchor, multiplier: 0.55),
            animalImageView.heightAnchor.constraint(equalTo: avatarImageView.heightAnchor, multiplier: 0.55),

            headerBackground.topAnchor.constraint(equalTo: view.topAnchor),
            headerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBackground.bottomAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),

            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])

        // Setup sections
        setupSections(below: headerBackground)
    }

    private func configureWithProfile() {
        nameLabel.text = profile.accountInfo.name
        usernameLabel.text = "@\(profile.accountInfo.username)"
        configureAvatar(with: profile.accountInfo)
    }

    /// Account avatar, or an animal symbol (stable per account, so it doesn't change on refresh) when there is none.
    private func configureAvatar(with accountInfo: AccountInfoEntity) {
        let avatarURL = accountInfo.avatarPath.flatMap { TMDBImageSize.original.buildImageUrl(path: $0) }
        animalImageView.isHidden = avatarURL != nil
        guard let avatarURL else {
            avatarImageView.kf.cancelDownloadTask()
            avatarImageView.image = nil
            let symbols = Self.animalSymbols
            animalImageView.image = UIImage(systemName: symbols[abs(accountInfo.id) % symbols.count])
            return
        }
        avatarImageView.kf.setImage(with: avatarURL)
    }

    /// Shrinks the avatar as the list scrolls up; reverses when scrolling back.
    /// The header row shrinks with it, and the list (pinned below the header) takes the freed space.
    private func collapseAvatar(forScrollOffset offset: CGFloat) {
        let collapse = min(max(offset / Self.avatarCollapseDistance, 0), 1)
        let size = Self.avatarMaxSize - (Self.avatarMaxSize - Self.avatarMinSize) * collapse
        avatarSize.constant = size
        avatarImageView.layer.cornerRadius = size / 2
    }

    private func setupSections(below header: UIView) {
        var sections: [Section<ProfileCollectionItem>] = []
        let placeholderImageUrl = URL(string: "https://placehold.co/400")!
        // Add watchlist section (featured)
        if let watchlist = profile.watchlistTVShows {
            let watchlistItems = watchlist.map { show in
                let imageUrl = show.posterPath != nil ? TMDBImageSize.posterLarge
                    .buildImageUrl(path: show.posterPath!) ?? placeholderImageUrl : placeholderImageUrl
                return ProfileCollectionItem(
                    id: show.id,
                    imageURL: imageUrl,
                    name: show.name,
                    tagline: "TV Show",
                    subheading: "First aired: \(show.firstAirDate)"
                )
            }

            sections.append(Section(
                id: ProfileContentSection.watchlistTV.rawValue,
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
                    imageURL: show.posterPath != nil ? TMDBImageSize.posterSmall
                        .buildImageUrl(path: show.posterPath!) ?? placeholderImageUrl : placeholderImageUrl,
                    name: show.name,
                    tagline: String(format: "%.1f★", show.voteAverage),
                    subheading: show.overview
                )
            }

            sections.append(Section(
                id: ProfileContentSection.favoriteTV.rawValue,
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
                    imageURL: movie.posterPath != nil ? TMDBImageSize.posterSmall
                        .buildImageUrl(path: movie.posterPath!) ?? placeholderImageUrl : placeholderImageUrl,
                    name: movie.title,
                    tagline: String(format: "%.1f★", movie.voteAverage),
                    subheading: movie.overview
                )
            }

            sections.append(Section(
                id: ProfileContentSection.favoriteMovie.rawValue,
                type: .mediumTable,
                title: "Favorite Movies",
                subtitle: "Your movie collection",
                items: movieItems
            ))
        }

        let multiSectionVC = MultiSectionViewController(sections: sections, delegate: self)
        addChild(multiSectionVC)

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        multiSectionVC.onScroll = { [weak self] offset in self?.collapseAvatar(forScrollOffset: offset) }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: header.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        multiSectionVC.view.frame = containerView.bounds
        containerView.addSubview(multiSectionVC.view)
        multiSectionVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        multiSectionVC.didMove(toParent: self)

        multiSectionViewController = multiSectionVC

        // Setup pull-to-refresh
        setupPullToRefresh()
    }

    private func setupPullToRefresh() {
        guard let multiSectionVC = multiSectionViewController else { return }
        multiSectionVC.setupRefreshControl { [weak self] in
            guard let self = self else { return }
            self.delegate?.profileContentViewControllerDidRefresh(self)
        }
    }

    func updateProfile(_ newProfile: ProfileEntity) {
        currentProfile = newProfile
        nameLabel.text = newProfile.accountInfo.name
        usernameLabel.text = "@\(newProfile.accountInfo.username)"
        configureAvatar(with: newProfile.accountInfo)

        updateSections(with: newProfile)
        multiSectionViewController?.endRefreshing()
    }

    private func updateSections(with profile: ProfileEntity) {
        var sections: [Section<ProfileCollectionItem>] = []
        let placeholderImageUrl = URL(string: "https://placehold.co/400")!

        // Add watchlist section (featured)
        if let watchlist = profile.watchlistTVShows {
            let watchlistItems = watchlist.map { show in
                let imageUrl = show.posterPath != nil ? TMDBImageSize.posterLarge
                    .buildImageUrl(path: show.posterPath!) ?? placeholderImageUrl : placeholderImageUrl
                return ProfileCollectionItem(
                    id: show.id,
                    imageURL: imageUrl,
                    name: show.name,
                    tagline: "TV Show",
                    subheading: "First aired: \(show.firstAirDate)"
                )
            }

            sections.append(Section(
                id: ProfileContentSection.watchlistTV.rawValue,
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
                    imageURL: show.posterPath != nil ? TMDBImageSize.posterSmall
                        .buildImageUrl(path: show.posterPath!) ?? placeholderImageUrl : placeholderImageUrl,
                    name: show.name,
                    tagline: String(format: "%.1f★", show.voteAverage),
                    subheading: show.overview
                )
            }

            sections.append(Section(
                id: ProfileContentSection.favoriteTV.rawValue,
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
                    imageURL: movie.posterPath != nil ? TMDBImageSize.posterSmall
                        .buildImageUrl(path: movie.posterPath!) ?? placeholderImageUrl : placeholderImageUrl,
                    name: movie.title,
                    tagline: String(format: "%.1f★", movie.voteAverage),
                    subheading: movie.overview
                )
            }

            sections.append(Section(
                id: ProfileContentSection.favoriteMovie.rawValue,
                type: .mediumTable,
                title: "Favorite Movies",
                subtitle: "Your movie collection",
                items: movieItems
            ))
        }

        multiSectionViewController?.updateSections(sections)
    }

    @objc private func signOutTapped() {
        delegate?.profileContentViewControllerDidTapSignOut(self)
    }

    // MARK: MultiSection delegate

    func didSelectItem<ProfileCollectionItem>(
        _ item: ProfileCollectionItem,
        in section: Section<ProfileCollectionItem>
    ) {
        switch section.id {
        case ProfileContentSection.favoriteMovie.rawValue:
            if let favMov = profile.favoriteMovies?.first(where: { $0.id == item.id }) {
                coordinator?.navigateToMovie(favMov.id)
            }
        case ProfileContentSection.favoriteTV.rawValue, ProfileContentSection.watchlistTV.rawValue:
            if let tvShow = (
                profile.favoriteTVShows?.first(where: { $0.id == item.id }) ??
                    profile.watchlistTVShows?.first(where: { $0.id == item.id })
            ) {
                coordinator?.navigateToTVShow(tvShow.id)
            }
        default:
            break
        }
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

// swiftlint:disable all
#if DEBUG
import SwiftUI

let sampleProfileEntity = ProfileEntity(
    accountInfo: AccountInfoEntity(
        id: 21_446_814,
        name: "",
        username: "radiosilence",
        avatarPath: nil
    ),
    favoriteMovies: [
        MovieEntity(
            id: 1_184_918,
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
            id: 912_649,
            title: "Venom: The Last Dance",
            overview: "Eddie and Venom are on the run. Hunted by both of their worlds and with the net closing in, the duo are forced into a devastating decision that will bring the curtains down on Venom and Eddie's last dance.",
            posterPath: "/aosm8NMQ3UyoBVpSxyimorCQykC.jpg",
            voteAverage: 6.799,
            releaseDate: "2024-10-22"
        ),
    ],
    favoriteTVShows: [
        TVShowEntity(
            id: 251_691,
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
        ),
    ],
    watchlistTVShows: [
        TVShowEntity(
            id: 251_691,
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
        ),
    ]
)
#Preview {
    TMDBProfilePreviewCatalog.content.view
}

#Preview("Long name") {
    TMDBProfilePreviewCatalog.contentLongName.view
}
#endif
// swiftlint:enable all

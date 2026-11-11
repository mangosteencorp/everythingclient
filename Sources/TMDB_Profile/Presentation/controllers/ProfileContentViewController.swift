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

    private static let avatarMaxSize: CGFloat = 120
    private static let avatarMinSize: CGFloat = 32
    private static let headerTopPadding: CGFloat = 24
    private static let animalSymbols = [
        "hare.fill", "tortoise.fill", "dog.fill", "cat.fill", "bird.fill",
        "fish.fill", "ant.fill", "ladybug.fill", "lizard.fill", "pawprint.fill",
    ]

    /// The list's content offset: the header's top edge sits at minus this, in this view's coordinates.
    private var contentOffsetY: CGFloat?

    /// Holds the big avatar's place in the header; the avatar itself is drawn once, above the list.
    private let avatarPlaceholder: UIView = {
        let view = UIView()
        view.widthAnchor.constraint(equalToConstant: ProfileContentViewController.avatarMaxSize).isActive = true
        view.heightAnchor.constraint(equalToConstant: ProfileContentViewController.avatarMaxSize).isActive = true
        return view
    }()

    /// Moves from the header into the navigation bar's trailing edge as the list scrolls.
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
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

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
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
        button.setTitle(String(localized: .profileSignOut), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        return button
    }()

    /// The navigation bar's title: the name fades in there as the avatar docks.
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.alpha = 0
        return label
    }()

    /// Holds `titleLabel` in the bar: the bar resets its title view's own alpha, so the fade has to happen inside.
    private lazy var titleView: UIView = {
        let container = UIView()
        container.addSubview(titleLabel)
        return container
    }()

    /// Big avatar, name over @username, Sign Out; it scrolls with the list, so the list never resizes.
    private lazy var headerView: UIView = {
        let stack = UIStackView(arrangedSubviews: [avatarPlaceholder, nameLabel, usernameLabel, signOutButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: Self.headerTopPadding, leading: 16, bottom: 8, trailing: 16)
        return stack
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
        view.backgroundColor = .systemBackground
        setupSections()
        avatarImageView.addSubview(animalImageView)
        NSLayoutConstraint.activate([
            animalImageView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            animalImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            animalImageView.widthAnchor.constraint(equalTo: avatarImageView.widthAnchor, multiplier: 0.55),
            animalImageView.heightAnchor.constraint(equalTo: avatarImageView.heightAnchor, multiplier: 0.55),
        ])
        // Above the list, so it stays sharp under the bar's scroll edge effect.
        view.addSubview(avatarImageView)
        configureWithProfile(profile)
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        navigationBarHost?.navigationItem.titleView = titleView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutAvatar()
    }

    private func configureWithProfile(_ profile: ProfileEntity) {
        let accountInfo = profile.accountInfo
        let username = String(localized: .profileUsernameFormat(accountInfo.username))
        nameLabel.text = accountInfo.name
        nameLabel.isHidden = accountInfo.name.isEmpty
        usernameLabel.text = username
        titleLabel.text = accountInfo.name.isEmpty ? username : accountInfo.name
        titleLabel.sizeToFit()
        titleView.frame = titleLabel.bounds
        configureAvatar(with: accountInfo)
    }

    /// Account avatar, or an animal symbol (stable per account, so it doesn't change on refresh) when there is none.
    private func configureAvatar(with accountInfo: AccountInfoEntity) {
        let avatarURL = accountInfo.avatarPath.flatMap { TMDBImageSize.original.buildImageUrl(path: $0) }
        animalImageView.isHidden = avatarURL != nil
        guard let avatarURL else {
            avatarImageView.kf.cancelDownloadTask()
            avatarImageView.image = nil
            animalImageView.image = UIImage(systemName: Self.animalSymbols[abs(accountInfo.id) % Self.animalSymbols.count])
            return
        }
        avatarImageView.kf.setImage(with: avatarURL)
    }

    /// Where the docked avatar sits: the navigation bar's trailing edge, as a trailing bar item would.
    private var dockedSlot: CGRect? {
        guard let bar = navigationController?.navigationBar, bar.window != nil else { return nil }
        let frame = view.convert(bar.bounds, from: bar)
        let size = Self.avatarMinSize
        return CGRect(x: frame.maxX - bar.directionalLayoutMargins.trailing - size, y: frame.midY - size / 2, width: size, height: size)
    }

    /// Y follows the header until the avatar reaches the bar, then sticks; X eases in, so it rises first and then
    /// sweeps right. The bar title fades in over the last 30%.
    private func layoutAvatar() {
        // From the scroll offset, not the placeholder's frame: the header may not be laid out yet, or recycled.
        let restMidY = view.safeAreaInsets.top + Self.headerTopPadding + Self.avatarMaxSize / 2
        let bigMidY = contentOffsetY.map { Self.headerTopPadding + Self.avatarMaxSize / 2 - $0 } ?? restMidY
        var progress: CGFloat = 0
        var center = CGPoint(x: view.bounds.midX, y: bigMidY)
        if let slot = dockedSlot, restMidY > slot.midY {
            progress = min(max((restMidY - bigMidY) / (restMidY - slot.midY), 0), 1)
            center = CGPoint(x: center.x + (slot.midX - center.x) * progress * progress, y: max(bigMidY, slot.midY))
        }
        let size = Self.avatarMaxSize - (Self.avatarMaxSize - Self.avatarMinSize) * progress
        avatarImageView.bounds.size = CGSize(width: size, height: size)
        avatarImageView.center = center
        avatarImageView.layer.cornerRadius = size / 2
        titleLabel.alpha = min(max((progress - 0.7) / 0.3, 0), 1)
    }

    private func setupSections() {
        let multiSectionVC = MultiSectionViewController(sections: makeSections(for: profile), headerView: headerView, delegate: self)
        multiSectionVC.onScroll = { [weak self] offset in
            self?.contentOffsetY = offset
            self?.layoutAvatar()
        }
        addChild(multiSectionVC)

        // Fills the page, under the bars: the list insets its own content for them, and they track its scrolling.
        multiSectionVC.view.frame = view.bounds
        view.addSubview(multiSectionVC.view)
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
        configureWithProfile(newProfile)
        multiSectionViewController?.updateSections(makeSections(for: newProfile))
        multiSectionViewController?.endRefreshing()
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

private extension ProfileContentViewController {
    /// The watchlist (featured), then favourite TV shows and movies (medium tables), for the account's lists it has.
    func makeSections(for profile: ProfileEntity) -> [Section<ProfileCollectionItem>] {
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

        return sections
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
    UIViewControllerPreview { ProfileContentViewController(profile: sampleProfileEntity) }
}

#Preview("Long name") {
    UIViewControllerPreview {
        ProfileContentViewController(profile: ProfileEntity(
            accountInfo: AccountInfoEntity(
                id: 7,
                name: "Maximilian Alexander Featherstonehaugh-Montgomery",
                username: "maximilian_alexander_featherstonehaugh",
                avatarPath: nil
            ),
            favoriteMovies: sampleProfileEntity.favoriteMovies,
            favoriteTVShows: sampleProfileEntity.favoriteTVShows,
            watchlistTVShows: sampleProfileEntity.watchlistTVShows
        ))
    }
}
#endif
// swiftlint:enable all

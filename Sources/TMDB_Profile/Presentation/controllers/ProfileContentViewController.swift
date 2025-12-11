import Kingfisher
import Shared_UI_Support
import TMDB_Shared_Backend

protocol ProfileContentViewControllerDelegate: AnyObject {
    func profileContentViewControllerDidTapSignOut(_ viewController: ProfileContentViewController)
    func profileContentViewControllerDidRefresh(_ viewController: ProfileContentViewController)
}

enum ProfileContentSection: Int {
    case watchlistTV = 1
    case favoriteTV = 2
    case favoriteMovie = 3
}

#if canImport(UIKit)
import UIKit

class ProfileContentViewController: UIViewController, MultiSectionViewControllerDelegate {
    weak var delegate: ProfileContentViewControllerDelegate?
    weak var coordinator: ProfilePageVCView.Coordinator?
    private let profile: ProfileEntity
    private var multiSectionViewController: MultiSectionViewController<ProfileCollectionItem>?
    private let scrollView = UIScrollView()
    private let contentView = UIView()

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

    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
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

        // Setup header stack view with improved spacing
        let headerStack = UIStackView(arrangedSubviews: [avatarImageView, nameLabel, usernameLabel, signOutButton])
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
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        setupSections()
    }

    private func configureWithProfile() {
        nameLabel.text = profile.accountInfo.name
        usernameLabel.text = "@\(profile.accountInfo.username)"

        if let avatarPath = profile.accountInfo.avatarPath {
            avatarImageView.kf.setImage(with: TMDBImageSize.original.buildImageUrl(path: avatarPath))
        }
    }

    private func setupSections() {
        let sections = ProfileSectionsBuilder.sections(from: profile)

        let multiSectionVC = MultiSectionViewController(sections: sections, delegate: self)
        addChild(multiSectionVC)

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        multiSectionVC.view.frame = containerView.bounds
        containerView.addSubview(multiSectionVC.view)
        multiSectionVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        multiSectionVC.didMove(toParent: self)

        multiSectionVC.setupRefreshControl { [weak self] in
            guard let self = self else { return }
            self.delegate?.profileContentViewControllerDidRefresh(self)
        }

        multiSectionViewController = multiSectionVC
    }

    func updateProfile(_ newProfile: ProfileEntity) {
        currentProfile = newProfile
        nameLabel.text = newProfile.accountInfo.name
        usernameLabel.text = "@\(newProfile.accountInfo.username)"

        if let avatarPath = newProfile.accountInfo.avatarPath {
            avatarImageView.kf.setImage(with: TMDBImageSize.original.buildImageUrl(path: avatarPath))
        }

        updateSections(with: newProfile)
        multiSectionViewController?.endRefreshing()
    }

    private func updateSections(with profile: ProfileEntity) {
        let sections = ProfileSectionsBuilder.sections(from: profile)
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

#if DEBUG
import SwiftUI

// swiftlint:disable all
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
struct ProfileContentViewController_Previews: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            ProfileContentViewController(profile: sampleProfileEntity)
        }
    }
}
// swiftlint:enable all
#endif

#elseif canImport(AppKit)
import AppKit
import SwiftUI

class ProfileContentViewController: NSViewController, MultiSectionViewControllerDelegate {
    weak var delegate: ProfileContentViewControllerDelegate?
    weak var coordinator: ProfilePageVCView.Coordinator?
    private let profile: ProfileEntity
    private var currentProfile: ProfileEntity
    private var multiSectionViewController: MultiSectionViewController<ProfileCollectionItem>?

    private let avatarImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 40
        imageView.layer?.masksToBounds = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.layer?.borderWidth = 3
        imageView.layer?.borderColor = NSColor.windowBackgroundColor.cgColor
        return imageView
    }()

    private let nameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .boldSystemFont(ofSize: 22)
        label.alignment = .center
        return label
    }()

    private let usernameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        return label
    }()

    private lazy var signOutButton: NSButton = {
        let button = NSButton(title: "Sign Out", target: self, action: #selector(signOutTapped))
        button.bezelStyle = .rounded
        button.contentTintColor = .systemRed
        return button
    }()

    private let headerStack: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 6
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let headerBackground: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentContainer: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(profile: ProfileEntity) {
        self.profile = profile
        currentProfile = profile
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureWithProfile()
    }

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        view.addSubview(headerBackground)
        headerBackground.addSubview(headerStack)
        view.addSubview(contentContainer)

        headerStack.addArrangedSubview(avatarImageView)
        headerStack.addArrangedSubview(nameLabel)
        headerStack.addArrangedSubview(usernameLabel)
        headerStack.addArrangedSubview(signOutButton)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerBackground.topAnchor.constraint(equalTo: view.topAnchor),
            headerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerStack.topAnchor.constraint(equalTo: headerBackground.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: headerBackground.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: headerBackground.trailingAnchor),
            headerStack.bottomAnchor.constraint(equalTo: headerBackground.bottomAnchor, constant: -12),

            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),

            contentContainer.topAnchor.constraint(equalTo: headerBackground.bottomAnchor, constant: 20),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        setupSections()
    }

    private func configureWithProfile() {
        nameLabel.stringValue = profile.accountInfo.name
        usernameLabel.stringValue = "@\(profile.accountInfo.username)"

        if let avatarPath = profile.accountInfo.avatarPath {
            avatarImageView.kf.setImage(with: TMDBImageSize.original.buildImageUrl(path: avatarPath))
        }
    }

    private func setupSections() {
        let sections = ProfileSectionsBuilder.sections(from: profile)
        let multiSectionVC = MultiSectionViewController(sections: sections, delegate: self)

        addChild(multiSectionVC)

        let sectionsView = multiSectionVC.view
        sectionsView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(sectionsView)

        NSLayoutConstraint.activate([
            sectionsView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            sectionsView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            sectionsView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            sectionsView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
        ])

        
        multiSectionVC.setupRefreshControl { [weak self] in
            guard let self = self else { return }
            self.delegate?.profileContentViewControllerDidRefresh(self)
        }

        multiSectionViewController = multiSectionVC
    }

    func updateProfile(_ newProfile: ProfileEntity) {
        currentProfile = newProfile
        nameLabel.stringValue = newProfile.accountInfo.name
        usernameLabel.stringValue = "@\(newProfile.accountInfo.username)"

        if let avatarPath = newProfile.accountInfo.avatarPath {
            avatarImageView.kf.setImage(with: TMDBImageSize.original.buildImageUrl(path: avatarPath))
        }

        updateSections(with: newProfile)
        multiSectionViewController?.endRefreshing()
    }

    private func updateSections(with profile: ProfileEntity) {
        let sections = ProfileSectionsBuilder.sections(from: profile)
        multiSectionViewController?.updateSections(sections)
    }

    @objc private func signOutTapped() {
        delegate?.profileContentViewControllerDidTapSignOut(self)
    }

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
#endif

private enum ProfileSectionsBuilder {
    static func sections(from profile: ProfileEntity) -> [Section<ProfileCollectionItem>] {
        var sections: [Section<ProfileCollectionItem>] = []
        let placeholderImageUrl = URL(string: "https://placehold.co/400")!

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
